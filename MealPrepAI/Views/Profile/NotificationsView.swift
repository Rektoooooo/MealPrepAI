import SwiftUI

// MARK: - App Notification Model
struct AppNotification: Identifiable, Codable {
    let id: UUID
    let type: NotificationType
    let title: String
    let message: String
    let timestamp: Date
    var isRead: Bool

    init(type: NotificationType, title: String, message: String, timestamp: Date, isRead: Bool = false) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.message = message
        self.timestamp = timestamp
        self.isRead = isRead
    }

    enum NotificationType: String, Codable {
        case mealReminder
        case groceryReminder
        case planGenerated
        case goalAchieved
        case streakMilestone

        var icon: String {
            switch self {
            case .mealReminder: return "fork.knife"
            case .groceryReminder: return "cart.fill"
            case .planGenerated: return "sparkles"
            case .goalAchieved: return "star.fill"
            case .streakMilestone: return "flame.fill"
            }
        }

        var color: Color {
            switch self {
            case .mealReminder: return Color.accentPurple
            case .groceryReminder: return Color.mintVibrant
            case .planGenerated: return Color.accentPurple
            case .goalAchieved: return Color.accentYellow
            case .streakMilestone: return Color.accentOrange
            }
        }
    }
}

// MARK: - Notifications View
struct NotificationsView: View {
    @Environment(NotificationManager.self) var notificationManager
    @State private var showingSettings = false

    var body: some View {
        ScrollView {
            VStack(spacing: Design.Spacing.md) {
                if notificationManager.notifications.isEmpty {
                    emptyState
                } else {
                    // Unread section
                    let unreadNotifications = notificationManager.notifications.filter { !$0.isRead }
                    if !unreadNotifications.isEmpty {
                        notificationSection(title: "New", notifications: unreadNotifications)
                    }

                    // Read section
                    let readNotifications = notificationManager.notifications.filter { $0.isRead }
                    if !readNotifications.isEmpty {
                        notificationSection(title: "Earlier", notifications: readNotifications)
                    }
                }
            }
            .padding(.horizontal, Design.Spacing.md)
            .padding(.bottom, Design.Spacing.xxl)
        }
        .background(LinearGradient.mintBackgroundGradient.ignoresSafeArea())
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: markAllAsRead) {
                        Label("Mark All as Read", systemImage: "checkmark.circle")
                    }

                    Button(action: clearAllNotifications) {
                        Label("Clear All", systemImage: "trash")
                    }

                    Divider()

                    Button(action: { showingSettings = true }) {
                        Label("Notification Settings", systemImage: "gearshape")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(Design.Typography.bodyLarge)
                        .foregroundStyle(Color.accentPurple)
                }
                .accessibilityLabel("Notification options")
            }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                NotificationSettingsView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { showingSettings = false }
                                .foregroundStyle(Color.accentPurple)
                        }
                    }
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: Design.Spacing.lg) {
            Spacer()
                .frame(height: 60)

            ZStack {
                Circle()
                    .fill(Color.accentPurple.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "bell.slash")
                    .font(Design.Typography.heroNumberMedium)
                    .foregroundStyle(Color.accentPurple)
            }

            VStack(spacing: Design.Spacing.xs) {
                Text("No Notifications")
                    .font(Design.Typography.title3)
                    .foregroundStyle(Color.textPrimary)

                Text("You're all caught up! We'll notify you about meal reminders and updates here.")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Design.Spacing.xl)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Notification Section
    private func notificationSection(title: String, notifications: [AppNotification]) -> some View {
        VStack(alignment: .leading, spacing: Design.Spacing.sm) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.textSecondary)
                .padding(.leading, Design.Spacing.xs)

            VStack(spacing: Design.Spacing.xs) {
                ForEach(notifications) { notification in
                    NotificationRow(notification: notification) {
                        markAsRead(notification)
                    }
                }
            }
        }
    }

    // MARK: - Actions
    private func markAsRead(_ notification: AppNotification) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            notificationManager.markAsRead(notification)
        }
    }

    private func markAllAsRead() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            notificationManager.markAllAsRead()
        }
    }

    private func clearAllNotifications() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            notificationManager.clearAll()
        }
    }
}

// MARK: - Notification Row
struct NotificationRow: View {
    let notification: AppNotification
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: Design.Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(notification.type.color.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: notification.type.icon)
                        .font(Design.Typography.bodyLarge)
                        .foregroundStyle(notification.type.color)
                }

                // Content
                VStack(alignment: .leading, spacing: Design.Spacing.xxs) {
                    HStack {
                        Text(notification.title)
                            .font(.subheadline)
                            .fontWeight(notification.isRead ? .regular : .semibold)
                            .foregroundStyle(Color.textPrimary)

                        Spacer()

                        Text(notification.timestamp.timeAgoDisplay())
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }

                    Text(notification.message)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(2)
                }

                // Unread indicator
                if !notification.isRead {
                    Circle()
                        .fill(Color.accentPurple)
                        .frame(width: 8, height: 8)
                        .accessibilityHidden(true)
                }
            }
            .padding(Design.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.card)
                    .fill(notification.isRead ? Color.cardBackground.opacity(0.7) : Color.cardBackground)
                    .shadow(
                        color: Design.Shadow.card.color,
                        radius: notification.isRead ? Design.Shadow.card.radius / 2 : Design.Shadow.card.radius,
                        y: Design.Shadow.card.y
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(notification.title). \(notification.message)")
        .accessibilityValue(notification.isRead ? "Read" : "Unread")
        .accessibilityHint("Tap to mark as read")
    }
}

// MARK: - Date Extension for Time Ago
extension Date {
    func timeAgoDisplay() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: self, to: now)

        if let days = components.day, days > 0 {
            if days == 1 {
                return "Yesterday"
            } else if days < 7 {
                return "\(days)d ago"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                return formatter.string(from: self)
            }
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)h ago"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)m ago"
        } else {
            return "Just now"
        }
    }
}

#Preview {
    NavigationStack {
        NotificationsView()
            .environment(NotificationManager())
    }
}
