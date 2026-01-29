/**
 * Swap Meal API Endpoint
 *
 * POST /api/v1/swap-meal
 *
 * Generates a single replacement meal using Claude AI with:
 * - User profile-based personalization
 * - Exclude list to avoid repeating recipes
 * - Smart image matching
 * - Rate limiting per device
 */

import Anthropic from '@anthropic-ai/sdk';
import { checkRateLimit } from '../utils/rateLimiter';
// Image matching disabled — AI-generated recipes use gradient placeholders on iOS
// import { matchRecipeImage } from '../utils/imageMatch';
import { saveRecipeIfUnique, GeneratedRecipeDTO } from '../utils/recipeStorage';

// Types
interface UserProfile {
  dailyCalorieTarget: number;
  proteinGrams: number;
  carbsGrams: number;
  fatGrams: number;
  dietaryRestrictions: string[];
  allergies: string[];
  preferredCuisines: string[];
  cookingSkill: string;
  maxCookingTimeMinutes: number;
  simpleModeEnabled: boolean;
}

interface SwapMealRequest {
  userProfile: UserProfile;
  mealType: string; // breakfast, lunch, dinner, snack
  excludeRecipeNames?: string[];
  excludeImageUrls?: string[];
  weeklyPreferences?: string;
  deviceId: string;
}

interface IngredientDTO {
  name: string;
  quantity: number;
  unit: string;
  category: string;
}

interface RecipeDTO {
  name: string;
  description: string;
  matchedImageUrl?: string | null;
  prepTimeMinutes: number;
  cookTimeMinutes: number;
  servings: number;
  complexity: string;
  cuisineType: string;
  calories: number;
  proteinGrams: number;
  carbsGrams: number;
  fatGrams: number;
  fiberGrams: number;
  ingredients: IngredientDTO[];
  instructions: string[];
}

interface SwapMealResponse {
  success: boolean;
  recipe?: RecipeDTO;
  error?: string;
  rateLimitInfo?: {
    remaining: number;
    resetTime: string;
    limit: number;
  };
}

// Claude client - initialized lazily
let anthropic: Anthropic | null = null;

function getAnthropicClient(): Anthropic {
  if (!anthropic) {
    const apiKey = process.env.ANTHROPIC_API_KEY;
    if (!apiKey) {
      throw new Error('ANTHROPIC_API_KEY environment variable not set');
    }
    anthropic = new Anthropic({ apiKey });
  }
  return anthropic;
}

/**
 * Build the system prompt for Claude
 */
function buildSystemPrompt(): string {
  return `You are a professional nutritionist and chef creating personalized meals.

IMPORTANT: Respond ONLY with valid JSON. No markdown, no explanation, no code blocks.

Guidelines:
- Create a balanced, nutritious meal that fits the user's targets
- Respect all dietary restrictions strictly
- NEVER include any ingredients the user is allergic to - this is critical for health
- Consider cooking skill level when selecting recipe complexity
- Include practical, easy-to-find ingredients
- Provide accurate nutritional information
- Keep prep and cook times realistic
- CRITICAL: Every ingredient mentioned in instructions MUST be in the ingredients list (including oil, sauces, seasonings, cornstarch, etc.)`;
}

/**
 * Build the user prompt for a single meal
 */
