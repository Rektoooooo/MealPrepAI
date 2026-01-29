import SwiftUI

// MARK: - Hero Header Card
struct HeroHeaderCard: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        HStack(spacing: Design.Spacing.md) {
            VStack(alignment: .leading, spacing: Design.Spacing.xs) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer()

            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(Design.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Design.Radius.xl)
                .fill(LinearGradient.heroGradient)
                .shadow(
                    color: Color.brandGreen.opacity(0.3),
                    radius: 16,
                    y: 8
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
    }
}

// MARK: - Premium Meal Card
struct PremiumMealCard: View {
    let mealType: MealType
    let recipeName: String
    let calories: Int
    let isCompleted: Bool
    var onTap: () -> Void = {}
    var onComplete: () -> Void = {}

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Design.Spacing.md) {
                // Gradient Icon Circle
                ZStack {
                    Circle()
                        .fill(mealType.gradient)
                        .frame(width: 52, height: 52)
                        .shadow(color: mealType.primaryColor.opacity(0.3), radius: 8, y: 4)

                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                    } else {
                        Image(systemName: mealType.icon)
                            .font(.system(size: 22))
                            .foregroundStyle(.white)
                    }
                }

                // Content
                VStack(alignment: .leading, spacing: Design.Spacing.xxs) {
                    Text(mealType.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(mealType.primaryColor)

                    Text(recipeName)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }

                Spacer()

                // Calories & Arrow
                VStack(alignment: .trailing, spacing: Design.Spacing.xxs) {
                    Text("\(calories)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    Text("kcal")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .padding(Design.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.lg)
                    .fill(Color.backgroundSecondary)
                    .shadow(
                        color: Design.Shadow.sm.color,
                        radius: isPressed ? 2 : Design.Shadow.sm.radius,
                        y: isPressed ? 1 : Design.Shadow.sm.y
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(mealType.rawValue): \(recipeName), \(calories) calories")
        .accessibilityValue(isCompleted ? "Completed" : "Not completed")
        .accessibilityHint("Double tap to view recipe")
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(Design.Animation.quick) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Nutrition Ring Card
struct NutritionRingCard: View {
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
        return Double(consumed) / Double(target)
    }

    var body: some View {
        VStack(spacing: Design.Spacing.lg) {
            // Main Ring with Calories
            HStack(spacing: Design.Spacing.xl) {
                // Large Progress Ring
                ZStack {
                    ProgressRing(
                        progress: progress,
                        lineWidth: 12,
                        gradient: LinearGradient.brandGradient,
                        showLabel: false
                    )
                    .frame(width: 100, height: 100)

                    VStack(spacing: 2) {
                        Text("\(consumed)")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(.primary)
                        Text("/ \(target)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Macro Breakdown
                VStack(spacing: Design.Spacing.sm) {
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
        .premiumCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Calories: \(consumed) of \(target). Protein: \(protein) of \(proteinTarget) grams. Carbs: \(carbs) of \(carbsTarget) grams. Fat: \(fat) of \(fatTarget) grams")
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    var action: () -> Void = {}

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: Design.Spacing.xs) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(color)
                }

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Design.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.lg)
                    .fill(Color.backgroundSecondary)
                    .shadow(
                        color: Design.Shadow.sm.color,
                        radius: Design.Shadow.sm.radius,
                        y: Design.Shadow.sm.y
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(Design.Animation.quick) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    var action: String? = nil
    var onAction: () -> Void = {}

    var body: some View {
        HStack {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            Spacer()

            if let action = action {
                Button(action: onAction) {
                    Text(action)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.brandGreen)
                }
            }
        }
        .padding(.horizontal, Design.Spacing.xxs)
    }
}

// MARK: - Day Pill Selector
struct DayPillSelector: View {
    let days: [String]
    let dates: [Int]
    @Binding var selectedIndex: Int
    var todayIndex: Int = -1

    var body: some View {
        HStack(spacing: Design.Spacing.xs) {
            ForEach(0..<days.count, id: \.self) { index in
                DayPill(
                    day: days[index],
                    date: dates[index],
                    isSelected: selectedIndex == index,
                    isToday: index == todayIndex
                ) {
                    withAnimation(Design.Animation.smooth) {
                        selectedIndex = index
                    }
                }
            }
        }
    }
}

struct DayPill: View {
    let day: String
    let date: Int
    let isSelected: Bool
    let isToday: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Design.Spacing.xxs) {
                Text(day)
                    .font(.caption2)
                    .fontWeight(.medium)

                Text("\(date)")
                    .font(.system(.callout, design: .rounded, weight: .bold))
            }
            .foregroundStyle(isSelected ? Color.white : (isToday ? Color.brandGreen : Color.primary))
            .frame(maxWidth: .infinity)
            .padding(.vertical, Design.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.md)
                    .fill(isSelected ? LinearGradient.brandGradient : LinearGradient(colors: [Color.backgroundSecondary], startPoint: .top, endPoint: .bottom))
                    .shadow(
                        color: isSelected ? Color.brandGreen.opacity(0.3) : .clear,
                        radius: 8,
                        y: 4
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: Design.Radius.md)
                    .stroke(isToday && !isSelected ? Color.brandGreen : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(day) \(date)")
        .accessibilityValue(isSelected ? "Selected" : (isToday ? "Today" : ""))
        .accessibilityHint("Double tap to select")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Floating Primary Button
struct FloatingPrimaryButton: View {
    let title: String
    let icon: String
    var action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: Design.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, Design.Spacing.xl)
            .padding(.vertical, Design.Spacing.md)
            .background(
                Capsule()
                    .fill(LinearGradient.brandGradient)
                    .shadow(
                        color: Color.brandGreen.opacity(isPressed ? 0.2 : 0.4),
                        radius: isPressed ? 8 : 16,
                        y: isPressed ? 4 : 8
                    )
            )
            .scaleEffect(isPressed ? 0.96 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint("Double tap to activate")
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(Design.Animation.quick) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var buttonTitle: String? = nil
    var buttonIcon: String? = nil
    var onButtonTap: () -> Void = {}

    var body: some View {
        VStack(spacing: Design.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(LinearGradient.brandGradient.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: icon)
                    .font(.system(size: 48))
                    .foregroundStyle(LinearGradient.brandGradient)
            }

            VStack(spacing: Design.Spacing.xs) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Design.Spacing.xxl)
            }

            if let buttonTitle = buttonTitle {
                FloatingPrimaryButton(
                    title: buttonTitle,
                    icon: buttonIcon ?? "sparkles",
                    action: onButtonTap
                )
                .padding(.top, Design.Spacing.sm)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }
}

// MARK: - Grocery Item Row
struct PremiumGroceryItem: View {
    let name: String
    let quantity: String
    let category: GroceryCategory
    @Binding var isChecked: Bool

    var body: some View {
        HStack(spacing: Design.Spacing.md) {
            // Checkbox
            Button(action: {
                withAnimation(Design.Animation.smooth) {
                    isChecked.toggle()
                }
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isChecked ? LinearGradient.brandGradient : LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom))
                        .frame(width: 28, height: 28)

                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isChecked ? Color.clear : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 28, height: 28)

                    if isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            // Category Icon
            Image(systemName: category.icon)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .frame(width: 24)
                .accessibilityHidden(true)

            // Item Details
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(isChecked ? .secondary : .primary)
                    .strikethrough(isChecked)

                Text(quantity)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(Design.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Design.Radius.md)
                .fill(Color.backgroundSecondary)
                .opacity(isChecked ? 0.6 : 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(isChecked ? "Checked" : "Unchecked"), \(name), \(quantity)")
        .accessibilityHint("Double tap to toggle")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Recipe Card
struct PremiumRecipeCard: View {
    let name: String
    let mealType: String
    let calories: Int
    let cookTime: Int
    let complexity: RecipeComplexity
    @Binding var isFavorite: Bool
    var onTap: () -> Void = {}

    private var gradientForMealType: LinearGradient {
        switch mealType {
        case "Breakfast": return .sunriseGradient
        case "Lunch": return .freshGradient
        case "Dinner": return .eveningGradient
        default: return .skyGradient
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Image Area with Gradient
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: Design.Radius.md)
                        .fill(gradientForMealType)
                        .frame(height: 110)
                        .overlay(
                            Image(systemName: "fork.knife")
                                .font(.system(size: 36))
                                .foregroundStyle(.white.opacity(0.25))
                        )

                    // Favorite Button
                    Button(action: {
                        withAnimation(Design.Animation.bouncy) {
                            isFavorite.toggle()
                        }
                    }) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(isFavorite ? .white : .white.opacity(0.8))
                            .padding(10)
                            .background(
                                Circle()
                                    .fill(isFavorite ? Color.accentPink : Color.black.opacity(0.2))
                            )
                    }
                    .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
                    .padding(Design.Spacing.xs)
                }

                // Content
                VStack(alignment: .leading, spacing: Design.Spacing.xs) {
                    Text(mealType)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    Text(name)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: Design.Spacing.sm) {
                        Label("\(calories)", systemImage: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Label("\(cookTime)m", systemImage: "clock.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    // Complexity Badge
                    Text(complexity.label)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(complexityColor)
                        )
                }
                .padding(Design.Spacing.sm)
            }
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.lg)
                    .fill(Color.backgroundSecondary)
                    .shadow(
                        color: Design.Shadow.sm.color,
                        radius: Design.Shadow.sm.radius,
                        y: Design.Shadow.sm.y
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name), \(mealType), \(calories) calories, \(cookTime) minutes, \(complexity.label)")
        .accessibilityHint("Double tap to view recipe")
        .accessibilityAddTraits(.isButton)
    }

    private var complexityColor: Color {
        switch complexity {
        case .easy: return .brandGreen
        case .medium: return .accentOrange
        case .hard: return .accentPink
        }
    }
}

// MARK: - Tab Bar Badge
struct TabBarBadge: View {
    let count: Int

    var body: some View {
        if count > 0 {
            Text(count > 99 ? "99+" : "\(count)")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color.accentPink)
                )
        }
    }
}
