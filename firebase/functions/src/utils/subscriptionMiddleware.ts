import { Request, Response, NextFunction } from 'express';
import { getSubscriptionStatus, isEntitled } from './subscriptionVerifier';

// In-memory subscription status cache with 5-minute TTL
interface SubscriptionCacheEntry {
  isSubscribed: boolean;
  plansGenerated: number;
  expiresAt: number;   // subscription expiry (ms epoch)
  cachedAt: number;     // when this entry was cached (ms epoch)
}

const subscriptionCache = new Map<string, SubscriptionCacheEntry>();
const SUBSCRIPTION_CACHE_TTL_MS = 5 * 60_000; // 5 minutes

/**
 * Invalidate a cached subscription entry (call when webhook updates arrive)
 */
export function invalidateSubscriptionCache(deviceId: string): void {
  subscriptionCache.delete(deviceId);
}

/**
 * Express middleware that gates endpoints behind active subscription.
 * Allows access if:
 * 1. User has never generated a plan (free trial: first plan free)
 * 2. User has an active or billing_retry subscription
 *
 * Expects `deviceId` in the request body.
 */
export const requireSubscription = async (
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> => {
  const deviceId = req.body?.deviceId;

  if (!deviceId) {
    res.status(400).json({
      success: false,
      error: 'Missing deviceId',
    });
    return;
  }

  // Check in-memory cache first
  const now = Date.now();
  const cached = subscriptionCache.get(deviceId);
  if (cached && (now - cached.cachedAt < SUBSCRIPTION_CACHE_TTL_MS)) {
    // Free trial: first plan is free
    if (cached.plansGenerated === 0) {
      next();
      return;
    }
    if (cached.isSubscribed) {
      next();
      return;
    }
    res.status(403).json({
      success: false,
      error: 'subscription_required',
    });
    return;
  }

  const subscription = await getSubscriptionStatus(deviceId);

  // No subscription record yet — first-time user, allow free trial
  if (!subscription) {
    subscriptionCache.set(deviceId, {
      isSubscribed: false,
      plansGenerated: 0,
      expiresAt: 0,
      cachedAt: now,
    });
    next();
    return;
  }

  // Cache the result
  const entitled = isEntitled(subscription.status);
  subscriptionCache.set(deviceId, {
    isSubscribed: entitled,
    plansGenerated: subscription.plansGenerated,
    expiresAt: subscription.expiresDate?.toMillis() || 0,
    cachedAt: now,
  });

  // Free trial: first plan is free
  if (subscription.plansGenerated === 0) {
    next();
    return;
  }

  // Active subscription — allow
  if (entitled) {
    next();
    return;
  }

  // Not entitled
  res.status(403).json({
    success: false,
    error: 'subscription_required',
  });
};