function buildUserPrompt(
  profile: UserProfile,
  mealType: string,
  excludeRecipeNames?: string[],
  weeklyPreferences?: string
): string {
  const restrictions = profile.dietaryRestrictions.join(', ') || 'None';
  const allergies = profile.allergies.join(', ') || 'None';
  const cuisines = profile.preferredCuisines.join(', ') || 'Varied';
  const excludeList = excludeRecipeNames?.join(', ') || '';

  // Calculate approximate meal targets based on meal type
  const mealConfig: Record<string, { caloriePercent: number; maxTime: number }> = {
    breakfast: { caloriePercent: 0.25, maxTime: 10 },
    snack: { caloriePercent: 0.05, maxTime: 5 },
    lunch: { caloriePercent: 0.30, maxTime: 30 },
    dinner: { caloriePercent: 0.35, maxTime: profile.maxCookingTimeMinutes },
  };
  const config = mealConfig[mealType] || { caloriePercent: 0.25, maxTime: 30 };
  const mealCalories = Math.round(profile.dailyCalorieTarget * config.caloriePercent);
  const mealProtein = Math.round(profile.proteinGrams * config.caloriePercent);

  // Time constraint message based on meal type
  const timeConstraint = mealType === 'breakfast'
    ? 'MAX 10 minutes total (quick recipes only: eggs, toast, smoothies, overnight oats)'
    : mealType === 'snack'
    ? 'MAX 5 minutes total (no-cook or minimal prep: fruit, nuts, yogurt, cheese)'
    : `Up to ${config.maxTime} minutes`;

  return `Create a single ${mealType} recipe for a person with:

MEAL TARGETS (approximately):
- Calories: ~${mealCalories} kcal
- Protein: ~${mealProtein}g

TIME CONSTRAINT: ${timeConstraint}

DIETARY RESTRICTIONS: ${restrictions}
ALLERGIES (STRICT - NEVER include): ${allergies}
PREFERRED CUISINES: ${cuisines}
COOKING SKILL: ${profile.cookingSkill}
SIMPLE MODE: ${profile.simpleModeEnabled ? 'Yes - prefer fewer ingredients' : 'No'}

${weeklyPreferences ? `THIS WEEK'S PREFERENCES:\n${weeklyPreferences}` : ''}

${excludeList ? `DO NOT suggest these recipes (user wants variety):\n${excludeList}` : ''}

Respond with a single recipe JSON (no array, no wrapper):
{
  "name": "Recipe Name",
  "description": "Brief description",
  "instructions": ["Step 1", "Step 2"],
  "prepTimeMinutes": 10,
  "cookTimeMinutes": 15,
  "servings": 2,
  "complexity": "easy",
  "cuisineType": "american",
  "calories": 400,
  "proteinGrams": 20,
  "carbsGrams": 40,
  "fatGrams": 15,
  "fiberGrams": 5,
  "ingredients": [
    {"name": "Ingredient", "quantity": 1, "unit": "cup", "category": "produce"}
  ]
}

Valid complexity: easy, medium, hard
Valid cuisineTypes: american, italian, mexican, asian, mediterranean, indian, japanese, thai, french, greek, korean, vietnamese, middleEastern, african, caribbean
Valid categories: produce, meat, dairy, pantry, frozen, bakery, beverages, other
Valid units: gram, kilogram, milliliter, liter, cup, tablespoon, teaspoon, piece, slice, bunch, can, package, pound, ounce`;
}

/**
 * Parse and clean Claude's JSON response for a single recipe
 */
function parseClaudeResponse(content: string): RecipeDTO {
  // Clean up potential markdown code blocks
  let cleanJSON = content
    .replace(/```json/gi, '')
    .replace(/```/g, '')
    .trim();

  // Find JSON object boundaries
  const startIndex = cleanJSON.indexOf('{');
  const endIndex = cleanJSON.lastIndexOf('}');

  if (startIndex === -1 || endIndex === -1) {
    throw new Error('No valid JSON object found in response');
  }

  cleanJSON = cleanJSON.substring(startIndex, endIndex + 1);

  try {
    return JSON.parse(cleanJSON) as RecipeDTO;
  } catch {
    throw new Error('Failed to parse JSON response from Claude');
  }
}

/**
 * Main handler for swap-meal endpoint
 */
export async function handleSwapMeal(
  req: SwapMealRequest
): Promise<SwapMealResponse> {
  const {
    userProfile,
    mealType,
    excludeRecipeNames,
    weeklyPreferences,
    deviceId,
  } = req;

  console.log('[DEBUG] ========== SWAP MEAL START ==========');
  console.log('[DEBUG] Device ID:', deviceId);
  console.log('[DEBUG] Meal Type:', mealType);
  console.log('[DEBUG] Weekly Preferences:', weeklyPreferences || 'None');
  console.log('[DEBUG] Exclude Recipes:', excludeRecipeNames?.join(', ') || 'None');

  // Validate required fields
  if (!deviceId) {
    console.log('[DEBUG] ERROR: Device ID is required');
    return { success: false, error: 'Device ID is required' };
  }

  if (!userProfile) {
    console.log('[DEBUG] ERROR: User profile is required');
    return { success: false, error: 'User profile is required' };
  }

  if (!mealType) {
    console.log('[DEBUG] ERROR: Meal type is required');
    return { success: false, error: 'Meal type is required' };
  }

  const validMealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];
  if (!validMealTypes.includes(mealType.toLowerCase())) {
    console.log('[DEBUG] ERROR: Invalid meal type:', mealType);
    return { success: false, error: 'Invalid meal type' };
  }

  console.log('[DEBUG] User Profile:', JSON.stringify({
    dailyCalorieTarget: userProfile.dailyCalorieTarget,
    proteinGrams: userProfile.proteinGrams,
    dietaryRestrictions: userProfile.dietaryRestrictions,
    allergies: userProfile.allergies,
    cookingSkill: userProfile.cookingSkill,
  }));

  // Check rate limit
  console.log('[DEBUG] Checking rate limit for device:', deviceId);
  const rateLimit = await checkRateLimit(deviceId, 'swap-meal');
  console.log('[DEBUG] Rate limit result:', JSON.stringify({
    allowed: rateLimit.allowed,
    remaining: rateLimit.remaining,
    limit: rateLimit.limit,
  }));

  if (!rateLimit.allowed) {
    console.log('[DEBUG] ERROR: Rate limit exceeded');
    return {
      success: false,
      error: 'Rate limit exceeded. Please try again later.',
      rateLimitInfo: {
        remaining: rateLimit.remaining,
        resetTime: rateLimit.resetTime.toISOString(),
        limit: rateLimit.limit,
      },
    };
  }

  try {
    // Get Claude client
    console.log('[DEBUG] Initializing Claude client...');
    const client = getAnthropicClient();
    console.log('[DEBUG] Claude client initialized successfully');

    // Build prompts
    console.log('[DEBUG] Building prompts...');
    const systemPrompt = buildSystemPrompt();
    const userPrompt = buildUserPrompt(
      userProfile,
      mealType,
      excludeRecipeNames,
      weeklyPreferences
    );
    console.log('[DEBUG] User prompt length:', userPrompt.length, 'characters');

    console.log('[DEBUG] Calling Claude API for', mealType, 'swap (model: claude-3-5-haiku-latest)...');
    const startTime = Date.now();

    // Call Claude API - Using Claude Haiku for cost efficiency
    const response = await client.messages.create({
      model: 'claude-3-5-haiku-latest',
      max_tokens: 2000,
      system: systemPrompt,
      messages: [{ role: 'user', content: userPrompt }],
    });

    const apiDuration = Date.now() - startTime;
    console.log('[DEBUG] Claude API response received in', apiDuration, 'ms');
    console.log('[DEBUG] Claude usage:', JSON.stringify(response.usage));
    console.log('[DEBUG] Claude stop reason:', response.stop_reason);

    // Extract text content
    const textContent = response.content.find((c: Anthropic.ContentBlock) => c.type === 'text');
    if (!textContent || textContent.type !== 'text') {
      console.log('[DEBUG] ERROR: No text content in Claude response');
      throw new Error('No text content in Claude response');
    }

    console.log('[DEBUG] Response text length:', textContent.text.length, 'characters');
    console.log('[DEBUG] Parsing Claude response...');

    // Parse response
    const recipe = parseClaudeResponse(textContent.text);
    console.log('[DEBUG] Parsed recipe:', recipe.name);
    console.log('[DEBUG] Recipe details:', JSON.stringify({
      calories: recipe.calories,
      proteinGrams: recipe.proteinGrams,
      cuisineType: recipe.cuisineType,
      complexity: recipe.complexity,
      ingredientCount: recipe.ingredients.length,
    }));

    // AI-generated recipes don't get images — iOS shows gradient placeholders
    recipe.matchedImageUrl = null;

    // Save recipe to database
    console.log('[DEBUG] Saving recipe to database...');
    const recipeDTO: GeneratedRecipeDTO = {
      name: recipe.name,
      description: recipe.description,
      cuisineType: recipe.cuisineType,
      mealType: mealType,
      complexity: recipe.complexity,
      calories: recipe.calories,
      proteinGrams: recipe.proteinGrams,
      carbsGrams: recipe.carbsGrams,
      fatGrams: recipe.fatGrams,
      fiberGrams: recipe.fiberGrams,
      prepTimeMinutes: recipe.prepTimeMinutes,
      cookTimeMinutes: recipe.cookTimeMinutes,
      servings: recipe.servings,
      ingredients: recipe.ingredients,
      instructions: recipe.instructions,
      matchedImageUrl: null,
    };

    const saveResult = await saveRecipeIfUnique(recipeDTO);
    console.log('[DEBUG] Save result:', saveResult.saved ? 'New recipe saved' : 'Duplicate found',
      saveResult.saved ? saveResult.newId : saveResult.existingId);

    console.log('[DEBUG] ========== SWAP MEAL SUCCESS ==========');

    return {
      success: true,
      recipe,
      rateLimitInfo: {
        remaining: rateLimit.remaining,
        resetTime: rateLimit.resetTime.toISOString(),
        limit: rateLimit.limit,
      },
    };
  } catch (error) {
    console.log('[DEBUG] ========== SWAP MEAL ERROR ==========');
    console.error('[DEBUG] Error type:', error instanceof Error ? error.constructor.name : typeof error);
    console.error('[DEBUG] Error message:', error instanceof Error ? error.message : String(error));
    console.error('[DEBUG] Full error:', error);

    const errorMessage =
      error instanceof Error ? error.message : 'Unknown error occurred';

    return {
      success: false,
      error: `Failed to generate replacement meal: ${errorMessage}`,
    };
  }
}
