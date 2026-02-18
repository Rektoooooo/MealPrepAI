/**
 * MealPrepAI Firebase Cloud Functions
 *
 * This file contains Cloud Functions for:
 * 1. Recipe collection from Spoonacular API (scheduled daily)
 * 2. AI meal plan generation via Claude API
 * 3. Meal swap/replacement generation
 *
 * Spoonacular Free Tier: 150 API calls/day
 * Strategy: Collect ~100 recipes/day across 8 cuisines
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import express, { Request, Response } from 'express';
import cors from 'cors';
import { handleGeneratePlan } from './api/generatePlan';
import { handleSwapMeal } from './api/swapMeal';
import { handleSubstituteIngredient } from './api/substituteIngredient';
import { handleVerifySubscription } from './api/verifySubscription';
import { handleAppStoreWebhook } from './api/appStoreWebhook';
import { handleRevokeAppleToken } from './api/revokeAppleToken';
import { cleanupExpiredRateLimits } from './utils/rateLimiter';
import { requireSubscription } from './utils/subscriptionMiddleware';
import { incrementPlansGenerated } from './utils/subscriptionVerifier';

// Initialize Firebase Admin SDK
admin.initializeApp();
const db = admin.firestore();

// Spoonacular API key from environment variable (.env file)
const SPOONACULAR_API_KEY = process.env.SPOONACULAR_API_KEY;

// Cuisines to collect recipes for
const CUISINES = [
  'italian',
  'mexican',
  'asian',
  'american',
  'mediterranean',
  'indian',
  'chinese',
  'japanese'
];

// Meal types to categorize recipes
const MEAL_TYPES = ['breakfast', 'lunch', 'dinner', 'snack'];

// Recipes collection name
const RECIPES_COLLECTION = 'recipes';

// Minimum health score (0-100) for recipe ingestion
// Recipes below this threshold are filtered out before saving to Firestore
const MIN_HEALTH_SCORE = 40;

// Interface for Spoonacular recipe response
interface SpoonacularRecipe {
  id: number;
  title: string;
  image: string;
  readyInMinutes: number;
  servings: number;
  sourceUrl: string;
  creditsText: string;
  healthScore: number;
  diets: string[];
  dishTypes: string[];
  analyzedInstructions: {
    steps: { step: string }[];
  }[];
  nutrition: {
    nutrients: { name: string; amount: number }[];
    ingredients: {
      name: string;
      amount: number;
      unit: string;
      aisle: string;
    }[];
  };
}

interface SpoonacularResponse {
  results: SpoonacularRecipe[];
  totalResults: number;
}

/**
 * Determine meal type based on dish types
 */
function determineMealType(dishTypes: string[] = []): string {
  const types = dishTypes.map(t => t.toLowerCase());

  if (types.includes('breakfast') || types.includes('brunch')) {
    return 'breakfast';
  }
  if (types.includes('lunch') || types.includes('salad')) {
    return 'lunch';
  }
  if (types.includes('dinner') || types.includes('main course') || types.includes('main dish')) {
    return 'dinner';
  }
  if (types.includes('snack') || types.includes('appetizer') || types.includes('side dish')) {
    return 'snack';
  }

  // Default to dinner for main dishes
  return 'dinner';
}

/**
 * Extract nutrient value by name
 */
function getNutrient(nutrients: { name: string; amount: number }[], name: string): number {
  const nutrient = nutrients.find(n => n.name.toLowerCase() === name.toLowerCase());
  return Math.round(nutrient?.amount || 0);
}

/**
 * Fetch recipes from Spoonacular with given params and save new ones to Firestore.
 * Filters out recipes with healthScore below MIN_HEALTH_SCORE.
 * Returns { added, skipped, filtered }.
 */
