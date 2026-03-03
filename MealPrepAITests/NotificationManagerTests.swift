import Testing
import Foundation
@testable import MealPrepAI

struct NotificationManagerTests {

    @MainActor
    @Test func initStartsEmpty() {
        let manager = NotificationManager()
        #expect(manager.notifications.isEmpty)
        #expect(manager.unreadCount == 0)
        #expect(!manager.hasUnread)
    }

    @MainActor
    @Test func addNotificationInsertsAtFront() {
        let manager = NotificationManager()
        let notification = AppNotification(
            type: .goalAchieved,
            title: "Test",
            message: "Test message",
            timestamp: Date()
        )
        manager.addNotification(notification)
        #expect(manager.notifications.count == 1)
        #expect(manager.notifications.first?.title == "Test")
        #expect(manager.hasUnread)
    }

    @MainActor
    @Test func addNotificationOrderingNewestFirst() {
        let manager = NotificationManager()
        let n1 = AppNotification(type: .planGenerated, title: "First", message: "msg", timestamp: Date())
        let n2 = AppNotification(type: .planGenerated, title: "Second", message: "msg", timestamp: Date())
        manager.addNotification(n1)
        manager.addNotification(n2)
        #expect(manager.notifications.first?.title == "Second")
    }

    @MainActor
    @Test func markAsReadDecreasesUnread() {
        let manager = NotificationManager()
        let n = AppNotification(type: .goalAchieved, title: "New", message: "msg", timestamp: Date())
        manager.addNotification(n)
        #expect(manager.unreadCount == 1)
        manager.markAsRead(manager.notifications[0])
        #expect(manager.unreadCount == 0)
    }

    @MainActor
    @Test func markAllAsReadSetsAllRead() {
        let manager = NotificationManager()
        manager.addNotification(AppNotification(type: .planGenerated, title: "A", message: "m", timestamp: Date()))
        manager.addNotification(AppNotification(type: .groceryReminder, title: "B", message: "m", timestamp: Date()))
        manager.markAllAsRead()
        #expect(manager.unreadCount == 0)
        #expect(!manager.hasUnread)
    }

    @MainActor
    @Test func clearAllRemovesAllNotifications() {
        let manager = NotificationManager()
        manager.addNotification(AppNotification(type: .planGenerated, title: "A", message: "m", timestamp: Date()))
        manager.clearAll()
        #expect(manager.notifications.isEmpty)
        #expect(manager.unreadCount == 0)
    }

    @MainActor
    @Test func hasUnreadReflectsState() {
        let manager = NotificationManager()
        #expect(!manager.hasUnread)

        let n = AppNotification(type: .goalAchieved, title: "New", message: "msg", timestamp: Date())
        manager.addNotification(n)
        #expect(manager.hasUnread)
    }

    @MainActor
    @Test func cappedAt50Notifications() {
        let manager = NotificationManager()
        for i in 0..<60 {
            manager.addNotification(AppNotification(type: .planGenerated, title: "N\(i)", message: "m", timestamp: Date()))
        }
        #expect(manager.notifications.count == 50)
        #expect(manager.notifications.first?.title == "N59")
    }

    @MainActor
    @Test func persistenceRoundTrip() {
        // Clear any existing data
        UserDefaults.standard.removeObject(forKey: "com.mealprepai.notifications.v2")

        // Create a manager and add a notification
        let manager1 = NotificationManager()
        manager1.addNotification(AppNotification(type: .goalAchieved, title: "Persisted", message: "test", timestamp: Date()))
        manager1.markAsRead(manager1.notifications[0])

        // Create a new manager — it should load from UserDefaults
        let manager2 = NotificationManager()
        #expect(manager2.notifications.count == 1)
        #expect(manager2.notifications[0].title == "Persisted")
        #expect(manager2.notifications[0].isRead == true)

        // Clean up
        UserDefaults.standard.removeObject(forKey: "com.mealprepai.notifications.v2")
    }

    @MainActor
    @Test func convenienceMethodsCreateCorrectNotifications() {
        let manager = NotificationManager()

        manager.notifyPlanGenerated(planDuration: 7)
        #expect(manager.notifications[0].type == .planGenerated)
        #expect(manager.notifications[0].title == "Meal Plan Ready")

        manager.notifyGroceryListGenerated(itemCount: 15)
        #expect(manager.notifications[0].type == .groceryReminder)
        #expect(manager.notifications[0].title == "Grocery List Updated")

        manager.notifyCalorieGoalReached(calories: 2100, target: 2000)
        #expect(manager.notifications[0].type == .goalAchieved)
        #expect(manager.notifications[0].title == "Daily Calorie Goal Reached")

        manager.notifyPlanExpiring()
        #expect(manager.notifications[0].type == .mealReminder)
        #expect(manager.notifications[0].title == "Meal Plan Ending Today")

        #expect(manager.notifications.count == 4)
    }
}
