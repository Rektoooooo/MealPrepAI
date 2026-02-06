import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable
class NewOnboardingViewModel {
    // MARK: - Save State
    var saveError: Error?
    var didSaveSuccessfully: Bool = false

    // MARK: - User Info (from Apple Sign In)
    var userName: String = ""

    // MARK: - Step 3: Primary Goals
    var primaryGoals: Set<PrimaryGoal> = []

    // MARK: - Step 4: Weight Goal
    var weightGoal: WeightGoal = .maintain

    // MARK: - Step 5: Dietary Restriction
    var dietaryRestriction: DietaryRestriction = .none

    // MARK: - Step 6: Allergies
    var allergies: Set<Allergy> = []

    // MARK: - Step 7: Food Dislikes
    var foodDislikes: Set<FoodDislike> = []

    // MARK: - Step 9-12: Body Metrics
    var weightKg: Double = 70
    var targetWeightKg: Double = 65
    var age: Int = 30
    var gender: Gender = .other
    var heightCm: Double = 170
    var measurementSystem: MeasurementSystem = .metric

    // MARK: - Goal Timeline
    var goalPace: GoalPace = .moderate

    // MARK: - Barriers
    var barriers: Set<Barrier> = []

    // MARK: - Permissions
    var healthKitEnabled: Bool = false
    var notificationsEnabled: Bool = false

    // MARK: - Step 13: Cuisine Preferences
    var cuisinePreferences: [String: CuisinePreference] = [:]

    // MARK: - Step 14: Cooking Skills
    var cookingSkill: CookingSkill = .intermediate

    // MARK: - Step 15: Pantry Level
    var pantryLevel: PantryLevel = .average

    // MARK: - Step 18: Avatar
    var avatarEmoji: String = "🍳"

    // MARK: - Activity Level (used for calorie calculation)
    var activityLevel: ActivityLevel = .moderate

    // MARK: - Calculated Properties

    /// Recommended daily calories based on user inputs
    var recommendedCalories: Int {
        // Mifflin-St Jeor Equation
        let bmr: Double
        switch gender {
        case .male:
            bmr = 10 * weightKg + 6.25 * heightCm - 5 * Double(age) + 5
        case .female:
            bmr = 10 * weightKg + 6.25 * heightCm - 5 * Double(age) - 161
        case .other:
            // Average of male and female
            bmr = 10 * weightKg + 6.25 * heightCm - 5 * Double(age) - 78
        }

        let tdee = bmr * activityLevel.multiplier

        // Adjust based on weight goal and pace
        switch weightGoal {
        case .lose:
            // Calculate safe deficit based on amount to lose
            let amountToLoseLbs = abs(weightDifferenceKg) * 2.20462

            // Determine maximum safe deficit based on amount to lose
            let maxSafeDeficit: Double
            if amountToLoseLbs < 10 {
                // < 10 lbs: Force gradual pace for safety
                maxSafeDeficit = 350
            } else if amountToLoseLbs < 25 {
                // 10-25 lbs: Allow gradual or moderate
                maxSafeDeficit = 500
            } else {
                // 25+ lbs: Allow any pace
                maxSafeDeficit = 750
            }

            // Apply requested deficit, capped at safe maximum
            let requestedDeficit = goalPace.dailyCalorieAdjustment
            let safeDeficit = min(requestedDeficit, maxSafeDeficit)

            return Int(tdee - safeDeficit)

        case .maintain:
            return Int(tdee)

        case .gain:
            // For gaining, pace matters less for safety
            let dailySurplus = goalPace.dailyCalorieAdjustment
            return Int(tdee + dailySurplus)

        case .recomp:
            // Body recomp always uses gradual pace (0.5 lb/week = 250 cal deficit)
            return Int(tdee - 250)
        }
    }

    // MARK: - Macro Calculations (Evidence-based)

    /// Protein grams per kg of body weight based on goal
    /// Research-backed ranges:
    /// - Weight loss: 1.6-2.2g/kg (higher to preserve muscle in deficit)
    /// - Maintenance: 1.2-1.6g/kg
    /// - Muscle gain: 1.6-2.0g/kg
    /// - Recomp: 1.8-2.2g/kg
    private var proteinPerKg: Double {
        switch weightGoal {
        case .lose:
            // Higher protein to preserve muscle during deficit
            return 1.8
        case .maintain:
            // Moderate protein for maintenance
            return 1.4
        case .gain:
            // Higher protein to build muscle
            return 1.8
        case .recomp:
            // High protein for muscle retention while cutting fat
            return 2.0
        }
    }

