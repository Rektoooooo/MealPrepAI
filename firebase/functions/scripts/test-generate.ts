/**
 * Local test script for meal plan generation.
 *
 * Module mocking is handled by register-mocks.cjs (preloaded via --require).
 * This script calls handleGeneratePlan with a realistic profile and validates
 * the output for calorie variation, meal diversity, and consecutive-day repetition.
 *
 * Usage: cd firebase/functions && npm run test:generate
 */

import path from 'path';
import dotenv from 'dotenv';

// ─── Environment setup ──────────────────────────────────────────────
dotenv.config({ path: path.join(__dirname, '..', '.env') });
process.env.DEBUG_GENERATE = 'true';

// ─── Import the module under test (mocks are already registered) ────
import { handleGeneratePlan } from '../src/api/generatePlan';

// ─── Types ──────────────────────────────────────────────────────────
interface DayDTO {
  dayOfWeek: number;
  meals: MealDTO[];
}

interface MealDTO {
  mealType: string;
  recipe: RecipeDTO;
}

interface RecipeDTO {
  name: string;
  calories: number;
  proteinGrams: number;
  carbsGrams: number;
  fatGrams: number;
  cuisineType: string;
  ingredients: { name: string; quantity: number; unit: string; category: string }[];
  instructions: string[];
}

// ─── Test profile ───────────────────────────────────────────────────
const testRequest = {
  userProfile: {
    age: 30,
    gender: 'male',
    weightKg: 80,
    heightCm: 180,
    activityLevel: 'moderate',
    dailyCalorieTarget: 2400,
    proteinGrams: 150,
    carbsGrams: 280,
    fatGrams: 75,
    weightGoal: 'maintain',
    dietaryRestrictions: [] as string[],
    allergies: [] as string[],
    foodDislikes: [] as string[],
    preferredCuisines: ['Italian', 'Mexican', 'Asian'],
    dislikedCuisines: [] as string[],
    cookingSkill: 'intermediate',
    maxCookingTimeMinutes: 45,
    simpleModeEnabled: false,
    mealsPerDay: 5,
    includeSnacks: true,
    breakfastCount: 1,
    lunchCount: 1,
    dinnerCount: 1,
    snackCount: 2,
    pantryLevel: 'Average',
    barriers: [] as string[],
    primaryGoals: ['planMeals', 'eatHealthy'],
    goalPace: 'Moderate',
    measurementSystem: 'Metric',
  },
  deviceId: 'test-device-local',
  duration: 7,
};

// ─── Validation helpers ─────────────────────────────────────────────
const DAYS_OF_WEEK = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

function printHeader(title: string) {
  console.log(`\n${'═'.repeat(60)}`);
  console.log(`  ${title}`);
  console.log(`${'═'.repeat(60)}`);
}

function printSection(title: string) {
  console.log(`\n── ${title} ${'─'.repeat(Math.max(0, 54 - title.length))}`);
}

interface ValidationResult {
  name: string;
  passed: boolean;
  detail: string;
}

function validateCalorieVariation(days: DayDTO[]): ValidationResult {
  const dailyCalories = days.map((day) =>
    day.meals.reduce((sum, m) => sum + (m.recipe?.calories ?? 0), 0)
  );

  const allIdentical = dailyCalories.every((c) => c === dailyCalories[0]);
  const min = Math.min(...dailyCalories);
  const max = Math.max(...dailyCalories);
  const avg = dailyCalories.reduce((a, b) => a + b, 0) / dailyCalories.length;
  const spread = max - min;

  printSection('Calorie Totals Per Day');
  days.forEach((day, i) => {
    const cals = dailyCalories[i];
    const pct = ((cals / 2400) * 100).toFixed(1);
    console.log(
      `  ${DAYS_OF_WEEK[i].padEnd(10)} ${cals.toFixed(0).padStart(5)} kcal  (${pct}% of target)`
    );
  });
  console.log(`  ${'─'.repeat(40)}`);
  console.log(
    `  Avg: ${avg.toFixed(0)} | Min: ${min.toFixed(0)} | Max: ${max.toFixed(0)} | Spread: ${spread.toFixed(0)}`
  );

  return {
    name: 'Calorie Variation',
    passed: !allIdentical && spread > 50,
    detail: allIdentical
      ? 'FAIL: All days have identical calories'
      : `Spread: ${spread.toFixed(0)} kcal (${((spread / avg) * 100).toFixed(1)}% variation)`,
  };
}

function validateBreakfastDiversity(days: DayDTO[]): ValidationResult {
  const breakfasts = days
    .flatMap((d) => d.meals.filter((m) => m.mealType === 'breakfast'))
    .map((m) => m.recipe?.name ?? 'unknown');

  const unique = new Set(breakfasts);

  printSection('Breakfast Recipes');
  breakfasts.forEach((name, i) => {
    console.log(`  ${DAYS_OF_WEEK[i].padEnd(10)} ${name}`);
  });
  console.log(`  Unique: ${unique.size}/${breakfasts.length}`);

  return {
    name: 'Breakfast Diversity',
    passed: unique.size >= 4,
    detail: `${unique.size} unique breakfasts out of ${breakfasts.length} days`,
  };
}