async function fetchAndSaveRecipes(params: {
  cuisine?: string;
  type?: string;
  number: number;
  offset?: number;
}): Promise<{ added: number; skipped: number; filtered: number }> {
  let added = 0;
  let skipped = 0;
  let filtered = 0;

  const queryParts = [
    params.cuisine ? `cuisine=${params.cuisine}` : '',
    params.type ? `type=${params.type}` : '',
    params.offset == null ? `sort=random` : '',
    params.offset != null ? `offset=${params.offset}` : '',
    `addRecipeNutrition=true`,
    `addRecipeInstructions=true`,
    `number=${params.number}`,
    `apiKey=${SPOONACULAR_API_KEY}`,
  ].filter(Boolean);

  const url = `https://api.spoonacular.com/recipes/complexSearch?${queryParts.join('&')}`;
  const label = [params.cuisine, params.type].filter(Boolean).join('/') || 'general';
  console.log(`Fetching ${label} recipes...`);

  const response = await fetch(url);
  if (!response.ok) {
    console.error(`API error for ${label}: ${response.status} ${response.statusText}`);
    return { added, skipped, filtered };
  }

  const data: SpoonacularResponse = await response.json();
  console.log(`Found ${data.results.length} ${label} recipes`);

  // Filter out recipes below health score threshold
  const healthyRecipes = data.results.filter(r => (r.healthScore || 0) >= MIN_HEALTH_SCORE);
  filtered = data.results.length - healthyRecipes.length;
  if (filtered > 0) {
    console.log(`Filtered out ${filtered} ${label} recipes with healthScore < ${MIN_HEALTH_SCORE}`);
  }

  for (const recipe of healthyRecipes) {
    try {
      const existingQuery = await db.collection(RECIPES_COLLECTION)
        .where('externalId', '==', recipe.id)
        .limit(1)
        .get();

      if (!existingQuery.empty) {
        skipped++;
        continue;
      }

      const nutrients = recipe.nutrition?.nutrients || [];
      const mealType = params.type
        ? (params.type === 'main course' ? 'dinner' : params.type)
        : determineMealType(recipe.dishTypes);

      await db.collection(RECIPES_COLLECTION).add({
        externalId: recipe.id,
        title: recipe.title,
        imageUrl: recipe.image,
        readyInMinutes: recipe.readyInMinutes || 30,
        servings: recipe.servings || 4,
        calories: getNutrient(nutrients, 'Calories'),
        proteinGrams: getNutrient(nutrients, 'Protein'),
        carbsGrams: getNutrient(nutrients, 'Carbohydrates'),
        fatGrams: getNutrient(nutrients, 'Fat'),
        instructions: recipe.analyzedInstructions?.[0]?.steps
          ?.map(step => step.step)
          .filter(step => step && step.trim().length > 0) || [],
        cuisineType: (params.cuisine || 'mixed').toLowerCase(),
        mealType,
        diets: recipe.diets || [],
        dishTypes: recipe.dishTypes || [],
        healthScore: recipe.healthScore || 0,
        sourceUrl: recipe.sourceUrl || null,
        creditsText: recipe.creditsText || null,
        ingredients: (recipe.nutrition?.ingredients || []).map(ing => ({
          name: ing.name,
          amount: ing.amount,
          unit: ing.unit,
          aisle: ing.aisle || 'Other'
        })),
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });
      added++;
      console.log(`Added: ${recipe.title} (${label}, ${mealType})`);
    } catch (recipeError) {
      console.error(`Error processing recipe ${recipe.id}:`, recipeError);
    }
  }

  return { added, skipped, filtered };
}

/**
 * Scheduled Cloud Function: Collect recipes from Spoonacular
 * Runs daily at 2pm UTC to populate the Firestore database
 *
 * Uses sort=random to get different recipes each day.
 * Fetches across cuisines AND meal types for balanced coverage.
 *
 * API budget: ~150 calls/day free tier
 * - 8 cuisines × 10 recipes = 80 calls (random cuisine-based)
 * - 4 meal types × 12 recipes = 48 calls (breakfast, lunch, dinner, snack)
 * Total: ~128 calls/day
 */
export const collectRecipes = functions.pubsub
  .schedule('0 14 * * *')  // 2pm UTC daily
  .timeZone('UTC')
  .onRun(async () => {
    console.log('Starting daily recipe collection...');

    if (!SPOONACULAR_API_KEY) {
      console.error('Spoonacular API key not configured!');
      return null;
    }

    let totalAdded = 0;
    let totalSkipped = 0;
    let totalFiltered = 0;

    // Part 1: Fetch random recipes by cuisine (6 per cuisine)
    for (const cuisine of CUISINES) {
      try {
        const result = await fetchAndSaveRecipes({ cuisine, number: 10 });
        totalAdded += result.added;
        totalSkipped += result.skipped;
        totalFiltered += result.filtered;
        await new Promise(resolve => setTimeout(resolve, 500));
      } catch (error) {
        console.error(`Error fetching ${cuisine}:`, error);
      }
    }

    // Part 2: Fetch by meal type to fill gaps (breakfast, dinner, snack)
    const mealTypeQueries = [
      { type: 'breakfast', number: 12 },
      { type: 'lunch', number: 12 },
      { type: 'main course', number: 12 },  // maps to 'dinner'
      { type: 'snack', number: 12 },
    ];

    for (const query of mealTypeQueries) {
      try {
        const result = await fetchAndSaveRecipes(query);
        totalAdded += result.added;
        totalSkipped += result.skipped;
        totalFiltered += result.filtered;
        await new Promise(resolve => setTimeout(resolve, 500));
      } catch (error) {
        console.error(`Error fetching ${query.type}:`, error);
      }
    }

    console.log(`Recipe collection complete! Added: ${totalAdded}, Skipped: ${totalSkipped}, Filtered (health score < ${MIN_HEALTH_SCORE}): ${totalFiltered}`);
    return null;
  });

