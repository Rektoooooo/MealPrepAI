import SwiftUI

// MARK: - Step 3: Goals
struct GoalsStep: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Design.Spacing.xl) {
                OnboardingHeader(
                    icon: "target",
                    title: "Your Goals",
                    subtitle: "What would you like to achieve with your meal plan?"
                )

                // Weight Goal Section
                VStack(alignment: .leading, spacing: Design.Spacing.md) {
                    Text("Weight Goal")
                        .font(Design.Typography.headline)
                        .foregroundStyle(Color.textPrimary)

                    ForEach(WeightGoal.allCases) { goal in
                        PremiumGoalRow(
                            icon: goal.icon,
                            title: goal.rawValue,
                            description: goal.description,
                            isSelected: viewModel.weightGoal == goal
                        ) {
                            hapticSelection()
                            withAnimation(Design.Animation.bouncy) {
                                viewModel.weightGoal = goal
                            }
                        }
                    }
                }

                // Activity Level Section
                VStack(alignment: .leading, spacing: Design.Spacing.md) {
                    Text("Activity Level")
                        .font(Design.Typography.headline)
                        .foregroundStyle(Color.textPrimary)

                    ForEach(ActivityLevel.allCases) { level in
                        PremiumGoalRow(
                            icon: level.icon,
                            title: level.rawValue,
                            description: level.description,
                            isSelected: viewModel.activityLevel == level
                        ) {
                            hapticSelection()
                            withAnimation(Design.Animation.bouncy) {
                                viewModel.activityLevel = level
                            }
                        }
                    }
                }
            }
            .padding(Design.Spacing.lg)
        }
    }

    private func hapticSelection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
