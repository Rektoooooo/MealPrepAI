import SwiftUI
import SwiftData
import UserNotifications

struct NotificationSettingsView: View {
    @State private var notificationsEnabled = false
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var isCheckingPermission = true

    @Environment(NotificationManager.self) private var notificationManager
    @Environment(SubscriptionManager.self) private var subscriptionManager

    @AppStorage("mealReminders") private var mealReminders = true
    @AppStorage("groceryReminders") private var groceryReminders = true
    @AppStorage("weeklyDigest") private var weeklyDigest = false
    @AppStorage("tipsAndSuggestions") private var tipsAndSuggestions = true
    @AppStorage("prepReminders") private var prepReminders = true
    @AppStorage("planExpiryReminder") private var planExpiryReminder = true
    @AppStorage("trialExpiryReminder") private var trialExpiryReminder = true
    @AppStorage("breakfastReminderTime") private var breakfastReminderTime = Calendar.current.date(from: DateComponents(hour: 7, minute: 30)) ?? Date()
    @AppStorage("lunchReminderTime") private var lunchReminderTime = Calendar.current.date(from: DateComponents(hour: 12, minute: 0)) ?? Date()
    @AppStorage("dinnerReminderTime") private var dinnerReminderTime = Calendar.current.date(from: DateComponents(hour: 18, minute: 30)) ?? Date()

    @Query(filter: #Predicate<MealPlan> { $0.isActive }) private var activePlans: [MealPlan]
    @Environment(\.userProfile) private var userProfile

    var body: some View {
        ScrollView {
            VStack(spacing: Design.Spacing.lg) {
                // Permission Status Section
                permissionSection

                // Only show settings if notifications are authorized
                if authorizationStatus == .authorized {
                    // Meal Reminders Section
                    mealRemindersSection

                    // Other Notifications Section
                    otherNotificationsSection
                }
            }
            .padding(.horizontal, Design.Spacing.md)
            .padding(.bottom, Design.Spacing.xxl)
        }
        .background(LinearGradient.mintBackgroundGradient.ignoresSafeArea())
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkNotificationPermission()
        }
        .onChange(of: mealReminders) { _, _ in triggerReschedule() }
        .onChange(of: groceryReminders) { _, _ in triggerReschedule() }
        .onChange(of: prepReminders) { _, _ in triggerReschedule() }
        .onChange(of: planExpiryReminder) { _, _ in triggerReschedule() }
        .onChange(of: trialExpiryReminder) { _, _ in triggerReschedule() }
        .onChange(of: breakfastReminderTime) { _, _ in triggerReschedule() }
        .onChange(of: lunchReminderTime) { _, _ in triggerReschedule() }
        .onChange(of: dinnerReminderTime) { _, _ in triggerReschedule() }
    }

    // MARK: - Permission Section
    private var permissionSection: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            NewSectionHeader(title: "Permission", icon: "bell.badge.fill", iconColor: Color.accentPurple)