/**
 * HTTP Function: Manually trigger recipe collection
 * Useful for testing and initial database population
 * Only accessible with proper authentication
 */
export const triggerRecipeCollection = functions.https.onRequest(async (req, res) => {
  // Verify request has proper authorization
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).send('Unauthorized');
    return;
  }

  // Verify the token (in production, validate against Firebase Auth)
  const token = authHeader.split('Bearer ')[1];
  try {
    await admin.auth().verifyIdToken(token);
  } catch {
    res.status(401).send('Invalid token');
    return;
  }

  console.log('Manual recipe collection triggered');

  if (!SPOONACULAR_API_KEY) {
    res.status(500).send('Spoonacular API key not configured');
    return;
  }

  // Run the collection logic (same as scheduled function, but only 2 cuisines)
  let totalAdded = 0;
  let totalSkipped = 0;
  let totalFiltered = 0;

  for (const cuisine of CUISINES.slice(0, 2)) {
    try {
      const result = await fetchAndSaveRecipes({ cuisine, number: 5 });
      totalAdded += result.added;
      totalSkipped += result.skipped;
      totalFiltered += result.filtered;
    } catch (error) {
      console.error(`Error fetching ${cuisine}:`, error);
    }
  }

  res.json({
    success: true,
    recipesAdded: totalAdded,
    recipesSkipped: totalSkipped,
    recipesFilteredByHealthScore: totalFiltered,
    minHealthScore: MIN_HEALTH_SCORE,
  });
});

/**
 * HTTP Function: Get recipe statistics
 * Returns counts of recipes by cuisine and meal type
 */
export const getRecipeStats = functions.https.onRequest(async (req, res) => {
  // Verify request has proper authorization
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).send('Unauthorized');
    return;
  }

  const token = authHeader.split('Bearer ')[1];
  try {
    await admin.auth().verifyIdToken(token);
  } catch {
    res.status(401).send('Invalid token');
    return;
  }

  try {
    // Get total count
    const totalSnapshot = await db.collection(RECIPES_COLLECTION).count().get();
    const totalCount = totalSnapshot.data().count;

    // Get counts by cuisine (simplified - would need aggregation in production)
    const cuisineCounts: Record<string, number> = {};
    for (const cuisine of CUISINES) {
      const snapshot = await db.collection(RECIPES_COLLECTION)
        .where('cuisineType', '==', cuisine)
        .count()
        .get();
      cuisineCounts[cuisine] = snapshot.data().count;
    }

    // Get counts by meal type
    const mealTypeCounts: Record<string, number> = {};
    for (const mealType of MEAL_TYPES) {
      const snapshot = await db.collection(RECIPES_COLLECTION)
        .where('mealType', '==', mealType)
        .count()
        .get();
      mealTypeCounts[mealType] = snapshot.data().count;
    }

    // Health score distribution
    const healthScoreSnapshot = await db.collection(RECIPES_COLLECTION)
      .select('healthScore')
      .get();

    const scores = healthScoreSnapshot.docs.map(doc => (doc.data().healthScore as number) || 0);
    const distribution: Record<string, number> = {};
    for (let bucket = 0; bucket <= 90; bucket += 10) {
      const upper = bucket === 90 ? 100 : bucket + 9;
      const label = `${bucket}-${upper}`;
      distribution[label] = scores.filter(s => s >= bucket && s <= upper).length;
    }

    const belowThreshold = scores.filter(s => s < MIN_HEALTH_SCORE).length;

    res.json({
      totalRecipes: totalCount,
      byCuisine: cuisineCounts,
      byMealType: mealTypeCounts,
      healthScore: {
        distribution,
        average: scores.length > 0 ? Math.round(scores.reduce((a, b) => a + b, 0) / scores.length) : 0,
        min: scores.length > 0 ? Math.min(...scores) : 0,
        max: scores.length > 0 ? Math.max(...scores) : 0,
        currentThreshold: MIN_HEALTH_SCORE,
        belowThreshold,
        percentBelowThreshold: scores.length > 0
          ? Math.round((belowThreshold / scores.length) * 100)
          : 0,
      },
    });
  } catch (error) {
    console.error('Error getting stats:', error);
    res.status(500).json({ error: 'Failed to get recipe statistics' });
  }
});

