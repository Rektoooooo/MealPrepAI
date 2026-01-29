/**
 * Image Matching Utility
 *
 * Match AI-generated recipes to existing Spoonacular images using
 * ingredient similarity (Jaccard coefficient) + title matching + diversity.
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
 * Normalize an ingredient name to its core words
 */
function normalizeIngredient(name: string): string {
  return name
    .toLowerCase()
    .trim()
    .replace(/\b(fresh|dried|ground|chopped|minced|sliced|diced|whole|boneless|skinless|lean|extra|large|small|medium|raw|cooked|canned|frozen)\b/gi, '')
    .replace(/\s+/g, ' ')
    .trim();
}

/**
 * Extract individual words from an ingredient name for fuzzy matching
 */
function getIngredientWords(name: string): string[] {
  return normalizeIngredient(name)
    .split(' ')
    .filter((w) => w.length > 2); // skip tiny words like "of"
}

/**
 * Calculate ingredient similarity using fuzzy word-level matching.
 * If "chicken breast" is in set A and "chicken" is in set B, that's a partial match.
 */
export function calculateIngredientSimilarity(
  ingredientsA: string[],
  ingredientsB: string[]
): number {
  const wordsA = new Set(ingredientsA.flatMap(getIngredientWords));
  const wordsB = new Set(ingredientsB.flatMap(getIngredientWords));

  if (wordsA.size === 0 || wordsB.size === 0) {
    return 0;
  }

  const intersection = [...wordsA].filter((w) => wordsB.has(w));
  const union = new Set([...wordsA, ...wordsB]);

  return intersection.length / union.size;
}

/**
 * Calculate title similarity between two recipe titles using word overlap
 */
function calculateTitleSimilarity(titleA: string, titleB: string): number {
  const wordsA = new Set(
    titleA
      .toLowerCase()
      .replace(/[^a-z\s]/g, '')
      .split(/\s+/)
      .filter((w) => w.length > 2)
  );
  const wordsB = new Set(
    titleB
      .toLowerCase()
      .replace(/[^a-z\s]/g, '')
      .split(/\s+/)
      .filter((w) => w.length > 2)
  );

  if (wordsA.size === 0 || wordsB.size === 0) return 0;

  const intersection = [...wordsA].filter((w) => wordsB.has(w));
  const union = new Set([...wordsA, ...wordsB]);

  return intersection.length / union.size;
}

/**
 * Shuffle an array in place (Fisher-Yates)
 */
function shuffleArray<T>(arr: T[]): T[] {
  const shuffled = [...arr];
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
  }
  return shuffled;
}

/**
 * Match an AI-generated recipe to an existing image in the recipes collection
 *
 * @param recipe - The generated recipe with title, cuisineType, mealType, and ingredients
 * @param excludeImageUrls - Image URLs already used in this plan (for diversity)
 * @param minScore - Minimum similarity score to accept a match (default 0.15)
 * @returns Matched image URL or null if no good match found
 */
