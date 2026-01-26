import SwiftUI

struct SexInputStepView: View {
    @Binding var gender: Gender
    let onContinue: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            OnboardingStepHeader(
                "Choose your Gender",
                subtitle: "This will be used to calibrate your custom plan."
            )
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .padding(.top, OnboardingDesign.Spacing.xl)

            Spacer()

            // Gender options - Cal AI style (black when selected, light gray when not)
            VStack(spacing: OnboardingDesign.Spacing.sm) {
                GenderOption(
                    title: "Male",
                    isSelected: gender == .male
                ) {
                    gender = .male
                }

                GenderOption(
                    title: "Female",
                    isSelected: gender == .female
                ) {
                    gender = .female
                }

                GenderOption(
                    title: "Other",
                    isSelected: gender == .other
                ) {
                    gender = .other
                }
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 30)

            Spacer()
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

// MARK: - Gender Option (Cal AI Style)
private struct GenderOption: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            hapticFeedback(.light)
            action()
        }) {
            Text(title)
                .font(OnboardingDesign.Typography.headline)
                .foregroundStyle(isSelected ? OnboardingDesign.Colors.textOnDark : OnboardingDesign.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, OnboardingDesign.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: OnboardingDesign.Radius.lg)
                        .fill(isSelected ? OnboardingDesign.Colors.selectedBackground : OnboardingDesign.Colors.unselectedBackground)
                )
        }
        .buttonStyle(OnboardingScaleButtonStyle())
    }

    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

#Preview {
    SexInputStepView(
        gender: .constant(.other),
        onContinue: {}
    )
}
