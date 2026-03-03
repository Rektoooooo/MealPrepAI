/**
 * Recipe Storage Utility
 *
 * Saves AI-generated recipes to Firestore with deduplication.
 * Recipes with 80%+ ingredient overlap are considered duplicates.
 */

import * as admin from 'firebase-admin';
import { calculateIngredientSimilarity } from './imageMatch';

const DEBUG = process.env.FUNCTIONS_EMULATOR === 'true';

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
  if (DEBUG) console.log('[DEBUG:RecipeStorage] Checking recipe:', recipe.name);

  const normalizedName = recipe.name.toLowerCase().trim();
  const ingredientNames = recipe.ingredients.map((i) =>
    i.name.toLowerCase().trim()
  );

  if (DEBUG) {
    console.log('[DEBUG:RecipeStorage] Normalized name:', normalizedName);
    console.log('[DEBUG:RecipeStorage] Ingredients:', ingredientNames.slice(0, 5).join(', '));
  }

  // Step 1: Check exact name match
  if (DEBUG) console.log('[DEBUG:RecipeStorage] Step 1: Checking exact name match...');
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

    if (DEBUG) console.log('[DEBUG:RecipeStorage] DUPLICATE (exact name match):', recipe.name, '-> existing ID:', existingDoc.id);
    return { saved: false, existingId: existingDoc.id };
  }

  if (DEBUG) console.log('[DEBUG:RecipeStorage] No exact name match found');

  // Step 2: Check ingredient similarity for same cuisine + meal type
  if (DEBUG) {
    console.log('[DEBUG:RecipeStorage] Step 2: Checking ingredient similarity...');
    console.log('[DEBUG:RecipeStorage] Querying:', recipe.cuisineType.toLowerCase(), '+', recipe.mealType.toLowerCase());
  }

  const sameCuisine = await getDb()
    .collection(GENERATED_RECIPES_COLLECTION)
    .where('cuisineType', '==', recipe.cuisineType.toLowerCase())
    .where('mealType', '==', recipe.mealType.toLowerCase())
    .limit(50)
    .get();

  if (DEBUG) console.log('[DEBUG:RecipeStorage] Found', sameCuisine.size, 'similar recipes to compare');

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

      if (DEBUG) console.log('[DEBUG:RecipeStorage] DUPLICATE (', (similarity * 100).toFixed(0), '% overlap):', recipe.name, 'matches', existing.name);
      return { saved: false, existingId: doc.id };
    }
  }

  if (DEBUG) console.log('[DEBUG:RecipeStorage] No similar recipes found (all below', (SIMILARITY_THRESHOLD * 100), '% threshold)');

  // Step 3: No match found - save as new recipe
  if (DEBUG) console.log('[DEBUG:RecipeStorage] Step 3: Saving as new recipe...');
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
  if (DEBUG) console.log('[DEBUG:RecipeStorage] NEW RECIPE SAVED:', recipe.name, '-> ID:', docRef.id);

  return { saved: true, newId: docRef.id };
}

/**
 * Save multiple recipes with batched dedup checks and controlled concurrency
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

  // Step 1: Batch exact-name-match dedup check
  const normalizedNames = recipes.map(r => r.name.toLowerCase().trim());
  const existingNameSet = new Set<string>();

  for (let i = 0; i < normalizedNames.length; i += 30) {
    const chunk = normalizedNames.slice(i, i + 30);
    const snapshot = await getDb()
      .collection(GENERATED_RECIPES_COLLECTION)
      .where('normalizedName', 'in', chunk)
      .select('normalizedName')
      .get();
    for (const doc of snapshot.docs) {
      existingNameSet.add(doc.data().normalizedName as string);
    }
  }

  // Step 2: Cache cuisine+mealType similarity queries
  const similarityCache = new Map<string, FirebaseFirestore.QueryDocumentSnapshot[]>();

  async function getCachedSimilarRecipes(cuisineType: string, mealType: string): Promise<FirebaseFirestore.QueryDocumentSnapshot[]> {
    const key = `${cuisineType.toLowerCase()}|${mealType.toLowerCase()}`;
    if (similarityCache.has(key)) {
      return similarityCache.get(key)!;
    }
    const snapshot = await getDb()
      .collection(GENERATED_RECIPES_COLLECTION)
      .where('cuisineType', '==', cuisineType.toLowerCase())
      .where('mealType', '==', mealType.toLowerCase())
      .limit(50)
      .get();
    similarityCache.set(key, snapshot.docs);
    return snapshot.docs;
  }

  // Step 3: Process recipes with controlled concurrency (5 at a time)
  const CONCURRENCY = 5;
  for (let i = 0; i < recipes.length; i += CONCURRENCY) {
    const batch = recipes.slice(i, i + CONCURRENCY);
    const results = await Promise.allSettled(
      batch.map(async (recipe) => {
        const normalizedName = recipe.name.toLowerCase().trim();
        const ingredientNames = recipe.ingredients.map(ing => ing.name.toLowerCase().trim());

        // Check if exact name match was found in batch query
        if (existingNameSet.has(normalizedName)) {
          // Increment usage counter
          const exactMatch = await getDb()
            .collection(GENERATED_RECIPES_COLLECTION)
            .where('normalizedName', '==', normalizedName)
            .limit(1)
            .get();
          if (!exactMatch.empty) {
            const existingDoc = exactMatch.docs[0];
            await existingDoc.ref.update({
              timesGenerated: admin.firestore.FieldValue.increment(1),
              lastGeneratedAt: admin.firestore.Timestamp.now(),
            });
            return { saved: false, existingId: existingDoc.id } as SaveResult;
          }
        }

        // Similarity check using cached query
        const similarDocs = await getCachedSimilarRecipes(recipe.cuisineType, recipe.mealType);
        for (const doc of similarDocs) {
          const existing = doc.data() as GeneratedRecipeDoc;
          const similarity = calculateIngredientSimilarity(
            ingredientNames,
            existing.ingredientNames || []
          );
          if (similarity >= SIMILARITY_THRESHOLD) {
            await doc.ref.update({
              timesGenerated: admin.firestore.FieldValue.increment(1),
              lastGeneratedAt: admin.firestore.Timestamp.now(),
            });
            return { saved: false, existingId: doc.id } as SaveResult;
          }
        }

        // No match - save as new recipe
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
        return { saved: true, newId: docRef.id } as SaveResult;
      })
    );

    for (let j = 0; j < results.length; j++) {
      const r = results[j];
      if (r.status === 'fulfilled') {
        if (r.value.saved) {
          saved++;
          if (r.value.newId) savedIds.push(r.value.newId);
        } else {
          duplicates++;
          if (r.value.existingId) duplicateIds.push(r.value.existingId);
        }
      } else {
        console.error(`Error saving recipe "${batch[j].name}":`, r.reason);
      }
    }
  }

  if (DEBUG) console.log(
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
