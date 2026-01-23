/**
 * Image Matching Utility
 *
 * Match AI-generated recipes to existing Spoonacular images using
 * ingredient similarity (Jaccard coefficient).
 */

import * as admin from 'firebase-admin';

// Lazy initialization to avoid accessing Firestore before app is initialized
function getDb() {
  return admin.firestore();
}

interface RecipeDoc {
  title: string;
  imageUrl: string;
  cuisineType: string;
  mealType: string;
  ingredients: Array<{
    name: string;
    amount: number;
    unit: string;
    aisle: string;
  }>;
}

interface MatchedRecipe {
  imageUrl: string;
  score: number;
  title: string;
}

/**
 * Calculate Jaccard similarity between two sets of ingredient names
 * Returns a value between 0 (no overlap) and 1 (identical)
 */
export function calculateIngredientSimilarity(
  ingredientsA: string[],
  ingredientsB: string[]
): number {
  // Normalize ingredient names: lowercase, trim, remove common words
  const normalize = (name: string): string => {
    return name
      .toLowerCase()
      .trim()
      .replace(/\b(fresh|dried|ground|chopped|minced|sliced|diced|whole)\b/gi, '')
      .replace(/\s+/g, ' ')
      .trim();
  };

  const setA = new Set(ingredientsA.map(normalize).filter((s) => s.length > 0));
  const setB = new Set(ingredientsB.map(normalize).filter((s) => s.length > 0));

  if (setA.size === 0 || setB.size === 0) {
    return 0;
  }

  // Calculate intersection
  const intersection = [...setA].filter((x) => setB.has(x));

  // Calculate union
  const union = new Set([...setA, ...setB]);

  // Jaccard coefficient
  return intersection.length / union.size;
}

/**
 * Match an AI-generated recipe to an existing image in the recipes collection
 *
 * @param recipe - The generated recipe with cuisineType, mealType, and ingredients
 * @param minScore - Minimum similarity score to accept a match (default 0.3)
 * @returns Matched image URL or null if no good match found
 */
export async function matchRecipeImage(
  recipe: {
    cuisineType: string;
    mealType: string;
    ingredients: Array<{ name: string }>;
  },
  minScore: number = 0.3
): Promise<string | null> {
  console.log('[DEBUG:ImageMatch] Starting image match for:', {
    cuisineType: recipe.cuisineType,
    mealType: recipe.mealType,
    ingredientCount: recipe.ingredients.length,
  });

  try {
    const ingredientNames = recipe.ingredients.map((i) => i.name);
    console.log('[DEBUG:ImageMatch] Ingredients:', ingredientNames.slice(0, 5).join(', '), ingredientNames.length > 5 ? '...' : '');

    // First, try to find recipes with the same cuisine type
    console.log('[DEBUG:ImageMatch] Querying recipes by cuisine:', recipe.cuisineType.toLowerCase());
    let recipesQuery = getDb()
      .collection('recipes')
      .where('cuisineType', '==', recipe.cuisineType.toLowerCase())
      .limit(50);

    let recipesSnapshot = await recipesQuery.get();
    console.log('[DEBUG:ImageMatch] Cuisine query returned:', recipesSnapshot.size, 'recipes');

    // If no matches for cuisine, try meal type
    if (recipesSnapshot.empty) {
      console.log('[DEBUG:ImageMatch] No cuisine matches, trying meal type:', recipe.mealType.toLowerCase());
      recipesQuery = getDb()
        .collection('recipes')
        .where('mealType', '==', recipe.mealType.toLowerCase())
        .limit(50);

      recipesSnapshot = await recipesQuery.get();
      console.log('[DEBUG:ImageMatch] Meal type query returned:', recipesSnapshot.size, 'recipes');
    }

    // If still no matches, get any recipes
    if (recipesSnapshot.empty) {
      console.log('[DEBUG:ImageMatch] No meal type matches, getting any recipes');
      recipesQuery = getDb().collection('recipes').limit(50);
      recipesSnapshot = await recipesQuery.get();
      console.log('[DEBUG:ImageMatch] General query returned:', recipesSnapshot.size, 'recipes');
    }

    if (recipesSnapshot.empty) {
      console.log('[DEBUG:ImageMatch] No recipes found in database');
      return null;
    }

    // Score each recipe by ingredient similarity
    const matches: MatchedRecipe[] = [];

    for (const doc of recipesSnapshot.docs) {
      const recipeData = doc.data() as RecipeDoc;

      if (!recipeData.imageUrl) {
        continue;
      }

      const recipeIngredients = (recipeData.ingredients || []).map(
        (i) => i.name
      );
      const score = calculateIngredientSimilarity(
        ingredientNames,
        recipeIngredients
      );

      matches.push({
        imageUrl: recipeData.imageUrl,
        score,
        title: recipeData.title,
      });
    }

    console.log('[DEBUG:ImageMatch] Scored', matches.length, 'recipes with images');

    // Sort by score descending
    matches.sort((a, b) => b.score - a.score);

    if (matches.length > 0) {
      console.log('[DEBUG:ImageMatch] Top 3 matches:', matches.slice(0, 3).map(m => ({
        title: m.title,
        score: m.score.toFixed(2)
      })));
    }

    // Return best match if it meets minimum score
    const best = matches[0];
    if (best && best.score >= minScore) {
      console.log('[DEBUG:ImageMatch] MATCH FOUND:', best.title, 'score:', best.score.toFixed(2));
      return best.imageUrl;
    }

    console.log('[DEBUG:ImageMatch] Best score', best?.score?.toFixed(2) || 'N/A', 'below threshold', minScore);

    // Fallback: return any image from same cuisine if available
    const sameCuisine = recipesSnapshot.docs.find((doc: FirebaseFirestore.QueryDocumentSnapshot) => {
      const data = doc.data() as RecipeDoc;
      return (
        data.imageUrl &&
        data.cuisineType === recipe.cuisineType.toLowerCase()
      );
    });

    if (sameCuisine) {
      const data = sameCuisine.data() as RecipeDoc;
      console.log('[DEBUG:ImageMatch] FALLBACK cuisine match:', data.title);
      return data.imageUrl;
    }

    // Fallback: return any image
    const anyImage = recipesSnapshot.docs.find((doc: FirebaseFirestore.QueryDocumentSnapshot) => {
      const data = doc.data() as RecipeDoc;
      return !!data.imageUrl;
    });

    if (anyImage) {
      const data = anyImage.data() as RecipeDoc;
      console.log('[DEBUG:ImageMatch] FALLBACK any image:', data.title);
      return data.imageUrl;
    }

    console.log('[DEBUG:ImageMatch] No image found at all');
    return null;
  } catch (error) {
    console.error('[DEBUG:ImageMatch] ERROR:', error);
    return null;
  }
}

/**
 * Batch match images for multiple recipes
 */
export async function matchRecipeImages(
  recipes: Array<{
    cuisineType: string;
    mealType: string;
    ingredients: Array<{ name: string }>;
  }>
): Promise<(string | null)[]> {
  // Process in parallel but limit concurrency
  const BATCH_SIZE = 5;
  const results: (string | null)[] = [];

  for (let i = 0; i < recipes.length; i += BATCH_SIZE) {
    const batch = recipes.slice(i, i + BATCH_SIZE);
    const batchResults = await Promise.all(
      batch.map((recipe) => matchRecipeImage(recipe))
    );
    results.push(...batchResults);
  }

  return results;
}
