import { Request, Response } from 'express';
import { verifyAndStoreTransaction } from '../utils/subscriptionVerifier';

/**
 * POST /v1/verify-subscription
 * Receives a signed transaction JWS from the iOS app and verifies it with Apple.
 * Stores the subscription status in Firestore.
 */
export const handleVerifySubscription = async (
  req: Request,
  res: Response,
): Promise<void> => {
  const { deviceId, signedTransactionJWS } = req.body;

  if (!deviceId || !signedTransactionJWS) {
    res.status(400).json({
      success: false,
      error: 'Missing deviceId or signedTransactionJWS',
    });
    return;
  }

  try {
    const result = await verifyAndStoreTransaction(deviceId, signedTransactionJWS);

    res.json({
      success: true,
      subscriptionStatus: result.status,
      expiresDate: result.expiresDate?.toISOString() ?? null,
    });
  } catch (error) {
    console.error('[verify-subscription] Verification failed:', error);
    res.status(400).json({
      success: false,
      error: 'Transaction verification failed',
    });
  }
};
