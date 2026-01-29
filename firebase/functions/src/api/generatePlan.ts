/**
 * Generate Plan API Endpoint
 *
 * POST /api/v1/generate-plan
 *
 * Generates a 1-14 day meal plan using Claude AI with:
 * - User profile-based personalization
 * - Weekly preference support
 * - Smart image matching
 * - Recipe deduplication and storage
 * - Rate limiting per device
 */

import Anthropic from '@anthropic-ai/sdk';
import { checkRateLimit } from '../utils/rateLimiter';
// Image matching disabled — AI-generated recipes use gradient placeholders on iOS
// import { matchRecipeImage } from '../utils/imageMatch';
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
  dislikedCuisines: string[];  // Cuisines user marked as "dislike"
  cookingSkill: string;
  maxCookingTimeMinutes: number;
  simpleModeEnabled: boolean;
  mealsPerDay: number;
  includeSnacks: boolean;
  pantryLevel: string;  // Well-stocked, Average, Minimal
  barriers: string[];   // Time constraints, budget, etc.
  primaryGoals: string[];  // planMeals, eatHealthy, saveMoney, etc.
  goalPace: string;  // Gradual, Moderate, Aggressive
}

interface GeneratePlanRequest {
  userProfile: UserProfile;
  weeklyPreferences?: string;
  excludeRecipeNames?: string[];
  deviceId: string;
  duration?: number; // 1-14 days, defaults to 7
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
  return `You are a professional nutritionist creating personalized meal plans.

IMPORTANT: Respond ONLY with valid JSON. No markdown, no explanation, no code blocks.

═══════════════════════════════════════════════════════════════
STRICT CALORIE & MACRO REQUIREMENTS
═══════════════════════════════════════════════════════════════

CRITICAL: Each day's totals MUST hit targets closely:
- Daily calories: within 100 kcal of target (NOT 300 - must be close!)
- Daily protein: within 10g of target (this is critical for muscle)
- Carbs and fat: within 15g of target

CALORIE DISTRIBUTION per day (percentages - apply to user's specific targets):
- Breakfast: 22% of daily calories, 20% of protein
- Lunch: 32% of calories, 28% of protein (largest meal)
- Dinner: 28% of calories, 26% of protein
- Snacks: 18% total (2 snacks at 9% each), 26% of protein (13% each)

The user prompt contains the EXACT calculated targets for each meal based on their profile.
Follow those specific numbers, not generic examples.

═══════════════════════════════════════════════════════════════
INGREDIENT GUIDELINES
═══════════════════════════════════════════════════════════════

IMPORTANT: Use ONLY the ingredients listed in the user's specific prompt.
The ingredient list is customized based on their dietary restrictions.

PANTRY (always available, don't list in ingredients):
- salt, pepper, garlic powder, Italian seasoning, soy sauce, honey

LIMIT: Maximum 4-5 ingredients per recipe (excluding pantry staples)

═══════════════════════════════════════════════════════════════
VARIETY REQUIREMENTS (CRITICAL)
═══════════════════════════════════════════════════════════════
- NEVER repeat same protein 2 days in a row for lunch/dinner
- Follow the rotation pattern provided in the user's prompt
- Each breakfast should be DIFFERENT - rotate daily!
- Snacks can repeat but vary the accompaniments

═══════════════════════════════════════════════════════════════
MEAL GUIDELINES
═══════════════════════════════════════════════════════════════

CRITICAL: Follow the PER-MEAL TARGETS in the user prompt exactly!
The targets are calculated based on the user's specific protein goal.

BREAKFAST (quick, ~10 min):
- Use available proteins: eggs, yogurt, or protein from user's list
- Add carbs (oats, toast) for energy
- Hit the protein target from user prompt (varies per user)

LUNCH (respect user's max cooking time):
- Use the ASSIGNED PROTEIN from the schedule + carb + vegetable
- This is the biggest protein meal of the day

DINNER (respect user's max cooking time):
- Use the ASSIGNED PROTEIN from the schedule + vegetables + small carb

SNACKS (no-cook, 5 min):
- Use high-protein dairy: Greek yogurt or cottage cheese (adjust portions to hit target)
- Add fruit for carbs and flavor
- Hit the snack protein target from user prompt (varies per user!)
- If user is dairy-free/vegan, use available protein sources

═══════════════════════════════════════════════════════════════
RESTRICTIONS
═══════════════════════════════════════════════════════════════

- NEVER include allergenic ingredients - life-threatening
- Respect dietary restrictions strictly
- Every ingredient in instructions MUST be in ingredients list`;
}

