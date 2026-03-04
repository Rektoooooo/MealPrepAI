/**
 * Multi-profile meal plan test.
 * Generates 3 plans for different user profiles and prints full details.
 *
 * Usage: cd firebase/functions && npm run test:profiles
 */

import path from 'path';
import dotenv from 'dotenv';

dotenv.config({ path: path.join(__dirname, '..', '.env') });
process.env.DEBUG_GENERATE = 'true';

import { handleGeneratePlan } from '../src/api/generatePlan';

// ─── Profiles ───────────────────────────────────────────────────────

const PROFILES = [
  {
    label: 'Profile A: Female, 28, weight loss, vegetarian, 1600 kcal',
    request: {
      userProfile: {
        age: 28,
        gender: 'female',
        weightKg: 68,
        heightCm: 165,
        activityLevel: 'light',
        dailyCalorieTarget: 1600,
        proteinGrams: 100,
        carbsGrams: 170,
        fatGrams: 55,
        weightGoal: 'lose',
        dietaryRestrictions: ['Vegetarian'],
        allergies: [] as string[],
        foodDislikes: ['tofu', 'mushrooms'],
        preferredCuisines: ['Mediterranean', 'Indian'],
        dislikedCuisines: [] as string[],
        cookingSkill: 'beginner',
        maxCookingTimeMinutes: 30,
        simpleModeEnabled: false,
        mealsPerDay: 4,
        includeSnacks: true,
        breakfastCount: 1,
        lunchCount: 1,
        dinnerCount: 1,
        snackCount: 1,
        pantryLevel: 'Minimal',
        barriers: ['Time constraints'],
        primaryGoals: ['eatHealthy', 'lose weight'],
        goalPace: 'Gradual',
        measurementSystem: 'Metric',
      },
      deviceId: 'test-profile-a',
      duration: 7,
    },
  },
  {
    label: 'Profile B: Male, 24, bulking, omnivore, 3200 kcal',
    request: {
      userProfile: {
        age: 24,
        gender: 'male',
        weightKg: 75,
        heightCm: 183,
        activityLevel: 'very_active',
        dailyCalorieTarget: 3200,
        proteinGrams: 200,
        carbsGrams: 380,
        fatGrams: 95,
        weightGoal: 'gain',
        dietaryRestrictions: [] as string[],
        allergies: ['Tree nuts'],
        foodDislikes: ['sardines'],
        preferredCuisines: ['Mexican', 'Asian', 'American'],
        dislikedCuisines: [] as string[],
        cookingSkill: 'advanced',
        maxCookingTimeMinutes: 60,
        simpleModeEnabled: false,
        mealsPerDay: 6,
        includeSnacks: true,
        breakfastCount: 1,
        lunchCount: 1,
        dinnerCount: 1,
        snackCount: 3,
        pantryLevel: 'Well-stocked',
        barriers: [] as string[],
        primaryGoals: ['planMeals', 'buildMuscle'],
        goalPace: 'Aggressive',
        measurementSystem: 'Metric',
      },
      deviceId: 'test-profile-b',
      duration: 7,
    },
  },
  {
    label: 'Profile C: Female, 40, maintain, gluten-free + dairy-free, 2000 kcal',
    request: {
      userProfile: {
        age: 40,
        gender: 'female',
        weightKg: 62,
        heightCm: 170,
        activityLevel: 'moderate',
        dailyCalorieTarget: 2000,
        proteinGrams: 120,
        carbsGrams: 220,
        fatGrams: 70,
        weightGoal: 'maintain',
        dietaryRestrictions: ['Gluten-Free', 'Dairy-Free'],
        allergies: ['Peanuts'],
        foodDislikes: ['eggplant'],
        preferredCuisines: ['Japanese', 'Thai', 'Italian'],
        dislikedCuisines: ['French'],
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
        barriers: ['Budget'],
        primaryGoals: ['eatHealthy', 'planMeals'],
        goalPace: 'Moderate',
        measurementSystem: 'Imperial',
      },
      deviceId: 'test-profile-c',
      duration: 7,
    },
  },
];

// ─── Formatting helpers ─────────────────────────────────────────────

const DAYS = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

function hr(char = '─', len = 70) {
  return char.repeat(len);
}

