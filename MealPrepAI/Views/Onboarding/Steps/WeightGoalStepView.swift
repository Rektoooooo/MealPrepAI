import SwiftUI

struct WeightGoalStepView: View {
    @Binding var weightGoal: WeightGoal
    let onContinue: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            OnboardingStepHeader(
                "Goal",
                subtitle: "Goal is used to calculate your calories"
            )
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .padding(.top, OnboardingDesign.Spacing.xl)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxl)

            // Weight goal options
            VStack(spacing: OnboardingDesign.Spacing.sm) {
                ForEach(WeightGoal.allCases) { goal in
                    OnboardingSelectionCard(
                        title: goal.rawValue,
                        description: goal.description,
                        icon: goal.icon,
                        isSelected: weightGoal == goal
                    ) {
                        weightGoal = goal
                    }
                }
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 30)

            Spacer()

            // Privacy note
            PrivacyNote()
                .opacity(appeared ? 1 : 0)
                .padding(.bottom, OnboardingDesign.Spacing.md)

            // CTA
            OnboardingCTAButton("Continue") {
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

#Preview {
    WeightGoalStepView(
        weightGoal: .constant(.maintain),
        onContinue: {}
    )
}
