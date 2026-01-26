import SwiftUI

struct GoalTimelineStepView: View {
    @Binding var goalPace: GoalPace
    let weightDifferenceKg: Double
    let measurementSystem: MeasurementSystem
    let onContinue: () -> Void

    @State private var appeared = false

    private func weeksToGoal(for pace: GoalPace) -> Int {
        guard pace.weeklyLossKg > 0 else { return 0 }
        return Int(ceil(abs(weightDifferenceKg) / pace.weeklyLossKg))
    }

    private func estimatedDate(for pace: GoalPace) -> Date {
        Calendar.current.date(byAdding: .weekOfYear, value: weeksToGoal(for: pace), to: Date()) ?? Date()
    }

    private func formattedDate(for pace: GoalPace) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: estimatedDate(for: pace))
    }

    private func weeklyLossText(for pace: GoalPace) -> String {
        if measurementSystem == .metric {
            return String(format: "%.1f kg/week", pace.weeklyLossKg)
        } else {
            return String(format: "%.1f lbs/week", pace.weeklyLossLbs)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            OnboardingStepHeader(
                "Goal timeline",
                subtitle: "How fast do you want to reach your goal?"
            )
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .padding(.top, OnboardingDesign.Spacing.xl)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxl)

            // Pace options
            VStack(spacing: OnboardingDesign.Spacing.sm) {
                ForEach(GoalPace.allCases) { pace in
                    PaceOptionCard(
                        pace: pace,
                        weeklyLoss: weeklyLossText(for: pace),
                        estimatedDate: formattedDate(for: pace),
                        isSelected: goalPace == pace,
                        isRecommended: pace == .moderate
                    ) {
                        goalPace = pace
                    }
                }
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 30)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xl)

            // Info note
            HStack(spacing: OnboardingDesign.Spacing.sm) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(OnboardingDesign.Colors.textTertiary)

                Text("Moderate pace is most sustainable for long-term success")
                    .font(OnboardingDesign.Typography.footnote)
                    .foregroundStyle(OnboardingDesign.Colors.textSecondary)
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

// MARK: - Pace Option Card
private struct PaceOptionCard: View {
    let pace: GoalPace
    let weeklyLoss: String
    let estimatedDate: String
    let isSelected: Bool
    let isRecommended: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            HStack(spacing: OnboardingDesign.Spacing.md) {
                // Icon
                Image(systemName: pace.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? OnboardingDesign.Colors.textOnDark : OnboardingDesign.Colors.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(isSelected ? OnboardingDesign.Colors.textOnDark.opacity(0.2) : OnboardingDesign.Colors.iconBackground)
                    )

                VStack(alignment: .leading, spacing: OnboardingDesign.Spacing.xxs) {
                    HStack(spacing: OnboardingDesign.Spacing.xs) {
                        Text(pace.rawValue)
                            .font(OnboardingDesign.Typography.bodyMedium)
                            .foregroundStyle(isSelected ? OnboardingDesign.Colors.textOnDark : OnboardingDesign.Colors.textPrimary)

                        if isRecommended {
                            Text("Recommended")
                                .font(OnboardingDesign.Typography.captionSmall)
                                .foregroundStyle(isSelected ? OnboardingDesign.Colors.textOnDark : OnboardingDesign.Colors.success)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(isSelected ? OnboardingDesign.Colors.textOnDark.opacity(0.2) : OnboardingDesign.Colors.success.opacity(0.15))
                                )
                        }
                    }

                    Text("\(weeklyLoss) • Target: \(estimatedDate)")
                        .font(OnboardingDesign.Typography.footnote)
                        .foregroundStyle(isSelected ? OnboardingDesign.Colors.textOnDark.opacity(0.7) : OnboardingDesign.Colors.textSecondary)
                }

                Spacer()

                // Selection indicator
                Circle()
                    .strokeBorder(isSelected ? OnboardingDesign.Colors.textOnDark : OnboardingDesign.Colors.cardBorder, lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .fill(OnboardingDesign.Colors.textOnDark)
                            .frame(width: 12, height: 12)
                            .opacity(isSelected ? 1 : 0)
                    )
            }
            .padding(OnboardingDesign.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: OnboardingDesign.Radius.lg)
                    .fill(isSelected ? OnboardingDesign.Colors.selectedBackground : OnboardingDesign.Colors.unselectedBackground)
            )
        }
        .buttonStyle(OnboardingScaleButtonStyle())
    }
}

#Preview {
    GoalTimelineStepView(
        goalPace: .constant(.moderate),
        weightDifferenceKg: 10,
        measurementSystem: .metric,
        onContinue: {}
    )
}