            VStack(spacing: Design.Spacing.sm) {
                HStack(spacing: Design.Spacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(statusColor.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: statusIcon)
                            .font(Design.Typography.callout)
                            .foregroundStyle(statusColor)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Push Notifications")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.textPrimary)

                        Text(statusMessage)
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }

                    Spacer()

                    if isCheckingPermission {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        switch authorizationStatus {
                        case .notDetermined:
                            Button("Enable") {
                                requestNotificationPermission()
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.accentPurple)
                            .clipShape(Capsule())

                        case .denied:
                            Button("Settings") {
                                openSettings()
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.accentPurple)

                        case .authorized, .provisional, .ephemeral:
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color.mintVibrant)

                        @unknown default:
                            EmptyView()
                        }
                    }
                }

                if authorizationStatus == .denied {
                    Divider()
                        .padding(.vertical, Design.Spacing.xxs)

                    HStack(spacing: Design.Spacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(Color.accentYellow)

                        Text("Notifications are disabled. Open Settings to enable them for MealPrepAI.")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
            .padding(Design.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.card)
                    .fill(Color.cardBackground)
                    .shadow(
                        color: Design.Shadow.card.color,
                        radius: Design.Shadow.card.radius,
                        y: Design.Shadow.card.y
                    )
            )
        }
    }

    // MARK: - Meal Reminders Section
    private var mealRemindersSection: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            NewSectionHeader(title: "Meal Reminders", icon: "fork.knife", iconColor: Color.accentYellow)

            VStack(spacing: Design.Spacing.sm) {
                // Master Toggle
                HStack(spacing: Design.Spacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.accentYellow.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: "bell.fill")
                            .font(Design.Typography.callout)
                            .foregroundStyle(Color.accentYellow)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Meal Reminders")
                            .font(.subheadline)
                            .foregroundStyle(Color.textPrimary)

                        Text("Get reminded before each meal")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }

                    Spacer()

                    Toggle("", isOn: $mealReminders)
                        .labelsHidden()
                        .tint(Color.accentPurple)
                        .accessibilityLabel("Meal Reminders")
                        .accessibilityValue(mealReminders ? "On" : "Off")
                }

                if mealReminders {
                    Divider()
                        .padding(.vertical, Design.Spacing.xxs)
                        .accessibilityHidden(true)

                    // Breakfast Time
                    reminderTimeRow(
                        icon: "sunrise.fill",
                        color: Color.accentYellow,
                        title: "Breakfast",
                        time: $breakfastReminderTime
                    )

                    Divider()
                        .padding(.vertical, Design.Spacing.xxs)

                    // Lunch Time
                    reminderTimeRow(
                        icon: "sun.max.fill",
                        color: Color.accentOrange,
                        title: "Lunch",
                        time: $lunchReminderTime
                    )

                    Divider()
                        .padding(.vertical, Design.Spacing.xxs)

                    // Dinner Time
                    reminderTimeRow(
                        icon: "moon.fill",
                        color: Color.accentPurple,
                        title: "Dinner",
                        time: $dinnerReminderTime
                    )
                }
            }
            .padding(Design.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.card)
                    .fill(Color.cardBackground)
                    .shadow(
                        color: Design.Shadow.card.color,
                        radius: Design.Shadow.card.radius,
                        y: Design.Shadow.card.y
                    )
            )
        }
    }

    // MARK: - Other Notifications Section
    private var otherNotificationsSection: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            NewSectionHeader(title: "Other Notifications", icon: "bell.circle.fill", iconColor: Color.textSecondary)

            VStack(spacing: Design.Spacing.sm) {
                // Grocery Reminders
                HStack(spacing: Design.Spacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.mintVibrant.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: "cart.fill")
                            .font(Design.Typography.callout)
                            .foregroundStyle(Color.mintVibrant)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Grocery Reminders")
                            .font(.subheadline)
                            .foregroundStyle(Color.textPrimary)

                        Text("Remind to shop before groceries run out")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }

                    Spacer()

                    Toggle("", isOn: $groceryReminders)
                        .labelsHidden()
                        .tint(Color.accentPurple)
                        .accessibilityLabel("Grocery Reminders")
                        .accessibilityValue(groceryReminders ? "On" : "Off")
                }

                Divider()
                    .padding(.vertical, Design.Spacing.xxs)
                    .accessibilityHidden(true)

                // Advance Prep Reminders
                HStack(spacing: Design.Spacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.accentYellow.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: "clock.arrow.circlepath")
                            .font(Design.Typography.callout)
                            .foregroundStyle(Color.accentYellow)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Advance Prep Reminders")
                            .font(.subheadline)
                            .foregroundStyle(Color.textPrimary)

                        Text("8 PM alert for meals needing overnight prep")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }

                    Spacer()

                    Toggle("", isOn: $prepReminders)
                        .labelsHidden()
                        .tint(Color.accentPurple)
                        .accessibilityLabel("Advance Prep Reminders")
                        .accessibilityValue(prepReminders ? "On" : "Off")
                }

                Divider()
                    .padding(.vertical, Design.Spacing.xxs)
                    .accessibilityHidden(true)

                // Plan Expiry Reminder
                HStack(spacing: Design.Spacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.accentPurple.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(Design.Typography.callout)
                            .foregroundStyle(Color.accentPurple)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Plan Expiry Reminder")
                            .font(.subheadline)
                            .foregroundStyle(Color.textPrimary)

                        Text("Remind when your meal plan is ending")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }

                    Spacer()

                    Toggle("", isOn: $planExpiryReminder)
                        .labelsHidden()
                        .tint(Color.accentPurple)
                        .accessibilityLabel("Plan Expiry Reminder")
                        .accessibilityValue(planExpiryReminder ? "On" : "Off")
                }

                // Trial Expiry Reminder (only for non-subscribers)
                if !subscriptionManager.isSubscribed {
                    Divider()
                        .padding(.vertical, Design.Spacing.xxs)

                    HStack(spacing: Design.Spacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: "FF6B6B").opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "hourglass")
                                .font(Design.Typography.callout)
                                .foregroundStyle(Color(hex: "FF6B6B"))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Trial Expiry Reminder")
                                .font(.subheadline)
                                .foregroundStyle(Color.textPrimary)

                            Text("Remind before your free trial ends")
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                        }

                        Spacer()

                        Toggle("", isOn: $trialExpiryReminder)
                            .labelsHidden()
                            .tint(Color.accentPurple)
                            .accessibilityLabel("Trial Expiry Reminder")
                            .accessibilityValue(trialExpiryReminder ? "On" : "Off")
                    }
                }

                Divider()
                    .padding(.vertical, Design.Spacing.xxs)
                    .accessibilityHidden(true)

                // Weekly Digest
                HStack(spacing: Design.Spacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.accentBlue.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: "chart.bar.fill")
                            .font(Design.Typography.callout)
                            .foregroundStyle(Color.accentBlue)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Weekly Digest")
                            .font(.subheadline)
                            .foregroundStyle(Color.textPrimary)

                        Text("Summary of your weekly progress")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }

                    Spacer()

                    Toggle("", isOn: $weeklyDigest)
                        .labelsHidden()
                        .tint(Color.accentPurple)
                        .accessibilityLabel("Weekly Digest")
                        .accessibilityValue(weeklyDigest ? "On" : "Off")
                }

                Divider()
                    .padding(.vertical, Design.Spacing.xxs)
                    .accessibilityHidden(true)

                // Tips & Suggestions
                HStack(spacing: Design.Spacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.accentOrange.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: "lightbulb.fill")
                            .font(Design.Typography.callout)
                            .foregroundStyle(Color.accentOrange)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tips & Suggestions")
                            .font(.subheadline)
                            .foregroundStyle(Color.textPrimary)

                        Text("Helpful meal prep tips and ideas")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }

                    Spacer()

                    Toggle("", isOn: $tipsAndSuggestions)
                        .labelsHidden()
                        .tint(Color.accentPurple)
                        .accessibilityLabel("Tips and Suggestions")
                        .accessibilityValue(tipsAndSuggestions ? "On" : "Off")
                }
            }
            .padding(Design.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.card)
                    .fill(Color.cardBackground)
                    .shadow(
                        color: Design.Shadow.card.color,
                        radius: Design.Shadow.card.radius,
                        y: Design.Shadow.card.y
                    )
            )
        }
    }

    // MARK: - Helper Views
    private func reminderTimeRow(icon: String, color: Color, title: String, time: Binding<Date>) -> some View {
        HStack(spacing: Design.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(Design.Typography.callout)
                    .foregroundStyle(color)
            }

            Text(title)
                .font(.subheadline)
                .foregroundStyle(Color.textPrimary)

            Spacer()

            DatePicker("", selection: time, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(Color.accentPurple)
                .accessibilityLabel("\(title) reminder time")
        }
    }

    // MARK: - Computed Properties
    private var statusColor: Color {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return Color.mintVibrant
        case .denied:
            return Color(hex: "FF6B6B")
        case .notDetermined:
            return Color.accentYellow
        @unknown default:
            return Color.textSecondary
        }
    }

    private var statusIcon: String {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return "checkmark.circle.fill"
        case .denied:
            return "xmark.circle.fill"
        case .notDetermined:
            return "questionmark.circle.fill"
        @unknown default:
            return "bell.fill"
        }
    }

    private var statusMessage: String {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return "Notifications are enabled"
        case .denied:
            return "Notifications are disabled"
        case .notDetermined:
            return "Enable to receive reminders"
        @unknown default:
            return "Unknown status"
        }
    }

    // MARK: - Actions
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
                self.notificationsEnabled = settings.authorizationStatus == .authorized
                self.isCheckingPermission = false
            }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.authorizationStatus = granted ? .authorized : .denied
                self.notificationsEnabled = granted
                if granted {
                    self.triggerReschedule()
                }
            }
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func triggerReschedule() {
        let plan = activePlans.first
        Task {
            await notificationManager.rescheduleAllNotifications(
                activePlan: plan,
                isSubscribed: subscriptionManager.isSubscribed,
                trialStartDate: userProfile?.createdAt
            )
        }
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
    .environment(NotificationManager())
    .environment(SubscriptionManager())
    .modelContainer(for: [MealPlan.self, UserProfile.self], inMemory: true)
}
