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
import { checkRateLimit, incrementRateLimit } from '../utils/rateLimiter';
// Image matching disabled — AI-generated recipes use gradient placeholders on iOS
// import { matchRecipeImage } from '../utils/imageMatch';
import { saveRecipesIfUnique, GeneratedRecipeDTO } from '../utils/recipeStorage';

const DEBUG = process.env.FUNCTIONS_EMULATOR === 'true' ||
  process.env.DEBUG_GENERATE === 'true';

/**
 * Retry a Claude API call with exponential backoff on rate limit (429) errors.
 */
async function callClaudeWithRetry<T>(
  fn: () => Promise<T>,
  label: string,
  maxRetries = 3,
  baseDelayMs = 15000
): Promise<T> {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (err: unknown) {
      const isRateLimit =
        (err instanceof Error && err.message.includes('429')) ||
        (err instanceof Error && err.constructor.name === 'RateLimitError');
      if (isRateLimit && attempt < maxRetries) {
        const delay = baseDelayMs * attempt;
        if (DEBUG) console.warn(`[RETRY] ${label} hit rate limit (attempt ${attempt}/${maxRetries}), waiting ${delay / 1000}s...`);
        await new Promise(resolve => setTimeout(resolve, delay));
        continue;
      }
      throw err;
    }
  }
  throw new Error(`${label} failed after ${maxRetries} retries`);
}

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
  breakfastCount: number;  // 0-2
  lunchCount: number;      // 0-2
  dinnerCount: number;     // 0-2
  snackCount: number;      // 0-4
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
 * Build a dynamic pantry staples list based on user's restrictions and allergies.
 * Removes soy sauce for GF/soy-allergy, adds tamari for GF without soy allergy.
 */
function buildPantryStaples(profile: UserProfile): string {
  const restrictions = profile.dietaryRestrictions.map(r => r.toLowerCase());
  const allergyTerms = expandAllergyTerms(profile.allergies);
  const isGlutenFree = restrictions.includes('gluten-free') || allergyTerms.includes('gluten');
  const hasSoyAllergy = allergyTerms.includes('soy') || allergyTerms.includes('soy sauce');

  const staples = ['salt', 'pepper', 'garlic powder', 'Italian seasoning'];

  if (!isGlutenFree && !hasSoyAllergy) {
    staples.push('soy sauce');
  } else if (isGlutenFree && !hasSoyAllergy) {
    staples.push('tamari (gluten-free soy sauce)');
  }
  // If soy allergy: no soy sauce or tamari at all

  if (!allergyTerms.includes('sesame')) {
    // sesame oil is a common pantry staple but skip if allergic
  }

  staples.push('honey');

  return staples.join(', ');
}

/**
 * Build the system prompt for Claude
 */
