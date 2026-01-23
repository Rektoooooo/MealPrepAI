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
import { cleanupExpiredRateLimits } from './utils/rateLimiter';

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
 * Scheduled Cloud Function: Collect recipes from Spoonacular
 * Runs daily at 3am UTC to populate the Firestore database
 */
export const collectRecipes = functions.pubsub
  .schedule('0 3 * * *')  // Run at 3am UTC daily
  .timeZone('UTC')
  .onRun(async (context) => {
    console.log('Starting daily recipe collection...');

    if (!SPOONACULAR_API_KEY) {
      console.error('Spoonacular API key not configured!');
      console.error('Run: firebase functions:config:set spoonacular.key="YOUR_API_KEY"');
      return null;
    }

    let totalAdded = 0;
    let totalSkipped = 0;

    // Iterate through each cuisine
    for (const cuisine of CUISINES) {
      try {
        console.log(`Fetching ${cuisine} recipes...`);

        // Fetch recipes with nutrition data (costs 1 point per recipe)
        // addRecipeNutrition=true includes nutrition info
        // addRecipeInstructions=true includes cooking steps
        const url = `https://api.spoonacular.com/recipes/complexSearch?` +
          `cuisine=${cuisine}` +
          `&addRecipeNutrition=true` +
          `&addRecipeInstructions=true` +
          `&number=12` +  // 12 recipes per cuisine × 8 cuisines = 96 calls
          `&apiKey=${SPOONACULAR_API_KEY}`;

        const response = await fetch(url);

        if (!response.ok) {
          console.error(`API error for ${cuisine}: ${response.status} ${response.statusText}`);
          continue;
        }

        const data: SpoonacularResponse = await response.json();
        console.log(`Found ${data.results.length} ${cuisine} recipes`);

        // Process each recipe
        for (const recipe of data.results) {
          try {
            // Check if recipe already exists (by externalId)
            const existingQuery = await db.collection(RECIPES_COLLECTION)
              .where('externalId', '==', recipe.id)
              .limit(1)
              .get();

            if (!existingQuery.empty) {
              totalSkipped++;
              continue;  // Skip existing recipes
            }

            // Extract nutrition values
            const nutrients = recipe.nutrition?.nutrients || [];
            const calories = getNutrient(nutrients, 'Calories');
            const protein = getNutrient(nutrients, 'Protein');
            const carbs = getNutrient(nutrients, 'Carbohydrates');
            const fat = getNutrient(nutrients, 'Fat');

            // Extract instructions as array of steps
            const instructions: string[] = recipe.analyzedInstructions?.[0]?.steps
              ?.map(step => step.step)
              .filter(step => step && step.trim().length > 0) || [];

            // Extract ingredients
            const ingredients = (recipe.nutrition?.ingredients || []).map(ing => ({
              name: ing.name,
              amount: ing.amount,
              unit: ing.unit,
              aisle: ing.aisle || 'Other'
            }));

            // Determine meal type
            const mealType = determineMealType(recipe.dishTypes);

            // Create Firestore document
            const recipeDoc = {
              externalId: recipe.id,
              title: recipe.title,
              imageUrl: recipe.image,
              readyInMinutes: recipe.readyInMinutes || 30,
              servings: recipe.servings || 4,
              calories,
              proteinGrams: protein,
              carbsGrams: carbs,
              fatGrams: fat,
              instructions,
              cuisineType: cuisine.toLowerCase(),
              mealType,
              diets: recipe.diets || [],
              dishTypes: recipe.dishTypes || [],
              healthScore: recipe.healthScore || 0,
              sourceUrl: recipe.sourceUrl || null,
              creditsText: recipe.creditsText || null,
              ingredients,
              createdAt: admin.firestore.FieldValue.serverTimestamp()
            };

            // Save to Firestore
            await db.collection(RECIPES_COLLECTION).add(recipeDoc);
            totalAdded++;

            console.log(`Added: ${recipe.title} (${cuisine}, ${mealType})`);

          } catch (recipeError) {
            console.error(`Error processing recipe ${recipe.id}:`, recipeError);
          }
        }

        // Small delay between cuisine requests to be nice to the API
        await new Promise(resolve => setTimeout(resolve, 500));

      } catch (cuisineError) {
        console.error(`Error fetching ${cuisine} recipes:`, cuisineError);
      }
    }

    console.log(`Recipe collection complete! Added: ${totalAdded}, Skipped: ${totalSkipped}`);
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

  // Run the collection logic (same as scheduled function)
  let totalAdded = 0;

  for (const cuisine of CUISINES.slice(0, 2)) {  // Only 2 cuisines for manual trigger
    try {
      const url = `https://api.spoonacular.com/recipes/complexSearch?` +
        `cuisine=${cuisine}` +
        `&addRecipeNutrition=true` +
        `&addRecipeInstructions=true` +
        `&number=5` +
        `&apiKey=${SPOONACULAR_API_KEY}`;

      const response = await fetch(url);
      const data: SpoonacularResponse = await response.json();

      for (const recipe of data.results) {
        const existingQuery = await db.collection(RECIPES_COLLECTION)
          .where('externalId', '==', recipe.id)
          .limit(1)
          .get();

        if (existingQuery.empty) {
          const nutrients = recipe.nutrition?.nutrients || [];

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
            instructions: recipe.analyzedInstructions?.[0]?.steps?.map(s => s.step) || [],
            cuisineType: cuisine.toLowerCase(),
            mealType: determineMealType(recipe.dishTypes),
            diets: recipe.diets || [],
            dishTypes: recipe.dishTypes || [],
            healthScore: recipe.healthScore || 0,
            sourceUrl: recipe.sourceUrl,
            creditsText: recipe.creditsText,
            ingredients: (recipe.nutrition?.ingredients || []).map(ing => ({
              name: ing.name,
              amount: ing.amount,
              unit: ing.unit,
              aisle: ing.aisle || 'Other'
            })),
            createdAt: admin.firestore.FieldValue.serverTimestamp()
          });
          totalAdded++;
        }
      }
    } catch (error) {
      console.error(`Error fetching ${cuisine}:`, error);
    }
  }

  res.json({ success: true, recipesAdded: totalAdded });
});

