import { Request, Response } from 'express';
import {
  getVerifier,
  updateStatusByOriginalTransactionId,
  SubscriptionStatus,
} from '../utils/subscriptionVerifier';

/**
 * POST /v1/apple-notifications
 * Webhook for Apple Server Notifications V2.
 * Apple sends signed notifications for subscription lifecycle events.
 * NOT protected by App Check (Apple calls this directly).
 */
export const handleAppStoreWebhook = async (
  req: Request,
  res: Response,
): Promise<void> => {
  const { signedPayload } = req.body;

  if (!signedPayload) {
    res.status(400).json({ error: 'Missing signedPayload' });
    return;
  }

  try {
    const verifier = getVerifier();
    const notification = await verifier.verifyAndDecodeNotification(signedPayload);

    const notificationType = notification.notificationType;
    const subtype = notification.subtype;
    console.log(`[apple-webhook] Received: ${notificationType} / ${subtype ?? 'none'}`);

    // Decode the transaction info from the notification
    const signedTransactionInfo = notification.data?.signedTransactionInfo;
    if (!signedTransactionInfo) {
      console.warn('[apple-webhook] No transaction info in notification');
      res.status(200).json({ received: true });
      return;
    }

    const transaction = await verifier.verifyAndDecodeTransaction(signedTransactionInfo);
    const originalTransactionId = transaction.originalTransactionId;

    if (!originalTransactionId) {
      console.warn('[apple-webhook] No originalTransactionId in transaction');
      res.status(200).json({ received: true });
      return;
    }

    const expiresDate = transaction.expiresDate
      ? new Date(transaction.expiresDate)
      : null;

    // Map notification type to subscription status
    let status: SubscriptionStatus | null = null;
    let autoRenewEnabled: boolean | undefined;

    switch (notificationType) {
      case 'SUBSCRIBED':
      case 'DID_RENEW':
        status = 'active';
        autoRenewEnabled = true;
        break;

      case 'EXPIRED':
      case 'GRACE_PERIOD_EXPIRED':
        status = 'expired';
        autoRenewEnabled = false;
        break;

      case 'REVOKE':
      case 'REFUND':
        status = 'revoked';
        autoRenewEnabled = false;
        break;

      case 'DID_FAIL_TO_RENEW':
        status = 'billing_retry';
        break;

      case 'DID_CHANGE_RENEWAL_STATUS':
        // Just update auto-renew flag, don't change status
        if (subtype === 'AUTO_RENEW_DISABLED') {
          autoRenewEnabled = false;
        } else if (subtype === 'AUTO_RENEW_ENABLED') {
          autoRenewEnabled = true;
        }
        break;

      default:
        console.log(`[apple-webhook] Unhandled notification type: ${notificationType}`);
    }

    if (status) {
      await updateStatusByOriginalTransactionId(
        originalTransactionId,
        status,
        expiresDate,
        autoRenewEnabled,
      );
      console.log(`[apple-webhook] Updated ${originalTransactionId} → ${status}`);
    } else if (autoRenewEnabled !== undefined) {
      // Import needed for auto-renew only update
      await updateStatusByOriginalTransactionId(
        originalTransactionId,
        'active', // keep current, but we pass active as fallback
        undefined,
        autoRenewEnabled,
      );
      console.log(`[apple-webhook] Updated auto-renew for ${originalTransactionId}`);
    }

    res.status(200).json({ received: true });
  } catch (error) {
    console.error('[apple-webhook] Error processing notification:', error);
    // Return 200 to prevent Apple from retrying on verification errors
    res.status(200).json({ received: true, error: 'processing_failed' });
  }
};
