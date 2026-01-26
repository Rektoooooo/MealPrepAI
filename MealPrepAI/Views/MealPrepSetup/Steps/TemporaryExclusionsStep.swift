import SwiftUI

// MARK: - Temporary Exclusions Step
/// Step 3: Foods to avoid THIS WEEK only (optional)
struct TemporaryExclusionsStep: View {
    @Bindable var viewModel: MealPrepSetupViewModel
    @FocusState private var isTextFieldFocused: Bool

    private let columns = [
        GridItem(.adaptive(minimum: 75), spacing: OnboardingDesign.Spacing.sm)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: OnboardingDesign.Spacing.xs) {
                OnboardingStepHeader(
                    "Anything to avoid this week?",
                    subtitle: "These won't affect your permanent preferences"
                )

                // Note about optional
                PrivacyNote("This step is optional - skip if nothing comes to mind")
            }
            .padding(.horizontal, OnboardingDesign.Spacing.lg)
            .padding(.top, OnboardingDesign.Spacing.lg)

            // Selection Grid
            ScrollView(showsIndicators: false) {
                VStack(spacing: OnboardingDesign.Spacing.lg) {
                    // Common exclusions grid
                    LazyVGrid(columns: columns, spacing: OnboardingDesign.Spacing.sm) {
                        ForEach(FoodDislike.allCases.prefix(15)) { food in
                            FoodDislikeChip(
                                food: food,
                                isSelected: viewModel.preferences.isExclusionSelected(food)
                            ) {
                                viewModel.toggleExclusion(food)
                            }
                        }
                    }

                    // Custom exclusions text field
                    VStack(alignment: .leading, spacing: OnboardingDesign.Spacing.sm) {
                        HStack {
                            Image(systemName: "text.bubble")
                                .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                            Text("Other exclusions")
                                .font(OnboardingDesign.Typography.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                        }

                        TextField(
                            "e.g., leftovers, raw fish, heavy cream",
                            text: $viewModel.preferences.customExclusions,
                            axis: .vertical
                        )
                        .textFieldStyle(.plain)
                        .lineLimit(2...3)
                        .padding(OnboardingDesign.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: OnboardingDesign.Radius.md)
                                .fill(OnboardingDesign.Colors.unselectedBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: OnboardingDesign.Radius.md)
                                        .strokeBorder(
                                            isTextFieldFocused ? OnboardingDesign.Colors.accent : Color.clear,
                                            lineWidth: 1.5
                                        )
                                )
                        )
                        .focused($isTextFieldFocused)

                        Text("Separate multiple items with commas")
                            .font(OnboardingDesign.Typography.caption)
                            .foregroundStyle(OnboardingDesign.Colors.textTertiary)
                    }
                }
                .padding(.horizontal, OnboardingDesign.Spacing.lg)
                .padding(.top, OnboardingDesign.Spacing.xl)
                .padding(.bottom, 120)
            }

            Spacer()

            // CTA Button
            VStack(spacing: OnboardingDesign.Spacing.sm) {
                // Selection summary
                if !viewModel.preferences.temporaryExclusions.isEmpty {
                    Text("\(viewModel.preferences.temporaryExclusions.count) items excluded this week")
                        .font(OnboardingDesign.Typography.caption)
                        .foregroundStyle(OnboardingDesign.Colors.textTertiary)
                }

                OnboardingCTAButton(viewModel.ctaButtonTitle) {
                    isTextFieldFocused = false
                    viewModel.goToNextStep()
                }
            }
            .padding(.horizontal, OnboardingDesign.Spacing.lg)
            .padding(.bottom, OnboardingDesign.Spacing.xxl)
        }
    }
}

// MARK: - Preview
#Preview {
    TemporaryExclusionsStep(viewModel: MealPrepSetupViewModel())
        .onboardingBackground()
}