function buildSystemPrompt(profile: UserProfile): string {
  const pantryLine = buildPantryStaples(profile);
  const expandedAllergies = expandAllergyTerms(profile.allergies);
  const restrictions = profile.dietaryRestrictions.map(r => r.toLowerCase());
  const isGlutenFree = restrictions.includes('gluten-free') || expandedAllergies.includes('gluten');

  // Build explicit allergen ban lines for the RESTRICTIONS section
  const allergenBanLines: string[] = [];
  for (const allergy of profile.allergies) {
    const key = allergy.toLowerCase();
    const terms = ALLERGY_EXPANSIONS[key];
    if (terms) {
      allergenBanLines.push(`- ${allergy}: NEVER use ${terms.slice(0, 10).join(', ')}${terms.length > 10 ? ', ...' : ''}`);
    }
  }
  // Also add explicit bans for dairy-free restriction (not just allergy)
  const isDairyFree = restrictions.includes('dairy-free');
  if (isDairyFree && !expandedAllergies.includes('dairy')) {
    const dairyTerms = ALLERGY_EXPANSIONS['dairy'];
    if (dairyTerms) {
      allergenBanLines.push(`- Dairy-Free: NEVER use ${dairyTerms.slice(0, 10).join(', ')}${dairyTerms.length > 10 ? ', ...' : ''}`);
    }
  }
  const allergenBanSection = allergenBanLines.length > 0
    ? `\nEXPLICIT ALLERGEN BANS (life-threatening — zero tolerance):\n${allergenBanLines.join('\n')}\n`
    : '';

  // Conditional GF oat note
  const gfOatNote = isGlutenFree
    ? '\n- When using oats for gluten-free users, always specify "certified gluten-free oats"\n'
    : '';

  // Dairy-free does NOT mean egg-free clarification
  const dairyFreeEggNote = isDairyFree && !profile.allergies.some(a => a.toLowerCase().includes('egg'))
    ? '\nIMPORTANT: Dairy-free does NOT mean egg-free. Eggs are NOT dairy. Use eggs freely for protein and variety.\n'
    : '';

  return `You are a professional nutritionist creating personalized meal plans.

IMPORTANT: Respond ONLY with valid JSON. No markdown, no explanation, no code blocks.

═══════════════════════════════════════════════════════════════
CALORIE & MACRO REQUIREMENTS
═══════════════════════════════════════════════════════════════

The user prompt contains SPECIFIC per-day calorie targets that already vary.
Follow each day's specific targets — they are intentionally different.
Do NOT adjust portions to force identical daily totals.
Each day's totals should be CLOSE to that day's specific target (within ~150 cal).

═══════════════════════════════════════════════════════════════
INGREDIENT GUIDELINES
═══════════════════════════════════════════════════════════════

IMPORTANT: Use ONLY the ingredients listed in the user's specific prompt.
The ingredient list is customized based on their dietary restrictions.

PANTRY (always available, don't list in ingredients):
- ${pantryLine}

LIMIT: 5-8 ingredients per recipe (excluding pantry staples)

═══════════════════════════════════════════════════════════════
VARIETY REQUIREMENTS (CRITICAL)
═══════════════════════════════════════════════════════════════
- NEVER repeat same protein 2 days in a row for lunch/dinner
- Follow the rotation pattern provided in the user's prompt
- Breakfast categories and snack types are pre-assigned in the user prompt — follow them exactly
- NEVER generate two recipes with the same primary protein AND cooking method in the same plan
- Each recipe name must be distinct — no duplicates across the entire plan
- Each day's meals should feel distinct from adjacent days — different cuisine feel, different cooking methods
- Use at least 4 different cooking methods across lunch/dinner (grill, bake, pan-sear, stir-fry, slow-cook, etc.)
- No single ingredient (excluding pantry staples) should appear in more than 4 out of 7 days
- Rotate fruits across breakfasts — never use the same fruit more than 3 times per week
- No single protein source should appear in more than 3 lunch/dinner meals across a 7-day plan

═══════════════════════════════════════════════════════════════
MEAL GUIDELINES
═══════════════════════════════════════════════════════════════

CRITICAL: Follow the PER-MEAL TARGETS in the user prompt exactly!
The targets are calculated based on the user's specific protein goal.

BREAKFAST (MAX 15 minutes total prep+cook — this is non-negotiable):
- prepTimeMinutes + cookTimeMinutes MUST be ≤ 15
- Follow the assigned breakfast CATEGORY from the user prompt. Category examples:
  - "toast/bread": avocado toast, PB banana toast, smoked salmon toast — NOT eggs on toast
  - "pancake/waffle": protein pancakes, banana oat pancakes, sweet potato pancakes
  - "smoothie/shake": protein smoothie, green smoothie, berry shake, chocolate PB smoothie
  - "oats/porridge": overnight oats, protein oatmeal, baked oats, chia pudding
  - "yogurt bowl": yogurt parfait, cottage cheese bowl, acai bowl
  - "eggs": scrambled eggs, veggie egg scramble, egg muffins — eggs category ONLY
- IMPORTANT: Only use eggs as the main protein when the category is "eggs". Other categories should use their own protein sources.
- Hit the protein target from user prompt (varies per user)

LUNCH (respect user's max cooking time):
- Use the ASSIGNED PROTEIN from the schedule + carb + vegetable
- This is the biggest protein meal of the day

DINNER (respect user's max cooking time):
- Use the ASSIGNED PROTEIN from the schedule + vegetables + small carb

SNACKS (no-cook, 5 min):
- VARY snacks across the week — do NOT repeat the same snack concept more than twice
- Follow the pre-assigned snack types from the user prompt EXACTLY
- Hit the snack protein target from user prompt (varies per user!)
- If user is dairy-free/vegan, use available protein sources
- NEVER use an ingredient the user is allergic to in snacks — check the allergen list above

═══════════════════════════════════════════════════════════════
CARB & FAT ENFORCEMENT (CRITICAL)
═══════════════════════════════════════════════════════════════

Carbs are often too low. To fix:
- LUNCH: Include a proper carb source (rice, potato, quinoa, pasta, bread) — at least 40-50g carbs
- DINNER: Include a carb side — at least 30-40g carbs
${profile.fatGrams >= 80
    ? `- FAT: User needs ${profile.fatGrams}g fat/day. Use generous oil (2 tbsp per recipe), add avocado/nuts, don't skimp on fats.`
    : `- FAT: Don't over-oil. Use 1 tbsp oil max per recipe. Avoid adding cheese/butter unless needed.`}

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
- Every ingredient in instructions MUST be in ingredients list
${allergenBanSection}${gfOatNote}${dairyFreeEggNote}`;
}

// Module-level constant: maps compound food categories to individual ingredients
const DISLIKE_EXPANSIONS: Record<string, string[]> = {
  'seafood': ['salmon', 'tuna', 'shrimp', 'cod', 'tilapia', 'crab', 'lobster', 'clam', 'mussel', 'scallop'],
  'fish': ['salmon', 'tuna', 'cod', 'tilapia', 'trout', 'bass', 'halibut', 'mackerel'],
  'beans': ['black beans', 'chickpeas', 'lentils', 'kidney beans'],
  'spicy food': ['chili', 'jalapeño', 'cayenne', 'hot sauce'],
};

/**
 * Maps each allergy type to all ingredient terms that must be banned.
 * Used for both ingredient filtering AND post-generation scanning.
 */
const ALLERGY_EXPANSIONS: Record<string, string[]> = {
  'peanuts': ['peanut', 'peanut butter', 'peanut oil', 'peanut sauce', 'peanuts'],
  'peanut': ['peanut', 'peanut butter', 'peanut oil', 'peanut sauce', 'peanuts'],
  'tree nuts': ['almond', 'almonds', 'almond butter', 'almond flour', 'almond milk', 'walnut', 'walnuts', 'cashew', 'cashews', 'pecan', 'pecans', 'pistachio', 'pistachios', 'macadamia', 'hazelnut', 'hazelnuts', 'pine nut', 'pine nuts', 'mixed nuts', 'trail mix'],
  'tree nut': ['almond', 'almonds', 'almond butter', 'almond flour', 'almond milk', 'walnut', 'walnuts', 'cashew', 'cashews', 'pecan', 'pecans', 'pistachio', 'pistachios', 'macadamia', 'hazelnut', 'hazelnuts', 'pine nut', 'pine nuts', 'mixed nuts', 'trail mix'],
  'milk': ['cheese', 'butter', 'yogurt', 'greek yogurt', 'cream', 'cottage cheese', 'ricotta', 'mozzarella', 'parmesan', 'whey', 'casein', 'ghee', 'ice cream', 'milk', 'whole milk', 'skim milk'],
  'dairy': ['cheese', 'butter', 'yogurt', 'greek yogurt', 'cream', 'cottage cheese', 'ricotta', 'mozzarella', 'parmesan', 'whey', 'casein', 'ghee', 'ice cream', 'milk', 'whole milk', 'skim milk'],
  'lactose': ['cheese', 'butter', 'yogurt', 'greek yogurt', 'cream', 'cottage cheese', 'ricotta', 'mozzarella', 'parmesan', 'whey', 'casein', 'ghee', 'ice cream', 'milk', 'whole milk', 'skim milk'],
  'eggs': ['egg', 'eggs', 'egg white', 'egg whites', 'mayonnaise'],
  'egg': ['egg', 'eggs', 'egg white', 'egg whites', 'mayonnaise'],
  'wheat': ['bread', 'pasta', 'tortilla', 'flour', 'couscous', 'seitan', 'crackers', 'breadcrumbs', 'noodles', 'pita', 'naan', 'wrap', 'whole wheat bread'],
  'gluten': ['bread', 'pasta', 'tortilla', 'flour', 'couscous', 'seitan', 'crackers', 'breadcrumbs', 'noodles', 'pita', 'naan', 'wrap', 'whole wheat bread', 'soy sauce'],
  'soy': ['soy sauce', 'tofu', 'tempeh', 'edamame', 'soy milk', 'miso', 'tamari'],
  'fish': ['salmon', 'tuna', 'cod', 'tilapia', 'trout', 'bass', 'halibut', 'mackerel', 'sardine', 'anchovy', 'fish sauce'],
  'shellfish': ['shrimp', 'crab', 'lobster', 'clam', 'mussel', 'scallop', 'oyster', 'prawn'],
  'sesame': ['sesame oil', 'sesame seeds', 'tahini'],
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
 * Expand allergy names into all ingredient terms that must be banned.
 * Returns a deduplicated flat list of lowercase terms.
 */
function expandAllergyTerms(allergies: string[]): string[] {
  const expanded = new Set<string>();
  for (const allergy of allergies) {
    const key = allergy.toLowerCase();
    expanded.add(key);
    const terms = ALLERGY_EXPANSIONS[key];
    if (terms) {
      for (const term of terms) {
        expanded.add(term.toLowerCase());
      }
    }
  }
  return Array.from(expanded);
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
  const allergies = expandAllergyTerms(profile.allergies);

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
    ? filterItems(['rice', 'oats', 'potato', 'quinoa', 'sweet potato'])
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

/**
 * Resolve per-type meal counts from the profile.
 * Falls back to legacy mealsPerDay/includeSnacks when the new fields are absent.
 */
function resolveMealCounts(profile: UserProfile): {
  breakfastCount: number;
  lunchCount: number;
  dinnerCount: number;
  snackCount: number;
} {
  // New fields present
  if (typeof profile.breakfastCount === 'number' &&
      typeof profile.lunchCount === 'number' &&
      typeof profile.dinnerCount === 'number' &&
      typeof profile.snackCount === 'number') {
    return {
      breakfastCount: Math.max(0, Math.min(profile.breakfastCount, 2)),
      lunchCount: Math.max(0, Math.min(profile.lunchCount, 2)),
      dinnerCount: Math.max(0, Math.min(profile.dinnerCount, 2)),
      snackCount: Math.max(0, Math.min(profile.snackCount, 4)),
    };
  }
  // Legacy fallback
  return {
    breakfastCount: 1,
    lunchCount: 1,
    dinnerCount: 1,
    snackCount: profile.includeSnacks ? 2 : 0,
  };
}

/**
 * Build the ordered meal list for a single day based on counts.
 * Order: breakfast(s), snack, lunch(es), snack, dinner(s), remaining snacks
 */
function buildMealOrder(counts: ReturnType<typeof resolveMealCounts>): string[] {
  const order: string[] = [];
  for (let i = 0; i < counts.breakfastCount; i++) order.push('breakfast');
  if (counts.snackCount >= 1) order.push('snack'); // morning snack
  for (let i = 0; i < counts.lunchCount; i++) order.push('lunch');
  if (counts.snackCount >= 2) order.push('snack'); // afternoon snack
  for (let i = 0; i < counts.dinnerCount; i++) order.push('dinner');
  // Extra snacks beyond 2
  for (let i = 2; i < counts.snackCount; i++) order.push('snack');
  return order;
}

/**
 * Compute per-meal calorie/macro percentages dynamically.
 * Returns a map of mealType -> { calPct, protPct, carbPct, fatPct }
 */
function computeMealPercentages(counts: ReturnType<typeof resolveMealCounts>): Record<string, { calPct: number; protPct: number; carbPct: number; fatPct: number }> {
  const total = counts.breakfastCount + counts.lunchCount + counts.dinnerCount + counts.snackCount;
  if (total === 0) return {};

  // Base weights (relative importance)
  const bfWeight = 2.2;   // breakfast gets ~22% of a standard day
  const lnWeight = 3.2;   // lunch gets ~32%
  const dnWeight = 2.8;   // dinner gets ~28%
  const skWeight = 0.9;   // each snack gets ~9%

  const totalWeight =
    counts.breakfastCount * bfWeight +
    counts.lunchCount * lnWeight +
    counts.dinnerCount * dnWeight +
    counts.snackCount * skWeight;

  const pct = (w: number) => w / totalWeight;

  // Protein distribution differs slightly: snacks get proportionally less
  const bfProtWeight = 2.0;
  const lnProtWeight = 2.8;
  const dnProtWeight = 2.6;
  const skProtWeight = 1.3;
  const totalProtWeight =
    counts.breakfastCount * bfProtWeight +
    counts.lunchCount * lnProtWeight +
    counts.dinnerCount * dnProtWeight +
    counts.snackCount * skProtWeight;

  const protPct = (w: number) => w / totalProtWeight;

  return {
    breakfast: { calPct: pct(bfWeight), protPct: protPct(bfProtWeight), carbPct: pct(bfWeight), fatPct: pct(bfWeight) },
    lunch:     { calPct: pct(lnWeight), protPct: protPct(lnProtWeight), carbPct: pct(lnWeight), fatPct: pct(lnWeight) },
    dinner:    { calPct: pct(dnWeight), protPct: protPct(dnProtWeight), carbPct: pct(dnWeight), fatPct: pct(dnWeight) },
    snack:     { calPct: pct(skWeight), protPct: protPct(skProtWeight), carbPct: pct(skWeight), fatPct: pct(skWeight) },
  };
}

// ═══════════════════════════════════════════════════════════════
// Server-side pre-randomization utilities
// ═══════════════════════════════════════════════════════════════

/**
 * Fisher-Yates shuffle (returns a new array, does not mutate input)
 */
function shuffleArray<T>(arr: T[]): T[] {
  const copy = [...arr];
  for (let i = copy.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [copy[i], copy[j]] = [copy[j], copy[i]];
  }
  return copy;
}

interface DayTargets {
  day: number;
  cal: number;
  protein: number;
  carbs: number;
  fat: number;
}

/**
 * Pre-randomize per-day calorie/macro targets with ±8% jitter.
 * Each day gets a fresh random multiplier so daily totals are visibly different.
 */
function jitterDailyTargets(profile: UserProfile, duration: number): DayTargets[] {
  const targets: DayTargets[] = [];
  for (let d = 0; d < duration; d++) {
    // ±8% for calories
    const calMult = 1 + (Math.random() * 0.16 - 0.08);
    // ±7% for macros (slightly different per macro)
    const protMult = 1 + (Math.random() * 0.14 - 0.07);
    const carbMult = 1 + (Math.random() * 0.14 - 0.07);
    const fatMult = 1 + (Math.random() * 0.14 - 0.07);
    targets.push({
      day: d,
      cal: Math.round(profile.dailyCalorieTarget * calMult),
      protein: Math.round(profile.proteinGrams * protMult),
      carbs: Math.round(profile.carbsGrams * carbMult),
      fat: Math.round(profile.fatGrams * fatMult),
    });
  }
  return targets;
}

const BREAKFAST_CATEGORIES = [
  'eggs', 'oats/porridge', 'toast/bread', 'smoothie/shake', 'pancake/waffle', 'yogurt bowl',
];

/**
 * Pre-assign one breakfast category per day.
 * Shuffles randomly and cycles, ensuring no two consecutive days share the same category.
 * Guarantees 4+ distinct categories for 7-day plans.
 */
function assignBreakfastCategories(duration: number, breakfastCount: number): string[] {
  if (breakfastCount === 0) return [];

  // Shuffle categories freshly each call
  let pool = shuffleArray(BREAKFAST_CATEGORIES);

  // Cycle through shuffled pool for all days
  const assignments: string[] = [];
  for (let d = 0; d < duration; d++) {
    assignments.push(pool[d % pool.length]);
  }

  // Fix consecutive duplicates by swapping with next different category
  for (let d = 1; d < assignments.length; d++) {
    if (assignments[d] === assignments[d - 1]) {
      // Find next different category to swap with
      for (let j = d + 1; j < assignments.length; j++) {
        if (assignments[j] !== assignments[d - 1]) {
          [assignments[d], assignments[j]] = [assignments[j], assignments[d]];
          break;
        }
      }
      // If still duplicate (end of array), pick a random different one
      if (assignments[d] === assignments[d - 1]) {
        const others = BREAKFAST_CATEGORIES.filter(c => c !== assignments[d - 1]);
        assignments[d] = others[Math.floor(Math.random() * others.length)];
      }
    }
  }

  // Enforce max-per-category cap to prevent breakfast monotony
  const maxPerCategory = duration <= 7 ? 2 : Math.ceil(duration / BREAKFAST_CATEGORIES.length);
  const counts = new Map<string, number>();
  for (const cat of assignments) counts.set(cat, (counts.get(cat) || 0) + 1);

  for (let d = 0; d < assignments.length; d++) {
    const cat = assignments[d];
    if ((counts.get(cat) || 0) > maxPerCategory) {
      const underUsed = BREAKFAST_CATEGORIES.filter(c =>
        (counts.get(c) || 0) < maxPerCategory &&
        (d === 0 || c !== assignments[d - 1]) &&
        (d === assignments.length - 1 || c !== assignments[d + 1])
      );
      if (underUsed.length > 0) {
        const replacement = underUsed[Math.floor(Math.random() * underUsed.length)];
        counts.set(cat, (counts.get(cat) || 0) - 1);
        counts.set(replacement, (counts.get(replacement) || 0) + 1);
        assignments[d] = replacement;
      }
    }
  }

  return assignments;
}

const SNACK_POOL = [
  'nut butter + fruit', 'trail mix', 'hummus + veggies', 'hard boiled eggs',
  'protein smoothie', 'cottage cheese + fruit', 'yogurt parfait',
  'rice cakes + toppings', 'edamame', 'dark chocolate + almonds',
];

const DAIRY_SNACKS = new Set(['cottage cheese + fruit', 'yogurt parfait']);

/**
 * Pre-assign snack archetypes per day.
 * Filters dairy-based if needed, filters by expanded allergies, enforces max 2 yogurt-based and max 2 cottage-cheese-based.
 */
function assignSnackArchetypes(
  duration: number,
  snackCount: number,
  isDairyFree: boolean,
  expandedAllergies: string[] = []
): string[][] {
  if (snackCount === 0) return Array.from({ length: duration }, () => []);

  // Filter pool based on dietary restrictions
  let pool = isDairyFree
    ? SNACK_POOL.filter(s => !DAIRY_SNACKS.has(s))
    : [...SNACK_POOL];

  // Filter pool by expanded allergy terms
  if (expandedAllergies.length > 0) {
    pool = pool.filter(snack => {
      const snackLower = snack.toLowerCase();
      return !expandedAllergies.some(allergen => snackLower.includes(allergen));
    });
  }

  // Fallback pool if everything got filtered
  if (pool.length === 0) {
    pool = ['rice cakes + toppings', 'protein smoothie', 'fruit salad'];
  }

  const assignments: string[][] = [];
  let yogurtCount = 0;
  let cottageCount = 0;
  let hummusCount = 0;
  let eggsCount = 0;
  let trailMixCount = 0;

  const isAtCap = (snack: string): boolean => {
    if (snack === 'yogurt parfait' && yogurtCount >= 2) return true;
    if (snack === 'cottage cheese + fruit' && cottageCount >= 2) return true;
    if (snack === 'hummus + veggies' && hummusCount >= 2) return true;
    if (snack === 'hard boiled eggs' && eggsCount >= 2) return true;
    if (snack === 'trail mix' && trailMixCount >= 2) return true;
    return false;
  };

  const incrementCap = (snack: string): void => {
    if (snack === 'yogurt parfait') yogurtCount++;
    if (snack === 'cottage cheese + fruit') cottageCount++;
    if (snack === 'hummus + veggies') hummusCount++;
    if (snack === 'hard boiled eggs') eggsCount++;
    if (snack === 'trail mix') trailMixCount++;
  };

  for (let d = 0; d < duration; d++) {
    const daySnacks: string[] = [];
    const shuffled = shuffleArray(pool);

    for (const snack of shuffled) {
      if (daySnacks.length >= snackCount) break;

      // Enforce weekly caps
      if (isAtCap(snack)) continue;

      // Avoid same snack twice in one day
      if (daySnacks.includes(snack)) continue;

      daySnacks.push(snack);
      incrementCap(snack);
    }

    // Fill remaining slots if needed
    while (daySnacks.length < snackCount) {
      const fallback = shuffleArray(pool.filter(s =>
        !daySnacks.includes(s) && !isAtCap(s)
      ));
      if (fallback.length > 0) {
        const pick = fallback[0];
        daySnacks.push(pick);
        incrementCap(pick);
      } else {
        // Absolute fallback
        daySnacks.push('mixed nuts');
      }
    }

    assignments.push(daySnacks);
  }

  return assignments;
}

/**
 * Pre-assign 2-3 "featured vegetables" per day from the available pool.
 * Ensures no single vegetable dominates the week (max 4 days per veg).
 */
function assignDailyVegetables(
  duration: number,
  vegetables: string[]
): string[][] {
  if (vegetables.length === 0) return Array.from({ length: duration }, () => []);

  const vegsPerDay = Math.min(3, vegetables.length);
  const maxPerWeek = Math.min(4, Math.ceil(duration * vegsPerDay / vegetables.length));
  const counts = new Map<string, number>();
  const assignments: string[][] = [];

  for (let d = 0; d < duration; d++) {
    const dayVegs: string[] = [];
    const pool = shuffleArray(vegetables).filter(v =>
      (counts.get(v) || 0) < maxPerWeek && !dayVegs.includes(v)
    );

    for (const veg of pool) {
      if (dayVegs.length >= vegsPerDay) break;
      dayVegs.push(veg);
      counts.set(veg, (counts.get(veg) || 0) + 1);
    }

    // Fallback if pool was too small
    while (dayVegs.length < vegsPerDay && vegetables.length > 0) {
      const fallback = shuffleArray(vegetables).find(v => !dayVegs.includes(v));
      if (fallback) {
        dayVegs.push(fallback);
        counts.set(fallback, (counts.get(fallback) || 0) + 1);
      } else break;
    }

    assignments.push(dayVegs);
  }
  return assignments;
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
  breakfast2?: SkeletonMealConcept;
  lunch: SkeletonMealConcept;
  lunch2?: SkeletonMealConcept;
  dinner: SkeletonMealConcept;
  dinner2?: SkeletonMealConcept;
  snack1?: SkeletonMealConcept;
  snack2?: SkeletonMealConcept;
  snack3?: SkeletonMealConcept;
  snack4?: SkeletonMealConcept;
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
  temporaryExclusions?: string[],
  breakfastAssignments?: string[],
  snackAssignments?: string[][],
  vegetableAssignments?: string[][]
): string {
  const counts = resolveMealCounts(profile);
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
- Meal Structure: ${counts.breakfastCount} breakfast, ${counts.lunchCount} lunch, ${counts.dinnerCount} dinner, ${counts.snackCount} snack(s)
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
3. Same protein can appear multiple times but cooked differently (grilled vs stir-fry vs baked)
4. Rotate through the user's preferred cuisines across the week — spread them evenly
5. Each meal concept must be UNIQUE — no repeated concepts across the plan
6. Include the SPECIFIC cooking method in each concept (e.g. "pan-seared", "baked", "grilled", not just "chicken with rice")
7. CRITICAL: If the user's weekly preferences say to AVOID certain ingredients (e.g. "avoid seafood"), do NOT include ANY of those ingredients in the grocery list or meal concepts
8. Use at least 4 different cooking methods across lunch/dinner (grill, bake, pan-sear, stir-fry, slow-cook, roast, etc.)
9. No two consecutive days should share the same cuisine theme

${breakfastAssignments && breakfastAssignments.length > 0 ? `MANDATORY BREAKFAST CATEGORIES (pre-assigned, DO NOT CHANGE):
${breakfastAssignments.map((cat, i) => `Day ${i}: ${cat}`).join('\n')}
Each breakfast concept MUST match its assigned category above.` : ''}

${snackAssignments && snackAssignments.some(s => s.length > 0) ? `MANDATORY SNACK TYPES (pre-assigned, DO NOT CHANGE):
${snackAssignments.map((snacks, i) => `Day ${i}: ${snacks.map((s, j) => `Snack${j + 1}="${s}"`).join(', ')}`).join('\n')}
Each snack concept MUST match its assigned type above.` : ''}

${vegetableAssignments && vegetableAssignments.some(v => v.length > 0) ? `MANDATORY VEGETABLE ROTATION (pre-assigned, spread usage):
${vegetableAssignments.map((vegs, i) => `Day ${i}: ${vegs.join(', ')}`).join('\n')}
Use ONLY these vegetables as the primary vegetables for each day's lunch and dinner. Do NOT default to bell pepper every day.` : ''}

