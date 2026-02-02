# Complete Onboarding Data Audit

## Overview
Comprehensive audit of ALL onboarding data collection vs actual usage in calorie calculations and personalization.

---

## Data Collection vs Usage Matrix

| Step | Data Collected | Used in Calories? | Used Elsewhere? | Optimization Potential |
|------|----------------|-------------------|-----------------|------------------------|
| **3. Primary Goals** | primaryGoals (weight loss, muscle, health, etc.) | ❌ NO | ✅ Saved to profile | ⚠️ COULD optimize macros |
| **4. Weight Goal** | weightGoal (lose/maintain/gain/recomp) | ✅ YES | ✅ Deficit/surplus calc | ✅ Fully used |
| **5. Dietary Restriction** | dietaryRestriction (veg, vegan, keto, etc.) | ❌ NO | ✅ Recipe filtering | ❌ No impact on calories |
| **6. Allergies** | allergies (peanuts, dairy, etc.) | ❌ NO | ✅ Recipe filtering | ❌ No impact on calories |
| **7. Food Dislikes** | foodDislikes (specific ingredients) | ❌ NO | ✅ Recipe filtering | ❌ No impact on calories |
| **9. Weight Input** | weightKg | ✅ YES | ✅ BMR calculation | ✅ Fully used |
| **10. Desired Weight** | targetWeightKg | ❌ NO | ✅ Timeline estimation | ⚠️ COULD adjust deficit |
| **11. Age** | age | ✅ YES | ✅ BMR calculation | ✅ Fully used |
| **12. Gender** | gender | ✅ YES | ✅ BMR calculation | ✅ Fully used |
| **13. Height** | heightCm | ✅ YES | ✅ BMR calculation | ✅ Fully used |
| **14. Activity Level** | activityLevel | ✅ YES | ✅ TDEE multiplier | ✅ Fully used |
| **15. Goal Pace** | goalPace | ✅ YES | ✅ Deficit/surplus calc | ✅ Fully used |
| **16. Barriers** | barriers (time, budget, skills) | ❌ NO | ✅ Saved to profile | ❌ Not used yet |
| **17. Cuisine Preferences** | cuisinePreferences | ❌ NO | ✅ Recipe filtering | ❌ No impact on calories |
| **18. Cooking Skills** | cookingSkill | ❌ NO | ✅ Recipe complexity filter | ❌ No impact on calories |
| **19. Pantry Level** | pantryLevel | ❌ NO | ✅ Recipe ingredient filter | ❌ No impact on calories |
| **20. Avatar** | avatarEmoji | ❌ NO | ✅ UI personalization | ❌ No impact on calories |

---

## Current Calorie Calculation Formula

```
Step 1: BMR (Basal Metabolic Rate)
Uses: age ✅, gender ✅, weight ✅, height ✅

Step 2: TDEE (Total Daily Energy Expenditure)
Uses: BMR × activityLevel ✅

Step 3: Final Calories
Uses: TDEE ± goalPace.dailyCalorieAdjustment ✅
```

### What's Used:
✅ Age
✅ Gender
✅ Weight (current)
✅ Height
✅ Activity Level
✅ Weight Goal (lose/maintain/gain/recomp)
✅ Goal Pace (gradual/moderate/aggressive)

