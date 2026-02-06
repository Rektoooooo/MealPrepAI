import SwiftUI

enum InsightsHelper {
    static func currentStreak(for days: [Day]) -> Int {
        let sortedDays = days.sorted { $0.date > $1.date }
        var streak = 0
        for day in sortedDays {
            let meals = day.meals
            guard !meals.isEmpty else { break }
            if meals.allSatisfy({ $0.isEaten }) {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }
}

struct StreakCard: View {
    let days: [Day]
    let calorieTarget: Int

    @State private var flameGlow = false

    private var currentStreak: Int {
        InsightsHelper.currentStreak(for: days)
    }

    private var daysOnTarget: Int {
        let lowerBound = Int(Double(calorieTarget) * 0.9)
        let upperBound = Int(Double(calorieTarget) * 1.1)
        return days.filter { day in
            let cals = day.totalCalories
            return cals >= lowerBound && cals <= upperBound && cals > 0
        }.count
    }

    private var totalMealsEaten: Int {
        days.flatMap { $0.meals }.filter { $0.isEaten }.count
    }

    private var totalMeals: Int {
        days.flatMap { $0.meals }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(Color.accentOrange)
                Text("Consistency")
                    .font(Design.Typography.headline)
                    .foregroundStyle(Color.textPrimary)
            }

            HStack(spacing: Design.Spacing.md) {
                // Streak
                statBlock(
                    value: currentStreak,
                    label: "day streak",
                    color: Color.accentOrange,
                    glow: true
                )

                // Divider
                RoundedRectangle(cornerRadius: 1)
                    .fill(
                        LinearGradient(
                            colors: [Color.surfaceOverlay.opacity(0), Color.surfaceOverlay, Color.surfaceOverlay.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 1, height: 56)

                // Days on target
                statBlock(
                    value: daysOnTarget,
                    label: "of \(days.count) on target",
                    color: Color.lunchGradientEnd,
                    glow: false
                )

                // Divider
                RoundedRectangle(cornerRadius: 1)
                    .fill(
                        LinearGradient(
                            colors: [Color.surfaceOverlay.opacity(0), Color.surfaceOverlay, Color.surfaceOverlay.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 1, height: 56)

                // Meals completed
                statBlock(
                    value: totalMealsEaten,
                    label: "of \(totalMeals) meals",
                    color: Color.accentBlue,
                    glow: false
                )
            }
        }
        .insightsGlassCard(tint: Color.accentOrange)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                flameGlow = true
            }
        }
    }

    private func statBlock(value: Int, label: String, color: Color, glow: Bool) -> some View {
        VStack(spacing: Design.Spacing.xxs) {
            Text("\(value)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .shadow(
                    color: glow ? color.opacity(flameGlow ? 0.5 : 0.15) : .clear,
                    radius: glow && flameGlow ? 12 : 0
                )

            Text(label)
                .font(Design.Typography.captionSmall)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
