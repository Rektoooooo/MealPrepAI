# Macro Optimization Implementation

## Overview

Your app now **personalizes macro splits** based on user goals instead of using a fixed 30/40/30 ratio for everyone!

---

## 🎯 The Problem We Fixed

### Before:
**EVERYONE got the same macros:**
- Protein: 30%
- Carbs: 40%
- Fat: 30%

Whether you were losing fat, building muscle, or maintaining - same macros! ❌

### After:
**Personalized macros based on your SPECIFIC goal:**
- Lose Weight: 35/30/35 (high protein, lower carbs)
- Maintain: 30/40/30 (balanced)
- Gain Weight: 35/45/20 (high protein & carbs)
- Body Recomp: 40/35/25 (very high protein)

---

## New Macro Distribution

| Weight Goal | Protein | Carbs | Fat | Reasoning |
|-------------|---------|-------|-----|-----------|
| **Lose Weight** | 35% | 30% | 35% | High protein preserves muscle during deficit. Higher fat for satiety. Lower carbs to encourage fat burning. |
| **Maintain** | 30% | 40% | 30% | Balanced approach for maintenance. Standard healthy distribution. |
| **Gain Weight** | 35% | 45% | 20% | High protein for muscle building. High carbs for energy and glycogen. Lower fat as it's calorie-dense. |
| **Body Recomp** | 40% | 35% | 25% | Very high protein to build/preserve muscle. Moderate carbs for training energy. |

---

## Real-World Examples

### Example 1: Woman Losing Weight

**Profile:**
- Daily calories: 1600
- Goal: Lose Weight

**Old Macros (30/40/30):**
```
Protein: 1600 × 0.30 ÷ 4 = 120g
Carbs:   1600 × 0.40 ÷ 4 = 160g
Fat:     1600 × 0.30 ÷ 9 = 53g
```

**New Macros (35/30/35):**
```
Protein: 1600 × 0.35 ÷ 4 = 140g (+20g) ✅
Carbs:   1600 × 0.30 ÷ 4 = 120g (-40g) ✅
Fat:     1600 × 0.35 ÷ 9 = 62g (+9g) ✅
```

**Benefits:**
- ✅ **+20g protein** helps preserve muscle during weight loss
- ✅ **+9g fat** increases satiety (less hungry)
- ✅ **-40g carbs** encourages fat burning

---

### Example 2: Man Building Muscle

**Profile:**
- Daily calories: 2800
- Goal: Gain Weight

**Old Macros (30/40/30):**
```
Protein: 2800 × 0.30 ÷ 4 = 210g
Carbs:   2800 × 0.40 ÷ 4 = 280g
Fat:     2800 × 0.30 ÷ 9 = 93g
```

**New Macros (35/45/20):**
```
Protein: 2800 × 0.35 ÷ 4 = 245g (+35g) ✅
Carbs:   2800 × 0.45 ÷ 4 = 315g (+35g) ✅
Fat:     2800 × 0.20 ÷ 9 = 62g (-31g) ✅
```

**Benefits:**
- ✅ **+35g protein** optimal for muscle synthesis
- ✅ **+35g carbs** provides energy for workouts and recovery
- ✅ **-31g fat** reduces calorie-dense fat to make room for protein/carbs

---

### Example 3: Body Recomposition

**Profile:**
- Daily calories: 2100
- Goal: Body Recomp (lose fat + gain muscle)

**Old Macros (30/40/30):**
```
Protein: 2100 × 0.30 ÷ 4 = 158g
Carbs:   2100 × 0.40 ÷ 4 = 210g
Fat:     2100 × 0.30 ÷ 9 = 70g
```

**New Macros (40/35/25):**
```
Protein: 2100 × 0.40 ÷ 4 = 210g (+52g) ✅
Carbs:   2100 × 0.35 ÷ 4 = 184g (-26g) ✅
Fat:     2100 × 0.25 ÷ 9 = 58g (-12g) ✅
```

**Benefits:**
- ✅ **+52g protein** critical for building muscle while losing fat
- ✅ Very high protein ratio (40%) supports both goals
- ✅ Still enough carbs for training energy

---

## Safety Check: Deficit Limits

We also added **smart safety limits** based on amount to lose:

| Amount to Lose | Max Daily Deficit | Effect |
|----------------|-------------------|---------|
| **< 10 lbs** | 350 cal max | Forces gradual/moderate pace even if user selects aggressive |
| **10-25 lbs** | 500 cal max | Allows gradual or moderate pace |
| **25+ lbs** | 750 cal max | Allows any pace including aggressive |

### Example:

**User wants to lose 8 lbs:**
- Selects: "Aggressive" pace (750 cal deficit)
- App adjusts: 350 cal deficit (gradual pace)
- **Reason:** Too aggressive for small amount - prevents muscle loss

**User wants to lose 40 lbs:**
- Selects: "Aggressive" pace (750 cal deficit)
- App allows: 750 cal deficit
- **Reason:** Safe for larger amounts initially

---

## The Science Behind the Splits

### Weight Loss (35/30/35)

**High Protein (35%):**
- Prevents muscle loss during calorie deficit
- Most thermogenic macronutrient (body burns calories digesting it)
- Increases satiety (keeps you full)

**Lower Carbs (30%):**
- Creates hormonal environment favorable for fat loss
- Reduces insulin spikes
- Encourages body to use fat stores

**Higher Fat (35%):**
- Extremely satiating (helps prevent hunger)
- Essential for hormone production
- Provides steady energy

### Muscle Gain (35/45/20)

**High Protein (35%):**
- Muscle protein synthesis requires ~0.7-1g per lb body weight
- Building blocks for new muscle tissue

