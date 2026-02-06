import SwiftUI

struct BarriersStepView: View {
    @Binding var selectedBarriers: Set<Barrier>
    let onContinue: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            OnboardingStepHeader(
                "What's stopping you?",
                subtitle: "Select all that apply"
            )
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .padding(.top, OnboardingDesign.Spacing.xl)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxl)

            // Barriers grid
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: OnboardingDesign.Spacing.sm
            ) {
                ForEach(Barrier.allCases) { barrier in
                    BarrierCard(
                        barrier: barrier,
                        isSelected: selectedBarriers.contains(barrier)
                    ) {
                        if selectedBarriers.contains(barrier) {
                            selectedBarriers.remove(barrier)
                        } else {
                            selectedBarriers.insert(barrier)
                        }
                    }
                }
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 30)

            Spacer()

            // Encouragement text
            if !selectedBarriers.isEmpty {
                Text("Don't worry, MealPrepAI helps with all of these!")
                    .font(OnboardingDesign.Typography.footnote)
                    .foregroundStyle(OnboardingDesign.Colors.success)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, OnboardingDesign.Spacing.md)
                    .opacity(appeared ? 1 : 0)
            }

            // CTA
            OnboardingCTAButton("Continue", isEnabled: !selectedBarriers.isEmpty) {
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

// MARK: - Barrier Card
private struct BarrierCard: View {
    let barrier: Barrier
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            VStack(spacing: OnboardingDesign.Spacing.sm) {
                Text(barrier.emoji)
                    .font(OnboardingDesign.Typography.largeTitle)

                Text(barrier.rawValue)
                    .font(OnboardingDesign.Typography.caption)
                    .foregroundStyle(isSelected ? OnboardingDesign.Colors.textOnDark : OnboardingDesign.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .background(
                RoundedRectangle(cornerRadius: OnboardingDesign.Radius.lg)
                    .fill(isSelected ? OnboardingDesign.Colors.selectedBackground : OnboardingDesign.Colors.unselectedBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: OnboardingDesign.Radius.lg)
                    .strokeBorder(isSelected ? Color.clear : OnboardingDesign.Colors.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(OnboardingScaleButtonStyle())
    }
}

#Preview {
    BarriersStepView(
        selectedBarriers: .constant([.tooBusy, .dontKnowWhatToCook]),
        onContinue: {}
    )
}
