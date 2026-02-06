import SwiftUI

struct PrimaryGoalsStepView: View {
    @Binding var selectedGoals: Set<PrimaryGoal>
    let onContinue: () -> Void

    @State private var appeared = false

    let columns = [
        GridItem(.flexible(), spacing: OnboardingDesign.Spacing.sm),
        GridItem(.flexible(), spacing: OnboardingDesign.Spacing.sm)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            OnboardingStepHeader(
                "Goals",
                subtitle: "What goals would you like to achieve?"
            )
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .padding(.top, OnboardingDesign.Spacing.xl)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxl)

            // Goals grid
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: OnboardingDesign.Spacing.sm) {
                    ForEach(PrimaryGoal.allCases) { goal in
                        GoalChip(
                            goal: goal,
                            isSelected: selectedGoals.contains(goal)
                        ) {
                            if selectedGoals.contains(goal) {
                                selectedGoals.remove(goal)
                            } else {
                                selectedGoals.insert(goal)
                            }
                        }
                    }
                }
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 30)

            Spacer()

            // CTA
            OnboardingCTAButton("Continue", isEnabled: !selectedGoals.isEmpty) {
                onContinue()
            }
            .opacity(appeared ? 1 : 0)
        }
        .padding(.horizontal, OnboardingDesign.Spacing.xl)
        .padding(.bottom, OnboardingDesign.Spacing.xl)
        .onboardingBackground()
        .onAppear {
            withAnimation(OnboardingDesign.Animation.bouncy.delay(0.2)) {
                appeared = true
            }
        }
    }
}

// MARK: - Goal Chip
private struct GoalChip: View {
    let goal: PrimaryGoal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            hapticFeedback(.light)
            action()
        }) {
            HStack(spacing: OnboardingDesign.Spacing.sm) {
                Text(goal.emoji)
                    .font(OnboardingDesign.Typography.title3)

                Text(goal.rawValue)
                    .font(OnboardingDesign.Typography.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isSelected ? OnboardingDesign.Colors.textOnDark : OnboardingDesign.Colors.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 56)
            .padding(.horizontal, OnboardingDesign.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: OnboardingDesign.Radius.md)
                    .fill(isSelected ? OnboardingDesign.Colors.accent : OnboardingDesign.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: OnboardingDesign.Radius.md)
                    .strokeBorder(
                        isSelected ? OnboardingDesign.Colors.accent : OnboardingDesign.Colors.cardBorder,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(OnboardingScaleButtonStyle())
    }

    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

#Preview {
    PrimaryGoalsStepView(
        selectedGoals: .constant([.eatHealthy]),
        onContinue: {}
    )
}