Return JSON:
{
  "weeklyGroceryList": ["item1", "item2", ...],
  "days": [
    {
      "day": 0${counts.breakfastCount >= 1 ? `,
      "breakfast": { "concept": "veggie egg scramble with toast", "cuisine": "american" }` : ''}${counts.breakfastCount >= 2 ? `,
      "breakfast2": { "concept": "overnight oats with berries", "cuisine": "american" }` : ''}${counts.lunchCount >= 1 ? `,
      "lunch": { "concept": "grilled chicken quinoa bowl", "protein": "chicken breast", "cuisine": "mediterranean" }` : ''}${counts.lunchCount >= 2 ? `,
      "lunch2": { "concept": "turkey wrap with avocado", "protein": "turkey breast", "cuisine": "american" }` : ''}${counts.dinnerCount >= 1 ? `,
      "dinner": { "concept": "teriyaki salmon stir-fry", "protein": "salmon", "cuisine": "japanese" }` : ''}${counts.dinnerCount >= 2 ? `,
      "dinner2": { "concept": "herb baked chicken thighs", "protein": "chicken thighs", "cuisine": "mediterranean" }` : ''}${counts.snackCount >= 1 ? `,
      "snack1": { "concept": "apple slices with peanut butter" }` : ''}${counts.snackCount >= 2 ? `,
      "snack2": { "concept": "trail mix with dark chocolate" }` : ''}${counts.snackCount >= 3 ? `,
      "snack3": { "concept": "hummus with veggies" }` : ''}${counts.snackCount >= 4 ? `,
      "snack4": { "concept": "protein smoothie" }` : ''}
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
  temporaryExclusions?: string[],
  breakfastAssignments?: string[],
  snackAssignments?: string[][],
  vegetableAssignments?: string[][]
): Promise<WeekSkeleton | null> {
  try {
    const prompt = buildSkeletonPrompt(profile, duration, weeklyPreferences, excludeRecipeNames, temporaryExclusions, breakfastAssignments, snackAssignments, vegetableAssignments);
    const maxTokens = duration <= 7 ? 1200 : 2000;

    if (DEBUG) console.log('[DEBUG] Generating skeleton with Haiku...');
    const startTime = Date.now();

    const response = await callClaudeWithRetry(
      () => client.messages.create({
        model: 'claude-haiku-4-5-20251001',
        max_tokens: maxTokens,
        system: 'You are a meal planning assistant. Respond ONLY with valid JSON. No markdown, no explanation, no code blocks.',
        messages: [{ role: 'user', content: prompt }],
      }),
      'Skeleton generation'
    );

    const elapsed = Date.now() - startTime;
    if (DEBUG) console.log(`[DEBUG] Skeleton received in ${elapsed}ms, stop: ${response.stop_reason}`);

    const textContent = response.content.find((c: Anthropic.ContentBlock) => c.type === 'text');
    if (!textContent || textContent.type !== 'text') {
      if (DEBUG) console.warn('[DEBUG] Skeleton: No text content in response');
      return null;
    }

    // Parse JSON
    let cleanJSON = textContent.text.replace(/```json/gi, '').replace(/```/g, '').trim();
    const startIdx = cleanJSON.indexOf('{');
    const endIdx = cleanJSON.lastIndexOf('}');
    if (startIdx === -1 || endIdx === -1) {
      if (DEBUG) console.warn('[DEBUG] Skeleton: No JSON boundaries found');
      return null;
    }
    cleanJSON = cleanJSON.substring(startIdx, endIdx + 1);

    const skeleton = JSON.parse(cleanJSON) as WeekSkeleton;

    // Basic validation
    if (!skeleton.weeklyGroceryList || !skeleton.days || skeleton.days.length === 0) {
      if (DEBUG) console.warn('[DEBUG] Skeleton: Invalid structure (missing groceryList or days)');
      return null;
    }

    if (DEBUG) console.log(`[DEBUG] Skeleton: ${skeleton.weeklyGroceryList.length} grocery items, ${skeleton.days.length} days planned`);
    return skeleton;
  } catch (error) {
    if (DEBUG) console.warn('[DEBUG] Skeleton generation failed, falling back to parallel-only:', error instanceof Error ? error.message : error);
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
  allSkeletonConcepts?: string[],
  perDayTargets?: DayTargets[],
  snackAssignments?: string[][],
  vegetableAssignments?: string[][]
): string {
  const counts = resolveMealCounts(profile);
  const mealPcts = computeMealPercentages(counts);
  const expectedMealOrder = buildMealOrder(counts);

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

  // Calculate per-meal targets dynamically based on meal counts
  const mealTargets: Record<string, { cal: number; protein: number; carbs: number; fat: number }> = {};
  for (const type of ['breakfast', 'lunch', 'dinner', 'snack'] as const) {
    const p = mealPcts[type];
    if (p) {
      mealTargets[type] = {
        cal: Math.round(profile.dailyCalorieTarget * p.calPct),
        protein: Math.round(profile.proteinGrams * p.protPct),
        carbs: Math.round(profile.carbsGrams * p.carbPct),
        fat: Math.round(profile.fatGrams * p.fatPct),
      };
    }
  }
  // Build skeleton section if available
  let skeletonSection = '';
  if (skeleton) {
    const relevantDays = skeleton.days.filter(d => d.day >= startDay && d.day <= endDay);
    if (relevantDays.length > 0) {
      const skeletonLines = relevantDays.map(d => {
        let line = `Day ${d.day}:`;
        if (d.breakfast) line += ` Breakfast="${d.breakfast.concept}"`;
        if (d.breakfast2) line += `, Breakfast2="${d.breakfast2.concept}"`;
        if (d.lunch) line += `, Lunch="${d.lunch.concept}" (${d.lunch.protein || ''}, ${d.lunch.cuisine || ''})`;
        if (d.lunch2) line += `, Lunch2="${d.lunch2.concept}" (${d.lunch2.protein || ''}, ${d.lunch2.cuisine || ''})`;
        if (d.dinner) line += `, Dinner="${d.dinner.concept}" (${d.dinner.protein || ''}, ${d.dinner.cuisine || ''})`;
        if (d.dinner2) line += `, Dinner2="${d.dinner2.concept}" (${d.dinner2.protein || ''}, ${d.dinner2.cuisine || ''})`;
        if (d.snack1) line += `, Snack1="${d.snack1.concept}"`;
        if (d.snack2) line += `, Snack2="${d.snack2.concept}"`;
        if (d.snack3) line += `, Snack3="${d.snack3.concept}"`;
        if (d.snack4) line += `, Snack4="${d.snack4.concept}"`;
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

  // Build per-day targets section
  const relevantDayTargets = perDayTargets
    ? perDayTargets.filter(dt => dt.day >= startDay && dt.day <= endDay)
    : null;

  const perDayTargetSection = relevantDayTargets && relevantDayTargets.length > 0
    ? `═══ PER-DAY TARGETS (follow each day's specific numbers) ═══
${relevantDayTargets.map(dt => {
  // Compute per-meal targets from this day's jittered totals
  const mealLines: string[] = [];
  for (const type of ['breakfast', 'lunch', 'dinner', 'snack'] as const) {
    const p = mealPcts[type];
    if (p) {
      const mCal = Math.round(dt.cal * p.calPct);
      const mProt = Math.round(dt.protein * p.protPct);
      mealLines.push(`${type}: ~${mCal} cal, ~${mProt}g protein`);
    }
  }
  return `Day ${dt.day}: ~${dt.cal} cal, ~${dt.protein}g protein, ~${dt.carbs}g carbs, ~${dt.fat}g fat
  ${mealLines.join(' | ')}`;
}).join('\n')}`
    : `═══ DAILY TARGETS ═══
- Calories: ~${profile.dailyCalorieTarget} kcal
- Protein: ~${profile.proteinGrams}g, Carbs: ~${profile.carbsGrams}g, Fat: ~${profile.fatGrams}g`;

  // Build JSON example with 2 visibly different example days if we have per-day targets
  const exampleDays: string[] = [];
  const exDayTargets = relevantDayTargets && relevantDayTargets.length >= 2
    ? [relevantDayTargets[0], relevantDayTargets[1]]
    : relevantDayTargets && relevantDayTargets.length === 1
    ? [relevantDayTargets[0]]
    : null;

  if (exDayTargets) {
    for (const exDt of exDayTargets) {
      const meals = expectedMealOrder.map(type => {
        const p = mealPcts[type];
        const exCal = p ? Math.round(exDt.cal * p.calPct) : 400;
        const exProt = p ? Math.round(exDt.protein * p.protPct) : 25;
        const exCarbs = p ? Math.round(exDt.carbs * p.carbPct) : 40;
        const exFat = p ? Math.round(exDt.fat * p.fatPct) : 15;
        return `        {
          "mealType": "${type}",
          "recipe": {
            "name": "Example ${type} recipe",
            "description": "A ${type} recipe",
            "instructions": ["Step 1", "Step 2"],
            "prepTimeMinutes": ${type === 'breakfast' ? 5 : type === 'snack' ? 3 : 10},
            "cookTimeMinutes": ${type === 'breakfast' ? 8 : type === 'snack' ? 0 : 20},
            "servings": 1,
            "complexity": "easy",
            "cuisineType": "american",
            "calories": ${exCal},
            "proteinGrams": ${exProt},
            "carbsGrams": ${exCarbs},
            "fatGrams": ${exFat},
            "fiberGrams": 3,
            "ingredients": [
              {"name": "ingredient", "quantity": 100, "unit": "gram", "category": "Produce"}
            ]
          }
        }`;
      }).join(',\n');

      exampleDays.push(`    {
      "dayOfWeek": ${exDt.day},
      "meals": [
${meals}
      ]
    }`);
    }
  } else {
    // Fallback: single example day with offset values
    const meals = expectedMealOrder.map(type => {
      const t = mealTargets[type];
      const exCal = (t?.cal ?? 0) - 25;
      const exProt = (t?.protein ?? 0) - 3;
      const exCarbs = (t?.carbs ?? 0) + 5;
      const exFat = (t?.fat ?? 0) - 2;
      return `        {
          "mealType": "${type}",
          "recipe": {
            "name": "Example ${type} recipe",
            "description": "A ${type} recipe",
            "instructions": ["Step 1", "Step 2"],
            "prepTimeMinutes": ${type === 'breakfast' ? 5 : type === 'snack' ? 3 : 10},
            "cookTimeMinutes": ${type === 'breakfast' ? 8 : type === 'snack' ? 0 : 20},
            "servings": 1,
            "complexity": "easy",
            "cuisineType": "american",
            "calories": ${exCal},
            "proteinGrams": ${exProt},
            "carbsGrams": ${exCarbs},
            "fatGrams": ${exFat},
            "fiberGrams": 3,
            "ingredients": [
              {"name": "ingredient", "quantity": 100, "unit": "gram", "category": "Produce"}
            ]
          }
        }`;
    }).join(',\n');

    exampleDays.push(`    {
      "dayOfWeek": ${startDay},
      "meals": [
${meals}
      ]
    }`);
  }

  return `Create a ${numDays}-day meal plan (days ${startDay}-${endDay}).

${perDayTargetSection}

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

CRITICAL MEAL ORDER: Each day MUST contain exactly ${expectedMealOrder.length} meals in this order:
${expectedMealOrder.map((type, i) => `${i + 1}. ${type}`).join('\n')}
The "mealType" field MUST be exactly one of: "breakfast", "snack", "lunch", "dinner"
Never label a snack as "breakfast" or vice versa.

═══ MEASUREMENT SYSTEM (STRICT — use ONLY this system everywhere) ═══
${isMetric
  ? `- METRIC ONLY: grams (g), kilograms (kg), milliliters (ml), liters (L), Celsius (°C)
- Ingredient quantities: ALWAYS use grams (e.g. "200 g chicken breast", "50 g oats", "100 ml milk")
- For whole countable items (banana, apple, egg, potato, onion, tomato, bell pepper), use "piece" (e.g. "2 piece banana", "1 piece onion")
- Temperatures: ALWAYS °C (e.g. "Bake at 200°C", "Preheat to 180°C")
- NEVER use oz, cups, tablespoons, °F — the user uses metric`
  : `- IMPERIAL ONLY: ounces (oz), pounds (lb), cups, tablespoons (tbsp), teaspoons (tsp), Fahrenheit (°F)
- Ingredient quantities: ALWAYS use oz/lb/cups (e.g. "6 oz chicken breast", "1/2 cup oats", "1 cup milk")
- For whole countable items (banana, apple, egg, potato, onion, tomato, bell pepper), use "piece" (e.g. "2 piece banana", "1 piece onion")
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
- No repeated protein for lunch/dinner on consecutive days
- Use at least 4 different cooking methods across lunch/dinner (grill, bake, pan-sear, stir-fry, slow-cook, roast)
- No two consecutive days should share the same cuisine theme
- Each day should have a different overall character — different flavors, textures, and feel
- CARBS: Include a proper carb source in lunch and dinner (rice, potato, quinoa, pasta, bread)

${snackAssignments && snackAssignments.some(s => s.length > 0) ? `═══ MANDATORY SNACK TYPES (pre-assigned, follow EXACTLY) ═══
${snackAssignments
  .map((snacks, i) => ({ snacks, i }))
  .filter(({ i }) => i >= startDay && i <= endDay)
  .map(({ snacks, i }) => `Day ${i}: ${snacks.map((s, j) => `Snack${j + 1}="${s}"`).join(', ')}`)
  .join('\n')}
Each snack MUST match its assigned type. Do NOT substitute yogurt or cottage cheese for other types.` : ''}

${vegetableAssignments && vegetableAssignments.some(v => v.length > 0) ? `═══ MANDATORY VEGETABLE ROTATION (pre-assigned, spread usage) ═══
${vegetableAssignments
  .map((vegs, i) => ({ vegs, i }))
  .filter(({ i }) => i >= startDay && i <= endDay)
  .map(({ vegs, i }) => `Day ${i}: ${vegs.join(', ')}`)
  .join('\n')}
Use ONLY these vegetables as the primary vegetables for each day's lunch and dinner. Do NOT default to bell pepper every day.` : ''}

Respond with JSON (each day MUST have exactly ${expectedMealOrder.length} meals in order: ${expectedMealOrder.join(', ')}):
{
  "days": [
${exampleDays.join(',\n')}
  ]
}

Valid mealTypes: breakfast, snack, lunch, dinner
${isMetric
  ? 'Valid units: gram, milliliter, piece, slice, tablespoon, teaspoon'
  : 'Valid units: ounce, pound, cup, tablespoon, teaspoon, piece, slice'}
Valid categories: Produce, Meat & Seafood, Dairy & Eggs, Grains & Bread, Condiments & Sauces, Nuts & Seeds, Canned & Jarred, Frozen, Spices & Seasonings, Beverages, Baking & Cooking, Snacks

dayOfWeek: ${startDay}-${endDay}

When done, sanity-check each day is in the right ballpark. Don't adjust portions to force exact matches.`;
}

/**
 * Parse and clean Claude's JSON response
 */
function parseClaudeResponse(content: string, batchLabel: string = 'unknown'): MealPlanResponse {
  if (DEBUG) console.log(`[DEBUG] Parsing response for ${batchLabel}, length: ${content.length} chars`);

  // Clean up potential markdown code blocks
  let cleanJSON = content
    .replace(/```json/gi, '')
    .replace(/```/g, '')
    .trim();

  // Find JSON object boundaries
  const startIndex = cleanJSON.indexOf('{');
  const endIndex = cleanJSON.lastIndexOf('}');

  if (startIndex === -1 || endIndex === -1) {
    if (DEBUG) console.error(`[DEBUG] ${batchLabel} - No JSON boundaries found in response`);
    if (DEBUG) console.error(`[DEBUG] ${batchLabel} - Raw response (first 500 chars):`, content.substring(0, 500));
    throw new Error(`No valid JSON object found in response for ${batchLabel}`);
  }

  cleanJSON = cleanJSON.substring(startIndex, endIndex + 1);
  if (DEBUG) console.log(`[DEBUG] ${batchLabel} - Extracted JSON length: ${cleanJSON.length} chars`);

  try {
    const parsed = JSON.parse(cleanJSON) as MealPlanResponse;
    if (DEBUG) console.log(`[DEBUG] ${batchLabel} - Parse successful, ${parsed.days?.length || 0} days`);
    return parsed;
  } catch (parseError) {
    if (DEBUG) console.error(`[DEBUG] ${batchLabel} - JSON parse failed:`, parseError instanceof Error ? parseError.message : parseError);
    if (DEBUG) console.error(`[DEBUG] ${batchLabel} - Clean JSON (first 1000 chars):`, cleanJSON.substring(0, 1000));
    if (DEBUG) console.error(`[DEBUG] ${batchLabel} - Clean JSON (last 500 chars):`, cleanJSON.substring(Math.max(0, cleanJSON.length - 500)));
    throw new Error(`Failed to parse JSON response from Claude for ${batchLabel}`);
  }
}

// Known dairy-free alternatives that contain "milk"/"butter"/"cream" but are NOT dairy
const DAIRY_FREE_COMPOUNDS = new Set([
  'almond milk', 'oat milk', 'soy milk', 'coconut milk', 'rice milk', 'cashew milk',
  'almond butter', 'peanut butter', 'cashew butter', 'sunflower seed butter', 'nut butter',
  'coconut cream', 'coconut oil',
]);

/**
 * Scan every ingredient and recipe name for allergy violations.
 * Log-only for now — gives visibility without breaking UX.
 * Skips known dairy-free alternatives (almond milk, coconut milk, etc.)
 */
function scanForAllergyViolations(mealPlan: MealPlanResponse, expandedAllergies: string[]): void {
  if (expandedAllergies.length === 0) return;

  const isDairyFreeAllergen = (allergen: string) =>
    ['milk', 'butter', 'cream', 'yogurt', 'cheese'].includes(allergen);

  for (const day of mealPlan.days) {
    for (const meal of day.meals) {
      const recipeName = meal.recipe.name.toLowerCase();
      for (const allergen of expandedAllergies) {
        if (recipeName.includes(allergen)) {
          // Skip false positives: dairy-free compounds containing "milk"/"butter"
          if (isDairyFreeAllergen(allergen) && Array.from(DAIRY_FREE_COMPOUNDS).some(c => recipeName.includes(c))) continue;
          console.warn(`[ALLERGY] Day ${day.dayOfWeek} ${meal.mealType}: Recipe name "${meal.recipe.name}" contains allergen "${allergen}"`);
        }
      }
      for (const ing of meal.recipe.ingredients) {
        const ingName = ing.name.toLowerCase();
        for (const allergen of expandedAllergies) {
          if (ingName.includes(allergen)) {
            // Skip false positives: dairy-free compounds containing "milk"/"butter"
            if (isDairyFreeAllergen(allergen) && Array.from(DAIRY_FREE_COMPOUNDS).some(c => ingName.includes(c))) continue;
            console.warn(`[ALLERGY] Day ${day.dayOfWeek} ${meal.mealType} "${meal.recipe.name}": Ingredient "${ing.name}" contains allergen "${allergen}"`);
          }
        }
      }
    }
  }
}

/**
 * Maps common ingredients to correct iOS GroceryCategory enum values.
 * Longer patterns checked first to avoid partial matches (e.g., "almond milk" before "milk").
 */
const INGREDIENT_CATEGORY_MAP: [string, string][] = [
  // Beverages (check before shorter terms)
  ['almond milk', 'Beverages'],
  ['oat milk', 'Beverages'],
  ['soy milk', 'Beverages'],
  ['coconut milk', 'Beverages'],
  ['orange juice', 'Beverages'],
  ['protein shake', 'Beverages'],
  // Proteins - Meat & Seafood
  ['chicken breast', 'Meat & Seafood'],
  ['chicken thigh', 'Meat & Seafood'],
  ['ground beef', 'Meat & Seafood'],
  ['ground turkey', 'Meat & Seafood'],
  ['turkey breast', 'Meat & Seafood'],
  ['pork chop', 'Meat & Seafood'],
  ['steak', 'Meat & Seafood'],
  ['salmon', 'Meat & Seafood'],
  ['tuna', 'Meat & Seafood'],
  ['shrimp', 'Meat & Seafood'],
  ['cod', 'Meat & Seafood'],
  ['tilapia', 'Meat & Seafood'],
  ['chicken', 'Meat & Seafood'],
  ['beef', 'Meat & Seafood'],
  ['pork', 'Meat & Seafood'],
  ['turkey', 'Meat & Seafood'],
  ['fish', 'Meat & Seafood'],
  // Nuts & Seeds (butter variants — MUST come before generic 'butter' to avoid false matches)
  ['peanut butter', 'Nuts & Seeds'],
  ['almond butter', 'Nuts & Seeds'],
  ['cashew butter', 'Nuts & Seeds'],
  ['nut butter', 'Nuts & Seeds'],
  ['sunflower seed butter', 'Nuts & Seeds'],
  // Dairy & Eggs
  ['greek yogurt', 'Dairy & Eggs'],
  ['cottage cheese', 'Dairy & Eggs'],
  ['cream cheese', 'Dairy & Eggs'],
  ['sour cream', 'Dairy & Eggs'],
  ['egg white', 'Dairy & Eggs'],
  ['eggs', 'Dairy & Eggs'],
  ['egg', 'Dairy & Eggs'],
  ['cheese', 'Dairy & Eggs'],
  ['yogurt', 'Dairy & Eggs'],
  ['butter', 'Dairy & Eggs'],
  ['milk', 'Dairy & Eggs'],
  ['cream', 'Dairy & Eggs'],
  // Produce
  ['sweet potato', 'Produce'],
  ['bell pepper', 'Produce'],
  ['green beans', 'Produce'],
  ['mixed berries', 'Produce'],
  ['banana', 'Produce'],
  ['apple', 'Produce'],
  ['avocado', 'Produce'],
  ['broccoli', 'Produce'],
  ['spinach', 'Produce'],
  ['onion', 'Produce'],
  ['tomato', 'Produce'],
  ['carrot', 'Produce'],
  ['zucchini', 'Produce'],
  ['mushroom', 'Produce'],
  ['asparagus', 'Produce'],
  ['cauliflower', 'Produce'],
  ['cucumber', 'Produce'],
  ['corn', 'Produce'],
  ['kale', 'Produce'],
  ['cabbage', 'Produce'],
  ['lettuce', 'Produce'],
  ['garlic', 'Produce'],
  ['ginger', 'Produce'],
  ['lemon', 'Produce'],
  ['lime', 'Produce'],
  ['mango', 'Produce'],
  ['strawberr', 'Produce'],
  ['blueberr', 'Produce'],
  ['orange', 'Produce'],
  ['pear', 'Produce'],
  ['potato', 'Produce'],
  ['celery', 'Produce'],
  // Grains & Bread
  ['whole wheat bread', 'Grains & Bread'],
  ['bread', 'Grains & Bread'],
  ['tortilla', 'Grains & Bread'],
  ['rice', 'Grains & Bread'],
  ['oats', 'Grains & Bread'],
  ['quinoa', 'Grains & Bread'],
  ['pasta', 'Grains & Bread'],
  ['couscous', 'Grains & Bread'],
  ['noodle', 'Grains & Bread'],
  ['wrap', 'Grains & Bread'],
  ['pita', 'Grains & Bread'],
  ['naan', 'Grains & Bread'],
  ['rice cake', 'Grains & Bread'],
  ['cereal', 'Grains & Bread'],
  ['granola', 'Grains & Bread'],
  // Condiments & Sauces
  ['olive oil', 'Condiments & Sauces'],
  ['coconut oil', 'Condiments & Sauces'],
  ['soy sauce', 'Condiments & Sauces'],
  ['tamari', 'Condiments & Sauces'],
  ['hot sauce', 'Condiments & Sauces'],
  ['honey', 'Condiments & Sauces'],
  ['maple syrup', 'Condiments & Sauces'],
  ['vinegar', 'Condiments & Sauces'],
  ['mustard', 'Condiments & Sauces'],
  ['mayonnaise', 'Condiments & Sauces'],
  ['salsa', 'Condiments & Sauces'],
  ['hummus', 'Condiments & Sauces'],
  ['pesto', 'Condiments & Sauces'],
  ['tahini', 'Condiments & Sauces'],
  // Nuts & Seeds
  ['almond', 'Nuts & Seeds'],
  ['walnut', 'Nuts & Seeds'],
  ['cashew', 'Nuts & Seeds'],
  ['pecan', 'Nuts & Seeds'],
  ['pistachio', 'Nuts & Seeds'],
  ['peanut', 'Nuts & Seeds'],
  ['chia seed', 'Nuts & Seeds'],
  ['flax seed', 'Nuts & Seeds'],
  ['sunflower seed', 'Nuts & Seeds'],
  ['pumpkin seed', 'Nuts & Seeds'],
  ['sesame seed', 'Nuts & Seeds'],
  ['trail mix', 'Nuts & Seeds'],
  ['mixed nuts', 'Nuts & Seeds'],
  // Canned & Jarred
  ['black beans', 'Canned & Jarred'],
  ['chickpeas', 'Canned & Jarred'],
  ['lentils', 'Canned & Jarred'],
  ['kidney beans', 'Canned & Jarred'],
  ['canned tomato', 'Canned & Jarred'],
  ['coconut cream', 'Canned & Jarred'],
  // Frozen
  ['frozen berries', 'Frozen'],
  ['frozen vegetables', 'Frozen'],
  ['edamame', 'Frozen'],
  // Plant-based proteins
  ['tofu', 'Produce'],
  ['tempeh', 'Produce'],
  ['seitan', 'Produce'],
  // Spices (pantry)
  ['cumin', 'Spices & Seasonings'],
  ['paprika', 'Spices & Seasonings'],
  ['cinnamon', 'Spices & Seasonings'],
  ['turmeric', 'Spices & Seasonings'],
  ['oregano', 'Spices & Seasonings'],
  ['basil', 'Spices & Seasonings'],
  ['thyme', 'Spices & Seasonings'],
  // Baking
  ['protein powder', 'Baking & Cooking'],
  ['flour', 'Baking & Cooking'],
  ['cocoa powder', 'Baking & Cooking'],
  ['baking powder', 'Baking & Cooking'],
  ['dark chocolate', 'Snacks'],
  ['chocolate', 'Snacks'],
];

/**
 * Correct ingredient categories to match iOS GroceryCategory enum values.
 * Checks longer patterns first to avoid partial matches.
 */
function correctIngredientCategories(mealPlan: MealPlanResponse): void {
  for (const day of mealPlan.days) {
    for (const meal of day.meals) {
      for (const ing of meal.recipe.ingredients) {
        const ingLower = ing.name.toLowerCase();
        for (const [pattern, category] of INGREDIENT_CATEGORY_MAP) {
          if (ingLower.includes(pattern)) {
            if (ing.category !== category) {
              if (DEBUG) console.log(`[CATEGORY] "${ing.name}": "${ing.category}" → "${category}"`);
              ing.category = category;
            }
            break; // First match wins (longer patterns are first)
          }
        }
      }
    }
  }
}

/**
 * Protein/meat ingredient patterns that should use ounce, not cup/gram in imperial mode.
 */
const OUNCE_INGREDIENTS = [
  'chicken', 'beef', 'salmon', 'pork', 'turkey', 'shrimp', 'cod',
  'tilapia', 'steak', 'fish', 'tuna', 'lamb', 'bacon', 'sausage',
  'ground beef', 'ground turkey', 'chicken breast', 'pork chop',
  'tofu', 'tempeh',
];

/**
 * Naturally countable ingredients with grams-per-piece ratios.
 * Longer patterns first to avoid partial matches (e.g. "sweet potato" before "potato").
 */
const COUNTABLE_INGREDIENTS: [string, number][] = [
  ['sweet potato', 150],
  ['banana', 120],
  ['apple', 180],
  ['pear', 180],
  ['orange', 150],
  ['lemon', 60],
  ['lime', 45],
  ['avocado', 170],
  ['peach', 150],
  ['nectarine', 140],
  ['kiwi', 75],
  ['potato', 170],
  ['onion', 150],
  ['tomato', 125],
  ['bell pepper', 150],
  ['cucumber', 200],
  ['zucchini', 200],
  ['carrot', 70],
  ['corn', 250],
  ['tortilla', 40],
  ['pita', 60],
];

/** Skip conversion for these forms — they are measured by weight/volume, not count */
const COUNTABLE_SKIP_FORMS = [
  'diced', 'chopped', 'sliced', 'minced', 'grated', 'shredded',
  'juice', 'puree', 'paste', 'sauce', 'dried', 'canned', 'frozen',
  'powder', 'flakes', 'mashed', 'crushed',
];

/**
 * Correct nonsensical imperial units (e.g. "6 cup salmon" → "48 ounce salmon").
 * Also converts countable items from weight → piece (both metric and imperial).
 */
function correctIngredientUnits(mealPlan: MealPlanResponse, isMetric: boolean): void {
  // --- Imperial protein fix (cup/gram → ounce for proteins) ---
  if (!isMetric) {
    for (const day of mealPlan.days) {
      for (const meal of day.meals) {
        for (const ing of meal.recipe.ingredients) {
          const nameLower = ing.name.toLowerCase();
          const isProtein = OUNCE_INGREDIENTS.some(p => nameLower.includes(p));

          if (isProtein && ing.unit === 'cup') {
            const oldQty = ing.quantity;
            ing.quantity = Math.round(ing.quantity * 8 * 10) / 10;
            ing.unit = 'ounce';
            if (DEBUG) console.warn(`[UNIT-FIX] "${ing.name}": ${oldQty} cup → ${ing.quantity} ounce`);
          } else if (isProtein && ing.unit === 'gram') {
            const oldQty = ing.quantity;
            ing.quantity = Math.round(ing.quantity / 28.35 * 10) / 10;
            ing.unit = 'ounce';
            if (DEBUG) console.warn(`[UNIT-FIX] "${ing.name}": ${oldQty} gram → ${ing.quantity} ounce`);
          }
        }
      }
    }
  }

  // --- Countable item fix (both metric and imperial) ---
  for (const day of mealPlan.days) {
    for (const meal of day.meals) {
      for (const ing of meal.recipe.ingredients) {
        const nameLower = ing.name.toLowerCase();

        // Skip prepared forms (diced, sliced, juice, etc.)
        if (COUNTABLE_SKIP_FORMS.some(form => nameLower.includes(form))) continue;

        // Skip if already using a count unit
        if (['piece', 'slice', 'bunch', 'clove'].includes(ing.unit)) continue;

        for (const [pattern, gramsPerPiece] of COUNTABLE_INGREDIENTS) {
          if (!nameLower.includes(pattern)) continue;

          let grams: number;
          if (ing.unit === 'gram') {
            grams = ing.quantity;
          } else if (ing.unit === 'ounce') {
            grams = ing.quantity * 28.35;
          } else if (ing.unit === 'cup') {
            // 1 cup diced produce ≈ 150g, rough approximation
            grams = ing.quantity * 150;
          } else {
            break; // tablespoon, teaspoon etc. — skip
          }

          const pieces = grams / gramsPerPiece;
          if (pieces < 0.25) break; // too small, likely a sub-ingredient

          // Round to nearest 0.5
          const rounded = Math.round(pieces * 2) / 2;
          const finalQty = Math.max(0.5, rounded);

          const oldDesc = `${ing.quantity} ${ing.unit}`;
          ing.quantity = finalQty;
          ing.unit = 'piece';
          if (DEBUG) console.warn(`[UNIT-FIX] "${ing.name}": ${oldDesc} → ${finalQty} piece`);
          break; // first match wins
        }
      }
    }
  }
}

/**
 * Snack archetype → replacement recipe name templates for post-gen enforcement.
 */
const SNACK_REPLACEMENTS: Record<string, string[]> = {
  'nut butter + fruit': ['Apple with Peanut Butter', 'Banana with Peanut Butter', 'Pear with Sunflower Seed Butter'],
  'trail mix': ['Trail Mix with Dark Chocolate', 'Mixed Nuts and Dried Fruit', 'Energy Trail Mix'],
  'hummus + veggies': ['Hummus with Carrot Sticks', 'Hummus with Cucumber and Bell Pepper', 'Veggie Hummus Dip'],
  'hard boiled eggs': ['Hard Boiled Eggs with Sea Salt', 'Hard Boiled Eggs with Everything Seasoning', 'Seasoned Hard Boiled Eggs'],
  'protein smoothie': ['Berry Protein Smoothie', 'Banana Spinach Protein Shake', 'Chocolate Protein Smoothie'],
  'rice cakes + toppings': ['Rice Cakes with Avocado', 'Rice Cakes with Peanut Butter', 'Rice Cakes with Hummus'],
  'edamame': ['Steamed Edamame with Sea Salt', 'Spiced Edamame Bowl', 'Edamame Snack Bowl'],
  'dark chocolate + almonds': ['Dark Chocolate Bites', 'Dark Chocolate with Seeds', 'Dark Chocolate Snack Square'],
  'mixed nuts': ['Roasted Seed Mix', 'Pumpkin Seed Snack Bowl', 'Sunflower and Pumpkin Seeds'],
  'fruit salad': ['Fresh Fruit Salad', 'Mixed Berry Bowl', 'Tropical Fruit Cup'],
  'yogurt parfait': ['Greek Yogurt Berry Parfait', 'Yogurt with Granola and Honey', 'Blueberry Yogurt Bowl'],
  'cottage cheese + fruit': ['Cottage Cheese with Peaches', 'Cottage Cheese and Berry Bowl', 'Cottage Cheese with Pineapple'],
};

// Safe fallback replacements (no yogurt, no cottage cheese, no common allergens)
const FALLBACK_SNACK_NAMES = [
  'Rice Cakes with Sunflower Seed Butter', 'Steamed Edamame Bowl', 'Hummus with Veggie Sticks',
  'Hard Boiled Eggs with Sea Salt', 'Berry Protein Smoothie', 'Fresh Fruit Cup',
  'Sliced Apple with Honey', 'Banana with Seed Butter', 'Roasted Chickpea Snack Bowl',
];

/**
 * Post-gen: enforce snack type caps by renaming excess yogurt/cottage snacks
 * to match their originally assigned archetype.
 */
function enforceSnackTypeCaps(
  mealPlan: MealPlanResponse,
  snackAssignments: string[][]
): void {
  // First pass: count yogurt and cottage cheese snacks
  let yogurtCount = 0;
  let cottageCount = 0;

  for (const day of mealPlan.days) {
    for (const meal of day.meals) {
      if (meal.mealType !== 'snack') continue;
      const name = meal.recipe.name.toLowerCase();
      if (name.includes('yogurt') || name.includes('parfait')) yogurtCount++;
      if (name.includes('cottage')) cottageCount++;
    }
  }

  if (yogurtCount <= 2 && cottageCount <= 2) return; // All good

  // Second pass: fix excess by replacing with assigned archetype
  let yogurtSeen = 0;
  let cottageSeen = 0;

  for (const day of mealPlan.days) {
    let snackIdx = 0;
    for (const meal of day.meals) {
      if (meal.mealType !== 'snack') continue;
      const name = meal.recipe.name.toLowerCase();
      const isYogurt = name.includes('yogurt') || name.includes('parfait');
      const isCottage = name.includes('cottage');

      if (isYogurt) yogurtSeen++;
      if (isCottage) cottageSeen++;

      const needsReplace = (isYogurt && yogurtSeen > 2) || (isCottage && cottageSeen > 2);
      if (needsReplace) {
        const dayAssignments = snackAssignments[day.dayOfWeek];
        const assignedType = dayAssignments?.[snackIdx];

        // Don't replace excess yogurt with yogurt, or excess cottage with cottage
        const assignedIsYogurt = assignedType === 'yogurt parfait';
        const assignedIsCottage = assignedType === 'cottage cheese + fruit';
        const wouldRepeatProblem = (isYogurt && assignedIsYogurt) || (isCottage && assignedIsCottage);

        let replacements: string[] | undefined;
        let source = '';
        if (assignedType && !wouldRepeatProblem && SNACK_REPLACEMENTS[assignedType]) {
          replacements = SNACK_REPLACEMENTS[assignedType];
          source = assignedType;
        }

        // Fallback: pick from safe non-yogurt/non-cottage names
        if (!replacements) {
          replacements = FALLBACK_SNACK_NAMES;
          source = 'fallback';
        }

        const oldName = meal.recipe.name;
        meal.recipe.name = replacements[Math.floor(Math.random() * replacements.length)];
        console.warn(`[SNACK-ENFORCE] Day ${day.dayOfWeek}: Replaced excess "${oldName}" → "${meal.recipe.name}" (source: ${source})`);
      }
      snackIdx++;
    }
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

  if (DEBUG) {
    console.log('[DEBUG] ========== GENERATE PLAN START ==========');
    console.log('[DEBUG] Device ID:', deviceId);
    console.log('[DEBUG] Weekly Preferences:', weeklyPreferences || 'None');
    console.log('[DEBUG] Exclude Recipes:', excludeRecipeNames?.join(', ') || 'None');
    console.log('[DEBUG] Structured Prefs - Focus:', weeklyFocus?.join(', ') || 'None');
    console.log('[DEBUG] Structured Prefs - Exclusions:', temporaryExclusions?.join(', ') || 'None');
    console.log('[DEBUG] Structured Prefs - Busyness:', weeklyBusyness || 'None');
  }

  // Validate required fields
  if (!deviceId || typeof deviceId !== 'string' || deviceId.length > 128 || !/^[\w-]+$/.test(deviceId)) {
    if (DEBUG) console.log('[DEBUG] ERROR: Invalid device ID');
    return { success: false, error: 'Invalid device ID' };
  }

  if (!userProfile) {
    if (DEBUG) console.log('[DEBUG] ERROR: User profile is required');
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
  // Validate per-type counts when present
  const resolvedCounts = resolveMealCounts(userProfile);
  const totalMeals = resolvedCounts.breakfastCount + resolvedCounts.lunchCount + resolvedCounts.dinnerCount + resolvedCounts.snackCount;
  if (totalMeals < 1) {
    return { success: false, error: 'At least 1 meal per day is required' };
  }

  if (DEBUG) {
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
      breakfastCount: userProfile.breakfastCount,
      lunchCount: userProfile.lunchCount,
      dinnerCount: userProfile.dinnerCount,
      snackCount: userProfile.snackCount,
      pantryLevel: userProfile.pantryLevel,
      barriers: userProfile.barriers,
    }));
  }

  // Check rate limit
  if (DEBUG) console.log('[DEBUG] Checking rate limit for device:', deviceId);
  const rateLimit = await checkRateLimit(deviceId, 'generate-plan');
  if (DEBUG) {
    console.log('[DEBUG] Rate limit result:', JSON.stringify({
      allowed: rateLimit.allowed,
      remaining: rateLimit.remaining,
      limit: rateLimit.limit,
    }));
  }

  if (!rateLimit.allowed) {
    if (DEBUG) console.log('[DEBUG] ERROR: Rate limit exceeded');
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
    if (DEBUG) {
      console.log('[DEBUG] ========== PERSONALIZATION ==========');
      console.log('[DEBUG] Primary Goals:', userProfile.primaryGoals?.join(', ') || 'None');
      console.log('[DEBUG] Goal Pace:', userProfile.goalPace || 'Not set');
      console.log('[DEBUG] Barriers:', userProfile.barriers?.join(', ') || 'None');
      console.log('[DEBUG] Preferred Cuisines:', userProfile.preferredCuisines?.join(', ') || 'None');
      console.log('[DEBUG] Disliked Cuisines:', userProfile.dislikedCuisines?.join(', ') || 'None');
      console.log('[DEBUG] Food Dislikes:', userProfile.foodDislikes?.join(', ') || 'None');
    }

    // Get Claude client
    if (DEBUG) console.log('[DEBUG] Initializing Claude client...');
    const client = getAnthropicClient();
    if (DEBUG) console.log('[DEBUG] Claude client initialized successfully');

    // Resolve temporary exclusions: prefer structured field, fallback to parsing weeklyPreferences string
    const resolvedExclusions: string[] = temporaryExclusions && temporaryExclusions.length > 0
      ? temporaryExclusions
      : (() => {
          if (!weeklyPreferences) return [];
          const match = weeklyPreferences.match(/AVOID THESE INGREDIENTS THIS WEEK[^:]*:\n([\s\S]*?)(?:\n\n|$)/);
          if (!match) return [];
          return match[1].split('\n').map(line => line.replace(/^-\s*/, '').trim()).filter(Boolean);
        })();
    if (DEBUG && resolvedExclusions.length > 0) {
      console.log('[DEBUG] Resolved temporary exclusions:', resolvedExclusions.join(', '));
    }

    // Log the dynamic ingredient list being used
    const ingredientList = buildIngredientList(userProfile, resolvedExclusions);
    if (DEBUG) {
      console.log('[DEBUG] Dynamic ingredient list based on preferences:');
      console.log('[DEBUG]   Proteins:', ingredientList.proteins.join(', '));
      console.log('[DEBUG]   Carbs:', ingredientList.carbs.join(', '));
      console.log('[DEBUG]   Vegetables:', ingredientList.vegetables.join(', '));
      console.log('[DEBUG]   Fruits:', ingredientList.fruits.join(', '));
      console.log('[DEBUG]   Dairy/Fats:', ingredientList.dairy.join(', '));
      console.log('[DEBUG]   Rotation:', ingredientList.proteinRotation);
    }

    // Step 0: Server-side pre-randomization
    const perDayTargets = jitterDailyTargets(userProfile, duration);
    const breakfastAssignments = assignBreakfastCategories(duration, resolvedCounts.breakfastCount);
    const expandedAllergies = expandAllergyTerms(userProfile.allergies);
    const isDairyFree = userProfile.dietaryRestrictions.map(r => r.toLowerCase()).includes('dairy-free') ||
      expandedAllergies.includes('dairy') || expandedAllergies.includes('lactose');
    const snackAssignments = assignSnackArchetypes(duration, resolvedCounts.snackCount, isDairyFree, expandedAllergies);
    const vegetableAssignments = assignDailyVegetables(duration, ingredientList.vegetables);

    if (DEBUG) {
      console.log('[DEBUG] ========== PRE-RANDOMIZATION ==========');
      console.log('[DEBUG] Per-day targets:', JSON.stringify(perDayTargets));
      console.log('[DEBUG] Breakfast assignments:', JSON.stringify(breakfastAssignments));
      console.log('[DEBUG] Snack assignments:', JSON.stringify(snackAssignments));
      console.log('[DEBUG] Vegetable assignments:', JSON.stringify(vegetableAssignments));
    }

    // Step 1: Generate skeleton for the week
    const skeleton = await generateSkeleton(client, userProfile, duration, weeklyPreferences, excludeRecipeNames, resolvedExclusions, breakfastAssignments, snackAssignments, vegetableAssignments);
    if (DEBUG) {
      if (skeleton) {
        console.log(`[DEBUG] Skeleton: ${JSON.stringify(skeleton)}`);
      } else {
        console.log('[DEBUG] Skeleton generation failed or skipped, proceeding without skeleton');
      }
    }

    const systemPrompt = buildSystemPrompt(userProfile);
    const allDays: DayDTO[] = [];

    // Step 2: Using Claude Haiku for cost efficiency (~12x cheaper than Sonnet)
    // Haiku supports up to 8192 output tokens — use 8000 to leave margin
    // 2 days × 5 meals × detailed recipes typically needs 5000-7000 tokens
    const MODEL = 'claude-haiku-4-5-20251001';
    const MAX_TOKENS = 8000;

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
        if (day.breakfast) allSkeletonConcepts.push(day.breakfast.concept);
        if (day.breakfast2) allSkeletonConcepts.push(day.breakfast2.concept);
        if (day.lunch) allSkeletonConcepts.push(day.lunch.concept);
        if (day.lunch2) allSkeletonConcepts.push(day.lunch2.concept);
        if (day.dinner) allSkeletonConcepts.push(day.dinner.concept);
        if (day.dinner2) allSkeletonConcepts.push(day.dinner2.concept);
        if (day.snack1) allSkeletonConcepts.push(day.snack1.concept);
        if (day.snack2) allSkeletonConcepts.push(day.snack2.concept);
        if (day.snack3) allSkeletonConcepts.push(day.snack3.concept);
        if (day.snack4) allSkeletonConcepts.push(day.snack4.concept);
      }
    }

    // Run batches SEQUENTIALLY to stay within Anthropic rate limits
    // (10k output tokens/min — each batch uses ~5000-7000 tokens)
    if (DEBUG) console.log(`[DEBUG] Starting ${batches.length} batches SEQUENTIALLY for ${duration}-day plan...`);
    const sequentialStartTime = Date.now();

    // Track recipe names across batches to prevent cross-batch duplicates
    const generatedRecipeNames: string[] = [];

    for (let i = 0; i < batches.length; i++) {
      const [startDay, endDay] = batches[i];
      const batchNum = i + 1;
      if (DEBUG) console.log(`[DEBUG] Batch ${batchNum}: Days ${startDay}-${endDay} - STARTING`);

      // For cross-batch awareness, collect concepts from days NOT in this batch
      const otherBatchConcepts: string[] = [];
      if (skeleton) {
        for (const day of skeleton.days) {
          if (day.day < startDay || day.day > endDay) {
            if (day.breakfast) otherBatchConcepts.push(day.breakfast.concept);
            if (day.breakfast2) otherBatchConcepts.push(day.breakfast2.concept);
            if (day.lunch) otherBatchConcepts.push(day.lunch.concept);
            if (day.lunch2) otherBatchConcepts.push(day.lunch2.concept);
            if (day.dinner) otherBatchConcepts.push(day.dinner.concept);
            if (day.dinner2) otherBatchConcepts.push(day.dinner2.concept);
            if (day.snack1) otherBatchConcepts.push(day.snack1.concept);
            if (day.snack2) otherBatchConcepts.push(day.snack2.concept);
            if (day.snack3) otherBatchConcepts.push(day.snack3.concept);
            if (day.snack4) otherBatchConcepts.push(day.snack4.concept);
          }
        }
      }

      const batchExcludeNames = [...excludeRecipeNames, ...generatedRecipeNames];
      const userPrompt = buildUserPrompt(userProfile, startDay, endDay, weeklyPreferences, batchExcludeNames, skeleton, resolvedExclusions, otherBatchConcepts, perDayTargets, snackAssignments, vegetableAssignments);
      const startTime = Date.now();

      const response = await callClaudeWithRetry(
        () => client.messages.create({
          model: MODEL,
          max_tokens: MAX_TOKENS,
          system: systemPrompt,
          messages: [{ role: 'user', content: userPrompt }],
        }),
        `Batch ${batchNum} (days ${startDay}-${endDay})`
      );

      const batchTime = Date.now() - startTime;
      if (DEBUG) console.log(`[DEBUG] Batch ${batchNum} received in ${batchTime}ms, stop: ${response.stop_reason}`);

      // Check if response was truncated due to token limit
      if (response.stop_reason === 'max_tokens') {
        if (DEBUG) console.error(`[ERROR] Batch ${batchNum} (days ${startDay}-${endDay}) was TRUNCATED (stop_reason=max_tokens). Response may contain invalid JSON.`);
      }

      const textContent = response.content.find((c: Anthropic.ContentBlock) => c.type === 'text');
      if (!textContent || textContent.type !== 'text') {
        throw new Error(`No text content in Claude response (batch ${batchNum})`);
      }

      const batchResult = parseClaudeResponse(textContent.text, `Batch ${batchNum} (days ${startDay}-${endDay})`);
      if (DEBUG) console.log(`[DEBUG] Batch ${batchNum} parsed: ${batchResult.days.length} days`);

      // Accumulate recipe names for cross-batch deduplication
      for (const day of batchResult.days) {
        for (const meal of day.meals) {
          generatedRecipeNames.push(meal.recipe.name);
        }
      }

      allDays.push(...batchResult.days);
    }

    const totalSequentialTime = Date.now() - sequentialStartTime;
    if (DEBUG) console.log('[DEBUG] All batches completed in:', totalSequentialTime, 'ms (SEQUENTIAL)');

    // Combine batches
    const mealPlan: MealPlanResponse = { days: allDays };
    if (DEBUG) console.log('[DEBUG] Combined meal plan:', mealPlan.days.length, 'total days');

    const totalMeals = mealPlan.days.reduce((acc, day) => acc + day.meals.length, 0);
    if (DEBUG) console.log('[DEBUG] Parsed meal plan:', mealPlan.days.length, 'days,', totalMeals, 'total meals');

    // Post-generation: auto-correct meal types based on position
    // Build expected order dynamically from user's meal counts
    const postCounts = resolveMealCounts(userProfile);
    const expectedMealOrder = buildMealOrder(postCounts);

    for (const day of mealPlan.days) {
      if (day.meals.length === expectedMealOrder.length) {
        // Check if meal types match expected order
        const typesMatch = day.meals.every((meal, i) => meal.mealType === expectedMealOrder[i]);
        if (!typesMatch) {
          const originalTypes = day.meals.map(m => m.mealType).join(', ');
          // Force-correct meal types based on position
          for (let i = 0; i < day.meals.length; i++) {
            day.meals[i].mealType = expectedMealOrder[i];
          }
          if (DEBUG) console.warn(`[VALIDATION] Day ${day.dayOfWeek}: Auto-corrected meal types from [${originalTypes}] to [${expectedMealOrder.join(', ')}]`);
        }
      } else {
        if (DEBUG) console.warn(`[VALIDATION] Day ${day.dayOfWeek}: Expected ${expectedMealOrder.length} meals, got ${day.meals.length} — cannot auto-correct`);
      }
    }

    // Post-generation: auto-fix duplicate recipe names by appending day name
    const DAY_NAMES = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const recipeNameMap = new Map<string, { dayOfWeek: number; mealType: string }>();
    for (const day of mealPlan.days) {
      for (const meal of day.meals) {
        const nameKey = meal.recipe.name.toLowerCase().trim();
        if (recipeNameMap.has(nameKey)) {
          const dayName = DAY_NAMES[day.dayOfWeek % 7] ?? `Day ${day.dayOfWeek}`;
          const oldName = meal.recipe.name;
          meal.recipe.name = `${meal.recipe.name} (${dayName})`;
          console.warn(`[DEDUP] Renamed duplicate "${oldName}" → "${meal.recipe.name}"`);
        } else {
          recipeNameMap.set(nameKey, { dayOfWeek: day.dayOfWeek, mealType: meal.mealType });
        }
      }
    }

    // Post-generation: validate snack variety (always runs, not just DEBUG)
    {
      let yogurtSnacks = 0;
      let cottageSnacks = 0;
      const snackConcepts = new Set<string>();
      for (const day of mealPlan.days) {
        for (const meal of day.meals) {
          if (meal.mealType === 'snack') {
            const name = meal.recipe.name.toLowerCase();
            if (name.includes('yogurt')) yogurtSnacks++;
            if (name.includes('cottage')) cottageSnacks++;
            snackConcepts.add(name);
          }
        }
      }
      if (DEBUG) console.log(`[VALIDATION] Snack diversity: ${snackConcepts.size} distinct snacks, ${yogurtSnacks} yogurt-based, ${cottageSnacks} cottage-cheese-based`);
      if (yogurtSnacks > 2) console.warn(`[VALIDATION] WARNING: ${yogurtSnacks} yogurt snacks exceeds limit of 2`);
      if (cottageSnacks > 2) console.warn(`[VALIDATION] WARNING: ${cottageSnacks} cottage cheese snacks exceeds limit of 2`);

      // Enforce snack type caps by renaming excess yogurt/cottage to assigned archetypes
      if (yogurtSnacks > 2 || cottageSnacks > 2) {
        enforceSnackTypeCaps(mealPlan, snackAssignments);
      }

      // Log per-day calorie totals for verification
      if (DEBUG) {
        for (const day of mealPlan.days) {
          const dayCal = day.meals.reduce((sum, m) => sum + (m.recipe.calories || 0), 0);
          console.log(`[VALIDATION] Day ${day.dayOfWeek}: total ${dayCal} cal`);
        }
      }
    }

    // Post-generation: rename snacks appearing 3+ times to force variety
    {
      const snackNameCounts = new Map<string, number>();
      for (const day of mealPlan.days) {
        for (const meal of day.meals) {
          if (meal.mealType !== 'snack') continue;
          const nameKey = meal.recipe.name.toLowerCase().trim();
          const count = (snackNameCounts.get(nameKey) || 0) + 1;
          snackNameCounts.set(nameKey, count);
          if (count > 2) {
            const dayName = DAY_NAMES[day.dayOfWeek % 7] ?? `Day ${day.dayOfWeek}`;
            const oldName = meal.recipe.name;
            meal.recipe.name = `${meal.recipe.name} (${dayName} Variation)`;
            if (DEBUG) console.warn(`[SNACK-DEDUP] Renamed "${oldName}" → "${meal.recipe.name}" (appeared ${count} times)`);
          }
        }
      }
    }

    // Post-generation: ingredient dominance scanner (warning-only diagnostic)
    {
      const PANTRY_STAPLES = new Set(['olive oil', 'salt', 'pepper', 'honey', 'garlic powder', 'coconut oil', 'garlic', 'onion', 'soy sauce']);
      const ingredientDayMap = new Map<string, Set<number>>();
      for (const day of mealPlan.days) {
        for (const meal of day.meals) {
          for (const ing of meal.recipe.ingredients) {
            const ingKey = ing.name.toLowerCase().replace(/s$/, '');
            if (PANTRY_STAPLES.has(ingKey)) continue;
            if (!ingredientDayMap.has(ingKey)) ingredientDayMap.set(ingKey, new Set());
            ingredientDayMap.get(ingKey)!.add(day.dayOfWeek);
          }
        }
      }
      const dominantIngredients: string[] = [];
      for (const [ingredient, days] of ingredientDayMap) {
        if (days.size >= 5) {
          dominantIngredients.push(`${ingredient} (${days.size}/${duration})`);
          console.warn(`[VARIETY] "${ingredient}" appears in ${days.size}/${duration} days`);
        }
      }
      if (dominantIngredients.length > 0) {
        console.warn(`[VARIETY] DOMINANT INGREDIENTS SUMMARY: ${dominantIngredients.join(', ')}`);
      }
    }

    // Post-generation: clean up ingredient names
    // AI sometimes produces "50 g (50g) Eggplant" — strip parenthetical quantity duplications
    for (const day of mealPlan.days) {
      for (const meal of day.meals) {
        for (const ing of meal.recipe.ingredients) {
          // Remove parenthetical quantity patterns like "(50g)", "(200ml)", "(1 cup)"
          ing.name = ing.name.replace(/\s*\(\d+\s*(?:g|ml|oz|lb|kg|cup|tbsp|tsp)\)\s*/gi, ' ').trim();
          // Remove leading quantity+unit from name like "50 g Eggplant" → "Eggplant"
          ing.name = ing.name.replace(/^\d+\s*(?:g|ml|oz|lb|kg)\s+/i, '').trim();
        }
      }
    }

    // Post-generation: scan for allergy violations
    // Also include dairy terms for dairy-free users (restriction, not just allergy)
    const scanTerms = [...expandedAllergies];
    if (isDairyFree && !scanTerms.includes('dairy')) {
      const dairyTerms = ALLERGY_EXPANSIONS['dairy'];
      if (dairyTerms) {
        for (const term of dairyTerms) {
          if (!scanTerms.includes(term.toLowerCase())) {
            scanTerms.push(term.toLowerCase());
          }
        }
      }
    }
    scanForAllergyViolations(mealPlan, scanTerms);

    // Post-generation: correct ingredient categories to match iOS GroceryCategory enum
    correctIngredientCategories(mealPlan);

    // Post-generation: fix nonsensical imperial units (e.g. "6 cup salmon" → "48 oz salmon")
    const isMetric = (userProfile.measurementSystem || 'Metric') === 'Metric';
    correctIngredientUnits(mealPlan, isMetric);

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
    if (DEBUG) console.log('[DEBUG] Saving', allRecipes.length, 'recipes to database...');
    const storageResult = await saveRecipesIfUnique(allRecipes);
    if (DEBUG) console.log('[DEBUG] Storage result:', storageResult.saved, 'new,', storageResult.duplicates, 'duplicates');

    // Generate plan ID
    const planId = `mp_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    if (DEBUG) console.log('[DEBUG] Generated plan ID:', planId);

    if (DEBUG) console.log('[DEBUG] ========== GENERATE PLAN SUCCESS ==========');

    // Only count against rate limit after successful generation
    let rateLimitInfo = { remaining: 0, resetTime: new Date().toISOString(), limit: 5 };
    try {
      const updatedLimit = await incrementRateLimit(deviceId, 'generate-plan');
      rateLimitInfo = {
        remaining: updatedLimit.remaining,
        resetTime: updatedLimit.resetTime.toISOString(),
        limit: updatedLimit.limit,
      };
    } catch (rlError) {
      if (DEBUG) console.error('[WARN] incrementRateLimit failed (non-fatal):', rlError instanceof Error ? rlError.message : rlError);
    }

    return {
      success: true,
      mealPlan: {
        id: planId,
        days: mealPlan.days,
      },
      recipesAdded: storageResult.saved,
      recipesDuplicate: storageResult.duplicates,
      rateLimitInfo,
    };
  } catch (error) {
    if (DEBUG) console.log('[DEBUG] ========== GENERATE PLAN ERROR ==========');
    const errorType = error instanceof Error ? error.constructor.name : typeof error;
    const errorMsg = error instanceof Error ? error.message : String(error);
    if (DEBUG) console.error('Error type:', errorType);
    if (DEBUG) console.error('Error message:', errorMsg);
    if (DEBUG && error instanceof Error && error.stack) {
      console.error('Error stack:', error.stack);
    }

    // Surface rate limit errors so the client can show a meaningful message
    const isRateLimit = errorType === 'RateLimitError' || errorMsg.includes('429');
    const isJsonParse = errorMsg.includes('parse') || errorMsg.includes('JSON');
    return {
      success: false,
      error: isRateLimit
        ? 'AI service is busy. Please wait a minute and try again.'
        : isJsonParse
        ? 'AI returned an incomplete response. Please try again.'
        : 'Failed to generate meal plan. Please try again.',
    };
  }
}
