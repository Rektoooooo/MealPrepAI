/**
 * Rate Limiter Utility
 *
 * Firestore-backed rate limiting per device to prevent API abuse.
 * Limits: 5 plans/day, 20 swaps/day, 30 substitutions/day
 */

import * as admin from 'firebase-admin';

const DEBUG = process.env.FUNCTIONS_EMULATOR === 'true';

// Lazy initialization to avoid accessing Firestore before app is initialized
function getDb() {
  return admin.firestore();
}

// Rate limit configurations per endpoint
export const RATE_LIMITS = {
  'generate-plan': { limit: 5, windowHours: 24 },
  'swap-meal': { limit: 20, windowHours: 24 },
  'substitute-ingredient': { limit: 30, windowHours: 24 },
} as const;

export type RateLimitEndpoint = keyof typeof RATE_LIMITS;

// In-memory cache for rate limit checks to reduce Firestore transactions
interface RateLimitCacheEntry {
  count: number;
  resetAt: number;   // ms since epoch when the window resets
  checkedAt: number;  // ms since epoch when this was last verified from Firestore
}

const rateLimitCache = new Map<string, RateLimitCacheEntry>();
const CACHE_TTL_MS = 60_000; // 60 seconds

// Periodically clear expired entries every 5 minutes
setInterval(() => {
  const now = Date.now();
  for (const [key, entry] of rateLimitCache) {
    if (now > entry.resetAt || now - entry.checkedAt > CACHE_TTL_MS * 5) {
      rateLimitCache.delete(key);
    }
  }
}, 5 * 60_000);

interface RateLimitDoc {
  deviceId: string;
  endpoint: string;
  count: number;
  windowStart: admin.firestore.Timestamp;
  lastRequest: admin.firestore.Timestamp;
}

interface RateLimitResult {
  allowed: boolean;
  remaining: number;
  resetTime: Date;
  limit: number;
}

/**
 * Check if a request is within rate limits and increment counter
 */
export async function checkRateLimit(
  deviceId: string,
  endpoint: RateLimitEndpoint
): Promise<RateLimitResult> {
  if (DEBUG) console.log('[DEBUG:RateLimit] Checking rate limit:', { deviceId, endpoint });

  const config = RATE_LIMITS[endpoint];
  const docId = `${deviceId}_${endpoint}`;

  // Check in-memory cache first: if recently checked and well within limits, skip Firestore
  const now = Date.now();
  const cached = rateLimitCache.get(docId);
  if (cached && (now - cached.checkedAt < CACHE_TTL_MS) && now < cached.resetAt) {
    // Well within limits (< 50% of limit) — serve from cache
    if (cached.count < config.limit * 0.5) {
      cached.count += 1;
      console.log('[DEBUG:RateLimit] Cache hit (within limits):', { count: cached.count, limit: config.limit });
      return {
        allowed: true,
        remaining: config.limit - cached.count,
        resetTime: new Date(cached.resetAt),
        limit: config.limit,
      };
    }
  }

  const docRef = getDb().collection('rate_limits').doc(docId);

  const nowTs = admin.firestore.Timestamp.now();
  const windowMs = config.windowHours * 60 * 60 * 1000;
  const windowStart = new Date(nowTs.toMillis() - windowMs);

  if (DEBUG) console.log('[DEBUG:RateLimit] Config:', { limit: config.limit, windowHours: config.windowHours });

  const result = await getDb().runTransaction(async (transaction) => {
    const doc = await transaction.get(docRef);
    const data = doc.data() as RateLimitDoc | undefined;

    // Calculate window reset time
    const resetTime = new Date(nowTs.toMillis() + windowMs);

    // Check if existing record is within the current window
    if (data && data.windowStart.toMillis() > windowStart.getTime()) {
      if (DEBUG) console.log('[DEBUG:RateLimit] Existing record found:', {
        count: data.count,
        windowStart: data.windowStart.toDate().toISOString(),
      });

      // Still within window
      if (data.count >= config.limit) {
        // Rate limited
        const windowResetTime = new Date(
          data.windowStart.toMillis() + windowMs
        );
        if (DEBUG) console.log('[DEBUG:RateLimit] RATE LIMITED - count:', data.count, '>= limit:', config.limit);
        return {
          allowed: false,
          remaining: 0,
          resetTime: windowResetTime,
          limit: config.limit,
        };
      }

      // Increment counter
      if (DEBUG) console.log('[DEBUG:RateLimit] Incrementing counter:', data.count, '->', data.count + 1);
      transaction.update(docRef, {
        count: data.count + 1,
        lastRequest: nowTs,
      });

      return {
        allowed: true,
        remaining: config.limit - data.count - 1,
        resetTime: new Date(data.windowStart.toMillis() + windowMs),
        limit: config.limit,
      };
    }

    // No record or window expired - create new window
    if (DEBUG) console.log('[DEBUG:RateLimit] Creating new rate limit window');
    const newDoc: RateLimitDoc = {
      deviceId,
      endpoint,
      count: 1,
      windowStart: nowTs,
      lastRequest: nowTs,
    };

    transaction.set(docRef, newDoc);

    return {
      allowed: true,
      remaining: config.limit - 1,
      resetTime,
      limit: config.limit,
    };
  });

  // Update in-memory cache after Firestore transaction
  rateLimitCache.set(docId, {
    count: config.limit - result.remaining,
    resetAt: result.resetTime.getTime(),
    checkedAt: Date.now(),
  });

  return result;
}

/**
 * Get current rate limit status without incrementing
 */
export async function getRateLimitStatus(
  deviceId: string,
  endpoint: RateLimitEndpoint
): Promise<RateLimitResult> {
  const config = RATE_LIMITS[endpoint];
  const docId = `${deviceId}_${endpoint}`;
  const docRef = getDb().collection('rate_limits').doc(docId);

  const now = admin.firestore.Timestamp.now();
  const windowMs = config.windowHours * 60 * 60 * 1000;
  const windowStart = new Date(now.toMillis() - windowMs);

  const doc = await docRef.get();
  const data = doc.data() as RateLimitDoc | undefined;

  if (data && data.windowStart.toMillis() > windowStart.getTime()) {
    return {
      allowed: data.count < config.limit,
      remaining: Math.max(0, config.limit - data.count),
      resetTime: new Date(data.windowStart.toMillis() + windowMs),
      limit: config.limit,
    };
  }

  // No record or window expired
  return {
    allowed: true,
    remaining: config.limit,
    resetTime: new Date(now.toMillis() + windowMs),
    limit: config.limit,
  };
}

/**
 * Clean up expired rate limit records (run periodically)
 */
export async function cleanupExpiredRateLimits(): Promise<number> {
  const now = admin.firestore.Timestamp.now();
  const maxWindowMs = 24 * 60 * 60 * 1000; // 24 hours
  const expiredBefore = new Date(now.toMillis() - maxWindowMs * 2);

  const expired = await getDb()
    .collection('rate_limits')
    .where('windowStart', '<', admin.firestore.Timestamp.fromDate(expiredBefore))
    .limit(500)
    .get();

  if (expired.empty) {
    return 0;
  }

  const batch = getDb().batch();
  expired.docs.forEach((doc: FirebaseFirestore.QueryDocumentSnapshot) => {
    batch.delete(doc.ref);
  });

  await batch.commit();
  return expired.size;
}
