import SwiftUI

struct DislikesStepView: View {
    @Binding var selectedDislikes: Set<FoodDislike>
    @Binding var customDislikes: String
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
                subtitle: "What makes you go \"absolutely not\"?"
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

                // Custom dislikes input
                HStack(spacing: OnboardingDesign.Spacing.xs) {
                    Image(systemName: "plus.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(OnboardingDesign.Colors.textTertiary)

                    TextField("Other dislikes (e.g., liver, okra)", text: $customDislikes)
                        .font(OnboardingDesign.Typography.subheadline)
                        .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                }
                .padding(.horizontal, OnboardingDesign.Spacing.md)
                .padding(.vertical, OnboardingDesign.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: OnboardingDesign.Radius.sm)
                        .fill(OnboardingDesign.Colors.unselectedBackground)
                )
                .padding(.top, OnboardingDesign.Spacing.sm)
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
        customDislikes: .constant(""),
        onContinue: {}
    )
}
