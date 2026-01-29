import Foundation
import SwiftUI
import SwiftData

// MARK: - Meal Prep Setup Steps
enum MealPrepSetupStep: Int, CaseIterable {
    case welcome = 0
    case weeklyFocus = 1
    case temporaryExclusions = 2
    case cookingAvailability = 3
    case review = 4

    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .weeklyFocus: return "Weekly Focus"
        case .temporaryExclusions: return "Exclusions"
        case .cookingAvailability: return "Availability"
        case .review: return "Review"
        }
    }

    /// Progress bar excludes welcome step
    static var progressSteps: Int { 4 }
}

// MARK: - Meal Prep Setup View Model
@MainActor
@Observable
final class MealPrepSetupViewModel {
    // MARK: - Step State
    var currentStep: MealPrepSetupStep = .welcome

    // MARK: - Preferences Being Edited
    var preferences: MealPrepPreferences

    // MARK: - One-time Request (not saved)
    var specialRequest: String = ""

    // MARK: - Save Toggle
    var saveAsDefault: Bool = true

    // MARK: - Quick Start Mode
    var useQuickStart: Bool = false

    // MARK: - Generation State
    var isGenerating: Bool = false
    var generationProgress: String = ""
    var generationError: Error?

    // MARK: - Date Selection
    var selectedStartDate: Date = Date()
    var showingDatePicker: Bool = false
    var planDuration: Int = 7

    // MARK: - Macro Overrides (for this generation only)
    var overrideCalories: Int?
    var overrideProtein: Int?
    var overrideCarbs: Int?
    var overrideFat: Int?

    // MARK: - Mode
    var skipWelcome: Bool = false

    // MARK: - Dependencies
    private let preferencesStore: MealPrepPreferencesStore

    // MARK: - Computed Properties

    /// Whether to show the quick start option (returning user with saved prefs)
    var showQuickStartOption: Bool {
        preferencesStore.hasExistingPreferences
    }

    /// Progress for the progress bar (0 to 1)
    var progress: CGFloat {
        guard currentStep.rawValue > 0 else { return 0 }
        return CGFloat(currentStep.rawValue) / CGFloat(MealPrepSetupStep.progressSteps)
    }

    /// Whether the back button should be shown
    var showBackButton: Bool {
        currentStep != .welcome
    }