**High Carbs (45%):**
- Fuels intense workouts
- Replenishes glycogen stores
- Insulin helps shuttle nutrients to muscles

**Lower Fat (20%):**
- Still sufficient for hormone health
- Allows more room for protein and carbs within calorie budget

### Body Recomp (40/35/25)

**Very High Protein (40%):**
- Maximum muscle preservation/building
- Critical when simultaneously losing fat and gaining muscle
- 1g+ per lb body weight ideal for recomp

**Moderate Carbs (35%):**
- Enough for training performance
- Not so low that it impacts recovery

**Moderate Fat (25%):**
- Supports hormone production
- Allows maximum protein within calories

---

## Implementation Details

### Code Changes

**File:** `NewOnboardingViewModel.swift`

**Added private computed properties:**
```swift
private var proteinPercentage: Double {
    switch weightGoal {
    case .lose: return 0.35      // High protein for muscle preservation
    case .maintain: return 0.30  // Balanced
    case .gain: return 0.35      // High protein for muscle building
    case .recomp: return 0.40    // Very high for recomp
    }
}

private var carbsPercentage: Double {
    switch weightGoal {
    case .lose: return 0.30      // Lower for fat loss
    case .maintain: return 0.40  // Balanced
    case .gain: return 0.45      // High for energy
    case .recomp: return 0.35    // Moderate
    }
}

private var fatPercentage: Double {
    return 1.0 - proteinPercentage - carbsPercentage
}
```

**Updated macro calculations:**
```swift
var proteinGrams: Int {
    return Int(Double(recommendedCalories) * proteinPercentage / 4)
}

var carbsGrams: Int {
    return Int(Double(recommendedCalories) * carbsPercentage / 4)
}

var fatGrams: Int {
    return Int(Double(recommendedCalories) * fatPercentage / 9)
}
```

---

## Complete Calorie & Macro Formula

```
┌─────────────────────────────────────────┐
│  User Input                             │
├─────────────────────────────────────────┤
│ • Age, Gender, Weight, Height           │
│ • Activity Level                        │
│ • Weight Goal ✅ NEW: affects macros    │
│ • Goal Pace                             │
│ • Amount to Lose ✅ NEW: safety check   │
└────────────┬────────────────────────────┘
             ▼
┌─────────────────────────────────────────┐
│  Step 1: Calculate Calories             │
├─────────────────────────────────────────┤
│ BMR → TDEE → Apply Goal & Pace          │
│ With safety checks for amount to lose   │
└────────────┬────────────────────────────┘
             ▼
┌─────────────────────────────────────────┐
│  Step 2: Calculate Macros ✅ NEW        │
├─────────────────────────────────────────┤
│ Protein %: 30-40% based on goal         │
│ Carbs %:   30-45% based on goal         │
│ Fat %:     20-35% calculated            │
└────────────┬────────────────────────────┘
             ▼
┌─────────────────────────────────────────┐
│  Final Personalized Targets             │
│  (Saved to UserProfile)                 │
└─────────────────────────────────────────┘
```

---

## User Experience Impact

### Scenario 1: Weight Loss User

**Before:**
```
User: "I want to lose weight"
App: "Here's 30% protein"
User: "Why am I so hungry all the time?" 😞
Result: Loses muscle, gives up
```

**After:**
```
User: "I want to lose weight"
App: "Here's 35% protein for muscle preservation"
User: "I feel satisfied and strong!" 😊
Result: Loses fat, keeps muscle, succeeds
```

### Scenario 2: Muscle Building User

**Before:**
```
User: "I want to build muscle"
App: "Here's 30% protein, 30% fat"
User: "Not enough energy for workouts" 😞
Result: Poor gym performance, slow gains
```

**After:**
```
User: "I want to build muscle"
App: "Here's 35% protein, 45% carbs for energy"
User: "Great workouts and recovery!" 😊
Result: Optimal muscle building
```

---

## Testing the Feature

### Test Case 1: Weight Loss Macros
1. Complete onboarding
2. Select "Lose Weight" goal
3. Complete and check Settings → Profile
4. **Expected:**
   - Protein: ~35% of calories
   - Carbs: ~30% of calories
   - Fat: ~35% of calories

### Test Case 2: Muscle Gain Macros
1. Complete onboarding
2. Select "Gain Weight" goal
3. Complete and check Settings → Profile
4. **Expected:**
   - Protein: ~35% of calories
   - Carbs: ~45% of calories
   - Fat: ~20% of calories

### Test Case 3: Safety Check
1. Complete onboarding
2. Current weight: 150 lbs
3. Target weight: 145 lbs (5 lb difference)
4. Select "Aggressive" pace
5. **Expected:** Deficit capped at 350 cal (not 750 cal)

---

## Summary

### ✅ What We Improved

**Before:**
- Fixed 30/40/30 for everyone
- No consideration of user goals
- Same whether losing or gaining

**After:**
- Personalized macro splits by goal
- Scientifically optimized ratios
- Safety checks for deficit amounts

### 📊 Impact by Goal

| Goal | Change | Benefit |
|------|--------|---------|
| **Lose Weight** | 35/30/35 | +17% protein, better satiety |
| **Maintain** | 30/40/30 | Balanced (unchanged) |
| **Gain Weight** | 35/45/20 | +17% protein, +13% carbs for growth |
| **Recomp** | 40/35/25 | +33% protein for optimal body comp |

### 🎯 Your Nutrition is Now:

✅ **Personalized** - Based on YOUR specific goal
✅ **Optimized** - Science-backed macro ratios
✅ **Safe** - Deficit limits prevent aggressive cuts
✅ **Effective** - Macros support your actual goals

**Your app now provides professional-grade nutrition coaching!** 💪
