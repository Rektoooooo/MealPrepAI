/**
 * Generate Plan API Endpoint
 *
 * POST /api/v1/generate-plan
 *
 * Generates a full 7-day meal plan using Claude AI with:
 * - User profile-based personalization
 * - Weekly preference support
 * - Smart image matching
 * - Recipe deduplication and storage
 * - Rate limiting per device
 */

import Anthropic from '@anthropic-ai/sdk';
import { checkRateLimit } from '../utils/rateLimiter';
import { matchRecipeImage } from '../utils/imageMatch';
import { saveRecipesIfUnique, GeneratedRecipeDTO } from '../utils/recipeStorage';

// Types
interface UserProfile {
  age: number;
  gender: string;
  weightKg: number;
  heightCm: number;
  activityLevel: string;
  dailyCalorieTarget: number;
  proteinGrams: number;
  carbsGrams: number;
  fatGrams: number;
  weightGoal: string;
  dietaryRestrictions: string[];
  allergies: string[];
  foodDislikes: string[];  // Foods user doesn't like
  preferredCuisines: string[];
  cookingSkill: string;
  maxCookingTimeMinutes: number;
  simpleModeEnabled: boolean;
  mealsPerDay: number;
  includeSnacks: boolean;
  pantryLevel: string;  // Well-stocked, Average, Minimal
  barriers: string[];   // Time constraints, budget, etc.
}

