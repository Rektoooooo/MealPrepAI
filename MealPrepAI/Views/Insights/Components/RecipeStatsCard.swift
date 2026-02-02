import SwiftUI
import SwiftData

struct RecipeStatsCard: View {
    let days: [Day]

    private var allMeals: [Meal] {
        days.flatMap { $0.meals ?? [] }
    }

    private var topRecipes: [(name: String, count: Int)] {
        var counts: [String: Int] = [:]
        for meal in allMeals {
            if let name = meal.recipe?.name, !name.isEmpty {
                counts[name, default: 0] += 1
            }
        }
        return counts.sorted { $0.value > $1.value }
            .prefix(3)
            .map { (name: $0.key, count: $0.value) }
    }

    private var mealTypeDistribution: [(type: MealType, count: Int)] {
        var counts: [MealType: Int] = [:]
        for meal in allMeals {
            counts[meal.mealType, default: 0] += 1
        }
        return MealType.allCases.compactMap { type in
            guard let count = counts[type], count > 0 else { return nil }
            return (type: type, count: count)
        }
    }

    private var cuisineBreakdown: [(cuisine: String, count: Int)] {
        var counts: [String: Int] = [:]
        for meal in allMeals {
            if let cuisine = meal.recipe?.cuisineType {
                counts[cuisine.rawValue, default: 0] += 1
            }
        }
        return counts.sorted { $0.value > $1.value }
            .prefix(4)
            .map { (cuisine: $0.key, count: $0.value) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.sm) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(Color.accentYellow)
                Text("Recipe Stats")
                    .font(Design.Typography.headline)
                    .foregroundStyle(Color.textPrimary)
            }

            if topRecipes.isEmpty {
                VStack(spacing: Design.Spacing.sm) {
                    Image(systemName: "fork.knife.circle")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.textSecondary.opacity(0.4))

                    Text("No recipes tracked yet")
                        .font(Design.Typography.subheadline)
                        .foregroundStyle(Color.textSecondary)

                    Text("Your top recipes will appear here once you start planning meals")
                        .font(Design.Typography.caption)
                        .foregroundStyle(Color.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Design.Spacing.md)
            } else {
                VStack(alignment: .leading, spacing: Design.Spacing.xs) {
                    Text("Most Planned")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.textSecondary)

                    ForEach(Array(topRecipes.enumerated()), id: \.offset) { index, recipe in
                        HStack(spacing: Design.Spacing.sm) {
                            // Ranking badge with gradient for #1
                            ZStack {
                                Circle()
                                    .fill(
                                        index == 0
                                            ? AnyShapeStyle(LinearGradient(colors: [Color.accentYellowLight, Color.accentGold], startPoint: .topLeading, endPoint: .bottomTrailing))
                                            : AnyShapeStyle(Color.surfaceOverlay)
                                    )
                                    .frame(width: 26, height: 26)

                                if index == 0 {
                                    Circle()
                                        .strokeBorder(Color.white.opacity(0.4), lineWidth: 0.5)
                                        .frame(width: 26, height: 26)
                                }

                                Text("\(index + 1)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(index == 0 ? Color(hex: "5D4037") : Color.textSecondary)
                            }

                            Text(recipe.name)
                                .font(.subheadline)
                                .foregroundStyle(Color.textPrimary)
                                .lineLimit(1)

                            Spacer()

                            Text("\(recipe.count)x")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.textSecondary)
                                .padding(.horizontal, Design.Spacing.xs)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule().fill(Color.surfaceOverlay)
                                )
                        }
                    }
                }

                if !mealTypeDistribution.isEmpty {
                    Divider().opacity(0.5)

                    VStack(alignment: .leading, spacing: Design.Spacing.xs) {
                        Text("Meal Types")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.textSecondary)

                        HStack(spacing: Design.Spacing.xs) {
                            ForEach(mealTypeDistribution, id: \.type) { entry in
                                HStack(spacing: 4) {
                                    Image(systemName: entry.type.icon)
                                        .font(.caption2)
                                    Text("\(entry.count)")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                                .foregroundStyle(entry.type.primaryColor)
                                .padding(.horizontal, Design.Spacing.sm)
                                .padding(.vertical, Design.Spacing.xxs)
                                .background(
                                    Capsule().fill(entry.type.primaryColor.opacity(0.12))
                                )
                            }
                        }
                    }
                }

                if !cuisineBreakdown.isEmpty {
                    Divider().opacity(0.5)

                    VStack(alignment: .leading, spacing: Design.Spacing.xs) {
                        Text("Top Cuisines")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.textSecondary)

                        HStack(spacing: Design.Spacing.xs) {
                            ForEach(cuisineBreakdown, id: \.cuisine) { entry in
                                Text("\(entry.cuisine) (\(entry.count))")
                                    .font(.caption2)
                                    .foregroundStyle(Color.textPrimary)
                                    .padding(.horizontal, Design.Spacing.sm)
                                    .padding(.vertical, Design.Spacing.xxs)
                                    .background(
                                        Capsule().fill(Color.surfaceOverlay)
                                    )
                            }
                        }
                    }
                }
            }
        }
        .insightsGlassCard(tint: Color.accentYellow)
    }
}
