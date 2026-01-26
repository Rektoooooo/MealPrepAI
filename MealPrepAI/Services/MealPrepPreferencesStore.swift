import Foundation
import SwiftUI

// MARK: - Meal Prep Preferences Store
/// Observable store for meal prep preferences, persisted via UserDefaults
@MainActor
@Observable
final class MealPrepPreferencesStore {
    // MARK: - Singleton
    static let shared = MealPrepPreferencesStore()

    // MARK: - Properties
    private(set) var preferences: MealPrepPreferences

    // MARK: - UserDefaults Key
    private let preferencesKey = "com.mealprepai.mealPrepPreferences"

    // MARK: - Initialization
    private init() {
        // Load from UserDefaults or use default
        if let data = UserDefaults.standard.data(forKey: preferencesKey),
           let decoded = try? JSONDecoder().decode(MealPrepPreferences.self, from: data) {
            self.preferences = decoded
        } else {
            self.preferences = .default
        }
    }

    // MARK: - Public Methods

    /// Save current preferences to UserDefaults
    func save() {
        preferences.lastUpdated = Date()
        persistToUserDefaults()
    }

    /// Update preferences and save
    func update(_ newPreferences: MealPrepPreferences) {
        var updated = newPreferences
        updated.lastUpdated = Date()
        self.preferences = updated
        persistToUserDefaults()
    }

    /// Increment usage count (called when plan is generated)
    func incrementUsage() {
        preferences.timesUsed += 1
        preferences.lastUpdated = Date()
        persistToUserDefaults()
    }

    /// Reset preferences to defaults
    func reset() {
        preferences = .default
        persistToUserDefaults()
    }

    /// Clear all saved preferences (full reset)
    func clearAll() {
        UserDefaults.standard.removeObject(forKey: preferencesKey)
        preferences = .default
    }

    // MARK: - Convenience Setters

    /// Toggle a weekly focus option
    func toggleFocus(_ focus: WeeklyFocus) {
        preferences.toggleFocus(focus)
        persistToUserDefaults()
    }

    /// Toggle a temporary exclusion
    func toggleExclusion(_ food: FoodDislike) {
        preferences.toggleExclusion(food)
        persistToUserDefaults()
    }

    /// Set weekly busyness
    func setBusyness(_ busyness: WeeklyBusyness) {
        preferences.weeklyBusyness = busyness
        persistToUserDefaults()
    }

    /// Set custom exclusions text
    func setCustomExclusions(_ text: String) {
        preferences.customExclusions = text
        persistToUserDefaults()
    }

    // MARK: - Computed Properties

    /// Whether the user has saved preferences from a previous session
    var hasExistingPreferences: Bool {
        preferences.hasExistingPreferences
    }

    /// Human-readable summary of current preferences
    var summary: String {
        preferences.summary
    }

    // MARK: - Private Methods

    private func persistToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(encoded, forKey: preferencesKey)
        }
    }
}
