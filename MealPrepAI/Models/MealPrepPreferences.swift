import Foundation

// MARK: - Weekly Focus Options
/// Priorities the user wants to emphasize THIS WEEK only
enum WeeklyFocus: String, Codable, CaseIterable, Identifiable, Sendable, Hashable {
    case budgetFriendly = "Budget-Friendly"
    case quickEasy = "Quick & Easy"
    case highProtein = "High Protein"
    case tryNewCuisines = "Try New Cuisines"
    case comfortFood = "Comfort Food"
    case mealPrepFriendly = "Meal Prep Friendly"
    case familyFavorites = "Family Favorites"
    case lightFresh = "Light & Fresh"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .budgetFriendly: return "💰"
        case .quickEasy: return "⚡"
        case .highProtein: return "💪"
        case .tryNewCuisines: return "🌍"
        case .comfortFood: return "🍲"
        case .mealPrepFriendly: return "📦"
        case .familyFavorites: return "👨‍👩‍👧"
        case .lightFresh: return "🥗"
        }
    }

    var shortDescription: String {
        switch self {
        case .budgetFriendly: return "Economical ingredients"
        case .quickEasy: return "30 min or less"
        case .highProtein: return "Extra protein focus"
        case .tryNewCuisines: return "Explore new flavors"
        case .comfortFood: return "Warm & satisfying"
        case .mealPrepFriendly: return "Batch cook ahead"
        case .familyFavorites: return "Kid-approved meals"
        case .lightFresh: return "Lighter, veggie-forward"
        }
    }
}

// MARK: - Weekly Busyness Level
/// How busy the user is THIS WEEK, affecting cooking time
enum WeeklyBusyness: String, Codable, CaseIterable, Identifiable, Sendable {
    case superBusy = "Super Busy"
    case normal = "Normal Week"
    case relaxed = "Relaxed Week"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .superBusy: return "🐇"
        case .normal: return "🚶"
        case .relaxed: return "🐢"
        }
    }

    var shortDescription: String {
        switch self {
        case .superBusy: return "15-20 min max per meal"
        case .normal: return "Use my usual cooking time"
        case .relaxed: return "Extra time for cooking"
        }
    }

    /// Multiplier to apply to the user's max cooking time
    var cookingTimeMultiplier: Double {
        switch self {
        case .superBusy: return 0.5  // Half the usual time
        case .normal: return 1.0     // Normal time
        case .relaxed: return 1.5    // 50% more time
        }
    }

    /// Maximum cooking time in minutes for super busy mode
    var maxCookingTimeMinutes: Int {
        switch self {
        case .superBusy: return 20
        case .normal: return 0  // Use profile setting
        case .relaxed: return 0 // Use profile setting
        }
    }
}

// MARK: - Meal Prep Preferences
/// Weekly preferences for meal plan generation (persisted between sessions)
struct MealPrepPreferences: Codable, Sendable, Equatable {
    /// Focus areas for this week's meal plan (1-3 selections)
    var weeklyFocus: [WeeklyFocus]

    /// Foods to avoid THIS WEEK only (not permanent dislikes)
    var temporaryExclusions: [FoodDislike]

    /// Custom text for additional exclusions not in the predefined list
    var customExclusions: String

    /// How busy the user is this week (affects cooking time)
    var weeklyBusyness: WeeklyBusyness

    /// When these preferences were last saved
    var lastUpdated: Date

    /// How many times these preferences have been used
    var timesUsed: Int

    // MARK: - Default Values
    init(
        weeklyFocus: [WeeklyFocus] = [],
        temporaryExclusions: [FoodDislike] = [],
        customExclusions: String = "",
        weeklyBusyness: WeeklyBusyness = .normal,
        lastUpdated: Date = Date(),
        timesUsed: Int = 0
    ) {
        self.weeklyFocus = weeklyFocus
        self.temporaryExclusions = temporaryExclusions
        self.customExclusions = customExclusions
        self.weeklyBusyness = weeklyBusyness
        self.lastUpdated = lastUpdated
        self.timesUsed = timesUsed
    }

    // MARK: - Static Default
    static let `default` = MealPrepPreferences()

    // MARK: - Computed Properties

    /// Whether the user has saved preferences before
    var hasExistingPreferences: Bool {
        timesUsed > 0 || !weeklyFocus.isEmpty
    }

    /// Human-readable summary of current preferences
    var summary: String {
        var parts: [String] = []

        if !weeklyFocus.isEmpty {
            let focusNames = weeklyFocus.map { $0.rawValue }.joined(separator: ", ")
            parts.append("Focus: \(focusNames)")
        }

        if !temporaryExclusions.isEmpty || !customExclusions.isEmpty {
            parts.append("Some exclusions")
        }

        if weeklyBusyness != .normal {
            parts.append(weeklyBusyness.rawValue)
        }

        return parts.isEmpty ? "Default preferences" : parts.joined(separator: " • ")
    }

    /// Format weekly focus for API/prompt
    var weeklyFocusForAPI: [String] {
        weeklyFocus.map { $0.rawValue }
    }

    /// Format temporary exclusions for API/prompt
    var temporaryExclusionsForAPI: [String] {
        var exclusions = temporaryExclusions.map { $0.rawValue }
        if !customExclusions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Split custom exclusions by comma
            let custom = customExclusions
                .split(separator: ",")
                .map { String($0).trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            exclusions.append(contentsOf: custom)
        }
        return exclusions
    }

    // MARK: - Mutation Helpers

    /// Toggle a weekly focus option
    mutating func toggleFocus(_ focus: WeeklyFocus) {
        if let index = weeklyFocus.firstIndex(of: focus) {
            weeklyFocus.remove(at: index)
        } else {
            // Limit to 3 selections
            if weeklyFocus.count < 3 {
                weeklyFocus.append(focus)
            }
        }
    }

    /// Toggle a temporary exclusion
    mutating func toggleExclusion(_ food: FoodDislike) {
        if let index = temporaryExclusions.firstIndex(of: food) {
            temporaryExclusions.remove(at: index)
        } else {
            temporaryExclusions.append(food)
        }
    }

    /// Check if a focus is selected
    func isFocusSelected(_ focus: WeeklyFocus) -> Bool {
        weeklyFocus.contains(focus)
    }

    /// Check if an exclusion is selected
    func isExclusionSelected(_ food: FoodDislike) -> Bool {
        temporaryExclusions.contains(food)
    }
}
