import SwiftUI
import Charts

struct MacroBreakdownChart: View {
    let days: [Day]
    let proteinTarget: Int
    let carbsTarget: Int
    let fatTarget: Int

    @State private var animateDonut = false

    private var dayCount: Int { max(days.count, 1) }

    private var totalProtein: Int {
        days.reduce(0) { $0 + $1.totalProtein }
    }

    private var totalCarbs: Int {
        days.reduce(0) { $0 + $1.totalCarbs }
    }

    private var totalFat: Int {
        days.reduce(0) { $0 + $1.totalFat }
    }

    private var totalGrams: Int {
        totalProtein + totalCarbs + totalFat
    }

    private var dailyAvgGrams: Int {
        totalGrams / dayCount
    }

    private var macroData: [(name: String, grams: Int, color: Color, dailyAvg: Int, target: Int)] {
        [
            ("Protein", totalProtein, Color.proteinColor, totalProtein / dayCount, proteinTarget),
            ("Carbs", totalCarbs, Color.carbColor, totalCarbs / dayCount, carbsTarget),
            ("Fat", totalFat, Color.fatColor, totalFat / dayCount, fatTarget)
        ].filter { $0.grams > 0 }
    }

    private var displayData: [(name: String, grams: Int, color: Color)] {
        let base = macroData.map { (name: $0.name, grams: $0.grams, color: $0.color) }
        guard animateDonut else {
            return base.map { (name: $0.name, grams: 1, color: $0.color) }
        }
        return base
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.sm) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundStyle(Color.proteinColor)
                Text("Macro Breakdown")
                    .font(Design.Typography.headline)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text("Daily avg")
                    .font(Design.Typography.caption)
                    .foregroundStyle(Color.textSecondary)
            }

            if totalGrams == 0 {
                Text("No nutrition data yet")
                    .font(Design.Typography.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 140)
            } else {
                // Donut + legend row
                HStack(spacing: Design.Spacing.lg) {
                    Chart(displayData, id: \.name) { macro in
                        SectorMark(
                            angle: .value("Grams", macro.grams),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(macro.color)
                        .cornerRadius(4)
                    }
                    .chartLegend(.hidden)
                    .frame(width: 110, height: 110)
                    .overlay {
                        VStack(spacing: 0) {
                            AnimatedNumber(
                                value: dailyAvgGrams,
                                font: .system(size: 18, weight: .bold, design: .rounded),
                                color: Color.textPrimary
                            )
                            Text("g/day")
                                .font(Design.Typography.captionSmall)
                                .foregroundStyle(Color.textSecondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                        ForEach(macroData, id: \.name) { macro in
                            let pct = totalGrams > 0 ? Int(Double(macro.grams) / Double(totalGrams) * 100) : 0

                            HStack(spacing: Design.Spacing.xs) {
                                Circle()
                                    .fill(macro.color)
                                    .frame(width: 10, height: 10)

                                VStack(alignment: .leading, spacing: 0) {
                                    Text(macro.name)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(Color.textPrimary)
                                    Text("\(macro.dailyAvg)g/day (\(pct)%)")
                                        .font(.caption2)
                                        .foregroundStyle(Color.textSecondary)
                                }
                            }
                        }
                    }
                }

                // Macro target progress bars
                VStack(spacing: Design.Spacing.xs) {
                    ForEach(macroData, id: \.name) { macro in
                        macroTargetRow(
                            name: macro.name,
                            current: macro.dailyAvg,
                            target: macro.target,
                            color: macro.color
                        )
                    }
                }
                .padding(.top, Design.Spacing.xs)
            }
        }
        .insightsGlassCard(tint: Color.proteinColor)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                animateDonut = true
            }
        }
    }

    private func macroTargetRow(name: String, current: Int, target: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(name)
                    .font(Design.Typography.captionSmall)
                    .foregroundStyle(Color.textSecondary)
                Spacer()
                Text("\(current)g / \(target)g")
                    .font(Design.Typography.captionSmall)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.textPrimary)
            }

            GeometryReader { geo in
                let progress = target > 0 ? min(Double(current) / Double(target), 1.0) : 0

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color.opacity(0.12))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.7), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress)
                        .animation(.easeOut(duration: 0.8), value: animateDonut)
                }
            }
            .frame(height: 5)
        }
    }
}
