import Foundation
import SwiftUI
import UserNotifications

/// Manages in-app notifications with persistence and iOS local notification scheduling
@MainActor @Observable
final class NotificationManager {

    // MARK: - Properties

    private(set) var notifications: [AppNotification] = []

    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    var hasUnread: Bool {
        unreadCount > 0
    }

    // MARK: - Private Properties

    private let storageKey = "com.mealprepai.notifications"
    private let readStatusKey = "com.mealprepai.notificationReadStatus"
    private let center = UNUserNotificationCenter.current()

    // MARK: - Initialization

    init() {
        // Register defaults so bool reads return true when not yet set by @AppStorage
        // Build default reminder times matching NotificationSettingsView defaults
        let calendar = Calendar.current
        let breakfastDefault = calendar.date(from: DateComponents(hour: 7, minute: 30))?.timeIntervalSinceReferenceDate ?? 0
        let lunchDefault = calendar.date(from: DateComponents(hour: 12, minute: 0))?.timeIntervalSinceReferenceDate ?? 0
        let dinnerDefault = calendar.date(from: DateComponents(hour: 18, minute: 30))?.timeIntervalSinceReferenceDate ?? 0

        let defaults: [String: Any] = [
            "mealReminders": true,
            "groceryReminders": true,
            "prepReminders": true,
            "planExpiryReminder": true,
            "trialExpiryReminder": true,
            "breakfastReminderTime": breakfastDefault,
            "lunchReminderTime": lunchDefault,
            "dinnerReminderTime": dinnerDefault
        ]
        UserDefaults.standard.register(defaults: defaults)
        loadNotifications()
    }

    // MARK: - Public Methods

