import Foundation

/// Manages streak tracking with UserDefaults persistence
@MainActor @Observable
final class StreakManager {

    // MARK: - State

    private(set) var currentStreak: Int = 0
    private(set) var bestStreak: Int = 0

    // MARK: - Constants

    private static let currentKey = "com.mealprepai.streak.current"
    private static let bestKey = "com.mealprepai.streak.best"
    private static let lastMilestoneKey = "com.mealprepai.streak.lastMilestone"

    private static let milestones = [3, 5, 7, 14, 21, 30]

    // MARK: - Initialization

    init() {
        let defaults = UserDefaults.standard
        currentStreak = defaults.integer(forKey: Self.currentKey)
        bestStreak = defaults.integer(forKey: Self.bestKey)
    }

    // MARK: - Public Methods

    /// Recomputes the streak from plan days, persists to UserDefaults, and returns a milestone if one was just crossed (nil otherwise).
    @discardableResult
    func refreshStreak(days: [Day]) -> Int? {
        let sortedDays = days.sorted { $0.date > $1.date }
        var streak = 0
        for day in sortedDays {
            let meals = day.meals
            guard !meals.isEmpty else { break }
            if meals.allSatisfy({ $0.isEaten }) {
                streak += 1
            } else {
                break
            }
        }

        currentStreak = streak

        let defaults = UserDefaults.standard
        defaults.set(streak, forKey: Self.currentKey)

        if streak > bestStreak {
            bestStreak = streak
            defaults.set(streak, forKey: Self.bestKey)
        }

        // Check milestones
        let lastMilestone = defaults.integer(forKey: Self.lastMilestoneKey)
        if let milestone = Self.milestones.last(where: { streak >= $0 && $0 > lastMilestone }) {
            defaults.set(milestone, forKey: Self.lastMilestoneKey)
            return milestone
        }

        return nil
    }
}
