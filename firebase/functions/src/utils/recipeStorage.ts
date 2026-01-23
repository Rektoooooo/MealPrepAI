/**
 * Recipe Storage Utility
 *
 * Saves AI-generated recipes to Firestore with deduplication.
 * Recipes with 80%+ ingredient overlap are considered duplicates.
 */

import * as admin from 'firebase-admin';
import { calculateIngredientSimilarity } from './imageMatch';

// Lazy initialization to avoid accessing Firestore before app is initialized
function getDb() {
  return admin.firestore();
}

const GENERATED_RECIPES_COLLECTION = 'generated_recipes';
const SIMILARITY_THRESHOLD = 0.8; // 80% ingredient overlap = duplicate

export interface GeneratedRecipeDTO {
  name: string;
  description: string;
  cuisineType: string;
  mealType: string;
  complexity: string;
  calories: number;
  proteinGrams: number;
  carbsGrams: number;
  fatGrams: number;
  fiberGrams: number;
  prepTimeMinutes: number;
  cookTimeMinutes: number;
  servings: number;
  ingredients: Array<{
    name: string;
    quantity: number;
    unit: string;
    category: string;
  }>;
  instructions: string[];
  matchedImageUrl: string | null;
}

interface GeneratedRecipeDoc extends GeneratedRecipeDTO {
  id: string;
  normalizedName: string;
  ingredientNames: string[];
  timesGenerated: number;
  createdAt: admin.firestore.Timestamp;
  lastGeneratedAt: admin.firestore.Timestamp;
}

interface SaveResult {
  saved: boolean;
  existingId?: string;
  newId?: string;
}

/**
 * Save a recipe if it's unique, otherwise increment usage counter
 *
 * Deduplication algorithm:
 * 1. Check exact name match (normalized)
 * 2. Check ingredient similarity (same cuisine + 80%+ overlap)
 */
export async function saveRecipeIfUnique(
  recipe: GeneratedRecipeDTO
): Promise<SaveResult> {
  console.log('[DEBUG:RecipeStorage] Checking recipe:', recipe.name);

  const normalizedName = recipe.name.toLowerCase().trim();
  const ingredientNames = recipe.ingredients.map((i) =>
    i.name.toLowerCase().trim()
  );

  console.log('[DEBUG:RecipeStorage] Normalized name:', normalizedName);
  console.log('[DEBUG:RecipeStorage] Ingredients:', ingredientNames.slice(0, 5).join(', '));

  // Step 1: Check exact name match
  console.log('[DEBUG:RecipeStorage] Step 1: Checking exact name match...');
  const exactMatch = await getDb()
    .collection(GENERATED_RECIPES_COLLECTION)
    .where('normalizedName', '==', normalizedName)
    .limit(1)
    .get();

  if (!exactMatch.empty) {
    const existingDoc = exactMatch.docs[0];

    // Increment usage count
    await existingDoc.ref.update({
      timesGenerated: admin.firestore.FieldValue.increment(1),
      lastGeneratedAt: admin.firestore.Timestamp.now(),
    });

    console.log('[DEBUG:RecipeStorage] DUPLICATE (exact name match):', recipe.name, '-> existing ID:', existingDoc.id);
    return { saved: false, existingId: existingDoc.id };
  }

  console.log('[DEBUG:RecipeStorage] No exact name match found');

  // Step 2: Check ingredient similarity for same cuisine + meal type
  console.log('[DEBUG:RecipeStorage] Step 2: Checking ingredient similarity...');
  console.log('[DEBUG:RecipeStorage] Querying:', recipe.cuisineType.toLowerCase(), '+', recipe.mealType.toLowerCase());

  const sameCuisine = await getDb()
    .collection(GENERATED_RECIPES_COLLECTION)
    .where('cuisineType', '==', recipe.cuisineType.toLowerCase())
    .where('mealType', '==', recipe.mealType.toLowerCase())
    .limit(50)
    .get();

  console.log('[DEBUG:RecipeStorage] Found', sameCuisine.size, 'similar recipes to compare');

  for (const doc of sameCuisine.docs) {
    const existing = doc.data() as GeneratedRecipeDoc;
    const similarity = calculateIngredientSimilarity(
      ingredientNames,
      existing.ingredientNames || []
    );

    if (similarity >= SIMILARITY_THRESHOLD) {
      // Found a similar recipe
      await doc.ref.update({
        timesGenerated: admin.firestore.FieldValue.increment(1),
        lastGeneratedAt: admin.firestore.Timestamp.now(),
      });

      console.log('[DEBUG:RecipeStorage] DUPLICATE (', (similarity * 100).toFixed(0), '% overlap):', recipe.name, 'matches', existing.name);
      return { saved: false, existingId: doc.id };
    }
  }

  console.log('[DEBUG:RecipeStorage] No similar recipes found (all below', (SIMILARITY_THRESHOLD * 100), '% threshold)');

  // Step 3: No match found - save as new recipe
  console.log('[DEBUG:RecipeStorage] Step 3: Saving as new recipe...');
  const now = admin.firestore.Timestamp.now();
  const newDoc: Omit<GeneratedRecipeDoc, 'id'> = {
    ...recipe,
    normalizedName,
    ingredientNames,
    cuisineType: recipe.cuisineType.toLowerCase(),
    mealType: recipe.mealType.toLowerCase(),
    timesGenerated: 1,
    createdAt: now,
    lastGeneratedAt: now,
  };

  const docRef = await getDb().collection(GENERATED_RECIPES_COLLECTION).add(newDoc);
  console.log('[DEBUG:RecipeStorage] NEW RECIPE SAVED:', recipe.name, '-> ID:', docRef.id);

  return { saved: true, newId: docRef.id };
}