/**
 * Build dynamic ingredient list based on user preferences
 */
function buildIngredientList(profile: UserProfile): {
  proteins: string[];
  carbs: string[];
  vegetables: string[];
  fruits: string[];
  dairy: string[];
  proteinRotation: string;
} {
  const restrictions = profile.dietaryRestrictions.map(r => r.toLowerCase());
  const dislikes = (profile.foodDislikes || []).map(d => d.toLowerCase());
  const allergies = profile.allergies.map(a => a.toLowerCase());

  const isVegan = restrictions.includes('vegan');
  const isVegetarian = restrictions.includes('vegetarian') || isVegan;
  const isPescatarian = restrictions.includes('pescatarian');
  const isDairyFree = restrictions.includes('dairy-free') || allergies.includes('dairy') || allergies.includes('lactose');
  const isGlutenFree = restrictions.includes('gluten-free') || allergies.includes('gluten');

  // Helper to filter out disliked/allergic items
  const filterItems = (items: string[]) =>
    items.filter(item => !dislikes.includes(item.toLowerCase()) && !allergies.includes(item.toLowerCase()));

  // Build protein list based on dietary restrictions
  let proteins: string[] = [];
  let proteinRotation = '';

  if (isVegan) {
    proteins = filterItems(['tofu', 'tempeh', 'lentils', 'chickpeas', 'black beans', 'edamame']);
    proteinRotation = 'tofu → tempeh → lentils → chickpeas → tofu...';
  } else if (isVegetarian) {
    proteins = filterItems(['eggs', 'Greek yogurt', 'cottage cheese', 'tofu', 'lentils', 'chickpeas']);
    proteinRotation = 'eggs → tofu → lentils → chickpeas → eggs...';
  } else if (isPescatarian) {
    proteins = filterItems(['salmon', 'tuna', 'shrimp', 'eggs', 'Greek yogurt', 'cottage cheese', 'tofu']);
    proteinRotation = 'salmon → tuna → shrimp → tofu → salmon...';
  } else {
    // Standard (omnivore)
    proteins = filterItems(['chicken breast', 'ground beef', 'salmon', 'pork chop', 'eggs', 'Greek yogurt', 'cottage cheese']);
    proteinRotation = 'chicken → beef → salmon → pork → chicken...';
  }

  // Build carb list
  let carbs = isGlutenFree
    ? filterItems(['rice', 'oats', 'potato', 'quinoa', 'sweet potato'])
    : filterItems(['rice', 'oats', 'whole wheat bread', 'potato', 'pasta']);

  // Build vegetable list
  const vegetables = filterItems(['broccoli', 'spinach', 'bell pepper', 'onion', 'tomato', 'carrot', 'zucchini', 'mushrooms']);

  // Build fruit list
  const fruits = filterItems(['banana', 'apple', 'mixed berries']);

  // Build dairy list
  let dairy: string[] = [];
  if (!isDairyFree) {
    dairy = filterItems(['olive oil', 'butter', 'cheese', 'milk']);
  } else {
    dairy = filterItems(['olive oil', 'almond milk', 'coconut oil']);
  }

  return { proteins, carbs, vegetables, fruits, dairy, proteinRotation };
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
  const dislikedCuisines = profile.dislikedCuisines?.join(', ') || 'None';
  const excludeList = excludeRecipeNames?.join(', ') || '';

  const mealTypes = profile.includeSnacks
    ? 'breakfast, morning snack, lunch, afternoon snack, and dinner (5 meals total)'
    : 'breakfast, lunch, and dinner';

  const numDays = endDay - startDay + 1;

  // Build dynamic ingredient list based on user preferences
  const ingredients = buildIngredientList(profile);
  const allIngredients = [
    ...ingredients.proteins,
    ...ingredients.carbs,
    ...ingredients.vegetables,
    ...ingredients.fruits,
    ...ingredients.dairy,
  ].join(', ');

  // Build personalization notes based on user goals and barriers
  const goalNotes: string[] = [];
  const userGoals = profile.primaryGoals || [];
  const userBarriers = profile.barriers || [];

  // Primary goals personalization
  if (userGoals.includes('Save money') || userGoals.includes('saveMoney')) {
    goalNotes.push('💰 BUDGET-FRIENDLY: Use economical ingredients, plan for leftovers');
  }
  if (userGoals.includes('Save time') || userGoals.includes('saveTime')) {
    goalNotes.push('⏱️ TIME-SAVING: Quick prep, minimal cleanup, batch-friendly');
  }
  if (userGoals.includes('Meal prep') || userGoals.includes('mealPrep')) {
    goalNotes.push('📦 MEAL PREP: Make recipes that store well, good for batch cooking');
  }
  if (userGoals.includes('Family meals') || userGoals.includes('familyMeals')) {
    goalNotes.push('👨‍👩‍👧 FAMILY-FRIENDLY: Kid-approved flavors, crowd-pleasing dishes');
  }
  if (userGoals.includes('Try new recipes') || userGoals.includes('tryNewRecipes')) {
    goalNotes.push('🌍 ADVENTUROUS: Include interesting cuisines and unique flavors');
  }
  if (userGoals.includes('Eat healthy') || userGoals.includes('eatHealthy')) {
    goalNotes.push('🥗 HEALTH-FOCUSED: Whole foods, balanced nutrition, vegetables');
  }

  // Barriers personalization
  if (userBarriers.includes('Too busy to plan meals') || userBarriers.includes('tooBusy')) {
    goalNotes.push('⚡ QUICK MEALS: Keep recipes under 30 mins, simple prep');
  }
  if (userBarriers.includes('Lack of cooking skills') || userBarriers.includes('lackCookingSkills')) {
    goalNotes.push('👨‍🍳 BEGINNER-FRIENDLY: Simple techniques, clear instructions, forgiving recipes');
  }
  if (userBarriers.includes('Get bored eating the same things') || userBarriers.includes('getBored')) {
    goalNotes.push('🎨 VARIETY: Different cuisines each day, varied flavors and textures');
  }
  if (userBarriers.includes('Struggle with grocery shopping') || userBarriers.includes('groceryShopping')) {
    goalNotes.push('🛒 SIMPLE SHOPPING: Use overlapping ingredients, minimize unique items');
  }

  const personalizationSection = goalNotes.length > 0
    ? `═══ USER PRIORITIES (IMPORTANT!) ═══\n${goalNotes.join('\n')}\n`
    : '';

  // Adjust recommendations based on pantry level
  let pantryNote = '';
  if (profile.pantryLevel === 'Minimal' || profile.pantryLevel === 'Basic') {
    pantryNote = '- Pantry: MINIMAL - use only very common, basic ingredients (salt, pepper, oil, butter)';
  } else if (profile.pantryLevel === 'Well-Stocked' || profile.pantryLevel === 'wellStocked') {
    pantryNote = '- Pantry: Well-stocked - can use varied spices and specialty ingredients';
  } else {
    pantryNote = '- Pantry: Average - use common pantry staples';
  }

  // Calculate per-meal targets for the prompt
  // IMPORTANT: Percentages MUST add up to 100% for both calories and protein
  // Calories: 22 + 32 + 28 + 9 + 9 = 100%
  // Protein: 20 + 28 + 26 + 13 + 13 = 100%
  const breakfastCal = Math.round(profile.dailyCalorieTarget * 0.22);
  const breakfastProtein = Math.round(profile.proteinGrams * 0.20);
  const lunchCal = Math.round(profile.dailyCalorieTarget * 0.32);
  const lunchProtein = Math.round(profile.proteinGrams * 0.28);
  const dinnerCal = Math.round(profile.dailyCalorieTarget * 0.28);
  const snackProtein = Math.round(profile.proteinGrams * 0.13); // ~27g for 209g target

  // Assign specific proteins to specific days for VARIETY (critical for parallel batches)
  // This ensures different batches don't all pick the same protein
  const proteinSchedule: { [day: number]: { lunch: string; dinner: string } } = {};

  // Filter out dairy/egg proteins to get main meal proteins (meat, fish, legumes)
  const dairyProteins = ['eggs', 'greek yogurt', 'cottage cheese'];
  const mainProteins = ingredients.proteins.filter(p =>
    !dairyProteins.includes(p.toLowerCase())
  );

  // Use main proteins if available, otherwise fall back to all proteins
  const proteinsToRotate = mainProteins.length >= 2 ? mainProteins : ingredients.proteins;

  // Rotate through available proteins based on user's actual preferences
  for (let day = startDay; day <= endDay; day++) {
    if (proteinsToRotate.length === 0) {
      // Edge case: no proteins available (shouldn't happen)
      proteinSchedule[day] = { lunch: 'protein source', dinner: 'protein source' };
    } else if (proteinsToRotate.length === 1) {
      // Only one protein available
      proteinSchedule[day] = { lunch: proteinsToRotate[0], dinner: proteinsToRotate[0] };
    } else {
      // Multiple proteins - rotate them
      const lunchProteinIdx = day % proteinsToRotate.length;
      const dinnerProteinIdx = (day + 1) % proteinsToRotate.length;
      proteinSchedule[day] = {
        lunch: proteinsToRotate[lunchProteinIdx],
        dinner: proteinsToRotate[dinnerProteinIdx],
      };
    }
  }

  // Build variety schedule string
  const varietySchedule = Object.entries(proteinSchedule)
    .map(([day, proteins]) => `Day ${day}: Lunch=${proteins.lunch}, Dinner=${proteins.dinner}`)
    .join('\n');
  const dinnerProtein = Math.round(profile.proteinGrams * 0.26);
  const snackCal = Math.round(profile.dailyCalorieTarget * 0.09);

  // Calculate carbs and fat for breakfast (22% of daily)
  const breakfastCarbs = Math.round(profile.carbsGrams * 0.22);
  const breakfastFat = Math.round(profile.fatGrams * 0.22);

  return `Create a ${numDays}-day meal plan (days ${startDay}-${endDay}).

═══ DAILY TARGETS (vary naturally, don't force exact numbers) ═══
- Calories: ~${profile.dailyCalorieTarget} kcal (vary between ${profile.dailyCalorieTarget - 150}-${profile.dailyCalorieTarget + 150})
- Protein: ~${profile.proteinGrams}g (vary between ${profile.proteinGrams - 15}-${profile.proteinGrams + 15}g)
- Carbs: ~${profile.carbsGrams}g, Fat: ~${profile.fatGrams}g
- IMPORTANT: Create natural variation each day - don't hit exact same numbers daily!

═══ PER-MEAL GUIDELINES (approximate, vary naturally) ═══
- Breakfast: ${breakfastCal - 50}-${breakfastCal + 50} cal, ${breakfastProtein - 5}-${breakfastProtein + 5}g protein
- Morning Snack: ${snackCal - 30}-${snackCal + 30} cal, ${snackProtein - 3}-${snackProtein + 3}g protein
- Lunch: ${lunchCal - 75}-${lunchCal + 75} cal, ${lunchProtein - 8}-${lunchProtein + 8}g protein
- Afternoon Snack: ${snackCal - 30}-${snackCal + 30} cal, ${snackProtein - 3}-${snackProtein + 3}g protein
- Dinner: ${dinnerCal - 75}-${dinnerCal + 75} cal, ${dinnerProtein - 8}-${dinnerProtein + 8}g protein

${personalizationSection}
═══ RESTRICTIONS ═══
- Allergies (NEVER include): ${allergies}
- Dietary: ${restrictions}
- Food Dislikes: ${foodDislikes}
- Preferred Cuisines: ${cuisines}
- AVOID Cuisines: ${dislikedCuisines}
- Max cooking time: ${profile.maxCookingTimeMinutes} min
- Skill: ${profile.cookingSkill}
${pantryNote}

${weeklyPreferences ? `═══ THIS WEEK ═══\n${weeklyPreferences}` : ''}
${excludeList ? `═══ AVOID THESE RECIPES ═══\n${excludeList}` : ''}

Each day: ${mealTypes}

═══ INGREDIENT RULES ═══
- MAX 4-5 ingredients per recipe
- Use ONLY: ${allIngredients}
- Pantry staples (don't list): salt, pepper, garlic powder, spices, honey

═══ MANDATORY PROTEIN SCHEDULE (MUST FOLLOW!) ═══
${varietySchedule}

═══ VARIETY RULES ═══
- USE THE PROTEIN SCHEDULE ABOVE - this is mandatory!
- Each breakfast should be different (rotate eggs, oatmeal+yogurt, etc.)
- Snacks: target ~${snackProtein}g protein each (Greek yogurt or cottage cheese work well)

Respond with JSON:
{
  "days": [
    {
      "dayOfWeek": ${startDay},
      "meals": [
        {
          "mealType": "breakfast",
          "recipe": {
            "name": "Recipe Name",
            "description": "Brief description",
            "instructions": ["Step 1", "Step 2"],
            "prepTimeMinutes": 10,
            "cookTimeMinutes": 5,
            "servings": 1,
            "complexity": "easy",
            "cuisineType": "american",
            "calories": ${breakfastCal},
            "proteinGrams": ${breakfastProtein},
            "carbsGrams": ${breakfastCarbs},
            "fatGrams": ${breakfastFat},
            "fiberGrams": 5,
            "ingredients": [
              {"name": "eggs", "quantity": 3, "unit": "piece", "category": "dairy"}
            ]
          }
        }
      ]
    }
  ]
}

Valid mealTypes: breakfast, snack, lunch, dinner
Valid units: gram, cup, tablespoon, teaspoon, piece, slice
Valid categories: produce, meat, dairy, pantry

dayOfWeek: ${startDay}-${endDay}

NOTE: Vary the macros naturally each day - some days can be ${profile.proteinGrams - 15}g protein, others ${profile.proteinGrams + 10}g. Don't make every day identical!`;
}

