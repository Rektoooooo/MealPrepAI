import SwiftUI

struct AgeInputStepView: View {
    @Binding var age: Int
    let onContinue: () -> Void

    @State private var appeared = false

    private let ageRange = Array(13...100)

    var body: some View {
        VStack(spacing: 0) {
            // Header
            OnboardingStepHeader(
                "Age",
                subtitle: "Age is used to calculate your calories"
            )
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .padding(.top, OnboardingDesign.Spacing.xl)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxl)

            // Age picker
            VStack(spacing: OnboardingDesign.Spacing.md) {
                // Display value
                HStack(alignment: .firstTextBaseline, spacing: OnboardingDesign.Spacing.xs) {
                    Text("\(age)")
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                        .contentTransition(.numericText())

                    Text("years old")
                        .font(OnboardingDesign.Typography.title2)
                        .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                }

                // Picker
                Picker("Age", selection: $age) {
                    ForEach(ageRange, id: \.self) { value in
                        Text("\(value)")
                            .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                            .tag(value)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 150)
                .colorScheme(.light)
            }
            .padding(OnboardingDesign.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: OnboardingDesign.Radius.xl)
                    .fill(OnboardingDesign.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: OnboardingDesign.Radius.xl)
                    .strokeBorder(OnboardingDesign.Colors.cardBorder, lineWidth: 1)
            )
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
    AgeInputStepView(
        age: .constant(30),
        onContinue: {}
    )
}
