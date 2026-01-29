import * as admin from 'firebase-admin';
import {
  SignedDataVerifier,
  Environment,
  JWSTransactionDecodedPayload,
  JWSRenewalInfoDecodedPayload,
} from '@apple/app-store-server-library';

// Lazy-init to avoid calling firestore() before admin.initializeApp()
function getDb(): admin.firestore.Firestore {
  return admin.firestore();
}
const SUBSCRIPTIONS_COLLECTION = 'subscriptions';

// Subscription status values
export type SubscriptionStatus =
  | 'none'
  | 'active'
  | 'expired'
  | 'revoked'
  | 'billing_retry';

export interface SubscriptionDoc {
  originalTransactionId: string | null;
  productId: string | null;
  status: SubscriptionStatus;
  expiresDate: admin.firestore.Timestamp | null;
  purchaseDate: admin.firestore.Timestamp | null;
  autoRenewEnabled: boolean;
  plansGenerated: number;
  environment: string;
  lastVerifiedAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
}

let _verifier: SignedDataVerifier | null = null;

function getVerifier(): SignedDataVerifier {
  if (_verifier) return _verifier;

  const bundleId = process.env.APPLE_BUNDLE_ID || 'com.mealprepai';
  const appAppleId = parseInt(process.env.APPLE_APP_ID || '0', 10);
  const isProduction = process.env.FUNCTIONS_EMULATOR !== 'true';
  const environment = isProduction ? Environment.PRODUCTION : Environment.SANDBOX;

  // Apple root certificates - in production, download from Apple and store as env vars or files
  // For now, pass empty array; the library will use built-in Apple root certs
  _verifier = new SignedDataVerifier(
    [], // Apple root certificates (library includes defaults)
    true, // enableOnlineChecks
    environment,
    bundleId,
    appAppleId,
  );

  return _verifier;
}

export async function verifyAndStoreTransaction(
  deviceId: string,
  signedTransactionJWS: string,
): Promise<{ success: boolean; status: SubscriptionStatus; expiresDate: Date | null }> {
  const verifier = getVerifier();

  // Verify the JWS and decode the transaction
  const transaction: JWSTransactionDecodedPayload =
    await verifier.verifyAndDecodeTransaction(signedTransactionJWS);

  const expiresDate = transaction.expiresDate
    ? new Date(transaction.expiresDate)
    : null;
  const purchaseDate = transaction.purchaseDate
    ? new Date(transaction.purchaseDate)
    : null;

  const now = new Date();
  let status: SubscriptionStatus = 'none';

  if (transaction.revocationDate) {
    status = 'revoked';
  } else if (expiresDate && expiresDate > now) {
    status = 'active';
  } else if (expiresDate && expiresDate <= now) {
    status = 'expired';
  }

  const docRef = getDb().collection(SUBSCRIPTIONS_COLLECTION).doc(deviceId);
  const existingDoc = await docRef.get();

  const updateData: Partial<SubscriptionDoc> & { updatedAt: admin.firestore.Timestamp; lastVerifiedAt: admin.firestore.Timestamp } = {
    originalTransactionId: transaction.originalTransactionId ?? null,
    productId: transaction.productId ?? null,
    status,
    expiresDate: expiresDate ? admin.firestore.Timestamp.fromDate(expiresDate) : null,
    purchaseDate: purchaseDate ? admin.firestore.Timestamp.fromDate(purchaseDate) : null,
    autoRenewEnabled: false, // Will be updated by renewal info if available
    environment: transaction.environment ?? 'Production',
    lastVerifiedAt: admin.firestore.Timestamp.now(),
    updatedAt: admin.firestore.Timestamp.now(),
  };

  if (existingDoc.exists) {
    await docRef.update(updateData);
  } else {
    await docRef.set({
      ...updateData,
      plansGenerated: 0,
    });
  }

  return { success: true, status, expiresDate };
}

export async function getSubscriptionStatus(
  deviceId: string,
): Promise<SubscriptionDoc | null> {
  const docRef = getDb().collection(SUBSCRIPTIONS_COLLECTION).doc(deviceId);
  const doc = await docRef.get();

  if (!doc.exists) return null;
  return doc.data() as SubscriptionDoc;
}

export function isEntitled(status: SubscriptionStatus): boolean {
  return status === 'active' || status === 'billing_retry';
}

export async function incrementPlansGenerated(deviceId: string): Promise<void> {
  const docRef = getDb().collection(SUBSCRIPTIONS_COLLECTION).doc(deviceId);
  await docRef.set(
    {
      plansGenerated: admin.firestore.FieldValue.increment(1),
      updatedAt: admin.firestore.Timestamp.now(),
    },
    { merge: true },
  );
}

export async function updateStatusByOriginalTransactionId(
  originalTransactionId: string,
  status: SubscriptionStatus,
  expiresDate?: Date | null,
  autoRenewEnabled?: boolean,
): Promise<void> {
  const snapshot = await getDb()
    .collection(SUBSCRIPTIONS_COLLECTION)
    .where('originalTransactionId', '==', originalTransactionId)
    .limit(1)
    .get();

  if (snapshot.empty) {
    console.warn(`No subscription found for originalTransactionId: ${originalTransactionId}`);
    return;
  }

  const docRef = snapshot.docs[0].ref;
  const updateData: Record<string, unknown> = {
    status,
    updatedAt: admin.firestore.Timestamp.now(),
    lastVerifiedAt: admin.firestore.Timestamp.now(),
  };

  if (expiresDate !== undefined) {
    updateData.expiresDate = expiresDate
      ? admin.firestore.Timestamp.fromDate(expiresDate)
      : null;
  }

  if (autoRenewEnabled !== undefined) {
    updateData.autoRenewEnabled = autoRenewEnabled;
  }

  await docRef.update(updateData);
}

export { getVerifier, JWSRenewalInfoDecodedPayload };
