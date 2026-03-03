import { Request, Response } from 'express';
import * as admin from 'firebase-admin';

const DEBUG = process.env.FUNCTIONS_EMULATOR === 'true';

function getDb() {
  return admin.firestore();
}
const ANALYTICS_COLLECTION = 'user_analytics';
const UUID_REGEX = /^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$/i;

/**
 * POST /v1/sync-analytics
 * Receives batched counter deltas from the iOS app and merges them into Firestore.
 * Uses FieldValue.increment() for atomic counter updates.
 * Protected by App Check (NOT subscription-gated - collect from all users).
 */
export const handleSyncAnalytics = async (
  req: Request,
  res: Response,
): Promise<void> => {
  const { deviceId, counterDeltas, appVersion } = req.body;

  if (!deviceId || typeof deviceId !== 'string' || !UUID_REGEX.test(deviceId)) {
    res.status(400).json({
      success: false,
      error: 'Missing or invalid deviceId',
    });
    return;
  }

  if (!counterDeltas || typeof counterDeltas !== 'object') {
    res.status(400).json({
      success: false,
      error: 'Missing or invalid counterDeltas',
    });
    return;
  }

  // Sanitize appVersion
  const sanitizedAppVersion = typeof appVersion === 'string'
    ? appVersion.slice(0, 20)
    : 'unknown';

  // Validate counterDeltas keys (allow only known keys)
  const allowedKeys = new Set([
    'plans_generated',
    'meals_eaten',
    'meals_swapped',
    'recipes_favorited',
    'recipes_viewed',
    'grocery_items_checked',
    'recipes_shared',
    'paywalls_shown',
    'paywalls_converted',
    'onboarding_completed',
  ]);

  const sanitizedDeltas: Record<string, number> = {};
  for (const [key, value] of Object.entries(counterDeltas)) {
    if (allowedKeys.has(key) && typeof value === 'number' && Number.isFinite(value) && Number.isInteger(value) && value > 0) {
      sanitizedDeltas[key] = Math.min(value, 1000); // Cap to prevent abuse
    }
  }

  try {
    const docRef = getDb().collection(ANALYTICS_COLLECTION).doc(deviceId);
    const now = admin.firestore.FieldValue.serverTimestamp();

    // Build the update object with incremented counters
    const updateData: Record<string, admin.firestore.FieldValue | string> = {
      lastActiveAt: now,
      appVersion: sanitizedAppVersion,
    };

    // Increment lifetime counters
    for (const [key, value] of Object.entries(sanitizedDeltas)) {
      updateData[`lifetime.${key}`] = admin.firestore.FieldValue.increment(value);
    }

    // Track active date for streak calculation
    const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD
    updateData['engagement.activeDatesThisWeek'] = admin.firestore.FieldValue.arrayUnion(today);

    // Use a single get() to check for createdAt, then set with merge
    const doc = await docRef.get();
    const setData: Record<string, admin.firestore.FieldValue | string> = {
      deviceId,
      ...updateData,
    };

    // Only set createdAt on first write
    if (!doc.exists) {
      setData.createdAt = now;
    }

    await docRef.set(setData, { merge: true });

    if (DEBUG) console.log(`[Analytics] Synced ${Object.keys(sanitizedDeltas).length} counters for device ${deviceId.substring(0, 8)}...`);

    res.json({
      success: true,
      countersUpdated: Object.keys(sanitizedDeltas).length,
    });
  } catch (error) {
    console.error('[Analytics] Sync error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to sync analytics',
    });
  }
};

/**
 * Weekly analytics reset function.
 * Archives activeDatesThisWeek count to lastWeekActiveDays, resets arrays.
 * Should be called by a scheduled function on Monday midnight UTC.
 */
export const resetWeeklyAnalytics = async (): Promise<number> => {
  let processedCount = 0;
  const pageSize = 500;

  try {
    let lastDoc: FirebaseFirestore.QueryDocumentSnapshot | undefined;
    let hasMore = true;

    while (hasMore) {
      // Paginated query: only fetch the field we need, in pages of 500
      let query = getDb().collection(ANALYTICS_COLLECTION)
        .select('engagement.activeDatesThisWeek')
        .limit(pageSize);

      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      const snapshot = await query.get();

      if (snapshot.empty) {
        if (processedCount === 0) {
          if (DEBUG) console.log('[Analytics] No documents to reset');
        }
        break;
      }

      // Process this page as a batch
      const batch = getDb().batch();
      for (const doc of snapshot.docs) {
        const data = doc.data();
        const activeDates: string[] = data?.engagement?.activeDatesThisWeek || [];

        batch.set(doc.ref, {
          'engagement.lastWeekActiveDays': activeDates.length,
          'engagement.activeDatesThisWeek': [],
          'engagement.weeklyActiveDays': activeDates.length,
        }, { merge: true });
        processedCount++;
      }

      await batch.commit();

      // Set cursor for next page
      lastDoc = snapshot.docs[snapshot.docs.length - 1];
      hasMore = snapshot.docs.length === pageSize;
    }

    if (DEBUG) console.log(`[Analytics] Reset weekly analytics for ${processedCount} documents`);
    return processedCount;
  } catch (error) {
    console.error('[Analytics] Weekly reset error:', error);
    return processedCount;
  }
};
