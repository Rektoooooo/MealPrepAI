import SwiftUI
import Charts

struct WeeklyCalorieChart: View {
    let days: [Day]
    let calorieTarget: Int

    @State private var animateBars = false

    private var chartData: [(day: String, calories: Int, onTarget: Bool)] {
        days.prefix(7).map { day in
            let cals = day.totalCalories
            let lowerBound = Int(Double(calorieTarget) * 0.9)
            let upperBound = Int(Double(calorieTarget) * 1.1)
            let onTarget = cals >= lowerBound && cals <= upperBound
            return (day: day.shortDayName, calories: cals, onTarget: onTarget)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.sm) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(Color.lunchGradientEnd)
                Text("Weekly Calories")
                    .font(Design.Typography.headline)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text("\(calorieTarget) kcal goal")
                    .font(Design.Typography.caption)
                    .foregroundStyle(Color.textSecondary)
            }

            if chartData.isEmpty {
                Text("No meal data yet")
                    .font(Design.Typography.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                Chart {
                    ForEach(Array(chartData.enumerated()), id: \.offset) { _, entry in
                        BarMark(
                            x: .value("Day", entry.day),
                            y: .value("Calories", animateBars ? entry.calories : 0)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: entry.onTarget
                                    ? [Color.lunchGradientStart, Color.lunchGradientEnd]
                                    : [Color.calorieColor.opacity(0.7), Color.calorieColor],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .cornerRadius(6)
                    }

                    RuleMark(y: .value("Target", calorieTarget))
                        .foregroundStyle(Color.textSecondary.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text("\(intValue)")
                                    .font(Design.Typography.captionSmall)
                                    .foregroundStyle(Color.textSecondary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let str = value.as(String.self) {
                                Text(str)
                                    .font(Design.Typography.captionSmall)
                                    .foregroundStyle(Color.textSecondary)
                            }
                        }
                    }
                }
                .frame(height: 180)
            }

            // Legend
            HStack(spacing: Design.Spacing.md) {
                HStack(spacing: Design.Spacing.xxs) {
                    Circle().fill(Color.lunchGradientEnd).frame(width: 8, height: 8)
                    Text("On target").font(Design.Typography.captionSmall).foregroundStyle(Color.textSecondary)
                }
                HStack(spacing: Design.Spacing.xxs) {
                    Circle().fill(Color.calorieColor).frame(width: 8, height: 8)
                    Text("Off target").font(Design.Typography.captionSmall).foregroundStyle(Color.textSecondary)
                }
            }
        }
        .insightsGlassCard(tint: Color.lunchGradientEnd)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animateBars = true
            }
        }
    }
}