/**
 * HTTP Function: Remove existing recipes with low health scores
 * Auth-protected. Use ?dryRun=true to preview, ?threshold=N to override default.
 */
export const cleanupLowHealthScoreRecipes = functions
  .runWith({ timeoutSeconds: 300 })
  .https.onRequest(async (req, res) => {
    // Verify request has proper authorization
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      res.status(401).send('Unauthorized');
      return;
    }

    const token = authHeader.split('Bearer ')[1];
    try {
      await admin.auth().verifyIdToken(token);
    } catch {
      res.status(401).send('Invalid token');
      return;
    }

    const dryRun = req.query.dryRun === 'true';
    const threshold = Math.min(100, Math.max(0, parseInt(req.query.threshold as string) || MIN_HEALTH_SCORE));

    console.log(`Cleanup low health score recipes (threshold: ${threshold}, dryRun: ${dryRun})`);

    try {
      const snapshot = await db.collection(RECIPES_COLLECTION)
        .where('healthScore', '<', threshold)
        .get();

      if (snapshot.empty) {
        res.json({ success: true, message: 'No recipes below threshold', threshold, deleted: 0 });
        return;
      }

      if (dryRun) {
        const preview = snapshot.docs.slice(0, 20).map(doc => {
          const data = doc.data();
          return { id: doc.id, title: data.title, healthScore: data.healthScore };
        });

        res.json({
          dryRun: true,
          threshold,
          totalToDelete: snapshot.size,
          preview,
        });
        return;
      }

      // Batch delete (max 500 per batch — Firestore limit)
      let deleted = 0;
      const batchSize = 500;
      const docs = snapshot.docs;

      for (let i = 0; i < docs.length; i += batchSize) {
        const batch = db.batch();
        const chunk = docs.slice(i, i + batchSize);
        for (const doc of chunk) {
          batch.delete(doc.ref);
        }
        await batch.commit();
        deleted += chunk.length;
        console.log(`Deleted batch: ${deleted}/${docs.length}`);
      }

      res.json({
        success: true,
        threshold,
        deleted,
      });
    } catch (error) {
      console.error('Error cleaning up recipes:', error);
      res.status(500).json({ error: 'Failed to cleanup recipes' });
    }
  });

/**
 * HTTP Function: Initial database population (no auth required)
 * Use this once to populate the database, then disable
 */
export const populateRecipes = functions.https.onRequest(async (req, res) => {
  // Verify request has proper authorization
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).send('Unauthorized');
    return;
  }

  const token = authHeader.split('Bearer ')[1];
  try {
    await admin.auth().verifyIdToken(token);
  } catch {
    res.status(401).send('Invalid token');
    return;
  }

  console.log('Starting initial recipe population...');

  if (!SPOONACULAR_API_KEY) {
    res.status(500).json({ error: 'Spoonacular API key not configured' });
    return;
  }

  // Get offset from query param (default 0) to fetch different recipes each time
  const offset = Math.min(parseInt(req.query.offset as string) || 0, 5000);
  const number = Math.min(parseInt(req.query.number as string) || 10, 50);

  let totalAdded = 0;
  let totalFiltered = 0;
  const errors: string[] = [];

  for (const cuisine of CUISINES) {
    try {
      const result = await fetchAndSaveRecipes({ cuisine, number, offset });
      totalAdded += result.added;
      totalFiltered += result.filtered;
      await new Promise(resolve => setTimeout(resolve, 300));
    } catch (e) {
      errors.push(`${cuisine}: ${e}`);
    }
  }

  console.log(`Done! Added ${totalAdded} recipes, Filtered: ${totalFiltered}`);
  res.json({
    success: true,
    recipesAdded: totalAdded,
    recipesFilteredByHealthScore: totalFiltered,
    minHealthScore: MIN_HEALTH_SCORE,
    errors,
  });
});

// =============================================================================
// AI MEAL PLAN API
// =============================================================================