/**
 * Save multiple recipes and return statistics
 */
export async function saveRecipesIfUnique(
  recipes: GeneratedRecipeDTO[]
): Promise<{
  saved: number;
  duplicates: number;
  savedIds: string[];
  duplicateIds: string[];
}> {
  let saved = 0;
  let duplicates = 0;
  const savedIds: string[] = [];
  const duplicateIds: string[] = [];

  // Process sequentially to avoid race conditions on deduplication
  for (const recipe of recipes) {
    try {
      const result = await saveRecipeIfUnique(recipe);

      if (result.saved) {
        saved++;
        if (result.newId) {
          savedIds.push(result.newId);
        }
      } else {
        duplicates++;
        if (result.existingId) {
          duplicateIds.push(result.existingId);
        }
      }
    } catch (error) {
      console.error(`Error saving recipe "${recipe.name}":`, error);
    }
  }

  console.log(
    `Recipe storage complete: ${saved} new, ${duplicates} duplicates`
  );

  return { saved, duplicates, savedIds, duplicateIds };
}

/**
 * Get popular generated recipes (by timesGenerated)
 */
export async function getPopularGeneratedRecipes(
  limit: number = 20
): Promise<GeneratedRecipeDoc[]> {
  const snapshot = await getDb()
    .collection(GENERATED_RECIPES_COLLECTION)
    .orderBy('timesGenerated', 'desc')
    .limit(limit)
    .get();

  return snapshot.docs.map((doc: FirebaseFirestore.QueryDocumentSnapshot) => ({
    id: doc.id,
    ...doc.data(),
  })) as GeneratedRecipeDoc[];
}

/**
 * Get recently generated recipes
 */
export async function getRecentGeneratedRecipes(
  limit: number = 20
): Promise<GeneratedRecipeDoc[]> {
  const snapshot = await getDb()
    .collection(GENERATED_RECIPES_COLLECTION)
    .orderBy('lastGeneratedAt', 'desc')
    .limit(limit)
    .get();

  return snapshot.docs.map((doc: FirebaseFirestore.QueryDocumentSnapshot) => ({
    id: doc.id,
    ...doc.data(),
  })) as GeneratedRecipeDoc[];
}

/**
 * Get count of generated recipes
 */
export async function getGeneratedRecipeCount(): Promise<number> {
  const snapshot = await getDb()
    .collection(GENERATED_RECIPES_COLLECTION)
    .count()
    .get();

  return snapshot.data().count;
}
