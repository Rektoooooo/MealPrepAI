import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable
class OnboardingViewModel {
    // MARK: - Save State
    var saveError: Error?
    var didSaveSuccessfully: Bool = false

    // MARK: - Step 2: Personal Info
    var name: String = ""
    var age: Int = 30
    var gender: Gender = .other
    var heightCm: Double = 170
    var weightKg: Double = 70

    // MARK: - Step 3: Goals
    var weightGoal: WeightGoal = .maintain
    var activityLevel: ActivityLevel = .moderate
    var targetWeightKg: Double = 70

    // MARK: - Step 4: Dietary Restrictions
    var dietaryRestrictions: Set<DietaryRestriction> = []
    var customDietaryRestrictions: String = ""  // For diets not in the list

    // MARK: - Step 5: Allergies
    var allergies: Set<Allergy> = []
    var customAllergies: String = ""  // For allergies not in the list

    // MARK: - Step 6: Cuisine Preferences
    var preferredCuisines: Set<CuisineType> = []

    // MARK: - Step 7: Cooking Preferences
    var cookingSkill: CookingSkill = .intermediate
    var maxCookingTime: CookingTime = .standard
    var simpleModeEnabled: Bool = false

    // MARK: - Step 8: Meal Settings
    var mealsPerDay: Int = 3
    var includeSnacks: Bool = true
    var dailyCalorieTarget: Int = 2000

    // MARK: - Calculated Macros (based on calorie target)
    var proteinGrams: Int {
        // ~30% of calories from protein (4 cal/g)
        return Int(Double(dailyCalorieTarget) * 0.30 / 4)
    }

    var carbsGrams: Int {
        // ~40% of calories from carbs (4 cal/g)
        return Int(Double(dailyCalorieTarget) * 0.40 / 4)
    }

    var fatGrams: Int {
        // ~30% of calories from fat (9 cal/g)
        return Int(Double(dailyCalorieTarget) * 0.30 / 9)
    }

    // MARK: - Recommended Calories Calculator
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

    // MARK: - Save to SwiftData

    /// Saves the profile to SwiftData. Returns true if successful, false otherwise.
    /// Check `saveError` for details if save fails.
    @discardableResult
    func saveProfile(modelContext: ModelContext) -> Bool {
        // Reset state
        saveError = nil
        didSaveSuccessfully = false

        // Create profile with hasCompletedOnboarding = false initially
        let profile = UserProfile(
            name: name,
            age: age,
            gender: gender,
            heightCm: heightCm,
            weightKg: weightKg,
            activityLevel: activityLevel,
            weightGoal: weightGoal,
            targetWeightKg: weightGoal == .maintain ? nil : targetWeightKg,
            dailyCalorieTarget: dailyCalorieTarget,
            proteinGrams: proteinGrams,
            carbsGrams: carbsGrams,
            fatGrams: fatGrams,
            dietaryRestrictions: Array(dietaryRestrictions),
            allergies: Array(allergies),
            preferredCuisines: Array(preferredCuisines),
            cookingSkill: cookingSkill,
            maxCookingTime: maxCookingTime,
            mealsPerDay: mealsPerDay,
            includeSnacks: includeSnacks,
            simpleModeEnabled: simpleModeEnabled,
            hasCompletedOnboarding: false  // Set to false initially
        )

        // Set custom fields
        profile.customDietaryRestrictions = customDietaryRestrictions.isEmpty ? nil : customDietaryRestrictions
        profile.customAllergies = customAllergies.isEmpty ? nil : customAllergies

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
            // Remove the profile from context since save failed
            modelContext.delete(profile)
            return false
        }
    }
}
