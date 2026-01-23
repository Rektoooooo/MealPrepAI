import Foundation
import SwiftData

@Model
final class UserProfile {
    // CloudKit requires default values for all non-optional properties
    var id: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date()

    // Authentication
    var appleUserID: String?        // nil for guest users
    var isGuestAccount: Bool = true
    var iCloudSyncEnabled: Bool = false
    var lastSyncDate: Date?

    // Physical attributes
    var age: Int = 30
    var genderRaw: String = "Other"  // Store as String for SwiftData compatibility
    var heightCm: Double = 170.0
    var weightKg: Double = 70.0
    var activityLevelRaw: String = "Moderately Active"

    // Goals
    var weightGoalRaw: String = "Maintain Weight"
    var targetWeightKg: Double?
    var dailyCalorieTarget: Int = 2000
    var proteinGrams: Int = 150
    var carbsGrams: Int = 200
    var fatGrams: Int = 65

    // Preferences - stored as JSON Data for SwiftData compatibility
    var dietaryRestrictionsData: Data?
    var allergiesData: Data?
    var preferredCuisinesData: Data?
    var customDietaryRestrictions: String?  // Comma-separated custom diets
    var customAllergies: String?            // Comma-separated custom allergies
    var cookingSkillRaw: String = "Intermediate"
    var maxCookingTimeRaw: String = "30-45 minutes"

    // Meal settings
    var mealsPerDay: Int = 3
    var includeSnacks: Bool = true
    var simpleModeEnabled: Bool = false

    // Onboarding
    var hasCompletedOnboarding: Bool = false

    // HealthKit preferences
    var healthKitEnabled: Bool = false
    var syncNutritionToHealth: Bool = true
    var readWeightFromHealth: Bool = false
    var lastHealthKitSync: Date?

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \MealPlan.userProfile)
    var mealPlans: [MealPlan]?

    // MARK: - Computed Properties for Enums

    var gender: Gender {
        get { Gender(rawValue: genderRaw) ?? .other }
        set { genderRaw = newValue.rawValue }
    }

    var activityLevel: ActivityLevel {
        get { ActivityLevel(rawValue: activityLevelRaw) ?? .moderate }
        set { activityLevelRaw = newValue.rawValue }
    }

    var weightGoal: WeightGoal {
        get { WeightGoal(rawValue: weightGoalRaw) ?? .maintain }
        set { weightGoalRaw = newValue.rawValue }
    }

    var cookingSkill: CookingSkill {
        get { CookingSkill(rawValue: cookingSkillRaw) ?? .intermediate }
        set { cookingSkillRaw = newValue.rawValue }
    }

    var maxCookingTime: CookingTime {
        get { CookingTime(rawValue: maxCookingTimeRaw) ?? .standard }
        set { maxCookingTimeRaw = newValue.rawValue }
    }

    var dietaryRestrictions: [DietaryRestriction] {
        get {
            guard let data = dietaryRestrictionsData else { return [] }
            return (try? JSONDecoder().decode([DietaryRestriction].self, from: data)) ?? []
        }
        set {
            dietaryRestrictionsData = try? JSONEncoder().encode(newValue)
        }
    }

    var allergies: [Allergy] {
        get {
            guard let data = allergiesData else { return [] }
            return (try? JSONDecoder().decode([Allergy].self, from: data)) ?? []
        }
        set {
            allergiesData = try? JSONEncoder().encode(newValue)
        }
    }

    var preferredCuisines: [CuisineType] {
        get {
            guard let data = preferredCuisinesData else { return [] }
            return (try? JSONDecoder().decode([CuisineType].self, from: data)) ?? []
        }
        set {
            preferredCuisinesData = try? JSONEncoder().encode(newValue)
        }
    }

    init(
        name: String = "",
        appleUserID: String? = nil,
        isGuestAccount: Bool = true,
        iCloudSyncEnabled: Bool = false,
        age: Int = 30,
        gender: Gender = .other,
        heightCm: Double = 170,
        weightKg: Double = 70,
        activityLevel: ActivityLevel = .moderate,
        weightGoal: WeightGoal = .maintain,
        targetWeightKg: Double? = nil,
        dailyCalorieTarget: Int = 2000,
        proteinGrams: Int = 150,
        carbsGrams: Int = 200,
        fatGrams: Int = 65,
        dietaryRestrictions: [DietaryRestriction] = [],
        allergies: [Allergy] = [],
        preferredCuisines: [CuisineType] = [],
        cookingSkill: CookingSkill = .intermediate,
        maxCookingTime: CookingTime = .standard,
        mealsPerDay: Int = 3,
        includeSnacks: Bool = true,
        simpleModeEnabled: Bool = false,
        hasCompletedOnboarding: Bool = false,
        healthKitEnabled: Bool = false,
        syncNutritionToHealth: Bool = true,
        readWeightFromHealth: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.appleUserID = appleUserID
        self.isGuestAccount = isGuestAccount
        self.iCloudSyncEnabled = iCloudSyncEnabled
        self.lastSyncDate = nil
        self.age = age
        self.genderRaw = gender.rawValue
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.activityLevelRaw = activityLevel.rawValue
        self.weightGoalRaw = weightGoal.rawValue
        self.targetWeightKg = targetWeightKg
        self.dailyCalorieTarget = dailyCalorieTarget
        self.proteinGrams = proteinGrams
        self.carbsGrams = carbsGrams
        self.fatGrams = fatGrams
        self.dietaryRestrictionsData = try? JSONEncoder().encode(dietaryRestrictions)
        self.allergiesData = try? JSONEncoder().encode(allergies)
        self.preferredCuisinesData = try? JSONEncoder().encode(preferredCuisines)
        self.cookingSkillRaw = cookingSkill.rawValue
        self.maxCookingTimeRaw = maxCookingTime.rawValue
        self.mealsPerDay = mealsPerDay
        self.includeSnacks = includeSnacks
        self.simpleModeEnabled = simpleModeEnabled
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.healthKitEnabled = healthKitEnabled
        self.syncNutritionToHealth = syncNutritionToHealth
        self.readWeightFromHealth = readWeightFromHealth
        self.lastHealthKitSync = nil
    }

    // MARK: - Authentication Helpers

    /// Link this profile to an Apple ID (upgrade from guest)
    func linkAppleID(_ appleUserID: String) {
        self.appleUserID = appleUserID
        self.isGuestAccount = false
    }

    /// Unlink Apple ID (for sign out)
    func unlinkAppleID() {
        self.appleUserID = nil
        self.isGuestAccount = true
        self.iCloudSyncEnabled = false
        self.lastSyncDate = nil
    }
}