    /// Can proceed to next step
    var canProceed: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .weeklyFocus:
            // At least one focus selected
            return !preferences.weeklyFocus.isEmpty
        case .temporaryExclusions:
            // Always can proceed (optional step)
            return true
        case .cookingAvailability:
            // Always has a selection (default is .normal)
            return true
        case .review:
            return true
        }
    }

    /// Maximum duration allowed based on subscription
    func maxDuration(isSubscribed: Bool) -> Int {
        isSubscribed ? 14 : 7
    }

    /// End date for the selected plan
    var selectedEndDate: Date {
        Calendar.current.date(byAdding: .day, value: planDuration - 1, to: selectedStartDate) ?? selectedStartDate
    }

    /// Formatted date range string (e.g., "Mon, Feb 3 - Sun, Feb 9 (7 days)")
    var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        let startString = formatter.string(from: selectedStartDate)
        let endString = formatter.string(from: selectedEndDate)
        return "\(startString) - \(endString) (\(planDuration) \(planDuration == 1 ? "day" : "days"))"
    }

    /// CTA button title for current step
    var ctaButtonTitle: String {
        switch currentStep {
        case .welcome:
            return showQuickStartOption ? "Customize This Week" : "Let's Go"
        case .weeklyFocus, .temporaryExclusions, .cookingAvailability:
            return "Continue"
        case .review:
            return "Generate My Meal Plan"
        }
    }

    // MARK: - Initialization

    init(preferencesStore: MealPrepPreferencesStore? = nil, skipWelcome: Bool = false) {
        self.preferencesStore = preferencesStore ?? .shared
        self.skipWelcome = skipWelcome
        // Start with a copy of saved preferences
        self.preferences = self.preferencesStore.preferences
        // If skipping welcome, start at weeklyFocus
        if skipWelcome {
            self.currentStep = .weeklyFocus
        }
    }

    /// Initialize macro overrides from a user profile
    func initializeMacroOverrides(from profile: UserProfile) {
        overrideCalories = profile.dailyCalorieTarget
        overrideProtein = profile.proteinGrams
        overrideCarbs = profile.carbsGrams
        overrideFat = profile.fatGrams
    }

    /// Get effective calories (override or profile default)
    func effectiveCalories(profile: UserProfile) -> Int {
        overrideCalories ?? profile.dailyCalorieTarget
    }

    /// Get effective protein (override or profile default)
    func effectiveProtein(profile: UserProfile) -> Int {
        overrideProtein ?? profile.proteinGrams
    }

    /// Get effective carbs (override or profile default)
    func effectiveCarbs(profile: UserProfile) -> Int {
        overrideCarbs ?? profile.carbsGrams
    }

    /// Get effective fat (override or profile default)
    func effectiveFat(profile: UserProfile) -> Int {
        overrideFat ?? profile.fatGrams
    }

    // MARK: - Navigation

    func goToNextStep() {
        guard let nextStep = MealPrepSetupStep(rawValue: currentStep.rawValue + 1) else {
            return
        }
        withAnimation(OnboardingDesign.Animation.stepTransition) {
            currentStep = nextStep
        }
    }

    func goToPreviousStep() {
        guard let previousStep = MealPrepSetupStep(rawValue: currentStep.rawValue - 1) else {
            return
        }
        withAnimation(OnboardingDesign.Animation.stepTransition) {
            currentStep = previousStep
        }
    }

    func skipToReview() {
        withAnimation(OnboardingDesign.Animation.stepTransition) {
            currentStep = .review
            useQuickStart = true
        }
    }

    // MARK: - Preference Actions

    func toggleFocus(_ focus: WeeklyFocus) {
        preferences.toggleFocus(focus)
    }

    func toggleExclusion(_ food: FoodDislike) {
        preferences.toggleExclusion(food)
    }

    func setBusyness(_ busyness: WeeklyBusyness) {
        preferences.weeklyBusyness = busyness
    }

    // MARK: - Generation

    func generateMealPlan(
        for profile: UserProfile,
        isSubscribed: Bool,
        generator: MealPlanGenerator,
        modelContext: ModelContext,
        notificationManager: NotificationManager? = nil,
        measurementSystem: String = "Metric",
        onComplete: @escaping () -> Void
    ) {
        isGenerating = true
        generationProgress = "Preparing your preferences..."
        generationError = nil

        Task {
            do {
                // Save preferences if toggle is on
                if saveAsDefault {
                    preferencesStore.update(preferences)
                }
                preferencesStore.incrementUsage()

                // Build the weekly preferences string for the API
                let weeklyPrefsString = buildWeeklyPreferencesString()

                generationProgress = "Generating your personalized meal plan..."

                // Build macro overrides if any are set
                let macroOverrides: MacroOverrides? = {
                    if overrideCalories != nil || overrideProtein != nil || overrideCarbs != nil || overrideFat != nil {
                        return MacroOverrides(
                            calories: overrideCalories,
                            protein: overrideProtein,
                            carbs: overrideCarbs,
                            fat: overrideFat
                        )
                    }
                    return nil
                }()

                _ = try await generator.generateMealPlan(
                    for: profile,
                    startDate: selectedStartDate,
                    weeklyPreferences: weeklyPrefsString,
                    macroOverrides: macroOverrides,
                    duration: planDuration,
                    measurementSystem: measurementSystem,
                    modelContext: modelContext
                )

                // Mark free trial as used for free users
                if !isSubscribed {
                    profile.hasUsedFreeTrial = true
                    SuperwallTracker.trackFreeTrialStarted()
                }

                // Reschedule local notifications for the new plan
                if let nm = notificationManager {
                    // Fetch the active plan from the context
                    let descriptor = FetchDescriptor<MealPlan>(
                        predicate: #Predicate { $0.isActive },
                        sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
                    )
                    let activePlan = try? modelContext.fetch(descriptor).first
                    nm.rescheduleAllNotifications(
                        activePlan: activePlan,
                        isSubscribed: isSubscribed,
                        trialStartDate: profile.createdAt
                    )
                }

                isGenerating = false
                generationProgress = ""
                onComplete()

            } catch {
                isGenerating = false
                generationProgress = ""
                generationError = error
                print("Failed to generate meal plan: \(error)")
            }
        }
    }

    // MARK: - Private Helpers

    private func buildWeeklyPreferencesString() -> String? {
        var parts: [String] = []

        // Weekly Focus
        if !preferences.weeklyFocus.isEmpty {
            let focusList = preferences.weeklyFocus.map { focus -> String in
                switch focus {
                case .budgetFriendly:
                    return "Budget-Friendly: Use economical ingredients, minimize expensive items"
                case .quickEasy:
                    return "Quick & Easy: All meals should be 30 minutes or less"
                case .highProtein:
                    return "High Protein: Maximize protein in every meal"
                case .tryNewCuisines:
                    return "Try New Cuisines: Include diverse international flavors"
                case .comfortFood:
                    return "Comfort Food: Warm, hearty, satisfying meals"
                case .mealPrepFriendly:
                    return "Meal Prep Friendly: Recipes that store well and can be batch cooked"
                case .familyFavorites:
                    return "Family Favorites: Kid-friendly, crowd-pleasing recipes"
                case .lightFresh:
                    return "Light & Fresh: Lighter, vegetable-forward meals"
                }
            }
            parts.append("THIS WEEK'S PRIORITIES:\n- " + focusList.joined(separator: "\n- "))
        }

        // Temporary Exclusions
        let exclusions = preferences.temporaryExclusionsForAPI
        if !exclusions.isEmpty {
            parts.append("AVOID THESE INGREDIENTS THIS WEEK (temporary exclusions):\n- " + exclusions.joined(separator: "\n- "))
        }

        // Busyness Level
        switch preferences.weeklyBusyness {
        case .superBusy:
            parts.append("COOKING TIME THIS WEEK: Maximum 15-20 minutes per meal - user is super busy")
        case .normal:
            break // Use profile default
        case .relaxed:
            parts.append("COOKING TIME THIS WEEK: User has extra time - can include longer recipes up to 60 minutes")
        }

        // One-time Special Request
        let trimmedRequest = specialRequest.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedRequest.isEmpty {
            parts.append("SPECIAL REQUEST: \(trimmedRequest)")
        }

        return parts.isEmpty ? nil : parts.joined(separator: "\n\n")
    }
}
