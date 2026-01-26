import SwiftUI

struct DislikesStepView: View {
    @Binding var selectedDislikes: Set<FoodDislike>
    let onContinue: () -> Void

    @State private var appeared = false

    let columns = [
        GridItem(.flexible(), spacing: OnboardingDesign.Spacing.sm),
        GridItem(.flexible(), spacing: OnboardingDesign.Spacing.sm),
        GridItem(.flexible(), spacing: OnboardingDesign.Spacing.sm)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            OnboardingStepHeader(
                "Dislikes",
                subtitle: "Any foods you don't like?"
            )
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .padding(.top, OnboardingDesign.Spacing.xl)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xl)

            // Dislikes grid
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: OnboardingDesign.Spacing.sm) {
                    ForEach(FoodDislike.allCases) { food in
                        FoodDislikeChip(
                            food: food,
                            isSelected: selectedDislikes.contains(food)
                        ) {
                            if selectedDislikes.contains(food) {
                                selectedDislikes.remove(food)
                            } else {
                                selectedDislikes.insert(food)
                            }
                        }
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
    DislikesStepView(
        selectedDislikes: .constant([.mushrooms]),
        onContinue: {}
    )
}
