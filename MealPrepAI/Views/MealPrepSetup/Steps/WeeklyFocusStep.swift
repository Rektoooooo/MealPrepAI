import SwiftUI

// MARK: - Weekly Focus Step
/// Step 2: Select 1-3 weekly focus areas
struct WeeklyFocusStep: View {
    @Bindable var viewModel: MealPrepSetupViewModel

    private let columns = [
        GridItem(.flexible(), spacing: OnboardingDesign.Spacing.sm),
        GridItem(.flexible(), spacing: OnboardingDesign.Spacing.sm)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            OnboardingStepHeader(
                "What's your focus this week?",
                subtitle: "Select 1-3 priorities for your meal plan"
            )
            .padding(.horizontal, OnboardingDesign.Spacing.lg)
            .padding(.top, OnboardingDesign.Spacing.lg)

            // Selection Grid
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: OnboardingDesign.Spacing.sm) {
                    ForEach(WeeklyFocus.allCases) { focus in
                        WeeklyFocusChip(
                            focus: focus,
                            isSelected: viewModel.preferences.isFocusSelected(focus)
                        ) {
                            viewModel.toggleFocus(focus)
                        }
                    }
                }
                .padding(.horizontal, OnboardingDesign.Spacing.lg)
                .padding(.top, OnboardingDesign.Spacing.xl)
                .padding(.bottom, 120) // Space for button
            }

            Spacer()

            // CTA Button
            VStack(spacing: OnboardingDesign.Spacing.sm) {
                // Selection count
                HStack(spacing: OnboardingDesign.Spacing.xs) {
                    Text("\(viewModel.preferences.weeklyFocus.count)/3 selected")
                        .font(OnboardingDesign.Typography.caption)
                        .foregroundStyle(OnboardingDesign.Colors.textTertiary)

                    if viewModel.preferences.weeklyFocus.count >= 3 {
                        Text("(max)")
                            .font(OnboardingDesign.Typography.caption)
                            .foregroundStyle(OnboardingDesign.Colors.success)
                    }
                }

                OnboardingCTAButton(
                    viewModel.ctaButtonTitle,
                    isEnabled: viewModel.canProceed
                ) {
                    viewModel.goToNextStep()
                }
            }
            .padding(.horizontal, OnboardingDesign.Spacing.lg)
            .padding(.bottom, OnboardingDesign.Spacing.xxl)
        }
    }
}

// MARK: - Weekly Focus Chip
struct WeeklyFocusChip: View {
    let focus: WeeklyFocus
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            hapticFeedback(.light)
            action()
        }) {
            VStack(spacing: OnboardingDesign.Spacing.xs) {
                Text(focus.emoji)
                    .font(.system(size: 28))

                Text(focus.rawValue)
                    .font(OnboardingDesign.Typography.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? OnboardingDesign.Colors.textOnDark : OnboardingDesign.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Text(focus.shortDescription)
                    .font(OnboardingDesign.Typography.captionSmall)
                    .foregroundStyle(isSelected ? OnboardingDesign.Colors.textOnDark.opacity(0.7) : OnboardingDesign.Colors.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, OnboardingDesign.Spacing.md)
            .padding(.horizontal, OnboardingDesign.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: OnboardingDesign.Radius.lg)
                    .fill(isSelected ? OnboardingDesign.Colors.selectedBackground : OnboardingDesign.Colors.unselectedBackground)
            )
        }
        .buttonStyle(OnboardingScaleButtonStyle())
    }

    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Preview
#Preview {
    WeeklyFocusStep(viewModel: MealPrepSetupViewModel())
        .onboardingBackground()
}
