/**
 * Rate Limiter Utility
 *
 * Firestore-backed rate limiting per device to prevent API abuse.
 * Limits: 5 plans/day, 20 swaps/day, 30 substitutions/day
 */

import * as admin from 'firebase-admin';

// Lazy initialization to avoid accessing Firestore before app is initialized
function getDb() {
  return admin.firestore();
}

// Rate limit configurations per endpoint
// Increased for testing - TODO: reduce for production
export const RATE_LIMITS = {
  'generate-plan': { limit: 50, windowHours: 24 },
  'swap-meal': { limit: 100, windowHours: 24 },
  'substitute-ingredient': { limit: 100, windowHours: 24 },
} as const;

export type RateLimitEndpoint = keyof typeof RATE_LIMITS;

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
  console.log('[DEBUG:RateLimit] Checking rate limit:', { deviceId, endpoint });

  const config = RATE_LIMITS[endpoint];
  const docId = `${deviceId}_${endpoint}`;
  const docRef = getDb().collection('rate_limits').doc(docId);

  const now = admin.firestore.Timestamp.now();
  const windowMs = config.windowHours * 60 * 60 * 1000;
  const windowStart = new Date(now.toMillis() - windowMs);

  console.log('[DEBUG:RateLimit] Config:', { limit: config.limit, windowHours: config.windowHours });

  return await getDb().runTransaction(async (transaction) => {
    const doc = await transaction.get(docRef);
    const data = doc.data() as RateLimitDoc | undefined;

    // Calculate window reset time
    const resetTime = new Date(now.toMillis() + windowMs);

    // Check if existing record is within the current window
    if (data && data.windowStart.toMillis() > windowStart.getTime()) {
      console.log('[DEBUG:RateLimit] Existing record found:', {
        count: data.count,
        windowStart: data.windowStart.toDate().toISOString(),
      });

      // Still within window
      if (data.count >= config.limit) {
        // Rate limited
        const windowResetTime = new Date(
          data.windowStart.toMillis() + windowMs
        );
        console.log('[DEBUG:RateLimit] RATE LIMITED - count:', data.count, '>= limit:', config.limit);
        return {
          allowed: false,
          remaining: 0,
          resetTime: windowResetTime,
          limit: config.limit,
        };
      }

      // Increment counter
      console.log('[DEBUG:RateLimit] Incrementing counter:', data.count, '->', data.count + 1);
      transaction.update(docRef, {
        count: data.count + 1,
        lastRequest: now,
      });

      return {
        allowed: true,
        remaining: config.limit - data.count - 1,
        resetTime: new Date(data.windowStart.toMillis() + windowMs),
        limit: config.limit,
      };
    }

    // No record or window expired - create new window
    console.log('[DEBUG:RateLimit] Creating new rate limit window');
    const newDoc: RateLimitDoc = {
      deviceId,
      endpoint,
      count: 1,
      windowStart: now,
      lastRequest: now,
    };

    transaction.set(docRef, newDoc);

    return {
      allowed: true,
      remaining: config.limit - 1,
      resetTime,
      limit: config.limit,
    };
  });
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
