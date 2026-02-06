import SwiftUI
import SwiftData

struct InsightsView: View {
    let mealPlan: MealPlan
    let calorieTarget: Int
    let proteinTarget: Int
    let carbsTarget: Int
    let fatTarget: Int

    @State private var cardAppeared: [Bool] = Array(repeating: false, count: 4)

    private var days: [Day] {
        mealPlan.sortedDays
    }

    private var weeklyAdherencePercent: Int {
        guard calorieTarget > 0 else { return 0 }
        let lowerBound = Int(Double(calorieTarget) * 0.9)
        let upperBound = Int(Double(calorieTarget) * 1.1)
        let daysWithFood = days.filter { $0.totalCalories > 0 }
        guard !daysWithFood.isEmpty else { return 0 }
        let onTarget = daysWithFood.filter { day in
            let cals = day.totalCalories
            return cals >= lowerBound && cals <= upperBound
        }.count
        return Int(Double(onTarget) / Double(daysWithFood.count) * 100)
    }

    private var daysOnTarget: Int {
        let lowerBound = Int(Double(calorieTarget) * 0.9)
        let upperBound = Int(Double(calorieTarget) * 1.1)
        return days.filter { day in
            let cals = day.totalCalories
            return cals >= lowerBound && cals <= upperBound && cals > 0
        }.count
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Design.Spacing.lg) {
                insightsHeroCard
                    .opacity(cardAppeared[0] ? 1 : 0)
                    .offset(y: cardAppeared[0] ? 0 : 20)

                WeeklyCalorieChart(days: days, calorieTarget: calorieTarget)
                    .opacity(cardAppeared[1] ? 1 : 0)
                    .offset(y: cardAppeared[1] ? 0 : 20)

                MacroBreakdownChart(
                    days: days,
                    proteinTarget: proteinTarget,
                    carbsTarget: carbsTarget,
                    fatTarget: fatTarget
                )
                .opacity(cardAppeared[2] ? 1 : 0)
                .offset(y: cardAppeared[2] ? 0 : 20)

                StreakCard(days: days, calorieTarget: calorieTarget)
                    .opacity(cardAppeared[3] ? 1 : 0)
                    .offset(y: cardAppeared[3] ? 0 : 20)
            }
            .padding(.horizontal, Design.Spacing.md)
            .padding(.bottom, 100)
        }
        .warmBackground()
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            for index in 0..<cardAppeared.count {
                if !cardAppeared[index] {
                    withAnimation(Design.Animation.smooth.delay(Double(index) * 0.1)) {
                        cardAppeared[index] = true
                    }
                }
            }
        }
    }

    // MARK: - Hero Card
    private var insightsHeroCard: some View {
        HStack(spacing: Design.Spacing.lg) {
            ProgressRing(
                progress: Double(weeklyAdherencePercent) / 100.0,
                lineWidth: 8,
                gradient: .freshGradient,
                showLabel: false
            )
            .frame(width: 80, height: 80)
            .overlay {
                AnimatedNumber(
                    value: weeklyAdherencePercent,
                    font: .system(size: 20, weight: .bold, design: .rounded),
                    color: .white
                )
            }

            VStack(alignment: .leading, spacing: Design.Spacing.xxs) {
                Text("This Week")
                    .font(Design.Typography.caption)
                    .foregroundStyle(.white.opacity(0.8))

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    AnimatedNumber(
                        value: weeklyAdherencePercent,
                        font: .system(size: 34, weight: .bold, design: .rounded),
                        color: .white
                    )
                    Text("%")
                        .font(Design.Typography.title2)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Text("\(daysOnTarget) of \(days.count) days on target")
                    .font(Design.Typography.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()
        }
        .padding(Design.Spacing.lg)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: Design.Radius.featured)
                    .fill(
                        LinearGradient(
                            colors: [Color.lunchGradientStart, Color.lunchGradientEnd, Color.lunchGradientEnd.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: Design.Radius.featured)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.18), .clear, .white.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: Design.Radius.featured)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.4), .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(
                color: Color.lunchGradientEnd.opacity(0.3),
                radius: 20,
                y: 8
            )
        )
    }
}
