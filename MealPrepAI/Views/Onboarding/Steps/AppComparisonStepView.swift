import SwiftUI

struct AppComparisonStepView: View {
    let onContinue: () -> Void

    @State private var appeared = false
    @State private var barsAnimated = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Title
            VStack(spacing: OnboardingDesign.Spacing.sm) {
                Text("Meal prep saves")
                    .font(OnboardingDesign.Typography.title)
                    .foregroundStyle(OnboardingDesign.Colors.textPrimary)

                Text("5+ hours every week")
                    .font(OnboardingDesign.Typography.title)
                    .foregroundStyle(OnboardingDesign.Colors.accent)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxxl)

            // Comparison bars
            VStack(spacing: OnboardingDesign.Spacing.lg) {
                ComparisonBar(
                    label: "Without MealPrepAI",
                    value: 40,
                    maxValue: 100,
                    color: OnboardingDesign.Colors.textTertiary,
                    isAnimated: barsAnimated
                )

                ComparisonBar(
                    label: "With MealPrepAI",
                    value: 85,
                    maxValue: 100,
                    color: OnboardingDesign.Colors.accent,
                    isAnimated: barsAnimated
                )
            }
            .padding(OnboardingDesign.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: OnboardingDesign.Radius.xl)
                    .fill(OnboardingDesign.Colors.cardBackground)
            )
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 30)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xl)

            // Benefits list
            VStack(alignment: .leading, spacing: OnboardingDesign.Spacing.md) {
                BenefitRow(icon: "clock.fill", text: "Save 5+ hours on meal planning")
                BenefitRow(icon: "cart.fill", text: "Smarter grocery shopping")
                BenefitRow(icon: "chart.line.uptrend.xyaxis", text: "2x more likely to reach goals")
                BenefitRow(icon: "brain.fill", text: "No more decision fatigue")
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
            withAnimation(.easeOut(duration: 1.0).delay(0.5)) {
                barsAnimated = true
            }
        }
    }
}

// MARK: - Comparison Bar
private struct ComparisonBar: View {
    let label: String
    let value: Int
    let maxValue: Int
    let color: Color
    let isAnimated: Bool

    private var progress: CGFloat {
        CGFloat(value) / CGFloat(maxValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: OnboardingDesign.Spacing.sm) {
            HStack {
                Text(label)
                    .font(OnboardingDesign.Typography.subheadline)
                    .foregroundStyle(OnboardingDesign.Colors.textSecondary)

                Spacer()

                Text("\(value)%")
                    .font(OnboardingDesign.Typography.bodyMedium)
                    .foregroundStyle(OnboardingDesign.Colors.textPrimary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(OnboardingDesign.Colors.progressBackground)
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(color)
                        .frame(width: isAnimated ? geometry.size.width * progress : 0, height: 12)
                }
            }
            .frame(height: 12)
        }
    }
}

// MARK: - Benefit Row
private struct BenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: OnboardingDesign.Spacing.md) {
            Image(systemName: icon)
                .font(OnboardingDesign.Typography.bodyMedium)
                .foregroundStyle(OnboardingDesign.Colors.success)
                .frame(width: 28, height: 28)

            Text(text)
                .font(OnboardingDesign.Typography.subheadline)
                .foregroundStyle(OnboardingDesign.Colors.textPrimary)
        }
    }
}

#Preview {
    AppComparisonStepView(onContinue: {})
}
