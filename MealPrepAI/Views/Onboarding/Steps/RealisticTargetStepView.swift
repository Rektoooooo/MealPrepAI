import SwiftUI

struct RealisticTargetStepView: View {
    let weightDifferenceKg: Double
    let measurementSystem: MeasurementSystem
    let onContinue: () -> Void

    @State private var appeared = false
    @State private var checkmarkScale: CGFloat = 0

    private var weightDifferenceDisplay: Int {
        measurementSystem == .metric ? Int(abs(weightDifferenceKg)) : Int(abs(weightDifferenceKg) * 2.20462)
    }

    private var unit: String {
        measurementSystem == .metric ? "kg" : "lbs"
    }

    private var isLosing: Bool {
        weightDifferenceKg > 0
    }

    private var encouragementMessage: String {
        if weightDifferenceDisplay == 0 {
            return "Maintaining your weight is a great goal!"
        } else if weightDifferenceDisplay < 5 {
            return "This is totally achievable!"
        } else if weightDifferenceDisplay < 15 {
            return "This is a realistic target.\nIt's not hard at all!"
        } else {
            return "With consistency, you'll get there!"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Checkmark icon
            ZStack {
                Circle()
                    .fill(OnboardingDesign.Colors.success.opacity(0.2))
                    .frame(width: 120, height: 120)

                Circle()
                    .fill(OnboardingDesign.Colors.success.opacity(0.3))
                    .frame(width: 90, height: 90)

                Image(systemName: "checkmark")
                    .font(Design.Typography.iconSmall).fontWeight(.bold)
                    .foregroundStyle(OnboardingDesign.Colors.success)
            }
            .scaleEffect(checkmarkScale)
            .opacity(appeared ? 1 : 0)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxxl)

            // Weight goal text
            if weightDifferenceDisplay > 0 {
                VStack(spacing: OnboardingDesign.Spacing.sm) {
                    Text("\(isLosing ? "Losing" : "Gaining") \(weightDifferenceDisplay) \(unit)")
                        .font(OnboardingDesign.Typography.title)
                        .foregroundStyle(OnboardingDesign.Colors.textPrimary)

                    Text(encouragementMessage)
                        .font(OnboardingDesign.Typography.body)
                        .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
            } else {
                Text("Maintaining your current weight\nis a great goal!")
                    .font(OnboardingDesign.Typography.title2)
                    .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
            }

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxl)

            // Success stat
            VStack(spacing: OnboardingDesign.Spacing.sm) {
                Text("85%")
                    .font(OnboardingDesign.Typography.heroDisplay)
                    .foregroundStyle(OnboardingDesign.Colors.accent)

                Text("of MealPrepAI users\nreach their target weight")
                    .font(OnboardingDesign.Typography.subheadline)
                    .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

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
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.4)) {
                checkmarkScale = 1
            }
        }
    }
}

#Preview {
    RealisticTargetStepView(
        weightDifferenceKg: 10,
        measurementSystem: .metric,
        onContinue: {}
    )
}
