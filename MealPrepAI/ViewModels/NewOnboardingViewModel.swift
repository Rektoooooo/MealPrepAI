import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable
class NewOnboardingViewModel {
    // MARK: - Save State
    var saveError: Error?
    var didSaveSuccessfully: Bool = false

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

        // Adjust based on weight goal
        switch weightGoal {
        case .lose:
            return Int(tdee - 500) // 500 cal deficit
        case .maintain:
            return Int(tdee)
        case .gain:
            return Int(tdee + 300) // 300 cal surplus
        case .recomp:
            return Int(tdee - 100) // Slight deficit
        }
    }

    /// Protein grams (~30% of calories)
    var proteinGrams: Int {
        return Int(Double(recommendedCalories) * 0.30 / 4)
    }

    /// Carbs grams (~40% of calories)
    var carbsGrams: Int {
        return Int(Double(recommendedCalories) * 0.40 / 4)
    }

    /// Fat grams (~30% of calories)
    var fatGrams: Int {
        return Int(Double(recommendedCalories) * 0.30 / 9)
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
            name: "",
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
            print("Failed to save profile: \(error)")
            modelContext.delete(profile)
            return false
        }
    }
}