interface GeneratePlanRequest {
  userProfile: UserProfile;
  weeklyPreferences?: string;
  excludeRecipeNames?: string[];
  deviceId: string;
  // Structured weekly preferences (optional, for enhanced parsing)
  weeklyFocus?: string[];
  temporaryExclusions?: string[];
  weeklyBusyness?: string;
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

interface MealDTO {
  mealType: string;
  recipe: RecipeDTO;
}

interface DayDTO {
  dayOfWeek: number;
  meals: MealDTO[];
}

interface MealPlanResponse {
  days: DayDTO[];
}

interface GeneratePlanResponse {
  success: boolean;
  mealPlan?: {
    id: string;
    days: DayDTO[];
  };
  recipesAdded?: number;
  recipesDuplicate?: number;
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
  return `You are a professional nutritionist and chef creating personalized meal plans based on current nutrition science.

IMPORTANT: Respond ONLY with valid JSON. No markdown, no explanation, no code blocks.

═══════════════════════════════════════════════════════════════
EVIDENCE-BASED NUTRITION PRINCIPLES (from peer-reviewed research)
═══════════════════════════════════════════════════════════════

1. CALORIE DISTRIBUTION (front-load for better metabolism):
   - Breakfast: 25-30% of daily calories
   - Lunch: 35-40% (LARGEST meal - metabolism peaks midday)
   - Dinner: 20-25% (lighter - avoid late glucose spikes)
   - Snacks: 10-15% total (2 snacks, ~150 cal each)

2. BREAKFAST REQUIREMENTS (critical for satiety & muscle):
   - MUST include 20-30g protein minimum
   - Good sources: eggs (3 = 18g), Greek yogurt 1 cup (17g), cottage cheese (14g)
   - Include complex carbs: oats, whole grain toast
   - Avoid: sugar-heavy cereals, pastries, juice-only
   - MAX 10 minutes prep/cook time

3. LUNCH (largest meal of the day):
   - Aim for 30-40g protein
   - Can include heartier carbs (rice, pasta, potatoes)
   - Balance: protein + complex carbs + vegetables
   - Up to 30 minutes prep/cook

4. DINNER (lighter, veggie-focused):
   - Half plate: non-starchy vegetables (broccoli, salad, green beans)
   - Quarter plate: lean protein (25-30g)
   - Quarter plate: small portion complex carbs OR skip carbs entirely
   - Avoid: heavy pasta dishes, large rice portions, fried foods
   - Up to user's max cooking time

5. SNACKS (functional, not treats):
   - ALWAYS pair protein + carbohydrate for lasting fullness
   - Morning: Greek yogurt + fruit, apple + almond butter, cottage cheese + berries
   - Afternoon: veggies + hummus, cheese + whole grain crackers, handful nuts + banana
   - ~100-200 calories each, no-cook, under 5 minutes
   - Never just carbs alone (no plain crackers, chips, or fruit only)

═══════════════════════════════════════════════════════════════
CRITICAL HEALTH REQUIREMENTS
═══════════════════════════════════════════════════════════════

- Daily calories in RANGE: target minus 300 to target (flexibility allowed)
- NEVER include allergenic ingredients - this is life-threatening
- Respect all dietary restrictions strictly

═══════════════════════════════════════════════════════════════
TIME CONSTRAINTS BY MEAL
═══════════════════════════════════════════════════════════════

- Breakfast: MAX 10 minutes. Simple foods only: eggs, oats, yogurt, smoothies, toast
- Snacks: MAX 5 minutes, no-cook only
- Lunch: Up to 30 minutes
- Dinner: Up to user's max cooking time preference

═══════════════════════════════════════════════════════════════
INGREDIENT OPTIMIZATION (reuse across the week for smaller grocery list)
═══════════════════════════════════════════════════════════════

Proteins (pick 3-4 for week): chicken breast, eggs, salmon/fish, ground beef, Greek yogurt, cottage cheese
Carbs (pick 2-3): oats, rice, whole grain bread, potatoes, pasta
Vegetables (pick 5-6): broccoli, spinach, bell peppers, tomatoes, onions, carrots, zucchini
Fruits: bananas, apples, berries (fresh or frozen)
Pantry: olive oil, garlic, lemon, salt, pepper, common spices

═══════════════════════════════════════════════════════════════
CUISINE & STYLE
═══════════════════════════════════════════════════════════════

- User's preferred cuisines are INSPIRATION only, not mandatory for every meal
- Most meals should be simple home cooking: "Scrambled Eggs", "Chicken and Rice", "Salmon with Vegetables"
- Include 2-3 cuisine-specific meals per week, rest simple everyday food
- Breakfast NEVER has a cuisine label - just simple breakfast foods

CRITICAL: Every ingredient mentioned in instructions MUST be in the ingredients list.`;
}

/**
 * Build the user prompt from profile and preferences
 * @param startDay - First day to generate (0-6)
 * @param endDay - Last day to generate (0-6)
 */
function buildUserPrompt(
  profile: UserProfile,
  startDay: number,
  endDay: number,
  weeklyPreferences?: string,
  excludeRecipeNames?: string[]
): string {
  const restrictions = profile.dietaryRestrictions.join(', ') || 'None';
  const allergies = profile.allergies.join(', ') || 'None';
  const foodDislikes = profile.foodDislikes?.join(', ') || 'None';
  const cuisines = profile.preferredCuisines.join(', ') || 'Varied';
  const barriers = profile.barriers?.join(', ') || 'None';
  const excludeList = excludeRecipeNames?.join(', ') || '';

  const mealTypes = profile.includeSnacks
    ? 'breakfast, morning snack, lunch, afternoon snack, and dinner (5 meals total)'
    : 'breakfast, lunch, and dinner';

  const numDays = endDay - startDay + 1;

  // Adjust recommendations based on pantry level
  let pantryNote = '';
  if (profile.pantryLevel === 'Minimal') {
    pantryNote = '- Pantry: MINIMAL - use only very common, basic ingredients (salt, pepper, oil, butter)';
  } else if (profile.pantryLevel === 'Well-Stocked') {
    pantryNote = '- Pantry: Well-stocked - can use varied spices and specialty ingredients';
  } else {
    pantryNote = '- Pantry: Average - use common pantry staples';
  }

  // Adjust for barriers
  let barrierNotes = '';
  if (barriers !== 'None') {
    barrierNotes = `\nCHALLENGES TO CONSIDER:\n- ${barriers}\n(Optimize recipes to help with these challenges)`;
  }

  return `Create a ${numDays}-day meal plan (days ${startDay}-${endDay}) for:

PERSONAL INFO:
- Age: ${profile.age}, Gender: ${profile.gender}
- Weight: ${profile.weightKg}kg, Height: ${profile.heightCm}cm
- Activity: ${profile.activityLevel}
- Goal: ${profile.weightGoal}

DAILY TARGETS:
- Calories: ${profile.dailyCalorieTarget} kcal
- Protein: ${profile.proteinGrams}g, Carbs: ${profile.carbsGrams}g, Fat: ${profile.fatGrams}g

PERMANENT RESTRICTIONS:
- Dietary: ${restrictions}
- Allergies (NEVER include these ingredients): ${allergies}
- Food Dislikes (AVOID these - user doesn't like them): ${foodDislikes}
- Preferred Cuisines: ${cuisines}

COOKING PREFERENCES:
- Skill: ${profile.cookingSkill}
- Max Time: ${profile.maxCookingTimeMinutes} minutes
- Simple Mode: ${profile.simpleModeEnabled ? 'Yes - prefer recipes with fewer ingredients' : 'No'}
${pantryNote}
${barrierNotes}

THIS WEEK'S SPECIAL REQUESTS:
${weeklyPreferences || 'None - follow standard preferences'}

${excludeList ? `VARIETY (avoid these recently used recipes):\n${excludeList}` : ''}

Each day must include: ${mealTypes}

Respond with JSON in this exact format:
{
  "days": [
    {
      "dayOfWeek": 0,
      "meals": [
        {
          "mealType": "breakfast",
          "recipe": {
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
        }
      ]
    }
  ]
}

Valid mealTypes: breakfast, snack, lunch, snack, dinner (use "snack" for both morning and afternoon snacks)
Valid complexity: easy, medium, hard
Valid cuisineTypes: american, italian, mexican, asian, mediterranean, indian, japanese, thai, french, greek, korean, vietnamese, middleEastern, african, caribbean
Valid categories: produce, meat, dairy, pantry, frozen, bakery, beverages, other
Valid units: gram, kilogram, milliliter, liter, cup, tablespoon, teaspoon, piece, slice, bunch, can, package, pound, ounce

dayOfWeek should be ${startDay}-${endDay}
Include as many instruction steps as the recipe needs. Keep ingredients to essential items (5-8 per recipe).
IMPORTANT: Each day's total calories should be between ${profile.dailyCalorieTarget - 300} and ${profile.dailyCalorieTarget} kcal.`;
}

/**
 * Parse and clean Claude's JSON response
 */
function parseClaudeResponse(content: string): MealPlanResponse {
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
    return JSON.parse(cleanJSON) as MealPlanResponse;
  } catch {
    throw new Error('Failed to parse JSON response from Claude');
  }
}

