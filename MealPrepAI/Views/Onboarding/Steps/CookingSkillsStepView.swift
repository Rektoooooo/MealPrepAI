import SwiftUI

struct CookingSkillsStepView: View {
    @Binding var cookingSkill: CookingSkill
    let onContinue: () -> Void

    @State private var appeared = false

    private let skillDescriptions: [CookingSkill: String] = [
        .beginner: "I think I know where the microwave is",
        .intermediate: "Comfortable with simple recipes",
        .advanced: "Comfortable with most recipes",
        .chef: "I should be on MasterChef"
    ]

    private let skillLabels: [CookingSkill: String] = [
        .beginner: "Novice",
        .intermediate: "Beginner",
        .advanced: "Intermediate",
        .chef: "Advanced"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            OnboardingStepHeader(
                "Cooking skills",
                subtitle: "How would you rate your cooking skills?"
            )
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .padding(.top, OnboardingDesign.Spacing.xl)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxl)

            // Skill options
            VStack(spacing: OnboardingDesign.Spacing.sm) {
                ForEach(CookingSkill.allCases) { skill in
                    OnboardingSelectionCard(
                        title: skillLabels[skill] ?? skill.rawValue,
                        description: skillDescriptions[skill],
                        isSelected: cookingSkill == skill
                    ) {
                        cookingSkill = skill
                    }
                }
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 30)

            Spacer()

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
    CookingSkillsStepView(
        cookingSkill: .constant(.intermediate),
        onContinue: {}
    )
}
