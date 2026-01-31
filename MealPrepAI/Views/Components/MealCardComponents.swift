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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(mealType.rawValue): \(recipe.name), \(recipe.caloriesPerServing) calories per serving")
        .accessibilityValue(isCompleted ? "Completed" : "Not completed")
        .accessibilityHint("Double tap to view recipe")
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
            .accessibilityLabel(isCompleted ? "Mark as not eaten" : "Mark as eaten")
            .accessibilityHint("Double tap to toggle")
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
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

    @Environment(\.colorScheme) private var colorScheme

    private var cardBackground: Color {
        colorScheme == .dark ? Color(hex: "2C2C2E") : Color(hex: "1C1C1E")
    }

    var body: some View {
        HStack(spacing: Design.Spacing.md) {
            // Calories
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "FF9500"))
                Text("\(consumed)")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.white)
                Text("/ \(target)")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.5))
            }

            Spacer()

            // Protein
            HStack(spacing: 3) {
                Circle().fill(Color(hex: "FF453A")).frame(width: 6, height: 6)
                Text("P \(protein)g")
                    .font(.caption2)
                    .foregroundStyle(Color.white.opacity(0.7))
            }

            // Carbs
            HStack(spacing: 3) {
                Circle().fill(Color(hex: "FF9F0A")).frame(width: 6, height: 6)
                Text("C \(carbs)g")
                    .font(.caption2)
                    .foregroundStyle(Color.white.opacity(0.7))
            }

            // Fat
            HStack(spacing: 3) {
                Circle().fill(Color(hex: "0A84FF")).frame(width: 6, height: 6)
                Text("F \(fat)g")
                    .font(.caption2)
                    .foregroundStyle(Color.white.opacity(0.7))
            }
        }
        .padding(.horizontal, Design.Spacing.lg)
        .padding(.vertical, Design.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Design.Radius.lg)
                .fill(cardBackground)
                .shadow(color: Color.black.opacity(0.15), radius: 8, y: 4)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Calories: \(consumed) of \(target). Protein: \(protein) of \(proteinTarget) grams. Carbs: \(carbs) of \(carbsTarget) grams. Fat: \(fat) of \(fatTarget) grams")
    }
}