/**
 * HTTP Function: Get recipe statistics
 * Returns counts of recipes by cuisine and meal type
 */
export const getRecipeStats = functions.https.onRequest(async (req, res) => {
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

    res.json({
      totalRecipes: totalCount,
      byCuisine: cuisineCounts,
      byMealType: mealTypeCounts
    });
  } catch (error) {
    console.error('Error getting stats:', error);
    res.status(500).json({ error: 'Failed to get recipe statistics' });
  }
});

/**
 * HTTP Function: Initial database population (no auth required)
 * Use this once to populate the database, then disable
 */
export const populateRecipes = functions.https.onRequest(async (req, res) => {
  console.log('Starting initial recipe population...');

  if (!SPOONACULAR_API_KEY) {
    res.status(500).json({ error: 'Spoonacular API key not configured' });
    return;
  }

  let totalAdded = 0;
  const errors: string[] = [];

  // Fetch from all cuisines
  for (const cuisine of CUISINES) {
    try {
      console.log(`Fetching ${cuisine} recipes...`);

      const url = `https://api.spoonacular.com/recipes/complexSearch?` +
        `cuisine=${cuisine}` +
        `&addRecipeNutrition=true` +
        `&addRecipeInstructions=true` +
        `&number=10` +
        `&apiKey=${SPOONACULAR_API_KEY}`;

      const response = await fetch(url);

      if (!response.ok) {
        errors.push(`${cuisine}: API error ${response.status}`);
        continue;
      }

      const data: SpoonacularResponse = await response.json();
      console.log(`Got ${data.results.length} ${cuisine} recipes`);

      for (const recipe of data.results) {
        try {
          // Check if exists
          const existing = await db.collection(RECIPES_COLLECTION)
            .where('externalId', '==', recipe.id)
            .limit(1)
            .get();

          if (!existing.empty) continue;

          const nutrients = recipe.nutrition?.nutrients || [];

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
            instructions: recipe.analyzedInstructions?.[0]?.steps?.map(s => s.step) || [],
            cuisineType: cuisine.toLowerCase(),
            mealType: determineMealType(recipe.dishTypes),
            diets: recipe.diets || [],
            dishTypes: recipe.dishTypes || [],
            healthScore: recipe.healthScore || 0,
            sourceUrl: recipe.sourceUrl,
            creditsText: recipe.creditsText,
            ingredients: (recipe.nutrition?.ingredients || []).map(ing => ({
              name: ing.name,
              amount: ing.amount,
              unit: ing.unit,
              aisle: ing.aisle || 'Other'
            })),
            createdAt: admin.firestore.FieldValue.serverTimestamp()
          });
          totalAdded++;
          console.log(`Added: ${recipe.title}`);
        } catch (e) {
          console.error(`Error adding recipe:`, e);
        }
      }

      // Small delay between requests
      await new Promise(resolve => setTimeout(resolve, 300));

    } catch (e) {
      errors.push(`${cuisine}: ${e}`);
    }
  }

  console.log(`Done! Added ${totalAdded} recipes`);
  res.json({ success: true, recipesAdded: totalAdded, errors });
});

// =============================================================================
// AI MEAL PLAN API
// =============================================================================

/**
 * Express app for AI meal plan API endpoints
 */
const app = express();

// Middleware
app.use(cors({ origin: true }));
app.use(express.json());

/**
 * POST /api/v1/generate-plan
 * Generate a full 7-day meal plan
 */
app.post('/v1/generate-plan', async (req: Request, res: Response) => {
  try {
    const result = await handleGeneratePlan(req.body);

    if (!result.success) {
      const status = result.error?.includes('Rate limit') ? 429 : 400;
      res.status(status).json(result);
      return;
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
 */
app.post('/v1/swap-meal', async (req: Request, res: Response) => {
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