/**
 * Express app for AI meal plan API endpoints
 */
const app = express();

// Middleware
app.use(cors({ origin: false }));
app.use(express.json());

/**
 * App Check verification middleware
 * Verifies that requests come from the real iOS app using Firebase App Check
 * In development (DEBUG mode), the debug token is used
 * In production, App Attest is used
 */
const verifyAppCheck = async (req: Request, res: Response, next: express.NextFunction): Promise<void> => {
  const appCheckToken = req.header('X-Firebase-AppCheck');

  if (!appCheckToken) {
    console.warn('🔒 [AppCheck] Missing App Check token');
    res.status(401).json({
      success: false,
      error: 'Unauthorized - Missing App Check token',
    });
    return;
  }

  try {
    // Verify the App Check token
    const appCheckClaims = await admin.appCheck().verifyToken(appCheckToken);
    console.log(`🔒 [AppCheck] Token verified for app: ${appCheckClaims.appId}`);

    // Token is valid, proceed to the next middleware/route
    next();
  } catch (error) {
    console.error('🔒 [AppCheck] Token verification failed:', error);
    res.status(401).json({
      success: false,
      error: 'Unauthorized - Invalid App Check token',
    });
    return;
  }
};

/**
 * POST /api/v1/generate-plan
 * Generate a full 7-day meal plan
 * Protected by App Check verification
 */
app.post('/v1/generate-plan', verifyAppCheck, requireSubscription, async (req: Request, res: Response) => {
  try {
    const result = await handleGeneratePlan(req.body);

    if (!result.success) {
      const status = result.error?.includes('Rate limit') ? 429 : 400;
      res.status(status).json(result);
      return;
    }

    // Track plan generation for free trial gating
    const deviceId = req.body?.deviceId;
    if (deviceId && result.success) {
      try {
        await incrementPlansGenerated(deviceId);
      } catch (err) {
        console.error('Failed to increment plansGenerated:', err);
      }
    }

    res.json(result);
  } catch (error) {
    console.error('Error in generate-plan endpoint:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
    });
  }
});

/**
 * POST /api/v1/swap-meal
 * Generate a single replacement meal
 * Protected by App Check verification
 */
app.post('/v1/verify-subscription', verifyAppCheck, async (req: Request, res: Response) => {
  await handleVerifySubscription(req, res);
});

app.post('/v1/apple-notifications', async (req: Request, res: Response) => {
  await handleAppStoreWebhook(req, res);
});

app.post('/v1/swap-meal', verifyAppCheck, requireSubscription, async (req: Request, res: Response) => {
  try {
    const result = await handleSwapMeal(req.body);

    if (!result.success) {
      const status = result.error?.includes('Rate limit') ? 429 : 400;
      res.status(status).json(result);
      return;
    }

    res.json(result);
  } catch (error) {
    console.error('Error in swap-meal endpoint:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
    });
  }
});

app.post('/v1/substitute-ingredient', verifyAppCheck, requireSubscription, async (req: Request, res: Response) => {
  try {
    const result = await handleSubstituteIngredient(req.body);

    if (!result.success) {
      const status = result.error?.includes('Rate limit') ? 429 : 400;
      res.status(status).json(result);
      return;
    }

    res.json(result);
  } catch (error) {
    console.error('Error in substitute-ingredient endpoint:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
    });
  }
});

/**
 * POST /api/revokeAppleToken
 * Revoke Apple Sign In token for account deletion (Apple requirement)
 * Protected by App Check verification
 */
app.post('/revokeAppleToken', verifyAppCheck, async (req: Request, res: Response) => {
  await handleRevokeAppleToken(req, res);
});

/**
 * GET /api/v1/health
 * Health check endpoint
 */
app.get('/v1/health', (_req: Request, res: Response) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
  });
});

// Export the Express app as a Firebase Function
export const api = functions
  .runWith({
    timeoutSeconds: 300, // 5 minutes for long AI requests
    memory: '512MB',
  })
  .https.onRequest(app);

/**
 * Scheduled cleanup of expired rate limit records
 * Runs daily at 4am UTC
 */
export const cleanupRateLimits = functions.pubsub
  .schedule('0 4 * * *')
  .timeZone('UTC')
  .onRun(async () => {
    console.log('Starting rate limit cleanup...');
    const deleted = await cleanupExpiredRateLimits();
    console.log(`Cleaned up ${deleted} expired rate limit records`);
    return null;
  });