    /// Mark a single notification as read
    func markAsRead(_ notification: AppNotification) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].isRead = true
            saveReadStatus()
        }
    }

    /// Mark all notifications as read
    func markAllAsRead() {
        for index in notifications.indices {
            notifications[index].isRead = true
        }
        saveReadStatus()
    }

    /// Clear all notifications
    func clearAll() {
        notifications.removeAll()
        saveReadStatus()
    }

    /// Add a new notification
    func addNotification(_ notification: AppNotification) {
        notifications.insert(notification, at: 0)
        saveReadStatus()
    }

    // MARK: - Local Notification Scheduling

    /// Clears all pending notifications and re-schedules based on current settings and plan data
    func rescheduleAllNotifications(activePlan: MealPlan?, isSubscribed: Bool, trialStartDate: Date?) async {
        center.removeAllPendingNotificationRequests()

        // Only schedule if the user has granted notification permission
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }
        scheduleAll(activePlan: activePlan, isSubscribed: isSubscribed, trialStartDate: trialStartDate)
    }

    private func scheduleAll(activePlan: MealPlan?, isSubscribed: Bool, trialStartDate: Date?) {
        let defaults = UserDefaults.standard
        let mealReminders = defaults.bool(forKey: "mealReminders")
        let groceryReminders = defaults.bool(forKey: "groceryReminders")
        let prepReminders = defaults.bool(forKey: "prepReminders")
        let planExpiryReminder = defaults.bool(forKey: "planExpiryReminder")
        let trialExpiryReminder = defaults.bool(forKey: "trialExpiryReminder")

        // Trial expiry (only for non-subscribers)
        if !isSubscribed && trialExpiryReminder, let trialStart = trialStartDate {
            scheduleTrialExpiryReminder(trialStartDate: trialStart)
        }

        guard let plan = activePlan else { return }

        if planExpiryReminder {
            schedulePlanExpiryReminder(for: plan)
        }
        if groceryReminders {
            scheduleGroceryReminder(for: plan)
        }
        if prepReminders {
            schedulePrepReminders(for: plan)
        }
        if mealReminders {
            scheduleMealReminders(for: plan)
        }

        #if DEBUG
        center.getPendingNotificationRequests { requests in
            #if DEBUG
            print("📬 [NotificationManager] Scheduled \(requests.count) pending notifications")
            #endif
            for req in requests {
                #if DEBUG
                print("  - \(req.identifier): \(req.content.title)")
                #endif
            }
        }
        #endif
    }

    /// Schedule trial expiry reminder — 2 days before 7-day trial ends (i.e. 5 days after trial start)
    func scheduleTrialExpiryReminder(trialStartDate: Date) {
        let calendar = Calendar.current
        guard let fireDate = calendar.date(byAdding: .day, value: 5, to: trialStartDate),
              fireDate > Date() else { return }

        var components = calendar.dateComponents([.year, .month, .day], from: fireDate)
        components.hour = 10
        components.minute = 0

        let content = UNMutableNotificationContent()
        content.title = "Free Trial Ending Soon"
        content.body = "Your free trial ends in 2 days. Subscribe to keep creating meal plans!"
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "trial-expiry", content: content, trigger: trigger)
        center.add(request)
    }

    /// Schedule plan expiry reminder — 9 AM on the plan's last day
    func schedulePlanExpiryReminder(for plan: MealPlan) {
        let calendar = Calendar.current
        guard plan.endDate >= calendar.startOfDay(for: Date()) else { return }
        var components = calendar.dateComponents([.year, .month, .day], from: plan.endDate)
        components.hour = 9
        components.minute = 0

        let content = UNMutableNotificationContent()
        content.title = "Meal Plan Ending Today"
        content.body = "Create a new plan to stay on track with your goals!"
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "plan-expiry-\(plan.id)", content: content, trigger: trigger)
        center.add(request)
    }

    /// Schedule advance prep reminders — 8 PM the night before meals needing advance prep
    func schedulePrepReminders(for plan: MealPlan) {
        let calendar = Calendar.current
        for day in plan.sortedDays {
            for meal in day.sortedMeals {
                guard let recipe = meal.recipe, recipe.needsAdvancePrep else { continue }

                // Night before this day — skip if already past
                guard let nightBefore = calendar.date(byAdding: .day, value: -1, to: day.date),
                      nightBefore >= calendar.startOfDay(for: Date()) else { continue }
                var components = calendar.dateComponents([.year, .month, .day], from: nightBefore)
                components.hour = 20
                components.minute = 0

                let content = UNMutableNotificationContent()
                content.title = "Prep Reminder"
                content.body = "\(recipe.name) needs advance prep for tomorrow's \(meal.mealType.rawValue.lowercased())."
                content.sound = .default

                let dateString = Self.dateString(from: day.date)
                let identifier = "prep-\(dateString)-\(meal.mealType.rawValue)"
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                center.add(request)
            }
        }
    }

    /// Schedule grocery reminder — 10 AM on plan start date
    func scheduleGroceryReminder(for plan: MealPlan) {
        let calendar = Calendar.current
        guard plan.weekStartDate >= calendar.startOfDay(for: Date()) else { return }
        var components = calendar.dateComponents([.year, .month, .day], from: plan.weekStartDate)
        components.hour = 10
        components.minute = 0

        let content = UNMutableNotificationContent()
        content.title = "Grocery List Ready"
        content.body = "Your grocery list is ready — time to shop for the week!"
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "grocery-\(plan.id)", content: content, trigger: trigger)
        center.add(request)
    }

    /// Schedule daily meal reminders at user-configured times
    func scheduleMealReminders(for plan: MealPlan) {
        let calendar = Calendar.current
        let defaults = UserDefaults.standard

        // Read user-configured reminder times (stored as TimeInterval by @AppStorage)
        let breakfastTime = defaults.double(forKey: "breakfastReminderTime")
        let lunchTime = defaults.double(forKey: "lunchReminderTime")
        let dinnerTime = defaults.double(forKey: "dinnerReminderTime")

        let mealTimes: [(MealType, TimeInterval)] = [
            (.breakfast, breakfastTime),
            (.lunch, lunchTime),
            (.dinner, dinnerTime)
        ]

        let today = calendar.startOfDay(for: Date())
        for day in plan.sortedDays {
            guard day.date >= today else { continue }
            let meals = day.sortedMeals
            for (mealType, timeInterval) in mealTimes {
                guard let meal = meals.first(where: { $0.mealType == mealType }),
                      let recipe = meal.recipe else { continue }

                // Convert stored Date (as TimeInterval) to hour/minute
                // Fall back to sensible defaults if the value was never configured (0.0)
                let hour: Int
                let minute: Int
                if timeInterval == 0 {
                    switch mealType {
                    case .breakfast: hour = 7; minute = 30
                    case .lunch:     hour = 12; minute = 0
                    case .dinner:    hour = 18; minute = 30
                    default:         hour = 12; minute = 0
                    }
                } else {
                    let storedDate = Date(timeIntervalSinceReferenceDate: timeInterval)
                    let timeComponents = calendar.dateComponents([.hour, .minute], from: storedDate)
                    hour = timeComponents.hour ?? 12
                    minute = timeComponents.minute ?? 0
                }

                var components = calendar.dateComponents([.year, .month, .day], from: day.date)
                components.hour = hour
                components.minute = minute

                let content = UNMutableNotificationContent()
                content.title = "\(mealType.rawValue) Time"
                content.body = "Today's \(mealType.rawValue.lowercased()): \(recipe.name)"
                content.sound = .default

                let dateString = Self.dateString(from: day.date)
                let identifier = "meal-\(dateString)-\(mealType.rawValue)"
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                center.add(request)
            }
        }
    }

    // MARK: - Helpers

    private static let dateStringFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static func dateString(from date: Date) -> String {
        dateStringFormatter.string(from: date)
    }

    // MARK: - Private Methods (In-App Notifications)

    private func loadNotifications() {
        // Load sample notifications
        notifications = AppNotification.sampleNotifications

        // Restore read status from UserDefaults
        if let readStatusData = UserDefaults.standard.data(forKey: readStatusKey),
           let readStatus = try? JSONDecoder().decode([String: Bool].self, from: readStatusData) {
            for index in notifications.indices {
                if let isRead = readStatus[notifications[index].id.uuidString] {
                    notifications[index].isRead = isRead
                }
            }
        }
    }

    private func saveReadStatus() {
        var readStatus: [String: Bool] = [:]
        for notification in notifications {
            readStatus[notification.id.uuidString] = notification.isRead
        }

        if let data = try? JSONEncoder().encode(readStatus) {
            UserDefaults.standard.set(data, forKey: readStatusKey)
        }
    }
}