    /// Protein grams based on body weight (evidence-based approach)
    var proteinGrams: Int {
        return Int(weightKg * proteinPerKg)
    }

    /// Calories from protein
    private var proteinCalories: Int {
        return proteinGrams * 4
    }

    /// Fat percentage of remaining calories (after protein)
    /// - 25-30% of total calories is healthy range
    private var fatPercentage: Double {
        switch weightGoal {
        case .lose:
            // Lower fat (25%) to maximize protein and carbs
            return 0.25
        case .maintain:
            // Balanced fat (30%)
            return 0.30
        case .gain:
            // Moderate fat (25%) to leave room for carbs
            return 0.25
        case .recomp:
            // Moderate fat (28%)
            return 0.28
        }
    }

    /// Fat grams (percentage-based for healthy fats)
    var fatGrams: Int {
        return Int(Double(recommendedCalories) * fatPercentage / 9)
    }

    /// Calories from fat
    private var fatCalories: Int {
        return fatGrams * 9
    }

    /// Carbs grams (fills remaining calories after protein and fat)
    var carbsGrams: Int {
        let remainingCalories = recommendedCalories - proteinCalories - fatCalories
        return max(0, remainingCalories / 4)
    }

    /// Convert liked cuisines to preferred cuisines array
    var preferredCuisines: [CuisineType] {
        cuisinePreferences
            .filter { $0.value == .like }
            .compactMap { CuisineType(rawValue: $0.key) }
    }

    /// Weight difference from current to target (positive = need to lose, negative = need to gain)
    var weightDifferenceKg: Double {
        weightKg - targetWeightKg
    }

    var weightDifferenceLbs: Double {
        weightDifferenceKg * 2.20462
    }

    /// Estimated weeks to reach goal based on pace
    var weeksToGoal: Int {
        guard goalPace.weeklyLossKg > 0 else { return 0 }
        return Int(ceil(abs(weightDifferenceKg) / goalPace.weeklyLossKg))
    }

    /// Estimated date to reach goal
    var estimatedGoalDate: Date {
        Calendar.current.date(byAdding: .weekOfYear, value: weeksToGoal, to: Date()) ?? Date()
    }

    // MARK: - Save to SwiftData

    /// Saves the profile to SwiftData. Returns true if successful.
    @discardableResult
    func saveProfile(modelContext: ModelContext) -> Bool {
        saveError = nil
        didSaveSuccessfully = false

        // Convert allergies set to array, filtering out .none
        let allergiesArray = Array(allergies).filter { $0 != .none }

        // Create profile
        let profile = UserProfile(
            name: userName,
            age: age,
            gender: gender,
            heightCm: heightCm,
            weightKg: weightKg,
            activityLevel: activityLevel,
            weightGoal: weightGoal,
            targetWeightKg: weightGoal == .maintain ? nil : targetWeightKg,
            dailyCalorieTarget: recommendedCalories,
            proteinGrams: proteinGrams,
            carbsGrams: carbsGrams,
            fatGrams: fatGrams,
            dietaryRestrictions: dietaryRestriction == .none ? [] : [dietaryRestriction],
            allergies: allergiesArray,
            preferredCuisines: preferredCuisines,
            cookingSkill: cookingSkill,
            maxCookingTime: .standard,
            mealsPerDay: 3,
            includeSnacks: true,
            simpleModeEnabled: false,
            hasCompletedOnboarding: false,
            healthKitEnabled: healthKitEnabled,
            primaryGoals: Array(primaryGoals),
            foodDislikes: Array(foodDislikes),
            cuisinePreferencesMap: cuisinePreferences,
            pantryLevel: pantryLevel,
            avatarEmoji: avatarEmoji,
            goalPace: goalPace,
            barriers: Array(barriers)
        )

        // Remove any existing profiles to enforce single-profile invariant
        let existing = try? modelContext.fetch(FetchDescriptor<UserProfile>())
        existing?.forEach { modelContext.delete($0) }

        modelContext.insert(profile)

        do {
            try modelContext.save()
            // Only mark as completed after successful save
            profile.hasCompletedOnboarding = true
            try modelContext.save()
            didSaveSuccessfully = true
            return true
        } catch {
            saveError = error
            #if DEBUG
            print("Failed to save profile: \(error)")
            #endif
            modelContext.delete(profile)
            return false
        }
    }
}
