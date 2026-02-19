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
  measurementSystem: string; // "Metric" or "Imperial"
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
    anthropic = new Anthropic({ apiKey, timeout: 60000 });
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
- Daily protein: within 5g of target (do NOT exceed target + 5g — if individual meals run high, reduce protein in snacks to compensate)
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

LIMIT: 5-8 ingredients per recipe (excluding pantry staples)

═══════════════════════════════════════════════════════════════
VARIETY REQUIREMENTS (CRITICAL)
═══════════════════════════════════════════════════════════════
- NEVER repeat same protein 2 days in a row for lunch/dinner
- Follow the rotation pattern provided in the user's prompt
- Each breakfast should be DIFFERENT - rotate daily!
- Snacks can repeat but vary the accompaniments
- NEVER generate two recipes with the same primary protein AND cooking method in the same plan
- Each recipe name must be distinct — no duplicates across the entire plan

═══════════════════════════════════════════════════════════════
MEAL GUIDELINES
═══════════════════════════════════════════════════════════════

CRITICAL: Follow the PER-MEAL TARGETS in the user prompt exactly!
The targets are calculated based on the user's specific protein goal.

BREAKFAST (MAX 15 minutes total prep+cook — this is non-negotiable):
- prepTimeMinutes + cookTimeMinutes MUST be ≤ 15
- Quick recipes ONLY: scrambles, oatmeal, yogurt bowls, toast, smoothies, overnight oats
- Use available proteins: eggs, yogurt, or protein from user's list
- Add carbs (oats, toast) for energy
- Hit the protein target from user prompt (varies per user)