export async function matchRecipeImage(
  recipe: {
    title?: string;
    name?: string;
    cuisineType: string;
    mealType: string;
    ingredients: Array<{ name: string }>;
  },
  excludeImageUrls: Set<string> = new Set(),
  minScore: number = 0.15
): Promise<string | null> {
  const recipeTitle = recipe.title || recipe.name || '';
  console.log('[DEBUG:ImageMatch] Starting image match for:', {
    title: recipeTitle,
    cuisineType: recipe.cuisineType,
    mealType: recipe.mealType,
    ingredientCount: recipe.ingredients.length,
    excludeCount: excludeImageUrls.size,
  });

  try {
    const ingredientNames = recipe.ingredients.map((i) => i.name);

    // First, try to find recipes with the same cuisine type
    let recipesQuery = getDb()
      .collection('recipes')
      .where('cuisineType', '==', recipe.cuisineType.toLowerCase())
      .limit(50);

    let recipesSnapshot = await recipesQuery.get();
    console.log('[DEBUG:ImageMatch] Cuisine query returned:', recipesSnapshot.size, 'recipes');

    // If no matches for cuisine, try meal type
    if (recipesSnapshot.empty) {
      recipesQuery = getDb()
        .collection('recipes')
        .where('mealType', '==', recipe.mealType.toLowerCase())
        .limit(50);

      recipesSnapshot = await recipesQuery.get();
      console.log('[DEBUG:ImageMatch] Meal type query returned:', recipesSnapshot.size, 'recipes');
    }

    // If still no matches, get any recipes
    if (recipesSnapshot.empty) {
      recipesQuery = getDb().collection('recipes').limit(50);
      recipesSnapshot = await recipesQuery.get();
      console.log('[DEBUG:ImageMatch] General query returned:', recipesSnapshot.size, 'recipes');
    }

    if (recipesSnapshot.empty) {
      console.log('[DEBUG:ImageMatch] No recipes found in database');
      return null;
    }

    // Score each recipe by ingredient similarity + title similarity
    const matches: MatchedRecipe[] = [];

    for (const doc of recipesSnapshot.docs) {
      const recipeData = doc.data() as RecipeDoc;

      if (!recipeData.imageUrl) {
        continue;
      }

      const recipeIngredients = (recipeData.ingredients || []).map(
        (i) => i.name
      );
      const ingredientScore = calculateIngredientSimilarity(
        ingredientNames,
        recipeIngredients
      );

      // Title similarity as secondary signal (weighted at 30%)
      const titleScore = recipeTitle
        ? calculateTitleSimilarity(recipeTitle, recipeData.title || '')
        : 0;

      const score = ingredientScore * 0.7 + titleScore * 0.3;

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
        score: m.score.toFixed(3)
      })));
    }

    // Try to find the best match that isn't already used
    for (const match of matches) {
      if (match.score >= minScore && !excludeImageUrls.has(match.imageUrl)) {
        console.log('[DEBUG:ImageMatch] MATCH FOUND:', match.title, 'score:', match.score.toFixed(3));
        return match.imageUrl;
      }
    }

    // If all good matches are excluded, allow reuse of the best one
    const bestAboveThreshold = matches.find((m) => m.score >= minScore);
    if (bestAboveThreshold) {
      console.log('[DEBUG:ImageMatch] All good matches excluded, reusing best:', bestAboveThreshold.title);
      return bestAboveThreshold.imageUrl;
    }

    console.log('[DEBUG:ImageMatch] Best score', matches[0]?.score?.toFixed(3) || 'N/A', 'below threshold', minScore);

    // Fallback: pick a random image from same cuisine (not already used)
    const cuisineMatches = recipesSnapshot.docs
      .map((doc: FirebaseFirestore.QueryDocumentSnapshot) => doc.data() as RecipeDoc)
      .filter((data) => data.imageUrl && data.cuisineType === recipe.cuisineType.toLowerCase() && !excludeImageUrls.has(data.imageUrl));

    if (cuisineMatches.length > 0) {
      const pick = cuisineMatches[Math.floor(Math.random() * cuisineMatches.length)];
      console.log('[DEBUG:ImageMatch] FALLBACK random cuisine match:', pick.title);
      return pick.imageUrl;
    }

    // Fallback: pick a random image from any available (not already used)
    const anyMatches = recipesSnapshot.docs
      .map((doc: FirebaseFirestore.QueryDocumentSnapshot) => doc.data() as RecipeDoc)
      .filter((data) => data.imageUrl && !excludeImageUrls.has(data.imageUrl));

    if (anyMatches.length > 0) {
      const shuffled = shuffleArray(anyMatches);
      console.log('[DEBUG:ImageMatch] FALLBACK random any image:', shuffled[0].title);
      return shuffled[0].imageUrl;
    }

    // Last resort: any image at all (even if already used)
    const anyImage = recipesSnapshot.docs.find((doc: FirebaseFirestore.QueryDocumentSnapshot) => {
      const data = doc.data() as RecipeDoc;
      return !!data.imageUrl;
    });

    if (anyImage) {
      const data = anyImage.data() as RecipeDoc;
      console.log('[DEBUG:ImageMatch] FALLBACK last resort (reuse):', data.title);
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
 * Batch match images for multiple recipes with diversity tracking
 */
export async function matchRecipeImages(
  recipes: Array<{
    title?: string;
    name?: string;
    cuisineType: string;
    mealType: string;
    ingredients: Array<{ name: string }>;
  }>
): Promise<(string | null)[]> {
  const usedImageUrls = new Set<string>();
  const results: (string | null)[] = [];

  // Process sequentially to track used images for diversity
  for (const recipe of recipes) {
    const imageUrl = await matchRecipeImage(recipe, usedImageUrls);
    if (imageUrl) {
      usedImageUrls.add(imageUrl);
    }
    results.push(imageUrl);
  }

  return results;
}
