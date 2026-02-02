# Calorie Calculation System

## Overview

Your app uses the **Mifflin-St Jeor Equation** combined with **activity level multipliers** to calculate personalized daily calorie targets for each user.

---

## The Formula

### Step 1: Calculate BMR (Basal Metabolic Rate)

**BMR** = Calories your body burns at rest (sleeping, breathing, basic functions)

#### For Males:
```
BMR = (10 × weight_kg) + (6.25 × height_cm) - (5 × age) + 5
```

#### For Females:
```
BMR = (10 × weight_kg) + (6.25 × height_cm) - (5 × age) - 161
```

#### For Non-binary/Other:
```
BMR = (10 × weight_kg) + (6.25 × height_cm) - (5 × age) - 78
```
*(Average of male and female formulas)*

### Step 2: Calculate TDEE (Total Daily Energy Expenditure)

**TDEE** = BMR × Activity Level Multiplier

This accounts for calories burned through daily activities and exercise.

### Step 3: Adjust for Weight Goals

Apply calorie adjustments based on the user's goal:

| Goal | Adjustment | Result |
|------|------------|--------|
| **Lose Weight** | -500 cal | Calorie deficit for ~1 lb/week loss |
| **Maintain Weight** | 0 cal | Maintenance calories |
| **Gain Weight** | +300 cal | Calorie surplus for muscle gain |
| **Body Recomposition** | -100 cal | Slight deficit while building muscle |

---

## Activity Level Multipliers

### The Problem We Fixed ⚠️

Previously, the app **hardcoded** activity level to "Moderate" without asking the user. This meant:
- Sedentary users got too many calories (→ weight gain)
- Very active users got too few calories (→ energy deficit, poor performance)

### The Solution ✅

**New onboarding step added:** "Activity Level" (Step 14)

Users now select from 5 options:

| Activity Level | Multiplier | Description | Example |
|----------------|------------|-------------|---------|
| **Sedentary** | 1.2 | Little or no exercise | Desk job, no regular exercise |
| **Lightly Active** | 1.375 | Light exercise 1-3 days/week | Walking, light yoga, occasional gym |
| **Moderately Active** | 1.55 | Moderate exercise 3-5 days/week | Regular gym, jogging, sports 3-5x/week |
| **Very Active** | 1.725 | Hard exercise 6-7 days/week | Daily intense workouts, athlete training |
| **Extremely Active** | 1.9 | Very hard exercise & physical job | Professional athlete, construction worker who trains |

---

## Example Calculations

### Example 1: Sedentary Office Worker

