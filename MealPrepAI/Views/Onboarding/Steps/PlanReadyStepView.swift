import SwiftUI

struct PlanReadyStepView: View {
    let calculatedCalories: Int
    let weightKg: Double
    let age: Int
    let gender: Gender
    let heightCm: Double
    let weightGoal: WeightGoal
    let onContinue: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: OnboardingDesign.Spacing.xl)

            // Header
            Text("Your plan is ready")
                .font(OnboardingDesign.Typography.title)
                .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxl)

            // Calories display
            VStack(spacing: OnboardingDesign.Spacing.sm) {
                HStack(spacing: OnboardingDesign.Spacing.xs) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(OnboardingDesign.Colors.accent)

                    Text("\(calculatedCalories)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(OnboardingDesign.Colors.textPrimary)

                    Text("kCal")
                        .font(OnboardingDesign.Typography.title2)
                        .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                }

                Text("Your meals have been adapted for your energy needs and goals")
                    .font(OnboardingDesign.Typography.footnote)
                    .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(OnboardingDesign.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: OnboardingDesign.Radius.xl)
                    .fill(OnboardingDesign.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: OnboardingDesign.Radius.xl)
                    .strokeBorder(OnboardingDesign.Colors.accent.opacity(0.3), lineWidth: 2)
            )
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.95)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xl)

            // User stats
            HStack(spacing: OnboardingDesign.Spacing.lg) {
                StatBadge(icon: "scalemass", value: "\(Int(weightKg))kg")
                StatBadge(icon: "calendar", value: "\(age)")
                StatBadge(icon: gender == .male ? "figure.stand" : "figure.stand.dress", value: gender.rawValue)
                StatBadge(icon: "ruler", value: "\(Int(heightCm))cm")
            }
            .opacity(appeared ? 1 : 0)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xl)

            // Goal card
            HStack(spacing: OnboardingDesign.Spacing.md) {
                Image(systemName: weightGoal.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(OnboardingDesign.Colors.accent)

                VStack(alignment: .leading, spacing: OnboardingDesign.Spacing.xxs) {
                    Text(weightGoal.rawValue)
                        .font(OnboardingDesign.Typography.headline)
                        .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                    Text(weightGoal.description)
                        .font(OnboardingDesign.Typography.footnote)
                        .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(OnboardingDesign.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: OnboardingDesign.Radius.lg)
                    .fill(OnboardingDesign.Colors.cardBackground)
            )
            .opacity(appeared ? 1 : 0)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.lg)

            // Benefits
            VStack(alignment: .leading, spacing: OnboardingDesign.Spacing.sm) {
                BenefitRow(emoji: "🍽️", title: "Delicious meals", subtitle: "Wide variety of recipes")
                BenefitRow(emoji: "💰", title: "Save time & money", subtitle: "Optimized grocery lists")
            }
            .opacity(appeared ? 1 : 0)

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

// MARK: - Stat Badge
private struct StatBadge: View {
    let icon: String
    let value: String

    var body: some View {
        VStack(spacing: OnboardingDesign.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(OnboardingDesign.Colors.textSecondary)

            Text(value)
                .font(OnboardingDesign.Typography.caption)
                .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(width: 70, height: 60)
        .background(
            RoundedRectangle(cornerRadius: OnboardingDesign.Radius.md)
                .fill(OnboardingDesign.Colors.cardBackground)
        )
    }
}

// MARK: - Benefit Row
private struct BenefitRow: View {
    let emoji: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: OnboardingDesign.Spacing.sm) {
            Text(emoji)
                .font(.system(size: 24))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(OnboardingDesign.Typography.bodyMedium)
                    .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                Text(subtitle)
                    .font(OnboardingDesign.Typography.footnote)
                    .foregroundStyle(OnboardingDesign.Colors.textSecondary)
            }
        }
    }
}

#Preview {
    PlanReadyStepView(
        calculatedCalories: 2050,
        weightKg: 70,
        age: 30,
        gender: .male,
        heightCm: 175,
        weightGoal: .maintain,
        onContinue: {}
    )
}