function printFullMealPlan(days: any[], profileLabel: string, target: number) {
  console.log(`\n${'═'.repeat(70)}`);
  console.log(`  ${profileLabel}`);
  console.log(`${'═'.repeat(70)}`);

  for (const day of days) {
    const dayName = DAYS[day.dayOfWeek] ?? `Day ${day.dayOfWeek}`;
    const dayCalories = day.meals.reduce((s: number, m: any) => s + (m.recipe?.calories ?? 0), 0);
    const dayProtein = day.meals.reduce((s: number, m: any) => s + (m.recipe?.proteinGrams ?? 0), 0);
    const dayCarbs = day.meals.reduce((s: number, m: any) => s + (m.recipe?.carbsGrams ?? 0), 0);
    const dayFat = day.meals.reduce((s: number, m: any) => s + (m.recipe?.fatGrams ?? 0), 0);

    console.log(`\n${hr('━')}`);
    console.log(`  ${dayName.toUpperCase()}  |  ${dayCalories} kcal  |  P ${dayProtein}g  C ${dayCarbs}g  F ${dayFat}g  |  ${((dayCalories / target) * 100).toFixed(0)}% of target`);
    console.log(hr('━'));

    for (const meal of day.meals) {
      const r = meal.recipe;
      if (!r) continue;

      const mealLabel = (meal.mealType || 'unknown').toUpperCase();
      console.log(`\n  [${mealLabel}] ${r.name}`);
      console.log(`    ${r.calories} kcal | P ${r.proteinGrams}g | C ${r.carbsGrams}g | F ${r.fatGrams}g | Fiber ${r.fiberGrams ?? '?'}g`);
      console.log(`    Cuisine: ${r.cuisineType} | Prep: ${r.prepTimeMinutes}min | Cook: ${r.cookTimeMinutes}min | Servings: ${r.servings}`);

      if (r.ingredients?.length) {
        console.log(`    Ingredients (${r.ingredients.length}):`);
        for (const ing of r.ingredients) {
          console.log(`      - ${ing.quantity} ${ing.unit} ${ing.name} [${ing.category}]`);
        }
      }

      if (r.instructions?.length) {
        console.log(`    Steps (${r.instructions.length}):`);
        r.instructions.forEach((step: string, idx: number) => {
          console.log(`      ${idx + 1}. ${step}`);
        });
      }
    }
  }
}

// ─── Main ───────────────────────────────────────────────────────────

async function main() {
  console.log(`\n${'#'.repeat(70)}`);
  console.log(`  MULTI-PROFILE MEAL PLAN GENERATION TEST`);
  console.log(`  ${new Date().toISOString()}`);
  console.log(`${'#'.repeat(70)}\n`);

  const results: { label: string; response: any; elapsed: number; target: number }[] = [];

  for (let i = 0; i < PROFILES.length; i++) {
    const { label, request } = PROFILES[i];
    console.log(`\n>>> Starting ${label} ...`);
    const start = Date.now();

    try {
      const response = await handleGeneratePlan(request);
      const elapsed = (Date.now() - start) / 1000;
      console.log(`<<< Done in ${elapsed.toFixed(1)}s (success=${response.success})`);
      results.push({ label, response, elapsed, target: request.userProfile.dailyCalorieTarget });
    } catch (err) {
      const elapsed = (Date.now() - start) / 1000;
      console.error(`<<< FAILED after ${elapsed.toFixed(1)}s:`, err);
      results.push({ label, response: { success: false, error: String(err) }, elapsed, target: request.userProfile.dailyCalorieTarget });
    }
  }

  // ─── Print full meal plans ──────────────────────────────────────
  for (const r of results) {
    if (r.response.success && r.response.mealPlan) {
      printFullMealPlan(r.response.mealPlan.days, r.label, r.target);
    } else {
      console.log(`\n${'═'.repeat(70)}`);
      console.log(`  ${r.label} — FAILED`);
      console.log(`  Error: ${r.response.error}`);
      console.log(`${'═'.repeat(70)}`);
    }
  }

  // ─── Timing summary ────────────────────────────────────────────
  console.log(`\n${'#'.repeat(70)}`);
  console.log('  GENERATION TIMING');
  console.log(`${'#'.repeat(70)}`);
  for (const r of results) {
    console.log(`  ${r.label}: ${r.elapsed.toFixed(1)}s — ${r.response.success ? 'OK' : 'FAILED'}`);
  }
  const totalTime = results.reduce((s, r) => s + r.elapsed, 0);
  console.log(`  Total: ${totalTime.toFixed(1)}s\n`);
}

main();
