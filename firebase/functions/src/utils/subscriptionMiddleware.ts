import { Request, Response, NextFunction } from 'express';
import { getSubscriptionStatus, isEntitled } from './subscriptionVerifier';

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

  const subscription = await getSubscriptionStatus(deviceId);

  // No subscription record yet — first-time user, allow free trial
  if (!subscription) {
    next();
    return;
  }

  // Free trial: first plan is free
  if (subscription.plansGenerated === 0) {
    next();
    return;
  }

  // Active subscription — allow
  if (isEntitled(subscription.status)) {
    next();
    return;
  }

  // Not entitled
  res.status(403).json({
    success: false,
    error: 'subscription_required',
  });
};