/**
 * Parse and clean Claude's JSON response
 */
function parseClaudeResponse(content: string, batchLabel: string = 'unknown'): MealPlanResponse {
  console.log(`[DEBUG] Parsing response for ${batchLabel}, length: ${content.length} chars`);

  // Clean up potential markdown code blocks
  let cleanJSON = content
    .replace(/```json/gi, '')
    .replace(/```/g, '')
    .trim();

  // Find JSON object boundaries
  const startIndex = cleanJSON.indexOf('{');
  const endIndex = cleanJSON.lastIndexOf('}');

  if (startIndex === -1 || endIndex === -1) {
    console.error(`[DEBUG] ${batchLabel} - No JSON boundaries found in response`);
    console.error(`[DEBUG] ${batchLabel} - Raw response (first 500 chars):`, content.substring(0, 500));
    throw new Error(`No valid JSON object found in response for ${batchLabel}`);
  }

  cleanJSON = cleanJSON.substring(startIndex, endIndex + 1);
  console.log(`[DEBUG] ${batchLabel} - Extracted JSON length: ${cleanJSON.length} chars`);

  try {
    const parsed = JSON.parse(cleanJSON) as MealPlanResponse;
    console.log(`[DEBUG] ${batchLabel} - Parse successful, ${parsed.days?.length || 0} days`);
    return parsed;
  } catch (parseError) {
    console.error(`[DEBUG] ${batchLabel} - JSON parse failed:`, parseError instanceof Error ? parseError.message : parseError);
    console.error(`[DEBUG] ${batchLabel} - Clean JSON (first 1000 chars):`, cleanJSON.substring(0, 1000));
    console.error(`[DEBUG] ${batchLabel} - Clean JSON (last 500 chars):`, cleanJSON.substring(Math.max(0, cleanJSON.length - 500)));
    throw new Error(`Failed to parse JSON response from Claude for ${batchLabel}`);
  }
}

