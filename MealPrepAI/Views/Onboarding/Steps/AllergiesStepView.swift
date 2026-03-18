import SwiftUI

struct AllergiesStepView: View {
    @Binding var selectedAllergies: Set<Allergy>
    @Binding var customAllergies: String
    let onContinue: () -> Void

    @State private var appeared = false

    let columns = [
        GridItem(.flexible(), spacing: OnboardingDesign.Spacing.sm),
        GridItem(.flexible(), spacing: OnboardingDesign.Spacing.sm)
    ]

    // Extended list of allergies for grid display
    private let allergies = Allergy.allCases.filter { $0 != .none }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            OnboardingStepHeader(
                "Allergies",
                subtitle: "Anything your body has beef with?"
            )
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .padding(.top, OnboardingDesign.Spacing.xl)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxl)

            // Allergies grid
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: OnboardingDesign.Spacing.sm) {
                    // "None" option at the top
                    OnboardingChip("None", isSelected: selectedAllergies.isEmpty) {
                        selectedAllergies.removeAll()
                    }

                    ForEach(allergies) { allergy in
                        OnboardingChip(
                            allergy.rawValue,
                            isSelected: selectedAllergies.contains(allergy)
                        ) {
                            if selectedAllergies.contains(allergy) {
                                selectedAllergies.remove(allergy)
                            } else {
                                // Remove "none" if adding an allergy
                                selectedAllergies.insert(allergy)
                            }
                        }
                    }
                }

                // Custom allergies input
                HStack(spacing: OnboardingDesign.Spacing.xs) {
                    Image(systemName: "plus.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(OnboardingDesign.Colors.textTertiary)

                    TextField("Other allergies (e.g., kiwi, corn)", text: $customAllergies)
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
    AllergiesStepView(
        selectedAllergies: .constant([]),
        customAllergies: .constant(""),
        onContinue: {}
    )
}
