/**
 * Mock recipeStorage — accepts all recipes as "saved".
 */

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

export async function saveRecipeIfUnique(_recipe: GeneratedRecipeDTO) {
  return { saved: true, id: `mock-${Date.now()}`, duplicate: false };
}

export async function saveRecipesIfUnique(recipes: GeneratedRecipeDTO[]) {
  return {
    saved: recipes.length,
    duplicates: 0,
    savedIds: recipes.map((_, i) => `mock-${i}`),
    duplicateIds: [] as string[],
  };
}

export async function getPopularGeneratedRecipes(_limit?: number) {
  return [];
}

export async function getRecentGeneratedRecipes(_limit?: number) {
  return [];
}

export async function getGeneratedRecipeCount(): Promise<number> {
  return 0;
}
