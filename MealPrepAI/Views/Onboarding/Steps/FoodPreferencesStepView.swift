import SwiftUI

struct FoodPreferencesStepView: View {
    @Binding var dietaryRestriction: DietaryRestriction
    let onContinue: () -> Void

    @State private var appeared = false

    // Subset of dietary restrictions for onboarding (simplified)
    private let options: [(DietaryRestriction, String)] = [
        (.none, "Meat, veg, seafood, everything!"),
        (.vegetarian, "No meat or seafood"),
        (.vegan, "No animal products"),
        (.pescatarian, "Seafood but no meat"),
        (.keto, "Low carb, high fat")
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            OnboardingStepHeader(
                "Food preferences",
                subtitle: "Any food preferences?"
            )
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .padding(.top, OnboardingDesign.Spacing.xl)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxl)

            // Options
            VStack(spacing: OnboardingDesign.Spacing.sm) {
                ForEach(options, id: \.0) { option, description in
                    let title = option == .none ? "Flexible" : option.rawValue
                    OnboardingSelectionCard(
                        title: title,
                        description: description,
                        isSelected: dietaryRestriction == option
                    ) {
                        dietaryRestriction = option
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
    FoodPreferencesStepView(
        dietaryRestriction: .constant(.none),
        onContinue: {}
    )
}