LUNCH (respect user's max cooking time):
- Use the ASSIGNED PROTEIN from the schedule + carb + vegetable
- This is the biggest protein meal of the day

DINNER (respect user's max cooking time):
- Use the ASSIGNED PROTEIN from the schedule + vegetables + small carb

SNACKS (no-cook, 5 min):
- VARY snacks across the week — do NOT repeat the same snack concept more than twice
- Good options: nut butter + fruit, trail mix, hummus + veggies, hard boiled eggs, protein smoothie, cottage cheese + fruit, yogurt parfait, rice cakes + toppings, edamame, dark chocolate + almonds
- Hit the snack protein target from user prompt (varies per user!)
- If user is dairy-free/vegan, use available protein sources

═══════════════════════════════════════════════════════════════
CARB & FAT ENFORCEMENT (CRITICAL)
═══════════════════════════════════════════════════════════════

Carbs are often too low and fat too high. To fix:
- LUNCH: Include a proper carb source (rice, potato, quinoa, pasta, bread) — at least 40-50g carbs
- DINNER: Include a carb side — at least 30-40g carbs
- FAT: Don't over-oil. Use 1 tbsp oil max per recipe. Avoid adding cheese/butter unless needed.

═══════════════════════════════════════════════════════════════
SKELETON PLAN
═══════════════════════════════════════════════════════════════

If a skeleton plan is provided in the user prompt, follow it exactly:
- Use the assigned protein, cuisine, and cooking style for each meal
- Use ingredients from the weekly grocery list
- The skeleton ensures variety across the week — trust it

═══════════════════════════════════════════════════════════════
INSTRUCTION RULES (CRITICAL)
═══════════════════════════════════════════════════════════════

- Each recipe should have 5-8 clear instruction steps
- Each step: ONE clear action, easy to understand
- Include quantities and times inline (e.g. "Cook 200g chicken breast 6 min per side")
- Start each step with a direct verb: "Add", "Cook", "Mix", "Heat", "Slice", "Combine"
- NO filler words like "Now", "Then", "Next", "After that"
- Include temperature and cook time where relevant
- Never say "season to taste" — specify amounts (e.g. "Add 1/2 tsp salt and 1/4 tsp pepper")
- Cover every action needed — don't skip steps or assume the user knows what to do
- Every ingredient mentioned MUST be in the ingredients list

═══════════════════════════════════════════════════════════════
MEASUREMENT CONSISTENCY (CRITICAL)
═══════════════════════════════════════════════════════════════

The user prompt specifies METRIC or IMPERIAL. You MUST use ONLY that system:
- METRIC: grams (g), ml, °C in ALL ingredients AND instructions. Never use oz, cups, °F.
- IMPERIAL: oz, lb, cups, tbsp, tsp, °F in ALL ingredients AND instructions. Never use g, ml, °C.
- This applies to EVERY ingredient quantity AND every instruction step.

═══════════════════════════════════════════════════════════════
WEEKLY EXCLUSIONS (CRITICAL)
═══════════════════════════════════════════════════════════════

The user prompt may contain temporary ingredient exclusions (e.g. "avoid seafood").
These are STRICT — treat them like allergies for this week. Do NOT use any excluded ingredients.

═══════════════════════════════════════════════════════════════
RESTRICTIONS
═══════════════════════════════════════════════════════════════

- NEVER include allergenic ingredients - life-threatening
- Respect dietary restrictions strictly
- Every ingredient in instructions MUST be in ingredients list`;
}

// Module-level constant: maps compound food categories to individual ingredients
const DISLIKE_EXPANSIONS: Record<string, string[]> = {
  'seafood': ['salmon', 'tuna', 'shrimp', 'cod', 'tilapia', 'crab', 'lobster', 'clam', 'mussel', 'scallop'],
  'fish': ['salmon', 'tuna', 'cod', 'tilapia', 'trout', 'bass', 'halibut', 'mackerel'],
  'beans': ['black beans', 'chickpeas', 'lentils', 'kidney beans'],
  'spicy food': ['chili', 'jalapeño', 'cayenne', 'hot sauce'],
};

/**
 * Expand a list of food terms using DISLIKE_EXPANSIONS
 */
function expandFoodTerms(terms: string[]): string[] {
  const expanded: string[] = [];
  for (const t of terms) {
    expanded.push(t);
    if (DISLIKE_EXPANSIONS[t]) {
      expanded.push(...DISLIKE_EXPANSIONS[t]);
    }
  }
  return expanded;
}

/**
 * Build dynamic ingredient list based on user preferences
 */
function buildIngredientList(profile: UserProfile, temporaryExclusions?: string[]): {
  proteins: string[];
  carbs: string[];
  vegetables: string[];
  fruits: string[];
  dairy: string[];
  snackIngredients: string[];
  proteinRotation: string;
} {
  const restrictions = profile.dietaryRestrictions.map(r => r.toLowerCase());
  const rawDislikes = (profile.foodDislikes || []).map(d => d.toLowerCase());
  const dislikes = expandFoodTerms(rawDislikes);
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
    proteins = filterItems(['tofu', 'tempeh', 'lentils', 'chickpeas', 'black beans', 'edamame', 'seitan']);
    proteinRotation = 'tofu → tempeh → lentils → chickpeas → black beans → edamame → tofu...';
  } else if (isVegetarian) {
    proteins = filterItems(['eggs', 'Greek yogurt', 'cottage cheese', 'tofu', 'lentils', 'chickpeas', 'black beans']);
    proteinRotation = 'eggs → tofu → lentils → chickpeas → black beans → eggs...';
  } else if (isPescatarian) {
    proteins = filterItems(['salmon', 'tuna', 'shrimp', 'cod', 'tilapia', 'eggs', 'Greek yogurt', 'cottage cheese', 'tofu']);
    proteinRotation = 'salmon → tuna → shrimp → cod → tilapia → tofu → salmon...';
  } else {
    // Standard (omnivore)
    proteins = filterItems(['chicken breast', 'ground beef', 'salmon', 'pork chop', 'turkey breast', 'ground turkey', 'shrimp', 'cod', 'tilapia', 'steak', 'eggs', 'Greek yogurt', 'cottage cheese']);
    proteinRotation = 'chicken → beef → salmon → turkey → shrimp → pork → cod → chicken...';
  }

  // Build carb list
  let carbs = isGlutenFree
    ? filterItems(['rice', 'oats', 'potato', 'quinoa', 'sweet potato', 'couscous'])
    : filterItems(['rice', 'oats', 'whole wheat bread', 'potato', 'pasta', 'sweet potato', 'quinoa', 'couscous', 'tortilla']);

  // Build vegetable list
  let vegetables = filterItems(['broccoli', 'spinach', 'bell pepper', 'onion', 'tomato', 'carrot', 'zucchini', 'mushrooms', 'asparagus', 'green beans', 'cauliflower', 'cucumber', 'corn', 'kale', 'cabbage']);

  // Build fruit list
  let fruits = filterItems(['banana', 'apple', 'mixed berries', 'mango', 'strawberries', 'blueberries', 'pear', 'orange']);

  // Build snack ingredients list
  let snackIngredients = filterItems(['peanut butter', 'almonds', 'walnuts', 'hummus', 'hard boiled eggs', 'rice cakes', 'dark chocolate', 'trail mix', 'edamame', 'protein smoothie']);

  // Build dairy list
  let dairy: string[] = [];
  if (!isDairyFree) {
    dairy = filterItems(['olive oil', 'butter', 'cheese', 'milk']);
  } else {
    dairy = filterItems(['olive oil', 'almond milk', 'coconut oil']);
  }

  // Apply temporary exclusions (treat like dislikes for this generation)
  if (temporaryExclusions && temporaryExclusions.length > 0) {
    const expandedExclusions = expandFoodTerms(temporaryExclusions.map(e => e.toLowerCase()));
    const filterExcluded = (items: string[]) =>
      items.filter(item => !expandedExclusions.includes(item.toLowerCase()));

    proteins = filterExcluded(proteins);
    carbs = filterExcluded(carbs);
    vegetables = filterExcluded(vegetables);
    fruits = filterExcluded(fruits);
    dairy = filterExcluded(dairy);
    snackIngredients = filterExcluded(snackIngredients);

    // Rebuild proteinRotation to exclude removed proteins
    proteinRotation = proteins.length > 0
      ? proteins.map(p => p.split(' ')[0]).join(' → ') + ' → ' + proteins[0].split(' ')[0] + '...'
      : '';
  }

  return { proteins, carbs, vegetables, fruits, dairy, snackIngredients, proteinRotation };
}

// Skeleton types for 2-step generation
interface SkeletonMealConcept {
  concept: string;
  protein?: string;
  cuisine?: string;
}

interface SkeletonDay {
  day: number;
  breakfast: SkeletonMealConcept;
  lunch: SkeletonMealConcept;
  dinner: SkeletonMealConcept;
  snack1?: SkeletonMealConcept;
  snack2?: SkeletonMealConcept;
}

interface WeekSkeleton {
  weeklyGroceryList: string[];
  days: SkeletonDay[];
}

/**
 * Build the skeleton prompt for the first-pass planning call
 */
function buildSkeletonPrompt(
  profile: UserProfile,
  duration: number,
  weeklyPreferences?: string,
  excludeRecipeNames?: string[],
  temporaryExclusions?: string[]
): string {
  const ingredients = buildIngredientList(profile, temporaryExclusions);
  const restrictions = profile.dietaryRestrictions.join(', ') || 'None';
  const allergies = profile.allergies.join(', ') || 'None';
  const foodDislikes = profile.foodDislikes?.join(', ') || 'None';
  const cuisines = profile.preferredCuisines.length > 0
    ? profile.preferredCuisines.join(', ')
    : 'Varied';
  const dislikedCuisines = profile.dislikedCuisines?.join(', ') || 'None';
  const excludeList = excludeRecipeNames?.length ? excludeRecipeNames.join(', ') : '';

  const allProteins = ingredients.proteins.join(', ');
  const allCarbs = ingredients.carbs.join(', ');
  const allVegetables = ingredients.vegetables.join(', ');
  const allFruits = ingredients.fruits.join(', ');
  const allDairy = ingredients.dairy.join(', ');
  const allSnackIngredients = ingredients.snackIngredients.join(', ');

  const simpleModeNote = profile.simpleModeEnabled
    ? 'SIMPLE MODE: Pick simpler meal concepts with fewer ingredients and basic cooking techniques.'
    : '';

  const skillNote = profile.cookingSkill === 'beginner'
    ? 'BEGINNER COOK: Only pick simple concepts (scrambles, sheet pan, stir-fry, bowls, wraps).'
    : profile.cookingSkill === 'advanced'
    ? 'ADVANCED COOK: Feel free to include more complex techniques and cuisines.'
    : '';

  return `You are a meal prep coach planning a ${duration}-day meal plan.

RESPOND ONLY WITH VALID JSON. No markdown, no explanation.

USER PROFILE:
- Calories: ${profile.dailyCalorieTarget} kcal/day
- Protein: ${profile.proteinGrams}g, Carbs: ${profile.carbsGrams}g, Fat: ${profile.fatGrams}g
- Restrictions: ${restrictions}
- Allergies (NEVER include): ${allergies}
- Food Dislikes: ${foodDislikes}
- Preferred Cuisines: ${cuisines}
- Avoid Cuisines: ${dislikedCuisines}
- Cooking Skill: ${profile.cookingSkill}
- Max Cooking Time: ${profile.maxCookingTimeMinutes} min
- Include Snacks: ${profile.includeSnacks ? 'Yes (2 per day)' : 'No'}
${simpleModeNote}
${skillNote}

AVAILABLE INGREDIENTS:
- Proteins: ${allProteins}
- Carbs: ${allCarbs}
- Vegetables: ${allVegetables}
- Fruits: ${allFruits}
- Dairy/Fats: ${allDairy}
- Snack ingredients: ${allSnackIngredients}

${weeklyPreferences ? `THIS WEEK'S PREFERENCES (STRICT — treat temporary exclusions like allergies):\n${weeklyPreferences}` : ''}
${excludeList ? `AVOID THESE RECIPES: ${excludeList}` : ''}

RULES:
1. From the available ingredients above, pick a shared grocery list of 20-25 items for the week
2. No repeated proteins on consecutive days for lunch/dinner
3. Each breakfast must be a different concept AND must be quick (≤15 min total)
4. At least 5 different snack concepts across the week (NOT just yogurt/berries every day)
5. Same protein can appear multiple times but cooked differently (grilled vs stir-fry vs baked)
6. Rotate through the user's preferred cuisines across the week — spread them evenly
7. Each meal concept must be UNIQUE — no repeated concepts across the plan
8. Include the SPECIFIC cooking method in each concept (e.g. "pan-seared", "baked", "grilled", not just "chicken with rice")
9. CRITICAL: If the user's weekly preferences say to AVOID certain ingredients (e.g. "avoid seafood"), do NOT include ANY of those ingredients in the grocery list or meal concepts

Return JSON:
{
  "weeklyGroceryList": ["item1", "item2", ...],
  "days": [
    {
      "day": 0,
      "breakfast": { "concept": "veggie egg scramble with toast", "cuisine": "american" },
      "lunch": { "concept": "grilled chicken quinoa bowl", "protein": "chicken breast", "cuisine": "mediterranean" },
      "dinner": { "concept": "teriyaki salmon stir-fry", "protein": "salmon", "cuisine": "japanese" }${profile.includeSnacks ? `,
      "snack1": { "concept": "apple slices with peanut butter" },
      "snack2": { "concept": "trail mix with dark chocolate" }` : ''}
    }
  ]
}

Generate exactly ${duration} days (day 0 to day ${duration - 1}).`;
}

/**
 * Generate a week skeleton using a fast Haiku call
 * Returns null on failure (triggers fallback to current approach)
 */
async function generateSkeleton(
  client: Anthropic,
  profile: UserProfile,
  duration: number,
  weeklyPreferences?: string,
  excludeRecipeNames?: string[],
  temporaryExclusions?: string[]
): Promise<WeekSkeleton | null> {
  try {
    const prompt = buildSkeletonPrompt(profile, duration, weeklyPreferences, excludeRecipeNames, temporaryExclusions);
    const maxTokens = duration <= 7 ? 1200 : 2000;

    console.log('[DEBUG] Generating skeleton with Haiku...');
    const startTime = Date.now();

    const response = await client.messages.create({
      model: 'claude-3-5-haiku-latest',
      max_tokens: maxTokens,
      system: 'You are a meal planning assistant. Respond ONLY with valid JSON. No markdown, no explanation, no code blocks.',
      messages: [{ role: 'user', content: prompt }],
    });

    const elapsed = Date.now() - startTime;
    console.log(`[DEBUG] Skeleton received in ${elapsed}ms, stop: ${response.stop_reason}`);

    const textContent = response.content.find((c: Anthropic.ContentBlock) => c.type === 'text');
    if (!textContent || textContent.type !== 'text') {
      console.warn('[DEBUG] Skeleton: No text content in response');
      return null;
    }

    // Parse JSON
    let cleanJSON = textContent.text.replace(/```json/gi, '').replace(/```/g, '').trim();
    const startIdx = cleanJSON.indexOf('{');
    const endIdx = cleanJSON.lastIndexOf('}');
    if (startIdx === -1 || endIdx === -1) {
      console.warn('[DEBUG] Skeleton: No JSON boundaries found');
      return null;
    }
    cleanJSON = cleanJSON.substring(startIdx, endIdx + 1);

    const skeleton = JSON.parse(cleanJSON) as WeekSkeleton;

    // Basic validation
    if (!skeleton.weeklyGroceryList || !skeleton.days || skeleton.days.length === 0) {
      console.warn('[DEBUG] Skeleton: Invalid structure (missing groceryList or days)');
      return null;
    }

    console.log(`[DEBUG] Skeleton: ${skeleton.weeklyGroceryList.length} grocery items, ${skeleton.days.length} days planned`);
    return skeleton;
  } catch (error) {
    console.warn('[DEBUG] Skeleton generation failed, falling back to parallel-only:', error instanceof Error ? error.message : error);
    return null;
  }
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
  excludeRecipeNames?: string[],
  skeleton?: WeekSkeleton | null,
  temporaryExclusions?: string[],
  allSkeletonConcepts?: string[]
): string {
  const restrictions = profile.dietaryRestrictions.join(', ') || 'None';
  const allergies = profile.allergies.join(', ') || 'None';
  const foodDislikes = profile.foodDislikes?.join(', ') || 'None';
  const cuisines = profile.preferredCuisines.join(', ') || 'Varied';
  const dislikedCuisines = profile.dislikedCuisines?.join(', ') || 'None';
  const excludeList = excludeRecipeNames?.join(', ') || '';

  const isMetric = (profile.measurementSystem || 'Metric') === 'Metric';

  const numDays = endDay - startDay + 1;

  // Build dynamic ingredient list based on user preferences (with temporary exclusions)
  const ingredients = buildIngredientList(profile, temporaryExclusions);
  const allIngredients = [
    ...ingredients.proteins,
    ...ingredients.carbs,
    ...ingredients.vegetables,
    ...ingredients.fruits,
    ...ingredients.dairy,
    ...ingredients.snackIngredients,
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

  const dinnerProtein = Math.round(profile.proteinGrams * 0.26);
  const snackCal = Math.round(profile.dailyCalorieTarget * 0.09);

  // Calculate carbs and fat per meal
  const breakfastCarbs = Math.round(profile.carbsGrams * 0.22);
  const breakfastFat = Math.round(profile.fatGrams * 0.22);
  const lunchCarbs = Math.round(profile.carbsGrams * 0.32);
  const lunchFat = Math.round(profile.fatGrams * 0.32);
  const dinnerCarbs = Math.round(profile.carbsGrams * 0.28);
  const dinnerFat = Math.round(profile.fatGrams * 0.28);
  const snackCarbs = Math.round(profile.carbsGrams * 0.09);
  const snackFat = Math.round(profile.fatGrams * 0.09);

  // Build skeleton section if available
  let skeletonSection = '';
  if (skeleton) {
    const relevantDays = skeleton.days.filter(d => d.day >= startDay && d.day <= endDay);
    if (relevantDays.length > 0) {
      const skeletonLines = relevantDays.map(d => {
        let line = `Day ${d.day}: Breakfast="${d.breakfast.concept}"`;
        line += `, Lunch="${d.lunch.concept}" (${d.lunch.protein || ''}, ${d.lunch.cuisine || ''})`;
        line += `, Dinner="${d.dinner.concept}" (${d.dinner.protein || ''}, ${d.dinner.cuisine || ''})`;
        if (d.snack1) line += `, Snack1="${d.snack1.concept}"`;
        if (d.snack2) line += `, Snack2="${d.snack2.concept}"`;
        return line;
      }).join('\n');

      skeletonSection = `═══ SKELETON PLAN (FOLLOW THIS EXACTLY!) ═══
Weekly grocery list: ${skeleton.weeklyGroceryList.join(', ')}

${skeletonLines}

Generate the EXACT recipe matching each concept above. Do NOT substitute different recipes.
Use the assigned proteins, cuisines, and cooking styles. Use ingredients from the weekly grocery list.
`;

      // Add cross-batch awareness if we have all concepts
      if (allSkeletonConcepts && allSkeletonConcepts.length > 0) {
        skeletonSection += `\nOther batches are generating these recipes — do NOT duplicate them:\n${allSkeletonConcepts.join(', ')}\n`;
      }
    }
  }

  return `Create a ${numDays}-day meal plan (days ${startDay}-${endDay}).

═══ DAILY TARGETS (vary naturally, don't force exact numbers) ═══
- Calories: ~${profile.dailyCalorieTarget} kcal (vary between ${profile.dailyCalorieTarget - 150}-${profile.dailyCalorieTarget + 150})
- Protein: ~${profile.proteinGrams}g (vary between ${profile.proteinGrams - 15}-${profile.proteinGrams + 15}g)
- Carbs: ~${profile.carbsGrams}g, Fat: ~${profile.fatGrams}g
- IMPORTANT: Create natural variation each day - don't hit exact same numbers daily!

═══ PER-MEAL GUIDELINES (approximate, vary naturally) ═══
- Breakfast: ${breakfastCal - 50}-${breakfastCal + 50} cal, ${breakfastProtein - 5}-${breakfastProtein + 5}g protein, ~${breakfastCarbs}g carbs, ~${breakfastFat}g fat
- Morning Snack: ${snackCal - 30}-${snackCal + 30} cal, ${snackProtein - 3}-${snackProtein + 3}g protein, ~${snackCarbs}g carbs, ~${snackFat}g fat
- Lunch: ${lunchCal - 75}-${lunchCal + 75} cal, ${lunchProtein - 8}-${lunchProtein + 8}g protein, ~${lunchCarbs}g carbs, ~${lunchFat}g fat
- Afternoon Snack: ${snackCal - 30}-${snackCal + 30} cal, ${snackProtein - 3}-${snackProtein + 3}g protein, ~${snackCarbs}g carbs, ~${snackFat}g fat
- Dinner: ${dinnerCal - 75}-${dinnerCal + 75} cal, ${dinnerProtein - 8}-${dinnerProtein + 8}g protein, ~${dinnerCarbs}g carbs, ~${dinnerFat}g fat

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

${weeklyPreferences ? `═══ THIS WEEK (STRICT — temporary exclusions are like allergies!) ═══\n${weeklyPreferences}` : ''}
${excludeList ? `═══ AVOID THESE RECIPES ═══\n${excludeList}` : ''}

CRITICAL MEAL ORDER: Each day MUST contain exactly these meals in this order:
1. breakfast (1 meal)
2. snack (morning snack)
3. lunch (1 meal)
4. snack (afternoon snack)
5. dinner (1 meal)
The "mealType" field MUST be exactly one of: "breakfast", "snack", "lunch", "dinner"
Never label a snack as "breakfast" or vice versa.

═══ MEASUREMENT SYSTEM (STRICT — use ONLY this system everywhere) ═══
${isMetric
  ? `- METRIC ONLY: grams (g), kilograms (kg), milliliters (ml), liters (L), Celsius (°C)
- Ingredient quantities: ALWAYS use grams (e.g. "200 g chicken breast", "50 g oats", "100 ml milk")
- Temperatures: ALWAYS °C (e.g. "Bake at 200°C", "Preheat to 180°C")
- NEVER use oz, cups, tablespoons, °F — the user uses metric`
  : `- IMPERIAL ONLY: ounces (oz), pounds (lb), cups, tablespoons (tbsp), teaspoons (tsp), Fahrenheit (°F)
- Ingredient quantities: ALWAYS use oz/lb/cups (e.g. "6 oz chicken breast", "1/2 cup oats", "1 cup milk")
- Temperatures: ALWAYS °F (e.g. "Bake at 400°F", "Preheat to 350°F")
- NEVER use grams, ml, °C — the user uses imperial`}

═══ TIME CONSTRAINTS ═══
- Breakfast: MAX 15 minutes total (prepTimeMinutes + cookTimeMinutes ≤ 15)
- Lunch: Up to ${profile.maxCookingTimeMinutes} minutes
- Dinner: Up to ${profile.maxCookingTimeMinutes} minutes
- Snacks: MAX 5 minutes (no-cook or minimal prep)

═══ INGREDIENT RULES ═══
- 5-8 ingredients per recipe (excluding pantry staples)
- Use ONLY: ${allIngredients}
- Pantry staples (don't list): salt, pepper, garlic powder, spices, honey

${skeletonSection}
═══ VARIETY RULES ═══
- Each breakfast should be different (rotate eggs, oatmeal+yogurt, smoothie, toast, etc.)
- Snacks: target ~${snackProtein}g protein each — VARY across days (not all yogurt+berries!)
- No repeated protein for lunch/dinner on consecutive days
- CARBS: Include a proper carb source in lunch and dinner (rice, potato, quinoa, pasta, bread)

Respond with JSON (each day MUST have exactly 5 meals in this order):
{
  "days": [
    {
      "dayOfWeek": ${startDay},
      "meals": [
        {
          "mealType": "breakfast",
          "recipe": {
            "name": "Veggie Egg Scramble",
            "description": "Quick scrambled eggs with vegetables",
            "instructions": ["Step 1", "Step 2"],
            "prepTimeMinutes": 5,
            "cookTimeMinutes": 8,
            "servings": 1,
            "complexity": "easy",
            "cuisineType": "american",
            "calories": ${breakfastCal},
            "proteinGrams": ${breakfastProtein},
            "carbsGrams": ${breakfastCarbs},
            "fatGrams": ${breakfastFat},
            "fiberGrams": 3,
            "ingredients": [
              {"name": "eggs", "quantity": 3, "unit": "piece", "category": "dairy"}
            ]
          }
        },
        {
          "mealType": "snack",
          "recipe": {
            "name": "Apple Peanut Butter Bites",
            "description": "Morning snack",
            "instructions": ["Step 1"],
            "prepTimeMinutes": 3,
            "cookTimeMinutes": 0,
            "servings": 1,
            "complexity": "easy",
            "cuisineType": "american",
            "calories": ${snackCal},
            "proteinGrams": ${snackProtein},
            "carbsGrams": ${snackCarbs},
            "fatGrams": ${snackFat},
            "fiberGrams": 2,
            "ingredients": [
              {"name": "apple", "quantity": 1, "unit": "piece", "category": "produce"}
            ]
          }
        },
        {
          "mealType": "lunch",
          "recipe": {
            "name": "Grilled Chicken Rice Bowl",
            "description": "Protein-packed lunch bowl",
            "instructions": ["Step 1", "Step 2"],
            "prepTimeMinutes": 10,
            "cookTimeMinutes": 20,
            "servings": 1,
            "complexity": "easy",
            "cuisineType": "asian",
            "calories": ${lunchCal},
            "proteinGrams": ${lunchProtein},
            "carbsGrams": ${lunchCarbs},
            "fatGrams": ${lunchFat},
            "fiberGrams": 4,
            "ingredients": [
              {"name": "chicken breast", "quantity": 200, "unit": "gram", "category": "meat"}
            ]
          }
        },
        {
          "mealType": "snack",
          "recipe": {
            "name": "Trail Mix Energy Bites",
            "description": "Afternoon snack",
            "instructions": ["Step 1"],
            "prepTimeMinutes": 2,
            "cookTimeMinutes": 0,
            "servings": 1,
            "complexity": "easy",
            "cuisineType": "american",
            "calories": ${snackCal},
            "proteinGrams": ${snackProtein},
            "carbsGrams": ${snackCarbs},
            "fatGrams": ${snackFat},
            "fiberGrams": 2,
            "ingredients": [
              {"name": "trail mix", "quantity": 40, "unit": "gram", "category": "pantry"}
            ]
          }
        },
        {
          "mealType": "dinner",
          "recipe": {
            "name": "Baked Salmon with Asparagus",
            "description": "Herb-seasoned salmon dinner",
            "instructions": ["Step 1", "Step 2"],
            "prepTimeMinutes": 10,
            "cookTimeMinutes": 20,
            "servings": 1,
            "complexity": "easy",
            "cuisineType": "mediterranean",
            "calories": ${dinnerCal},
            "proteinGrams": ${dinnerProtein},
            "carbsGrams": ${dinnerCarbs},
            "fatGrams": ${dinnerFat},
            "fiberGrams": 4,
            "ingredients": [
              {"name": "salmon", "quantity": 180, "unit": "gram", "category": "meat"}
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

FINAL CHECK: Each day's meals must sum to:
- Calories: ~${profile.dailyCalorieTarget} ± 100 kcal
- Protein: ~${profile.proteinGrams}g ± 5g (do NOT exceed ${profile.proteinGrams + 5}g)
- Carbs: ~${profile.carbsGrams}g ± 15g
- Fat: ~${profile.fatGrams}g ± 10g

NOTE: Vary the macros naturally each day - some days can be ${profile.proteinGrams - 5}g protein, others ${profile.proteinGrams + 3}g. Don't make every day identical!`;
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
  const { userProfile, weeklyPreferences, deviceId, weeklyFocus, temporaryExclusions, weeklyBusyness } = req;
  const excludeRecipeNames = (req.excludeRecipeNames || []).slice(0, 200);
  const duration = Math.min(14, Math.max(1, req.duration ?? 7));

  console.log('[DEBUG] ========== GENERATE PLAN START ==========');
  console.log('[DEBUG] Device ID:', deviceId);
  console.log('[DEBUG] Weekly Preferences:', weeklyPreferences || 'None');
  console.log('[DEBUG] Exclude Recipes:', excludeRecipeNames?.join(', ') || 'None');
  console.log('[DEBUG] Structured Prefs - Focus:', weeklyFocus?.join(', ') || 'None');
  console.log('[DEBUG] Structured Prefs - Exclusions:', temporaryExclusions?.join(', ') || 'None');
  console.log('[DEBUG] Structured Prefs - Busyness:', weeklyBusyness || 'None');

  // Validate required fields
  if (!deviceId || typeof deviceId !== 'string' || deviceId.length > 128 || !/^[\w-]+$/.test(deviceId)) {
    console.log('[DEBUG] ERROR: Invalid device ID');
    return { success: false, error: 'Invalid device ID' };
  }

  if (!userProfile) {
    console.log('[DEBUG] ERROR: User profile is required');
    return { success: false, error: 'User profile is required' };
  }

  // Validate numeric profile fields
  if (typeof userProfile.dailyCalorieTarget !== 'number' || userProfile.dailyCalorieTarget < 800 || userProfile.dailyCalorieTarget > 10000) {
    return { success: false, error: 'Invalid calorie target' };
  }
  if (typeof userProfile.age !== 'number' || userProfile.age < 13 || userProfile.age > 120) {
    return { success: false, error: 'Invalid age' };
  }
  if (typeof userProfile.weightKg !== 'number' || userProfile.weightKg < 20 || userProfile.weightKg > 500) {
    return { success: false, error: 'Invalid weight' };
  }
  if (typeof userProfile.heightCm !== 'number' || userProfile.heightCm < 50 || userProfile.heightCm > 300) {
    return { success: false, error: 'Invalid height' };
  }
  if (typeof userProfile.proteinGrams !== 'number' || userProfile.proteinGrams < 0 || userProfile.proteinGrams > 1000) {
    return { success: false, error: 'Invalid protein target' };
  }
  if (typeof userProfile.mealsPerDay !== 'number' || userProfile.mealsPerDay < 1 || userProfile.mealsPerDay > 10) {
    return { success: false, error: 'Invalid meals per day' };
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

    // Resolve temporary exclusions: prefer structured field, fallback to parsing weeklyPreferences string
    const resolvedExclusions: string[] = temporaryExclusions && temporaryExclusions.length > 0
      ? temporaryExclusions
      : (() => {
          if (!weeklyPreferences) return [];
          const match = weeklyPreferences.match(/AVOID THESE INGREDIENTS THIS WEEK[^:]*:\n([\s\S]*?)(?:\n\n|$)/);
          if (!match) return [];
          return match[1].split('\n').map(line => line.replace(/^-\s*/, '').trim()).filter(Boolean);
        })();
    if (resolvedExclusions.length > 0) {
      console.log('[DEBUG] Resolved temporary exclusions:', resolvedExclusions.join(', '));
    }

    // Log the dynamic ingredient list being used
    const ingredientList = buildIngredientList(userProfile, resolvedExclusions);
    console.log('[DEBUG] Dynamic ingredient list based on preferences:');
    console.log('[DEBUG]   Proteins:', ingredientList.proteins.join(', '));
    console.log('[DEBUG]   Carbs:', ingredientList.carbs.join(', '));
    console.log('[DEBUG]   Vegetables:', ingredientList.vegetables.join(', '));
    console.log('[DEBUG]   Fruits:', ingredientList.fruits.join(', '));
    console.log('[DEBUG]   Dairy/Fats:', ingredientList.dairy.join(', '));
    console.log('[DEBUG]   Rotation:', ingredientList.proteinRotation);

    // Step 1: Generate skeleton for the week
    const skeleton = await generateSkeleton(client, userProfile, duration, weeklyPreferences, excludeRecipeNames, resolvedExclusions);
    if (skeleton) {
      console.log(`[DEBUG] Skeleton: ${JSON.stringify(skeleton)}`);
    } else {
      console.log('[DEBUG] Skeleton generation failed or skipped, proceeding without skeleton');
    }

    const systemPrompt = buildSystemPrompt();
    const allDays: DayDTO[] = [];

    // Step 2: Using Claude Haiku for cost efficiency (~12x cheaper than Sonnet)
    // Split into batches of 2 days each to fit within Haiku's 4096 token output limit
    const MODEL = 'claude-3-5-haiku-latest';
    const MAX_TOKENS = 4000;

    // Dynamic batching: pairs of 2 days each, remainder in last batch
    const batches: [number, number][] = [];
    for (let i = 0; i < duration; i += 2) {
      const endDay = Math.min(i + 1, duration - 1);
      batches.push([i, endDay]);
    }

    // Build cross-batch awareness: collect ALL skeleton concepts for each batch to see
    let allSkeletonConcepts: string[] = [];
    if (skeleton) {
      for (const day of skeleton.days) {
        allSkeletonConcepts.push(day.breakfast.concept);
        allSkeletonConcepts.push(day.lunch.concept);
        allSkeletonConcepts.push(day.dinner.concept);
        if (day.snack1) allSkeletonConcepts.push(day.snack1.concept);
        if (day.snack2) allSkeletonConcepts.push(day.snack2.concept);
      }
    }

    // Run all batches IN PARALLEL for speed
    console.log(`[DEBUG] Starting ${batches.length} batches in PARALLEL for ${duration}-day plan...`);
    const parallelStartTime = Date.now();

    const batchPromises = batches.map(async ([startDay, endDay], i) => {
      const batchNum = i + 1;
      console.log(`[DEBUG] Batch ${batchNum}: Days ${startDay}-${endDay} - STARTING`);

      // For cross-batch awareness, exclude concepts from THIS batch so other batch concepts are listed
      const otherBatchConcepts = skeleton ? allSkeletonConcepts.filter((_, idx) => {
        const conceptsPerDay = skeleton.days[0]?.snack1 ? 5 : 3;
        const dayIdx = Math.floor(idx / conceptsPerDay);
        const day = skeleton.days[dayIdx];
        return day && (day.day < startDay || day.day > endDay);
      }) : [];

      const userPrompt = buildUserPrompt(userProfile, startDay, endDay, weeklyPreferences, excludeRecipeNames, skeleton, resolvedExclusions, otherBatchConcepts);
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

    // Post-generation validation: check meal type distribution per day
    for (const day of mealPlan.days) {
      const mealTypeCounts: Record<string, number> = {};
      for (const meal of day.meals) {
        mealTypeCounts[meal.mealType] = (mealTypeCounts[meal.mealType] || 0) + 1;
      }
      const expectedBreakfast = 1;
      const expectedSnack = userProfile.includeSnacks ? 2 : 0;
      const expectedLunch = 1;
      const expectedDinner = 1;

      if ((mealTypeCounts['breakfast'] || 0) !== expectedBreakfast) {
        console.warn(`[VALIDATION] Day ${day.dayOfWeek}: Expected ${expectedBreakfast} breakfast, got ${mealTypeCounts['breakfast'] || 0}`);
      }
      if ((mealTypeCounts['snack'] || 0) !== expectedSnack) {
        console.warn(`[VALIDATION] Day ${day.dayOfWeek}: Expected ${expectedSnack} snacks, got ${mealTypeCounts['snack'] || 0}`);
      }
      if ((mealTypeCounts['lunch'] || 0) !== expectedLunch) {
        console.warn(`[VALIDATION] Day ${day.dayOfWeek}: Expected ${expectedLunch} lunch, got ${mealTypeCounts['lunch'] || 0}`);
      }
      if ((mealTypeCounts['dinner'] || 0) !== expectedDinner) {
        console.warn(`[VALIDATION] Day ${day.dayOfWeek}: Expected ${expectedDinner} dinner, got ${mealTypeCounts['dinner'] || 0}`);
      }
    }

    // Validation: check for recipe name uniqueness
    const recipeNames = new Set<string>();
    for (const day of mealPlan.days) {
      for (const meal of day.meals) {
        if (recipeNames.has(meal.recipe.name)) {
          console.warn(`[VALIDATION] Duplicate recipe name: "${meal.recipe.name}"`);
        }
        recipeNames.add(meal.recipe.name);
      }
    }

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

    return {
      success: false,
      error: 'Failed to generate meal plan. Please try again.',
    };
  }
}