/**
 * Main handler for generate-plan endpoint
 */
export async function handleGeneratePlan(
  req: GeneratePlanRequest
): Promise<GeneratePlanResponse> {
  const { userProfile, weeklyPreferences, excludeRecipeNames, deviceId, weeklyFocus, temporaryExclusions, weeklyBusyness } = req;
  const duration = Math.min(14, Math.max(1, req.duration ?? 7));

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
    // Log personalization data being used
    console.log('[DEBUG] ========== PERSONALIZATION ==========');
    console.log('[DEBUG] Primary Goals:', userProfile.primaryGoals?.join(', ') || 'None');
    console.log('[DEBUG] Goal Pace:', userProfile.goalPace || 'Not set');
    console.log('[DEBUG] Barriers:', userProfile.barriers?.join(', ') || 'None');
    console.log('[DEBUG] Preferred Cuisines:', userProfile.preferredCuisines?.join(', ') || 'None');
    console.log('[DEBUG] Disliked Cuisines:', userProfile.dislikedCuisines?.join(', ') || 'None');
    console.log('[DEBUG] Food Dislikes:', userProfile.foodDislikes?.join(', ') || 'None');

    // Get Claude client
    console.log('[DEBUG] Initializing Claude client...');
    const client = getAnthropicClient();
    console.log('[DEBUG] Claude client initialized successfully');

    // Log the dynamic ingredient list being used
    const ingredientList = buildIngredientList(userProfile);
    console.log('[DEBUG] Dynamic ingredient list based on preferences:');
    console.log('[DEBUG]   Proteins:', ingredientList.proteins.join(', '));
    console.log('[DEBUG]   Carbs:', ingredientList.carbs.join(', '));
    console.log('[DEBUG]   Vegetables:', ingredientList.vegetables.join(', '));
    console.log('[DEBUG]   Fruits:', ingredientList.fruits.join(', '));
    console.log('[DEBUG]   Dairy/Fats:', ingredientList.dairy.join(', '));
    console.log('[DEBUG]   Rotation:', ingredientList.proteinRotation);

    const systemPrompt = buildSystemPrompt();
    const allDays: DayDTO[] = [];

    // Using Claude Haiku for cost efficiency (~12x cheaper than Sonnet)
    // Split into batches of 2 days each to fit within Haiku's 4096 token output limit
    const MODEL = 'claude-3-5-haiku-latest';
    const MAX_TOKENS = 4000;

    // Dynamic batching: pairs of 2 days each, remainder in last batch
    const batches: [number, number][] = [];
    for (let i = 0; i < duration; i += 2) {
      const endDay = Math.min(i + 1, duration - 1);
      batches.push([i, endDay]);
    }

    // Run all batches IN PARALLEL for speed
    console.log(`[DEBUG] Starting ${batches.length} batches in PARALLEL for ${duration}-day plan...`);
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

      const batchResult = parseClaudeResponse(textContent.text, `Batch ${batchNum} (days ${startDay}-${endDay})`);
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

    // AI-generated recipes don't get images — iOS shows gradient placeholders
    const allRecipes: GeneratedRecipeDTO[] = [];

    for (const day of mealPlan.days) {
      for (const meal of day.meals) {
        const recipe = meal.recipe;

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
          matchedImageUrl: null,
        });
      }
    }

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
