import SwiftUI
import HealthKit

struct HealthKitStepView: View {
    @Binding var healthKitEnabled: Bool
    let onContinue: () -> Void
    let onSkip: () -> Void

    @State private var appeared = false
    @State private var iconPulsing = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Health icon
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .scaleEffect(iconPulsing ? 1.05 : 1.0)

                Circle()
                    .fill(Color.red.opacity(0.25))
                    .frame(width: 90, height: 90)

                Image(systemName: "heart.fill")
                    .font(Design.Typography.iconSmall)
                    .foregroundStyle(Color.red)
            }
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.5)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxxl)

            // Title
            Text("Connect to Apple Health")
                .font(OnboardingDesign.Typography.title)
                .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.md)

            // Subtitle
            Text("Sync your activity data to personalize\nyour meal plans")
                .font(OnboardingDesign.Typography.body)
                .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxl)

            // Benefits
            VStack(alignment: .leading, spacing: OnboardingDesign.Spacing.md) {
                HealthBenefitRow(icon: "figure.run", text: "Adjust calories based on activity")
                HealthBenefitRow(icon: "scalemass", text: "Track weight progress automatically")
                HealthBenefitRow(icon: "fork.knife", text: "Log meals to Apple Health")
            }
            .padding(OnboardingDesign.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: OnboardingDesign.Radius.xl)
                    .fill(OnboardingDesign.Colors.cardBackground)
            )
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 30)

            Spacer()

            // Privacy note
            HStack(spacing: OnboardingDesign.Spacing.xs) {
                Image(systemName: "lock.shield.fill")
                    .font(OnboardingDesign.Typography.caption)
                Text("Your data stays on your device")
                    .font(OnboardingDesign.Typography.caption)
            }
            .foregroundStyle(OnboardingDesign.Colors.textMuted)
            .opacity(appeared ? 1 : 0)
            .padding(.bottom, OnboardingDesign.Spacing.md)

            // CTAs
            VStack(spacing: OnboardingDesign.Spacing.sm) {
                OnboardingCTAButton("Connect Apple Health") {
                    requestHealthKitPermission()
                }
                .opacity(appeared ? 1 : 0)

                Button {
                    healthKitEnabled = false
                    onSkip()
                } label: {
                    Text("Skip for now")
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
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                iconPulsing = true
            }
        }
    }

    private func requestHealthKitPermission() {
        guard HKHealthStore.isHealthDataAvailable() else {
            // HealthKit not available, continue anyway
            healthKitEnabled = false
            onContinue()
            return
        }

        let healthStore = HKHealthStore()

        // Types to read
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!
        ]

        // Types to write
        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            HKObjectType.quantityType(forIdentifier: .dietaryProtein)!,
            HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
            HKObjectType.quantityType(forIdentifier: .dietaryFatTotal)!
        ]

        healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { success, _ in
            DispatchQueue.main.async {
                healthKitEnabled = success
                onContinue()
            }
        }
    }
}

// MARK: - Health Benefit Row
private struct HealthBenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: OnboardingDesign.Spacing.md) {
            Image(systemName: icon)
                .font(OnboardingDesign.Typography.title3)
                .foregroundStyle(Color.red)
                .frame(width: 32, height: 32)

            Text(text)
                .font(OnboardingDesign.Typography.subheadline)
                .foregroundStyle(OnboardingDesign.Colors.textPrimary)
        }
    }
}

#Preview {
    HealthKitStepView(
        healthKitEnabled: .constant(false),
        onContinue: {},
        onSkip: {}
    )
}
