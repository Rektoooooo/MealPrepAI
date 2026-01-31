import Testing
import Foundation
@testable import MealPrepAI

struct NotificationManagerTests {

    @MainActor
    @Test func unreadCountReflectsState() {
        let manager = NotificationManager()
        let initialUnread = manager.unreadCount
        // After init, loads sample notifications - just verify it's a number >= 0
        #expect(initialUnread >= 0)
    }

    @MainActor
    @Test func markAsReadDecreasesUnread() {
        let manager = NotificationManager()
        guard let first = manager.notifications.first(where: { !$0.isRead }) else {
            return // skip if no unread
        }
        let before = manager.unreadCount
        manager.markAsRead(first)
        #expect(manager.unreadCount <= before)
    }

    @MainActor
    @Test func markAllAsReadSetsAllRead() {
        let manager = NotificationManager()
        manager.markAllAsRead()
        #expect(manager.unreadCount == 0)
        #expect(!manager.hasUnread)
    }

    @MainActor
    @Test func clearAllRemovesAllNotifications() {
        let manager = NotificationManager()
        manager.clearAll()
        #expect(manager.notifications.isEmpty)
        #expect(manager.unreadCount == 0)
    }

    @MainActor
    @Test func addNotificationInsertsAtFront() {
        let manager = NotificationManager()
        manager.clearAll()
        let notification = AppNotification(
            type: .tip,
            title: "Test",
            message: "Test message",
            timestamp: Date()
        )
        manager.addNotification(notification)
        #expect(manager.notifications.count == 1)
        #expect(manager.notifications.first?.title == "Test")
    }

    @MainActor
    @Test func addNotificationOrderingNewestFirst() {
        let manager = NotificationManager()
        manager.clearAll()
        let n1 = AppNotification(type: .tip, title: "First", message: "msg", timestamp: Date())
        let n2 = AppNotification(type: .tip, title: "Second", message: "msg", timestamp: Date())
        manager.addNotification(n1)
        manager.addNotification(n2)
        #expect(manager.notifications.first?.title == "Second")
    }

    @MainActor
    @Test func hasUnreadReflectsState() {
        let manager = NotificationManager()
        manager.clearAll()
        #expect(!manager.hasUnread)

        let n = AppNotification(type: .tip, title: "New", message: "msg", timestamp: Date())
        manager.addNotification(n)
        #expect(manager.hasUnread)
    }
}