/**
 * Main handler for generate-plan endpoint
 */
export async function handleGeneratePlan(
  req: GeneratePlanRequest
): Promise<GeneratePlanResponse> {
  const { userProfile, weeklyPreferences, excludeRecipeNames, deviceId, weeklyFocus, temporaryExclusions, weeklyBusyness } = req;

  console.log('[DEBUG] ========== GENERATE PLAN START ==========');
  console.log('[DEBUG] Device ID:', deviceId);
  console.log('[DEBUG] Weekly Preferences:', weeklyPreferences || 'None');
  console.log('[DEBUG] Exclude Recipes:', excludeRecipeNames?.join(', ') || 'None');
  console.log('[DEBUG] Structured Prefs - Focus:', weeklyFocus?.join(', ') || 'None');
  console.log('[DEBUG] Structured Prefs - Exclusions:', temporaryExclusions?.join(', ') || 'None');
  console.log('[DEBUG] Structured Prefs - Busyness:', weeklyBusyness || 'None');

  // Validate required fields
  if (!deviceId) {
    console.log('[DEBUG] ERROR: Device ID is required');
    return { success: false, error: 'Device ID is required' };
  }

  if (!userProfile) {
    console.log('[DEBUG] ERROR: User profile is required');
    return { success: false, error: 'User profile is required' };
  }

  console.log('[DEBUG] User Profile:', JSON.stringify({
    age: userProfile.age,
    gender: userProfile.gender,
    dailyCalorieTarget: userProfile.dailyCalorieTarget,
    dietaryRestrictions: userProfile.dietaryRestrictions,
    allergies: userProfile.allergies,
    foodDislikes: userProfile.foodDislikes,
    preferredCuisines: userProfile.preferredCuisines,
    cookingSkill: userProfile.cookingSkill,
    mealsPerDay: userProfile.mealsPerDay,
    includeSnacks: userProfile.includeSnacks,
    pantryLevel: userProfile.pantryLevel,
    barriers: userProfile.barriers,
  }));

  // Check rate limit
  console.log('[DEBUG] Checking rate limit for device:', deviceId);
  const rateLimit = await checkRateLimit(deviceId, 'generate-plan');
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

    const systemPrompt = buildSystemPrompt();
    const allDays: DayDTO[] = [];

    // Using Claude Haiku for cost efficiency (~12x cheaper than Sonnet)
    // Split into 4 batches to fit within Haiku's 4096 token output limit
    const MODEL = 'claude-3-5-haiku-latest';
    const MAX_TOKENS = 4000;

    // Batch definitions: [startDay, endDay]
    const batches: [number, number][] = [
      [0, 1],  // Days 0-1 (2 days, 8 meals)
      [2, 3],  // Days 2-3 (2 days, 8 meals)
      [4, 5],  // Days 4-5 (2 days, 8 meals)
      [6, 6],  // Day 6 (1 day, 4 meals)
    ];

    // Run all 4 batches IN PARALLEL for speed
    console.log('[DEBUG] Starting all 4 batches in PARALLEL...');
    const parallelStartTime = Date.now();

    const batchPromises = batches.map(async ([startDay, endDay], i) => {
      const batchNum = i + 1;
      console.log(`[DEBUG] Batch ${batchNum}: Days ${startDay}-${endDay} - STARTING`);

      const userPrompt = buildUserPrompt(userProfile, startDay, endDay, weeklyPreferences, excludeRecipeNames);
      const startTime = Date.now();

      const response = await client.messages.create({
        model: MODEL,
        max_tokens: MAX_TOKENS,
        system: systemPrompt,
        messages: [{ role: 'user', content: userPrompt }],
      });

      const batchTime = Date.now() - startTime;
      console.log(`[DEBUG] Batch ${batchNum} received in ${batchTime}ms, stop: ${response.stop_reason}`);

      const textContent = response.content.find((c: Anthropic.ContentBlock) => c.type === 'text');
      if (!textContent || textContent.type !== 'text') {
        throw new Error(`No text content in Claude response (batch ${batchNum})`);
      }

      const batchResult = parseClaudeResponse(textContent.text);
      console.log(`[DEBUG] Batch ${batchNum} parsed: ${batchResult.days.length} days`);

      return { batchNum, days: batchResult.days };
    });

    // Wait for all batches to complete
    const batchResults = await Promise.all(batchPromises);

    // Sort by batch number and combine days in order
    batchResults.sort((a, b) => a.batchNum - b.batchNum);
    for (const result of batchResults) {
      allDays.push(...result.days);
    }

    const totalParallelTime = Date.now() - parallelStartTime;
    console.log('[DEBUG] All batches completed in:', totalParallelTime, 'ms (PARALLEL)');

    // Combine batches
    const mealPlan: MealPlanResponse = { days: allDays };
    console.log('[DEBUG] Combined meal plan:', mealPlan.days.length, 'total days');

    const totalMeals = mealPlan.days.reduce((acc, day) => acc + day.meals.length, 0);
    console.log('[DEBUG] Parsed meal plan:', mealPlan.days.length, 'days,', totalMeals, 'total meals');

    // Match images and prepare recipes for storage
    console.log('[DEBUG] Starting image matching for', totalMeals, 'recipes...');
    const allRecipes: GeneratedRecipeDTO[] = [];
    let imagesMatched = 0;

    for (const day of mealPlan.days) {
      for (const meal of day.meals) {
        const recipe = meal.recipe;

        // Match image
        console.log('[DEBUG] Matching image for:', recipe.name, '(', recipe.cuisineType, meal.mealType, ')');
        const matchedImageUrl = await matchRecipeImage({
          cuisineType: recipe.cuisineType,
          mealType: meal.mealType,
          ingredients: recipe.ingredients,
        });

        if (matchedImageUrl) {
          imagesMatched++;
          console.log('[DEBUG]   -> Image matched:', matchedImageUrl.substring(0, 50) + '...');
        } else {
          console.log('[DEBUG]   -> No image match found');
        }

        // Add matched image URL to recipe
        recipe.matchedImageUrl = matchedImageUrl;

        // Prepare for storage
        allRecipes.push({
          name: recipe.name,
          description: recipe.description,
          cuisineType: recipe.cuisineType,
          mealType: meal.mealType,
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
          matchedImageUrl,
        });
      }
    }

    console.log('[DEBUG] Image matching complete:', imagesMatched, '/', totalMeals, 'matched');

    // Save recipes to database
    console.log('[DEBUG] Saving', allRecipes.length, 'recipes to database...');
    const storageResult = await saveRecipesIfUnique(allRecipes);
    console.log('[DEBUG] Storage result:', storageResult.saved, 'new,', storageResult.duplicates, 'duplicates');

    // Generate plan ID
    const planId = `mp_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    console.log('[DEBUG] Generated plan ID:', planId);

    console.log('[DEBUG] ========== GENERATE PLAN SUCCESS ==========');

    return {
      success: true,
      mealPlan: {
        id: planId,
        days: mealPlan.days,
      },
      recipesAdded: storageResult.saved,
      recipesDuplicate: storageResult.duplicates,
      rateLimitInfo: {
        remaining: rateLimit.remaining,
        resetTime: rateLimit.resetTime.toISOString(),
        limit: rateLimit.limit,
      },
    };
  } catch (error) {
    console.log('[DEBUG] ========== GENERATE PLAN ERROR ==========');
    console.error('[DEBUG] Error type:', error instanceof Error ? error.constructor.name : typeof error);
    console.error('[DEBUG] Error message:', error instanceof Error ? error.message : String(error));
    console.error('[DEBUG] Full error:', error);

    const errorMessage =
      error instanceof Error ? error.message : 'Unknown error occurred';

    return {
      success: false,
      error: `Failed to generate meal plan: ${errorMessage}`,
    };
  }
}
