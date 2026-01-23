import SwiftUI

// MARK: - Step 7: Cooking Preferences
struct CookingPreferencesStep: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Design.Spacing.xl) {
                OnboardingHeader(
                    icon: "frying.pan.fill",
                    title: "Cooking Preferences",
                    subtitle: "Help us match recipes to your skill level and available time."
                )

                // Skill Level Section
                VStack(alignment: .leading, spacing: Design.Spacing.md) {
                    Text("Cooking Skill")
                        .font(Design.Typography.headline)
                        .foregroundStyle(Color.textPrimary)

                    ForEach(CookingSkill.allCases) { skill in
                        PremiumGoalRow(
                            icon: skill.icon,
                            title: skill.rawValue,
                            description: skill.description,
                            isSelected: viewModel.cookingSkill == skill
                        ) {
                            hapticSelection()
                            withAnimation(Design.Animation.bouncy) {
                                viewModel.cookingSkill = skill
                            }
                        }
                    }
                }

                // Max Cooking Time Section
                VStack(alignment: .leading, spacing: Design.Spacing.md) {
                    Text("Max Cooking Time")
                        .font(Design.Typography.headline)
                        .foregroundStyle(Color.textPrimary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Design.Spacing.sm) {
                            ForEach(CookingTime.allCases) { time in
                                PremiumTimeChip(
                                    title: time.rawValue,
                                    isSelected: viewModel.maxCookingTime == time
                                ) {
                                    hapticSelection()
                                    withAnimation(Design.Animation.bouncy) {
                                        viewModel.maxCookingTime = time
                                    }
                                }
                            }
                        }
                    }
                }

                // Simple Mode Toggle
                HStack {
                    VStack(alignment: .leading, spacing: Design.Spacing.xxs) {
                        Text("Simple Mode")
                            .font(Design.Typography.headline)
                            .foregroundStyle(Color.textPrimary)
                        Text("Prefer recipes with fewer ingredients and steps")
                            .font(Design.Typography.caption)
                            .foregroundStyle(Color.textSecondary)
                    }

                    Spacer()

                    Toggle("", isOn: $viewModel.simpleModeEnabled)
                        .tint(Color.accentPurple)
                        .labelsHidden()
                }
                .premiumCard()
            }
            .padding(Design.Spacing.lg)
        }
    }

    private func hapticSelection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
