import Foundation
import FirebaseAnalytics

/// Centralized analytics service wrapping Firebase Analytics.
/// Tracks user events, session state, and accumulates counter deltas for server sync.
@MainActor
final class AnalyticsService {
    static let shared = AnalyticsService()

    // MARK: - Session State
    private var sessionStartTime: Date?
    private var screensViewed: Int = 0
    private var currentOnboardingStep: OnboardingStep?
    private var onboardingStepStartTime: Date?

    // MARK: - Counter Deltas (for Phase 3 batched server sync)
    private var counterDeltas: [String: Int] = [:]
    private var syncTimer: Timer?
    private var lastSyncDate: Date?
    private var isSyncing = false

    private init() {}

    // MARK: - Configuration

    /// Call after FirebaseApp.configure() to set up analytics
    func configure() {
        sessionStartTime = Date()
        screensViewed = 0

        // Set anonymous user ID
        let deviceId = DeviceIdentifier.shared.deviceId
        Analytics.setUserID(deviceId)

        // Log app_open
        Analytics.logEvent("app_open", parameters: [
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "build_number": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown",
        ])

        // Start sync timer (5 minute interval)
        syncTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.syncToServer()
            }
        }
        syncTimer?.tolerance = 30

        #if DEBUG
        print("[Analytics] Configured with device ID: \(deviceId.prefix(8))...")
        // Enable debug mode for real-time event viewing in Firebase DebugView
        Analytics.setAnalyticsCollectionEnabled(true)
        #endif
    }

    // MARK: - User Properties

    /// Set user properties from profile for segmentation (no PII)
    func setUserProperties(from profile: UserProfile) {
        Analytics.setUserProperty(profile.weightGoal.rawValue, forName: "weight_goal")
        Analytics.setUserProperty(profile.cookingSkill.rawValue, forName: "cooking_skill")
        Analytics.setUserProperty("\(profile.dailyCalorieTarget)", forName: "calorie_target")
        Analytics.setUserProperty(
            profile.dietaryRestrictions.isEmpty ? "none" : profile.dietaryRestrictions.map(\.rawValue).joined(separator: ","),
            forName: "diet_type"
        )
        Analytics.setUserProperty("\(profile.mealsPerDay)", forName: "meals_per_day")
        Analytics.setUserProperty(profile.activityLevel.rawValue, forName: "activity_level")

        #if DEBUG
        print("[Analytics] User properties set from profile")
        #endif
    }

    // MARK: - Session Events

    /// Track session start when app comes to foreground
    func trackSessionStart() {
        sessionStartTime = Date()
        screensViewed = 0
    }

    /// Track session end when app goes to background
    func trackSessionEnd() {
        guard let startTime = sessionStartTime else { return }
        let duration = Date().timeIntervalSince(startTime)

        Analytics.logEvent("session_end", parameters: [
            "duration_seconds": Int(duration),
            "screens_viewed": screensViewed,
        ])

        #if DEBUG
        print("[Analytics] session_end: \(Int(duration))s, \(screensViewed) screens")
        #endif

        // Reset session state for next foreground cycle
        sessionStartTime = nil
        screensViewed = 0

        // Sync to server on session end (only if there are pending deltas)
        if !counterDeltas.isEmpty {
            Task {
                await syncToServer()
            }
        }
    }

    // MARK: - Screen Events

    /// Track tab switches in ContentView
    func trackScreenView(screenName: String) {
        screensViewed += 1
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName,
        ])
    }

    // MARK: - Onboarding Events

    func trackOnboardingStarted() {
        onboardingStepStartTime = Date()
        Analytics.logEvent("onboarding_started", parameters: nil)
    }

    func trackOnboardingStepCompleted(step: OnboardingStep) {
        let timeOnStep: Int
        if let stepStart = onboardingStepStartTime {
            timeOnStep = Int(Date().timeIntervalSince(stepStart))
        } else {
            timeOnStep = 0
        }

        Analytics.logEvent("onboarding_step_completed", parameters: [
            "step_name": step.title,
            "step_index": step.rawValue,
            "time_on_step_seconds": timeOnStep,
        ])

        // Reset timer for next step
        currentOnboardingStep = step
        onboardingStepStartTime = Date()
    }

    func trackOnboardingCompleted() {
        Analytics.logEvent("onboarding_completed", parameters: nil)
        incrementCounter("onboarding_completed")
    }

    func trackOnboardingAbandoned(lastStep: OnboardingStep, timeSpent: Int) {
        Analytics.logEvent("onboarding_abandoned", parameters: [
            "last_step": lastStep.title,
            "step_index": lastStep.rawValue,
            "time_spent_seconds": timeSpent,
        ])
    }

    // MARK: - Plan Generation Events

    func trackPlanGenerationStarted() {
        Analytics.logEvent("plan_generation_started", parameters: nil)
    }

    func trackPlanGenerationCompleted(durationDays: Int, generationTimeSeconds: Double, recipeCount: Int) {
        Analytics.logEvent("plan_generation_completed", parameters: [
            "duration_days": durationDays,
            "generation_time_seconds": Int(generationTimeSeconds),
            "recipe_count": recipeCount,
        ])
        incrementCounter("plans_generated")
    }

    func trackPlanGenerationFailed(error: String) {
        Analytics.logEvent("plan_generation_failed", parameters: [
            "error_type": String(error.prefix(100)),
        ])
    }

    // MARK: - Meal Events

    func trackMealEaten(mealType: MealType) {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let timeOfDay: String
        switch hour {
        case 5..<12: timeOfDay = "morning"
        case 12..<17: timeOfDay = "afternoon"
        case 17..<21: timeOfDay = "evening"
        default: timeOfDay = "night"
        }

        let weekday = calendar.component(.weekday, from: Date())
        let dayNames = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

        Analytics.logEvent("meal_eaten", parameters: [
            "meal_type": mealType.rawValue,
            "day_of_week": dayNames[weekday],
            "time_of_day": timeOfDay,
        ])
        incrementCounter("meals_eaten")
    }

    func trackMealUneaten(mealType: MealType) {
        Analytics.logEvent("meal_uneaten", parameters: [
            "meal_type": mealType.rawValue,
        ])
    }

    func trackMealSwapped(mealType: MealType, generationTimeSeconds: Double) {
        Analytics.logEvent("meal_swapped", parameters: [
            "meal_type": mealType.rawValue,
            "generation_time_seconds": Int(generationTimeSeconds),
        ])
        incrementCounter("meals_swapped")
    }

    func trackMealLocked(mealType: MealType) {
        Analytics.logEvent("meal_locked", parameters: [
            "meal_type": mealType.rawValue,
        ])
    }

    // MARK: - Recipe Events

    func trackRecipeViewed(source: String, cuisineType: String, calories: Int) {
        Analytics.logEvent("recipe_viewed", parameters: [
            "source": source,
            "cuisine_type": cuisineType,
            "calories": calories,
        ])
        incrementCounter("recipes_viewed")
    }

    func trackRecipeFavorited(recipeName: String) {
        Analytics.logEvent("recipe_favorited", parameters: [
            "recipe_name": String(recipeName.prefix(100)),
        ])
        incrementCounter("recipes_favorited")
    }

    func trackRecipeUnfavorited(recipeName: String) {
        Analytics.logEvent("recipe_unfavorited", parameters: [
            "recipe_name": String(recipeName.prefix(100)),
        ])
    }

    func trackRecipeSearched(queryLength: Int, resultCount: Int, hasFilters: Bool) {
        Analytics.logEvent("recipe_searched", parameters: [
            "query_length": queryLength,
            "result_count": resultCount,
            "has_filters": hasFilters,
        ])
    }

    func trackRecipeShared() {
        Analytics.logEvent("recipe_shared", parameters: nil)
        incrementCounter("recipes_shared")
    }

    func trackRecipeAddedToPlan(mealType: String) {
        Analytics.logEvent("recipe_added_to_plan", parameters: [
            "meal_type": mealType,
        ])
    }

    // MARK: - Grocery Events

    func trackGroceryItemChecked(category: String) {
        Analytics.logEvent("grocery_item_checked", parameters: [
            "category": category,
        ])
        incrementCounter("grocery_items_checked")
    }

    func trackGroceryItemAdded() {
        Analytics.logEvent("grocery_item_added", parameters: nil)
    }

    func trackGroceryListShared(itemCount: Int) {
        Analytics.logEvent("grocery_list_shared", parameters: [
            "item_count": itemCount,
        ])
    }

    // MARK: - Profile Events

    func trackProfileEdited(fieldsChanged: [String]) {
        Analytics.logEvent("profile_edited", parameters: [
            "fields_changed": fieldsChanged.joined(separator: ","),
            "field_count": fieldsChanged.count,
        ])
    }

    func trackHealthKitToggled(enabled: Bool) {
        Analytics.logEvent("healthkit_toggled", parameters: [
            "enabled": enabled,
        ])
    }

    func trackNotificationsToggled(enabled: Bool) {
        Analytics.logEvent("notifications_toggled", parameters: [
            "enabled": enabled,
        ])
    }

    // MARK: - Paywall & Purchase Events

    func trackPaywallShown(source: String = "unknown") {
        Analytics.logEvent("paywall_shown", parameters: [
            "source": source,
        ])
        incrementCounter("paywalls_shown")
    }

    func trackPurchaseCompleted(planType: String) {
        Analytics.logEvent("purchase_completed", parameters: [
            "plan_type": planType,
        ])
        incrementCounter("paywalls_converted")
    }

    // MARK: - Error Events

    func trackAPIError(endpoint: String, errorType: String, statusCode: Int?) {
        var params: [String: Any] = [
            "endpoint": endpoint,
            "error_type": String(errorType.prefix(100)),
        ]
        if let code = statusCode {
            params["status_code"] = code
        }
        Analytics.logEvent("api_error", parameters: params)
    }

    func trackRateLimited(endpoint: String) {
        Analytics.logEvent("rate_limited", parameters: [
            "endpoint": endpoint,
        ])
    }

    func trackNetworkOffline(screen: String) {
        Analytics.logEvent("network_offline", parameters: [
            "screen": screen,
        ])
    }

    // MARK: - Counter Management

    private func incrementCounter(_ key: String, by amount: Int = 1) {
        counterDeltas[key, default: 0] += amount
    }

    // MARK: - Server Sync (Phase 3)

    /// Sync accumulated counters to backend
    private func syncToServer() async {
        guard !isSyncing, !counterDeltas.isEmpty else { return }
        isSyncing = true
        defer { isSyncing = false }

        // Snapshot the deltas before the async call so new increments during
        // the network request are not lost when we clear.
        let snapshot = counterDeltas

        do {
            try await APIService.shared.syncAnalytics(
                deviceId: DeviceIdentifier.shared.deviceId,
                counterDeltas: snapshot,
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
            )
            // Only subtract the values we actually sent, preserving any
            // new increments that arrived during the await.
            for (key, sentValue) in snapshot {
                if let current = counterDeltas[key] {
                    let remaining = current - sentValue
                    if remaining > 0 {
                        counterDeltas[key] = remaining
                    } else {
                        counterDeltas.removeValue(forKey: key)
                    }
                }
            }
            lastSyncDate = Date()
            #if DEBUG
            print("[Analytics] Server sync succeeded")
            #endif
        } catch {
            // Keep deltas for next sync attempt (fire-and-forget)
            #if DEBUG
            print("[Analytics] Server sync failed (will retry): \(error.localizedDescription)")
            #endif
        }
    }

    /// Stop the periodic sync timer
    func stopSyncTimer() {
        syncTimer?.invalidate()
        syncTimer = nil
    }
}
