import SwiftUI

struct ScalePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct InsightsPreviewCards: View {
    let days: [Day]
    let calorieTarget: Int

    private var avgCalories: Int {
        let daysWithFood = days.filter { $0.totalCalories > 0 }
        guard !daysWithFood.isEmpty else { return 0 }
        return daysWithFood.reduce(0) { $0 + $1.totalCalories } / daysWithFood.count
    }

    private var currentStreak: Int {
        InsightsHelper.currentStreak(for: days)
    }

    var body: some View {
        VStack(spacing: Design.Spacing.md) {
            NewSectionHeader(
                title: "Insights",
                icon: "chart.xyaxis.line",
                iconColor: Color.accentPurple
            )

            HStack(spacing: Design.Spacing.sm) {
                insightPill(
                    icon: "flame.fill",
                    value: avgCalories,
                    label: "avg kcal",
                    color: .calorieColor
                )

                insightPill(
                    icon: "flame.fill",
                    value: currentStreak,
                    label: "day streak",
                    color: .accentOrange
                )
            }
            .buttonStyle(ScalePressStyle())
        }
    }

    private func insightPill(icon: String, value: Int, label: String, color: Color) -> some View {
        VStack(spacing: Design.Spacing.xxs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)

            AnimatedNumber(
                value: value,
                font: .system(size: 18, weight: .bold, design: .rounded),
                color: Color.textPrimary
            )

            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Design.Spacing.sm)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: Design.Radius.md)
                    .fill(.ultraThinMaterial)

                RoundedRectangle(cornerRadius: Design.Radius.md)
                    .fill(color.opacity(0.04))

                RoundedRectangle(cornerRadius: Design.Radius.md)
                    .strokeBorder(
                        LinearGradient(
                            colors: [color.opacity(0.2), Color.white.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
            }
            .shadow(
                color: Design.Shadow.card.color,
                radius: Design.Shadow.card.radius,
                y: Design.Shadow.card.y
            )
        )
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.8), color.opacity(0.4)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2.5)
                .padding(.horizontal, Design.Spacing.md)
        }
    }
}
