import SwiftUI

struct ActivityLevelStepView: View {
    @Binding var activityLevel: ActivityLevel
    let onContinue: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            OnboardingStepHeader(
                "Activity level",
                subtitle: "How often do you exercise?"
            )
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .padding(.top, OnboardingDesign.Spacing.xl)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxl)

            // Options
            VStack(spacing: OnboardingDesign.Spacing.sm) {
                ForEach(ActivityLevel.allCases) { level in
                    OnboardingSelectionCard(
                        title: level.rawValue,
                        description: level.description,
                        icon: level.icon,
                        isSelected: activityLevel == level
                    ) {
                        activityLevel = level
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
    ActivityLevelStepView(
        activityLevel: .constant(.moderate),
        onContinue: {}
    )
}
