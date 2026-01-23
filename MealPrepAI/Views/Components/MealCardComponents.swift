import SwiftUI

// MARK: - Meal Card (Horizontal style for Meal Plan)
struct HorizontalMealCard: View {
    let recipe: Recipe
    let mealType: MealType
    var isCompleted: Bool = false
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Image area with real image or colorful meal-type themed gradient
                ZStack(alignment: .topLeading) {
                    FoodImagePlaceholder(
                        style: mealType.foodStyle,
                        height: 100,
                        cornerRadius: Design.Radius.lg,
                        showIcon: recipe.imageURL == nil,
                        iconSize: 32,
                        imageName: recipe.highResImageURL ?? recipe.imageURL
                    )
                    .frame(width: 140)

                    // Meal type badge
                    Text(mealType.rawValue)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Design.Spacing.xs)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(.black.opacity(0.3))
                        )
                        .padding(Design.Spacing.xs)

                    // Checkmark if completed
                    if isCompleted {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                ZStack {
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 28, height: 28)
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 26))
                                        .foregroundStyle(Color.mintVibrant)
                                }
                                .padding(Design.Spacing.xs)
                            }
                        }
                    }
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.name)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Text("\(recipe.caloriesPerServing) cal/serv")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(Design.Spacing.sm)
                .frame(width: 140, alignment: .leading)
            }
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Design.Radius.card))
            .shadow(
                color: Design.Shadow.sm.color,
                radius: Design.Shadow.sm.radius,
                y: Design.Shadow.sm.y
            )
            .opacity(isCompleted ? 0.7 : 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Wide Meal Card (Full-width for Meal Plan)
struct WideMealCard: View {
    let recipe: Recipe
    let mealType: MealType
    var isCompleted: Bool = false
    var onTap: () -> Void
    var onToggleCompleted: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: Design.Spacing.md) {
            // Tappable content area - opens recipe detail
            Button(action: onTap) {
                HStack(spacing: Design.Spacing.md) {
                    // Image area with real image or colorful meal-type themed gradient
                    ZStack(alignment: .bottomTrailing) {
                        FoodImagePlaceholder(
                            style: mealType.foodStyle,
                            height: 100,
                            cornerRadius: Design.Radius.lg,
                            showIcon: recipe.imageURL == nil,
                            iconSize: 32,
                            imageName: recipe.highResImageURL ?? recipe.imageURL
                        )
                        .frame(width: 100)

                        // Checkmark if completed
                        if isCompleted {
                            ZStack {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 28, height: 28)
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 26))
                                    .foregroundStyle(Color.mintVibrant)
                            }
                            .padding(Design.Spacing.xs)
                        }
                    }

                    // Info
                    VStack(alignment: .leading, spacing: Design.Spacing.xs) {
                        // Meal type badge
                        Text(mealType.rawValue)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(mealTypeColor)
                            .padding(.horizontal, Design.Spacing.sm)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(mealTypeColor.opacity(0.15))
                            )

                        Text(recipe.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .lineLimit(2)

                        HStack(spacing: Design.Spacing.md) {
                            Label("\(recipe.caloriesPerServing) cal", systemImage: "flame.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Label("\(recipe.totalTimeMinutes) min", systemImage: "clock")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()
                }
            }
            .buttonStyle(.plain)

            // Completion toggle button - separate from main tap
            Button(action: { onToggleCompleted?() }) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(isCompleted ? Color.mintVibrant : Color.textSecondary.opacity(0.3))
            }
        }
        .padding(Design.Spacing.md)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Design.Radius.card))
        .shadow(
            color: Design.Shadow.sm.color,
            radius: Design.Shadow.sm.radius,
            y: Design.Shadow.sm.y
        )
        .opacity(isCompleted ? 0.8 : 1)
    }

    private var mealTypeColor: Color {
        switch mealType {
        case .breakfast: return Color.accentYellow
        case .lunch: return Color.mintVibrant
        case .dinner: return Color.accentPurple
        case .snack: return Color.mintVibrant
        }
    }
}

// MARK: - Stats Card (Compact)
struct CompactStatsCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: Design.Spacing.xs) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
            }

            Text(value)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Nutrition Ring Card (Updated style)
struct NutritionSummaryCard: View {
    let consumed: Int
    let target: Int
    let protein: Int
    let proteinTarget: Int
    let carbs: Int
    let carbsTarget: Int
    let fat: Int
    let fatTarget: Int

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(consumed) / Double(target), 1.0)
    }

    var body: some View {
        VStack(spacing: Design.Spacing.lg) {
            HStack(spacing: Design.Spacing.xl) {
                // Main calorie ring
                VStack(spacing: Design.Spacing.sm) {
                    ZStack {
                        Circle()
                            .stroke(Color.surfaceOverlay, lineWidth: 10)
                            .frame(width: 100, height: 100)

                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                LinearGradient.brandGradient,
                                style: StrokeStyle(lineWidth: 10, lineCap: .round)
                            )
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 2) {
                            Text("\(consumed)")
                                .font(.system(.title2, design: .rounded, weight: .bold))
                            Text("/ \(target)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text("Calories")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Macro bars
                VStack(spacing: Design.Spacing.md) {
                    MacroProgressBar(
                        label: "Protein",
                        current: protein,
                        target: proteinTarget,
                        color: .proteinColor,
                        icon: "p.circle.fill"
                    )

                    MacroProgressBar(
                        label: "Carbs",
                        current: carbs,
                        target: carbsTarget,
                        color: .carbColor,
                        icon: "c.circle.fill"
                    )

                    MacroProgressBar(
                        label: "Fat",
                        current: fat,
                        target: fatTarget,
                        color: .fatColor,
                        icon: "f.circle.fill"
                    )
                }
            }
        }
        .padding(Design.Spacing.lg)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Design.Radius.card))
        .shadow(
            color: Design.Shadow.card.color,
            radius: Design.Shadow.card.radius,
            y: Design.Shadow.card.y
        )
    }
}