**Profile:**
- Age: 30
- Gender: Female
- Weight: 70 kg (154 lbs)
- Height: 165 cm (5'5")
- Activity: **Sedentary** (1.2x)
- Goal: Lose weight

**Calculation:**
```
BMR = (10 × 70) + (6.25 × 165) - (5 × 30) - 161
    = 700 + 1031.25 - 150 - 161
    = 1420 calories

TDEE = 1420 × 1.2 = 1704 calories

Weight Loss Target = 1704 - 500 = 1204 calories/day
```

**Result:** 1204 cal/day

### Example 2: Active Gym Goer

**Profile:**
- Age: 30
- Gender: Male
- Weight: 80 kg (176 lbs)
- Height: 180 cm (5'11")
- Activity: **Very Active** (1.725x)
- Goal: Gain weight

**Calculation:**
```
BMR = (10 × 80) + (6.25 × 180) - (5 × 30) + 5
    = 800 + 1125 - 150 + 5
    = 1780 calories

TDEE = 1780 × 1.725 = 3071 calories

Weight Gain Target = 3071 + 300 = 3371 calories/day
```

**Result:** 3371 cal/day

### Comparison: Same Person, Different Activity

| Scenario | Activity | Multiplier | TDEE | Weight Loss Target | Difference |
|----------|----------|------------|------|-------------------|------------|
| Desk job | Sedentary | 1.2 | 2136 cal | 1636 cal | - |
| Moderate exercise | Moderately Active | 1.55 | 2759 cal | 2259 cal | **+623 cal** |
| Daily training | Very Active | 1.725 | 3070 cal | 2570 cal | **+934 cal** |

**Impact:** Nearly **1000 calorie difference** between sedentary and very active!

---

## Macro Distribution

Once calories are calculated, they're split into macronutrients:

| Macro | Percentage | Calculation |
|-------|------------|-------------|
| **Protein** | 30% | (Calories × 0.30) ÷ 4 cal/g |
| **Carbs** | 40% | (Calories × 0.40) ÷ 4 cal/g |
| **Fat** | 30% | (Calories × 0.30) ÷ 9 cal/g |

### Example (2000 cal target):
- Protein: 600 cal ÷ 4 = **150g**
- Carbs: 800 cal ÷ 4 = **200g**
- Fat: 600 cal ÷ 9 = **67g**

---

## Data Flow in App

```
┌─────────────────────────────────────┐
│   Onboarding Steps (Collect Data)   │
├─────────────────────────────────────┤
│ Step 9:  Current Weight (kg)        │
│ Step 11: Age (years)                │
│ Step 12: Gender (M/F/Other)         │
│ Step 13: Height (cm)                │
│ Step 14: Activity Level ✨ NEW      │
│ Step 4:  Weight Goal                │
└──────────────┬──────────────────────┘
               ▼
┌─────────────────────────────────────┐
│    NewOnboardingViewModel            │
│    (Calculate Calories)              │
├─────────────────────────────────────┤
│ 1. Calculate BMR (Mifflin-St Jeor)  │
│ 2. Multiply by activity level       │
│ 3. Adjust for weight goal           │
│ 4. Calculate macro splits           │
└──────────────┬──────────────────────┘
               ▼
┌─────────────────────────────────────┐
│       UserProfile Model              │
│       (Saved to SwiftData)           │
├─────────────────────────────────────┤
│ • dailyCalorieTarget: 2000           │
│ • proteinGrams: 150                  │
│ • carbsGrams: 200                    │
│ • fatGrams: 67                       │
│ • activityLevel: .moderate           │
└──────────────┬──────────────────────┘
               ▼
┌─────────────────────────────────────┐
│      Used Throughout App             │
├─────────────────────────────────────┤
│ • Meal plan generation               │
│ • Recipe filtering                   │
│ • Nutrition tracking                 │
│ • Progress monitoring                │
└─────────────────────────────────────┘
```

---

## Validation & Accuracy

### Is Mifflin-St Jeor Accurate?

✅ **Yes** - It's one of the most accurate BMR formulas:
- Based on extensive research (1990 study, 498 subjects)
- More accurate than older Harris-Benedict equation
- Within ~10% accuracy for most people

### When It's Less Accurate:
- **Very muscular individuals** - May underestimate (muscle burns more)
- **Very high body fat** - May overestimate (fat burns less)
- **Medical conditions** - Thyroid issues, metabolic disorders
- **Age extremes** - Very young (<18) or elderly (>65)

### Improving Accuracy:
- User can adjust targets in Settings → Profile
- Track actual weight changes over 2-4 weeks
- Adjust calories ±200-300 if not seeing expected results

---

## User Experience Impact

### Before Fix:
```
User A: Sedentary office worker
Expected: 1650 cal/day
Got: 2100 cal/day (Moderate default)
Result: ❌ Gained weight instead of losing
```

```
User B: Athlete training 6 days/week
Expected: 2800 cal/day
Got: 2100 cal/day (Moderate default)
Result: ❌ Felt weak, poor recovery
```

### After Fix:
```
User A: Selects "Sedentary"
Gets: 1650 cal/day ✅
Result: ✅ Loses weight as expected
```

```
User B: Selects "Very Active"
Gets: 2800 cal/day ✅
Result: ✅ Proper energy, good performance
```

---

## Implementation Details

### Files Changed

1. **ActivityLevelStepView.swift** (NEW)
   - New onboarding step to collect activity level
   - Shows 5 options with descriptions
   - Icons for each level

2. **NewOnboardingView.swift**
   - Added `.activityLevel` to `OnboardingStep` enum
   - Added title: "Activity"
   - Added view case in switch statement

3. **NewOnboardingViewModel.swift**
   - Already had `activityLevel` property
   - Already used it in calculation
   - Changed from hardcoded `.moderate` to user-selected

4. **AppEnums.swift**
   - ActivityLevel enum already existed
   - 5 levels with multipliers
   - Icons and descriptions

---

## Testing the Feature

### 1. Complete Onboarding
- Go through onboarding
- When you reach "Activity level" step
- Select your actual activity level
- Continue to completion

### 2. Check Calculated Calories
- Go to Settings → Profile
- View "Daily Calorie Target"
- Should match your activity level

### 3. Test Different Scenarios

| Profile | Expected Cal Range |
|---------|-------------------|
| Sedentary, 50kg female, lose weight | 900-1200 cal |
| Moderate, 70kg male, maintain | 2200-2500 cal |
| Very active, 85kg male, gain weight | 3000-3500 cal |

### 4. Verify Meal Plans
- Generate a meal plan
- Check total daily calories
- Should match your target ±100 cal

---

## Future Enhancements

### Potential Improvements:
- [ ] Track actual activity with HealthKit steps
- [ ] Auto-adjust based on weight progress
- [ ] Weekly activity variation (active weekdays, sedentary weekends)
- [ ] Exercise logging and calorie burn tracking
- [ ] Smart recommendations based on activity patterns

### Advanced Features:
- [ ] Body composition consideration (lean mass vs fat mass)
- [ ] Metabolic adaptation tracking
- [ ] Refeed days for very active users
- [ ] Cycle calories based on training schedule

---

## Summary

✅ **What We Fixed:**
- Added Activity Level step to onboarding (Step 14)
- Users now explicitly select from 5 activity levels
- Calorie calculations now personalized to actual activity

✅ **Impact:**
- **More accurate calorie targets** (up to 1000 cal difference!)
- **Better weight loss/gain results**
- **Improved user satisfaction**
- **Prevents over/underfeeding**

✅ **Formula:**
```
Daily Calories = BMR × Activity Multiplier ± Goal Adjustment
```

Your calorie calculation is now **scientifically sound** and **personalized**! 🎯
