import SwiftUI

// MARK: - Cooking Availability Step
/// Step 4: How busy is the user this week
struct CookingAvailabilityStep: View {
    @Bindable var viewModel: MealPrepSetupViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            OnboardingStepHeader(
                "How's your week looking?",
                subtitle: "We'll adjust cooking times to fit your schedule"
            )
            .padding(.horizontal, OnboardingDesign.Spacing.lg)
            .padding(.top, OnboardingDesign.Spacing.lg)

            // Selection Cards
            ScrollView(showsIndicators: false) {
                VStack(spacing: OnboardingDesign.Spacing.md) {
                    ForEach(WeeklyBusyness.allCases) { busyness in
                        OnboardingSelectionCard(
                            title: busyness.rawValue,
                            description: busyness.shortDescription,
                            emoji: busyness.emoji,
                            isSelected: viewModel.preferences.weeklyBusyness == busyness
                        ) {
                            viewModel.setBusyness(busyness)
                        }
                    }
                }
                .padding(.horizontal, OnboardingDesign.Spacing.lg)
                .padding(.top, OnboardingDesign.Spacing.xl)
                .padding(.bottom, 120)
            }

            Spacer()

            // CTA Button
            OnboardingCTAButton(viewModel.ctaButtonTitle) {
                viewModel.goToNextStep()
            }
            .padding(.horizontal, OnboardingDesign.Spacing.lg)
            .padding(.bottom, OnboardingDesign.Spacing.xxl)
        }
    }
}

// MARK: - Preview
#Preview {
    CookingAvailabilityStep(viewModel: MealPrepSetupViewModel())
        .onboardingBackground()
}
