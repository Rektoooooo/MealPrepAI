import SwiftUI

// MARK: - Food Category
enum FoodCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case chicken = "Chicken"
    case pasta = "Pasta"
    case salad = "Salad"
    case soup = "Soup"
    case asian = "Asian"
    case mexican = "Mexican"
    case seafood = "Seafood"
    case vegetarian = "Vegetarian"
    case quick = "Quick"

    var id: String { rawValue }

    var imageName: String? {
        switch self {
        case .all: return nil // Use icon for "All"
        case .chicken: return "CategoryChicken"
        case .pasta: return "CategoryPasta"
        case .salad: return "CategorySalad"
        case .soup: return "CategorySoup"
        case .asian: return "CategoryAsian"
        case .mexican: return "CategoryMexican"
        case .seafood: return "CategorySeafood"
        case .vegetarian: return "CategoryVegetarian"
        case .quick: return nil // Use SF Symbol
        }
    }

    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .chicken: return "bird"
        case .pasta: return "fork.knife"
        case .salad: return "leaf"
        case .soup: return "cup.and.saucer"
        case .asian: return "takeoutbag.and.cup.and.straw"
        case .mexican: return "flame"
        case .seafood: return "fish"
        case .vegetarian: return "leaf.circle"
        case .quick: return "bolt.fill"
        }
    }

    var color: Color {
        switch self {
        case .all: return .accentPurple
        case .chicken: return .accentOrange
        case .pasta: return .accentYellow
        case .salad: return .mintVibrant
        case .soup: return .accentPink
        case .asian: return .accentBlue
        case .mexican: return .accentOrange
        case .seafood: return .accentBlue
        case .vegetarian: return .mintVibrant
        case .quick: return .accentPurple
        }
    }
}

// MARK: - Category Pill
struct CategoryPill: View {
    let category: FoodCategory
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Design.Spacing.xs) {
                // Circle with image or icon
                ZStack {
                    // Background circle
                    Circle()
                        .fill(isSelected ? category.color.opacity(0.15) : Color.backgroundSecondary)
                        .frame(width: 64, height: 64)

                    // Selected ring
                    if isSelected {
                        Circle()
                            .stroke(category.color, lineWidth: 3)
                            .frame(width: 64, height: 64)
                    }

                    // Image or icon
                    if let imageName = category.imageName {
                        Image(imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 54, height: 54)
                            .clipShape(Circle())
                    } else {
                        // Fallback icon for "All" category
                        Image(systemName: category.icon)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(isSelected ? category.color : .secondary)
                    }
                }
                .shadow(
                    color: isSelected ? category.color.opacity(0.3) : Color.black.opacity(0.05),
                    radius: isSelected ? 8 : 4,
                    y: isSelected ? 4 : 2
                )

                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
        .animation(Design.Animation.smooth, value: isSelected)
        .accessibilityIdentifier("recipes_category_\(category.rawValue.lowercased())")
        .accessibilityLabel("\(category.rawValue) category")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint("Double tap to select")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Category Pill Scroller
struct CategoryPillScroller: View {
    @Binding var selectedCategory: FoodCategory

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Design.Spacing.md) {
                ForEach(FoodCategory.allCases) { category in
                    CategoryPill(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(Design.Animation.smooth) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal, Design.Spacing.lg)
            .padding(.vertical, Design.Spacing.sm)
        }
    }
}