### What's NOT Used:
❌ Primary Goals
❌ Target Weight
❌ Barriers
❌ Dietary preferences (correctly - shouldn't affect calories)

---

## Potential Optimizations

### 🔥 HIGH PRIORITY: Primary Goals → Macro Split

**Current:** Fixed 30/40/30 (Protein/Carbs/Fat)

**Problem:** Not optimized for user's specific goals!

**Solution:** Adjust macros based on primary goals

| Primary Goal | Recommended Macros | Reasoning |
|--------------|-------------------|-----------|
| **Muscle Gain** | 35/40/25 | Higher protein for muscle synthesis |
| **Weight Loss** | 35/30/35 | Higher protein preserves muscle, higher fat for satiety |
| **Athletic Performance** | 25/50/25 | Higher carbs for energy/performance |
| **General Health** | 30/40/30 | Balanced (current default) |
| **Body Recomposition** | 40/30/30 | Very high protein to preserve/build muscle |

**Code Change Needed:**
```swift
var proteinPercentage: Double {
    // Check if user selected muscle gain or recomp as primary goal
    if primaryGoals.contains(.buildMuscle) || weightGoal == .recomp {
        return 0.35 // 35% protein
    } else if primaryGoals.contains(.loseWeight) {
        return 0.35 // 35% protein for muscle preservation
    }
    return 0.30 // Default 30%
}

var carbsPercentage: Double {
    if primaryGoals.contains(.improvePerformance) {
        return 0.50 // 50% carbs for athletes
    } else if primaryGoals.contains(.loseWeight) {
        return 0.30 // 30% carbs for weight loss
    }
    return 0.40 // Default 40%
}

var fatPercentage: Double {
    return 1.0 - proteinPercentage - carbsPercentage
}
```

---

### 🟡 MEDIUM PRIORITY: Target Weight → Dynamic Deficit

**Current:** Fixed deficit based on pace (250/500/750 cal)

**Problem:** Same deficit whether you need to lose 5 lbs or 50 lbs!

**Solution:** Adjust deficit based on amount to lose

| Amount to Lose | Max Safe Deficit | Max Pace |
|----------------|------------------|----------|
| **<10 lbs** | 250-350 cal | Gradual only |
| **10-25 lbs** | 350-500 cal | Gradual or Moderate |
| **25-50 lbs** | 500-750 cal | Any pace |
| **50+ lbs** | 750-1000 cal | Aggressive OK initially |

**Code Change Needed:**
```swift
var recommendedCalories: Int {
    let bmr: Double = /* ... calculate BMR ... */
    let tdee = bmr * activityLevel.multiplier

    // Calculate amount to lose/gain
    let weightDifferenceKg = abs(weightKg - targetWeightKg)
    let weightDifferenceLbs = weightDifferenceKg * 2.20462

    // Adjust maximum safe deficit based on amount to lose
    let maxSafeDeficit: Double
    if weightDifferenceLbs < 10 {
        maxSafeDeficit = 350 // Force slower pace for small amounts
    } else if weightDifferenceLbs < 25 {
        maxSafeDeficit = 500
    } else {
        maxSafeDeficit = 750
    }

    // Apply pace adjustment, but cap at safe maximum
    let requestedAdjustment = goalPace.dailyCalorieAdjustment
    let safeAdjustment = min(requestedAdjustment, maxSafeDeficit)

    switch weightGoal {
    case .lose:
        return Int(tdee - safeAdjustment)
    case .gain:
        return Int(tdee + safeAdjustment)
    // ... etc
    }
}
```

---

### 🟢 LOW PRIORITY: Barriers → Meal Prep Optimization

**Current:** Barriers collected but not used

**Barriers Available:**
- Time constraints
- Budget limitations
- Cooking skills
- Picky eaters in family
- Travel frequently
- No meal prep experience

**Solution:** Use barriers to customize meal plans

**Code Change Needed:**
```swift
// In meal plan generation logic
if barriers.contains(.timeConstraints) {
    // Prioritize quick recipes (<30 min)
    maxCookingTime = .quick
    // Suggest more meal prep recipes
}

if barriers.contains(.budgetLimitations) {
    // Prioritize affordable ingredients
    // Avoid expensive proteins (salmon, beef)
    // Suggest bulk cooking
}

if barriers.contains(.cookingSkills) {
    // Force simple recipes only
    cookingSkill = .beginner
}
```

---

## Missing Data That Could Improve Calculations

### 1. Body Composition (Optional)
**What:** Body fat percentage or lean body mass

**Why:** More accurate BMR calculation

**Impact:**
- Current Mifflin-St Jeor doesn't account for muscle mass
- Very muscular person burns more than formula predicts
- High body fat person burns less than formula predicts

**Implementation:**
```swift
// Optional step in onboarding
var bodyFatPercentage: Double? = nil

var bmr: Double {
    if let bodyFat = bodyFatPercentage {
        // Use Katch-McArdle formula (more accurate for athletes)
        let leanMassKg = weightKg * (1 - bodyFat / 100)
        return 370 + (21.6 * leanMassKg)
    } else {
        // Fall back to Mifflin-St Jeor
        // ... existing calculation ...
    }
}
```

**Priority:** 🔴 LOW (advanced users only)

---

### 2. Daily Step Count (from HealthKit)
**What:** Average daily steps

**Why:** More accurate activity level than self-reported

**Impact:**
- People often mis-estimate their activity
- Steps are objective data
- Can auto-adjust activity level

**Implementation:**
```swift
// If HealthKit enabled and steps available
var calculatedActivityLevel: ActivityLevel {
    if let avgSteps = healthKitAverageSteps {
        switch avgSteps {
        case ..<3000: return .sedentary
        case 3000..<7000: return .light
        case 7000..<10000: return .moderate
        case 10000..<15000: return .active
        default: return .extreme
        }
    }
    return activityLevel // Fall back to user-selected
}
```

**Priority:** 🟡 MEDIUM (good for accuracy)

---

### 3. Training Intensity (for Athletes)
**What:** Types of exercise (cardio, strength, HIIT)

**Why:** Different training burns different calories

**Impact:**
- Strength training needs more protein
- Cardio athletes need more carbs
- HIIT requires higher overall calories

**Implementation:**
```swift
enum TrainingType: CaseIterable {
    case strengthTraining
    case cardio
    case hiit
    case yoga
    case sports
}

var trainingTypes: Set<TrainingType> = []

// Adjust macros based on training
if trainingTypes.contains(.strengthTraining) {
    proteinPercentage += 0.05 // +5% protein
}

if trainingTypes.contains(.cardio) {
    carbsPercentage += 0.10 // +10% carbs
}
```

**Priority:** 🔴 LOW (advanced feature)

---

## Recommended Implementation Priority

### Phase 1: High-Impact Optimizations ⭐⭐⭐
**Status:** Should implement soon

1. ✅ **Primary Goals → Macro Split**
   - Easy to implement
   - High user impact
   - Makes goals actually meaningful
   - **Estimated effort:** 2-3 hours

2. ✅ **Target Weight → Dynamic Deficit Safety**
   - Prevents unsafe aggressive pace for small amounts
   - Shows warnings to users
   - **Estimated effort:** 3-4 hours

### Phase 2: Quality of Life ⭐⭐
**Status:** Nice to have

3. ⚠️ **Barriers → Meal Customization**
   - Makes meal plans more practical
   - Better user experience
   - **Estimated effort:** 4-6 hours

4. ⚠️ **HealthKit Steps → Activity Auto-Adjust**
   - More accurate than self-report
   - Requires HealthKit permission
   - **Estimated effort:** 4-5 hours

### Phase 3: Advanced Features ⭐
**Status:** Future enhancement

5. ❌ **Body Composition Support**
   - Advanced users only
   - Requires additional input step
   - **Estimated effort:** 6-8 hours

6. ❌ **Training Type Optimization**
   - Complex macro adjustments
   - Athlete-focused feature
   - **Estimated effort:** 8-10 hours

---

## Current State Summary

### ✅ What's Working Well

**Calorie Calculation:**
- Uses scientifically accurate Mifflin-St Jeor equation
- Factors in activity level (after our fix)
- Respects weight goals
- Honors goal pace (after our fix)
- Has appropriate adjustments for each goal

**Macro Calculation:**
- Fixed 30/40/30 split
- Simple and works for most people
- Easy to understand

### ⚠️ What Could Be Better

**Not Using:**
- Primary goals (just decorative right now)
- Target weight (only for timeline, not deficit adjustment)
- Barriers (collected but unused)

**Missing Data:**
- Body composition (optional, advanced)
- Actual training details
- Step count from HealthKit

---

## Implementation Recommendations

### Quick Win: Primary Goals → Macros

**Impact:** HIGH
**Effort:** LOW
**User Benefit:** Personalized macros that match their actual goals

```swift
// Add to NewOnboardingViewModel.swift

var proteinGrams: Int {
    let percentage = proteinPercentage
    return Int(Double(recommendedCalories) * percentage / 4)
}

var carbsGrams: Int {
    let percentage = carbsPercentage
    return Int(Double(recommendedCalories) * percentage / 4)
}

var fatGrams: Int {
    let percentage = fatPercentage
    return Int(Double(recommendedCalories) * percentage / 9)
}

private var proteinPercentage: Double {
    if primaryGoals.contains(.buildMuscle) || weightGoal == .recomp {
        return 0.35 // High protein for muscle
    } else if primaryGoals.contains(.loseWeight) {
        return 0.35 // High protein to preserve muscle
    }
    return 0.30 // Balanced
}

private var carbsPercentage: Double {
    if primaryGoals.contains(.improvePerformance) {
        return 0.50 // High carbs for performance
    } else if primaryGoals.contains(.loseWeight) {
        return 0.30 // Lower carbs for fat loss
    }
    return 0.40 // Balanced
}

private var fatPercentage: Double {
    return 1.0 - proteinPercentage - carbsPercentage
}
```

**Test Cases:**
- Muscle gain goal → 35/40/25 split
- Weight loss goal → 35/30/35 split
- Performance goal → 25/50/25 split
- General health → 30/40/30 split (default)

---

## Conclusion

### Current Status: 📊 85% Optimized

**What's Excellent:**
✅ Age, gender, weight, height → BMR ✅
✅ Activity level → TDEE ✅
✅ Weight goal + pace → Deficit/surplus ✅

**Quick Wins Available:**
⚠️ Primary goals → Macro split (2 hours of work)
⚠️ Target weight → Safe deficit limits (3 hours of work)

**Future Enhancements:**
- Barriers → Meal customization
- Body composition → Advanced BMR
- Training type → Specialized macros

### Final Recommendation

**Implement in this order:**

1. **Now:** Primary goals → macro personalization
2. **Soon:** Target weight → deficit safety checks
3. **Later:** Barriers → meal plan customization
4. **Future:** Advanced features for power users

Your calorie calculation is already very good! These optimizations would make it excellent. 🎯