function validateSnackDiversity(days: DayDTO[]): ValidationResult {
  const snacks = days
    .flatMap((d) => d.meals.filter((m) => m.mealType === 'snack'))
    .map((m) => m.recipe?.name ?? 'unknown');

  const nameLower = snacks.map((s) => s.toLowerCase());
  const yogurtCottage = nameLower.filter(
    (s) => s.includes('yogurt') || s.includes('cottage cheese')
  );

  printSection('Snack Recipes');
  let snackIdx = 0;
  days.forEach((day, i) => {
    const daySnacks = day.meals.filter((m) => m.mealType === 'snack');
    daySnacks.forEach((m) => {
      console.log(
        `  ${(snackIdx === 0 ? DAYS_OF_WEEK[i] : '').padEnd(10)} ${m.recipe?.name ?? 'unknown'} (${m.recipe?.calories ?? 0} kcal)`
      );
      snackIdx++;
    });
    snackIdx = 0;
  });

  const unique = new Set(snacks);
  console.log(
    `  Unique snacks: ${unique.size}/${snacks.length} | Yogurt/cottage cheese: ${yogurtCottage.length}`
  );

  return {
    name: 'Snack Diversity',
    passed: yogurtCottage.length <= 2,
    detail:
      yogurtCottage.length > 2
        ? `FAIL: ${yogurtCottage.length} yogurt/cottage cheese snacks (max 2)`
        : `${yogurtCottage.length} yogurt/cottage cheese (within limit)`,
  };
}

function validateConsecutiveDayRepetition(days: DayDTO[]): ValidationResult {
  const issues: string[] = [];

  printSection('Consecutive Day Protein Check');
  for (let i = 0; i < days.length - 1; i++) {
    for (const mealType of ['lunch', 'dinner']) {
      const todayMeal = days[i].meals.find((m) => m.mealType === mealType);
      const nextMeal = days[i + 1].meals.find((m) => m.mealType === mealType);
      const todayName = todayMeal?.recipe?.name ?? '';
      const nextName = nextMeal?.recipe?.name ?? '';

      if (todayName && nextName && todayName === nextName) {
        const msg = `${DAYS_OF_WEEK[i]} & ${DAYS_OF_WEEK[i + 1]} ${mealType}: "${todayName}"`;
        issues.push(msg);
        console.log(`  REPEAT: ${msg}`);
      }
    }
  }

  if (issues.length === 0) {
    console.log('  No consecutive-day lunch/dinner repeats found.');
  }

  return {
    name: 'No Consecutive Repeats',
    passed: issues.length === 0,
    detail:
      issues.length > 0
        ? `${issues.length} repeated meal(s): ${issues.join('; ')}`
        : 'No consecutive-day protein repeats',
  };
}

// ─── Main ───────────────────────────────────────────────────────────
async function main() {
  printHeader('Meal Plan Generation Test');
  console.log('Profile: 30M, 80kg, 2400 kcal, omnivore');
  console.log('Meals: 1 breakfast, 1 lunch, 1 dinner, 2 snacks × 7 days');
  console.log('Starting generation...\n');

  const startTime = Date.now();

  let response: any;
  try {
    response = await handleGeneratePlan(testRequest);
  } catch (err) {
    console.error('\nGeneration failed with error:');
    console.error(err);
    process.exit(1);
  }

  const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
  console.log(`\nGeneration completed in ${elapsed}s`);

  if (!response.success || !response.mealPlan) {
    console.error('\nGeneration returned failure:');
    console.error(response.error ?? 'No meal plan in response');
    process.exit(1);
  }

  const { days } = response.mealPlan;
  console.log(`Days: ${days.length} | Recipes stored: ${response.recipesAdded ?? 0}`);

  // ─── Run validations ────────────────────────────────────────────
  const results: ValidationResult[] = [
    validateCalorieVariation(days),
    validateBreakfastDiversity(days),
    validateSnackDiversity(days),
    validateConsecutiveDayRepetition(days),
  ];

  // ─── Summary ────────────────────────────────────────────────────
  printHeader('Validation Summary');
  let allPassed = true;
  for (const r of results) {
    const icon = r.passed ? 'PASS' : 'FAIL';
    console.log(`  [${icon}] ${r.name.padEnd(25)} ${r.detail}`);
    if (!r.passed) allPassed = false;
  }

  console.log(
    `\n${allPassed ? 'All checks passed!' : 'Some checks failed.'} (${elapsed}s)\n`
  );
  process.exit(allPassed ? 0 : 1);
}

main();
