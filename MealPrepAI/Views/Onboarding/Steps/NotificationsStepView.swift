import SwiftUI
import UserNotifications

struct NotificationsStepView: View {
    @Binding var notificationsEnabled: Bool
    let onContinue: () -> Void
    let onSkip: () -> Void

    @State private var appeared = false
    @State private var notificationPreviewShown = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Bell icon with notification badge
            ZStack {
                Circle()
                    .fill(OnboardingDesign.Colors.accent.opacity(0.15))
                    .frame(width: 120, height: 120)

                Circle()
                    .fill(OnboardingDesign.Colors.accent.opacity(0.25))
                    .frame(width: 90, height: 90)

                Image(systemName: "bell.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(OnboardingDesign.Colors.accent)

                // Notification badge
                Circle()
                    .fill(Color.red)
                    .frame(width: 16, height: 16)
                    .offset(x: 18, y: -18)
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0)
            }
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.5)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxxl)

            // Title
            Text("Never forget to prep")
                .font(OnboardingDesign.Typography.title)
                .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.md)

            // Subtitle
            Text("Get reminders for meal prep days\nand grocery trips")
                .font(OnboardingDesign.Typography.body)
                .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxl)

            // Notification preview mockup
            NotificationPreviewCard()
                .opacity(notificationPreviewShown ? 1 : 0)
                .offset(y: notificationPreviewShown ? 0 : 20)

            Spacer()

            // CTAs
            VStack(spacing: OnboardingDesign.Spacing.sm) {
                OnboardingCTAButton("Enable Notifications") {
                    requestNotificationPermission()
                }
                .opacity(appeared ? 1 : 0)

                Button {
                    notificationsEnabled = false
                    onSkip()
                } label: {
                    Text("Maybe later")
                        .font(OnboardingDesign.Typography.subheadline)
                        .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                }
                .opacity(appeared ? 1 : 0)
            }
        }
        .padding(.horizontal, OnboardingDesign.Spacing.xl)
        .padding(.bottom, OnboardingDesign.Spacing.xl)
        .onboardingBackground()
        .onAppear {
            withAnimation(OnboardingDesign.Animation.bouncy.delay(0.2)) {
                appeared = true
            }
            withAnimation(OnboardingDesign.Animation.bouncy.delay(0.5)) {
                notificationPreviewShown = true
            }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                notificationsEnabled = granted
                onContinue()
            }
        }
    }
}

// MARK: - Notification Preview Card
private struct NotificationPreviewCard: View {
    var body: some View {
        HStack(spacing: OnboardingDesign.Spacing.md) {
            // App icon
            RoundedRectangle(cornerRadius: 10)
                .fill(OnboardingDesign.Colors.accent)
                .frame(width: 44, height: 44)
                .overlay(
                    Text("M")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: OnboardingDesign.Spacing.xxs) {
                HStack {
                    Text("MealPrepAI")
                        .font(OnboardingDesign.Typography.caption)
                        .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                    Spacer()
                    Text("now")
                        .font(OnboardingDesign.Typography.captionSmall)
                        .foregroundStyle(OnboardingDesign.Colors.textTertiary)
                }

                Text("Time to meal prep!")
                    .font(OnboardingDesign.Typography.bodyMedium)
                    .foregroundStyle(OnboardingDesign.Colors.textPrimary)

                Text("Your weekly prep session starts in 30 min")
                    .font(OnboardingDesign.Typography.footnote)
                    .foregroundStyle(OnboardingDesign.Colors.textSecondary)
            }
        }
        .padding(OnboardingDesign.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: OnboardingDesign.Radius.lg)
                .fill(OnboardingDesign.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: OnboardingDesign.Radius.lg)
                .strokeBorder(OnboardingDesign.Colors.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5)
    }
}

#Preview {
    NotificationsStepView(
        notificationsEnabled: .constant(false),
        onContinue: {},
        onSkip: {}
    )
}
