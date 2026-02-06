import SwiftUI

// MARK: - Meal Prep Welcome Step
/// Step 1: Welcome screen with quick start option for returning users
struct MealPrepWelcomeStep: View {
    @Bindable var viewModel: MealPrepSetupViewModel

    var body: some View {
        VStack(spacing: OnboardingDesign.Spacing.xl) {
            Spacer()

            // Hero Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentPurple.opacity(0.2), Color.accentPurple.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentPurple.opacity(0.3), Color.accentPurple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "sparkles")
                    .font(Design.Typography.heroNumberMedium).fontWeight(.medium)
                    .foregroundStyle(Color.accentPurple)
            }
            .accessibilityHidden(true)

            // Title & Subtitle
            VStack(spacing: OnboardingDesign.Spacing.sm) {
                Text("Let's Set Up Your Week")
                    .font(OnboardingDesign.Typography.title)
                    .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Tell us your priorities and we'll create a personalized meal plan just for you.")
                    .font(OnboardingDesign.Typography.subheadline)
                    .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, OnboardingDesign.Spacing.xl)
            }

            Spacer()

            // Action Buttons
            VStack(spacing: OnboardingDesign.Spacing.md) {
                // Show quick start for returning users
                if viewModel.showQuickStartOption {
                    // Quick Start Button
                    Button(action: {
                        hapticFeedback(.medium)
                        viewModel.skipToReview()
                    }) {
                        HStack(spacing: OnboardingDesign.Spacing.sm) {
                            Image(systemName: "bolt.fill")
                                .font(OnboardingDesign.Typography.body).fontWeight(.semibold)
                            Text("Use Previous Preferences")
                                .font(OnboardingDesign.Typography.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, OnboardingDesign.Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: OnboardingDesign.Radius.xl)
                                .fill(OnboardingDesign.Colors.accent)
                        )
                    }
                    .accessibilityHint("Skips customization and uses your saved preferences")

                    // Previous preferences summary
                    Text(MealPrepPreferencesStore.shared.summary)
                        .font(OnboardingDesign.Typography.caption)
                        .foregroundStyle(OnboardingDesign.Colors.textTertiary)
                        .padding(.bottom, OnboardingDesign.Spacing.xs)

                    // Customize option
                    Button(action: {
                        hapticFeedback(.light)
                        viewModel.goToNextStep()
                    }) {
                        Text("Customize This Week")
                            .font(OnboardingDesign.Typography.headline)
                            .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, OnboardingDesign.Spacing.lg)
                            .background(
                                RoundedRectangle(cornerRadius: OnboardingDesign.Radius.xl)
                                    .fill(OnboardingDesign.Colors.unselectedBackground)
                            )
                    }
                    .accessibilityHint("Opens step-by-step customization for this week's meal plan")
                } else {
                    // First time user - single CTA
                    OnboardingCTAButton("Let's Go") {
                        viewModel.goToNextStep()
                    }
                }
            }
            .padding(.horizontal, OnboardingDesign.Spacing.lg)
            .padding(.bottom, OnboardingDesign.Spacing.xxl)
        }
    }

    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Preview
#Preview {
    MealPrepWelcomeStep(viewModel: MealPrepSetupViewModel())
        .onboardingBackground()
}
