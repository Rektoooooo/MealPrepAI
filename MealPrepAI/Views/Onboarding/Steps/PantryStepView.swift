import SwiftUI

struct PantryStepView: View {
    @Binding var pantryLevel: PantryLevel
    let onContinue: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            OnboardingStepHeader(
                "Your pantry",
                subtitle: "How well-stocked is your kitchen?"
            )
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .padding(.top, OnboardingDesign.Spacing.xl)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxl)

            // Pantry options
            VStack(spacing: OnboardingDesign.Spacing.sm) {
                ForEach(PantryLevel.allCases) { level in
                    OnboardingSelectionCard(
                        title: level.rawValue,
                        description: level.description,
                        icon: level.icon,
                        isSelected: pantryLevel == level
                    ) {
                        pantryLevel = level
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
    PantryStepView(
        pantryLevel: .constant(.average),
        onContinue: {}
    )
}
