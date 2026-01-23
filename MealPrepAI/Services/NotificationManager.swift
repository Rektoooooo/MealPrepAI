import Foundation
import SwiftUI

/// Manages in-app notifications with persistence
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

    // MARK: - Initialization

    init() {
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

    // MARK: - Private Methods

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
