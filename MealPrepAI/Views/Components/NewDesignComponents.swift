import SwiftUI
import SwiftData

// MARK: - Recipe Async Image with Fallback
/// Smart image loader that tries high-res first, falls back to original, then placeholder
struct RecipeAsyncImage: View {
    let recipe: Recipe
    let height: CGFloat
    let cornerRadius: CGFloat

    @State private var useOriginalURL = false
    @State private var loadFailed = false

    private var currentURL: URL? {
        if loadFailed {
            return nil
        }

        let urlString: String?
        if useOriginalURL {
            urlString = recipe.imageURL
        } else {
            urlString = recipe.highResImageURL ?? recipe.imageURL
        }

        guard let str = urlString, str.hasPrefix("http") else { return nil }
        return URL(string: str)
    }

    var body: some View {
        Group {
            if let url = currentURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            placeholderView
                            ProgressView()
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: height)
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    case .failure:
                        // Try fallback to original URL if high-res failed
                        if !useOriginalURL && recipe.highResImageURL != recipe.imageURL {
                            Color.clear
                                .onAppear {
                                    useOriginalURL = true
                                }
                        } else {
                            placeholderView
                                .onAppear {
                                    loadFailed = true
                                }
                        }
                    @unknown default:
                        placeholderView
                    }
                }
            } else {
                placeholderView
            }
        }
        .frame(height: height)
    }

    private var placeholderView: some View {
        FoodImagePlaceholder(
            style: recipe.cuisineType?.foodStyle ?? .random,
            height: height,
            cornerRadius: cornerRadius,
            showIcon: true,
            iconSize: height * 0.3
        )
    }
}

// MARK: - Food Image Placeholder
// Creates colorful gradient backgrounds that simulate food photography
struct FoodImagePlaceholder: View {
    enum FoodStyle {
        case salad      // Fresh greens
        case pizza      // Warm oranges/reds
        case breakfast  // Sunny yellows/oranges
        case seafood    // Ocean blues
        case meat       // Rich browns/reds
        case dessert    // Pink/purple pastels
        case healthy    // Vibrant greens
        case random     // Random colorful

        var gradient: [Color] {
            switch self {
            case .salad:
                return [.mintVibrant, Color(red: 0.66, green: 0.90, blue: 0.81), Color(red: 0.53, green: 0.85, blue: 0.69)]
            case .pizza:
                return [Color(red: 1, green: 0.42, blue: 0.42), Color(red: 1, green: 0.63, blue: 0.48), .accentYellow]
            case .breakfast:
                return [.breakfastGradientStart, .accentYellow, .breakfastGradientEnd]
            case .seafood:
                return [.accentPurple, .accentBlue, Color(red: 0.30, green: 0.82, blue: 0.88)]
            case .meat:
                return [Color(red: 0.55, green: 0.27, blue: 0.07), Color(red: 0.80, green: 0.52, blue: 0.25), Color(red: 0.82, green: 0.41, blue: 0.12)]
            case .dessert:
                return [.accentPink, Color(red: 0.77, green: 0.29, blue: 1), Color(red: 1, green: 0.71, blue: 0.76)]
            case .healthy:
                return [Color(red: 0.07, green: 0.60, blue: 0.56), .mintVibrant, Color(red: 0.34, green: 0.67, blue: 0.18)]
            case .random:
                return randomGradient()
            }
        }

        var icon: String {
            switch self {
            case .salad: return "leaf.fill"
            case .pizza: return "flame.fill"
            case .breakfast: return "sun.max.fill"
            case .seafood: return "fish.fill"
            case .meat: return "fork.knife"
            case .dessert: return "birthday.cake.fill"
            case .healthy: return "heart.fill"
            case .random: return "sparkles"
            }
        }

        private func randomGradient() -> [Color] {
            let options: [[Color]] = [
                [Color(red: 1, green: 0.42, blue: 0.42), Color(red: 0.31, green: 0.80, blue: 0.77)],
                [.accentPurple, Color(red: 0.81, green: 0.55, blue: 0.95), .breakfastGradientStart],
                [.accentPink, .accentYellow],
                [.accentBlue, .mintVibrant],
                [Color(red: 0.99, green: 0.27, blue: 0.42), .accentPurple],
                [.accentYellow, Color(red: 1, green: 0.31, blue: 0.31)],
            ]
            return options.randomElement() ?? options[0]
        }
    }

    let style: FoodStyle
    var height: CGFloat = 150
    var cornerRadius: CGFloat = Design.Radius.lg
    var showIcon: Bool = true
    var iconSize: CGFloat = 40
    var imageName: String? = nil  // Optional real image

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Check if it's a remote URL
                if let imageName = imageName,
                   imageName.hasPrefix("http"),
                   let url = URL(string: imageName) {
                    // Remote image from URL
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            // Loading state - show gradient placeholder
                            gradientPlaceholder
                        case .success(let image):
                            // Loaded successfully
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: height)
                                .clipped()
                        case .failure:
                            // Failed to load - show gradient placeholder
                            gradientPlaceholder
                        @unknown default:
                            gradientPlaceholder
                        }
                    }
                } else if let imageName = imageName, let uiImage = UIImage(named: imageName) {
                    // Local image from asset catalog
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: height)
                        .clipped()
                } else {
                    // No image - show gradient placeholder
                    gradientPlaceholder
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
        .frame(height: height)
    }

    // Extracted gradient placeholder view
    private var gradientPlaceholder: some View {
        ZStack {
            // Gradient background
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: style.gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: height)

            // Decorative circles for depth
            Circle()
                .fill(.white.opacity(0.1))
                .frame(width: height * 0.8)
                .offset(x: height * 0.3, y: -height * 0.2)

            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: height * 0.5)
                .offset(x: -height * 0.4, y: height * 0.15)

            // Icon
            if showIcon {
                Image(systemName: style.icon)
                    .font(.system(size: iconSize))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }
}

// Helper to get food style from cuisine type
extension CuisineType {
    var foodStyle: FoodImagePlaceholder.FoodStyle {
        switch self {
        case .italian: return .pizza
        case .mexican: return .meat
        case .japanese, .korean, .vietnamese, .chinese, .thai: return .seafood
        case .mediterranean, .greek: return .healthy
        case .american, .caribbean: return .breakfast
        case .indian, .middleEastern: return .pizza
        case .french, .spanish: return .salad
        }
    }
}

// Helper to get food style from meal type
extension MealType {
    var foodStyle: FoodImagePlaceholder.FoodStyle {
        switch self {
        case .breakfast: return .breakfast
        case .lunch: return .salad
        case .dinner: return .meat
        case .snack: return .dessert
        }
    }
}

// MARK: - Greeting Header
struct GreetingHeader: View {
    let userName: String
    var avatarInitials: String? = nil

    private var initials: String {
        avatarInitials ?? String(userName.prefix(2)).uppercased()
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
    }

    var body: some View {
        HStack(spacing: Design.Spacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(LinearGradient.purpleButtonGradient)
                    .frame(width: 50, height: 50)

                Text(initials)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(userName)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }

            Spacer()
        }
    }
}

// MARK: - Rounded Search Bar
struct RoundedSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search recipes..."
    var onSubmit: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: Design.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $text)
                .font(.body)
                .submitLabel(.search)
                .onSubmit {
                    onSubmit?()
                }

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.horizontal, Design.Spacing.md)
        .padding(.vertical, Design.Spacing.sm + 2)
        .background(
            Capsule()
                .fill(Color.backgroundSecondary)
        )
    }
}

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

// MARK: - Featured Recipe Card
struct FeaturedRecipeCard: View {
    let recipe: Recipe
    var onTap: () -> Void
    var onFavorite: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                // Background Image
                ZStack(alignment: .bottom) {
                    // Real image or colorful food-themed gradient placeholder
                    FoodImagePlaceholder(
                        style: recipe.cuisineType?.foodStyle ?? .random,
                        height: 220,
                        cornerRadius: Design.Radius.featured,
                        showIcon: recipe.imageURL == nil,
                        iconSize: 60,
                        imageName: recipe.highResImageURL ?? recipe.imageURL
                    )

                    // Purple overlay gradient for text readability
                    LinearGradient(
                        colors: [.clear, Color.accentPurpleDeep.opacity(0.85)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Design.Radius.featured))

                    // Content
                    VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                        // Cuisine badge
                        Text(recipe.cuisineType?.rawValue ?? "Recipe")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, Design.Spacing.sm)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(.white.opacity(0.2))
                            )

                        Text(recipe.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .lineLimit(2)

                        HStack(spacing: Design.Spacing.lg) {
                            // Time
                            HStack(spacing: Design.Spacing.xs) {
                                Image(systemName: "clock.fill")
                                    .font(.caption)
                                Text("\(recipe.totalTimeMinutes) min")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(.white.opacity(0.9))

                            // Calories per serving
                            HStack(spacing: Design.Spacing.xs) {
                                Image(systemName: "flame.fill")
                                    .font(.caption)
                                Text("\(recipe.caloriesPerServing) cal/serving")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(.white.opacity(0.9))

                            Spacer()

                            // See Recipe button
                            Text("See Recipe")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, Design.Spacing.md)
                                .padding(.vertical, Design.Spacing.xs)
                                .background(
                                    Capsule()
                                        .fill(.white.opacity(0.25))
                                )
                        }
                    }
                    .padding(Design.Spacing.lg)
                }

                // Favorite button
                Button(action: onFavorite) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 40, height: 40)

                        Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 18))
                            .foregroundStyle(recipe.isFavorite ? .red : .white)
                    }
                }
                .padding(Design.Spacing.md)
            }
        }
        .buttonStyle(.plain)
        .featuredCard()
    }
}

// MARK: - Stacked Recipe Card (for grids)
struct StackedRecipeCard: View {
    let recipe: Recipe
    var onTap: () -> Void
    var onAdd: (() -> Void)? = nil

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Image area with badges overlay
                ZStack {
                    FoodImagePlaceholder(
                        style: recipe.cuisineType?.foodStyle ?? .random,
                        height: 140,
                        cornerRadius: 0,
                        showIcon: recipe.imageURL == nil,
                        iconSize: 36,
                        imageName: recipe.highResImageURL ?? recipe.imageURL
                    )
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: Design.Radius.card,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: Design.Radius.card
                        )
                    )

                    // Gradient overlay for badges
                    VStack {
                        Spacer()
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 50)
                    }
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: Design.Radius.card,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: Design.Radius.card
                        )
                    )

                    // Badges layer
                    VStack {
                        // Top row: Add button
                        HStack {
                            Spacer()
                            if let onAdd = onAdd {
                                Button(action: onAdd) {
                                    ZStack {
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                            .frame(width: 34, height: 34)

                                        Image(systemName: "plus")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(Color.accentPurple)
                                    }
                                }
                            }
                        }
                        .padding(Design.Spacing.sm)

                        Spacer()

                        // Bottom row: Time & Cuisine badges
                        HStack {
                            // Time badge
                            HStack(spacing: 3) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 9))
                                Text("\(recipe.totalTimeMinutes)m")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(.black.opacity(0.5))
                            )

                            Spacer()

                            // Cuisine badge (if available)
                            if let cuisine = recipe.cuisineType {
                                Text(cuisine.rawValue)
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule()
                                            .fill(Color.accentPurple.opacity(0.8))
                                    )
                            }
                        }
                        .padding(.horizontal, Design.Spacing.sm)
                        .padding(.bottom, Design.Spacing.sm)
                    }
                }
                .frame(height: 140)

                // Info section
                VStack(alignment: .leading, spacing: 6) {
                    Text(recipe.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(height: 38, alignment: .top)

                    // Stats row
                    HStack(spacing: 0) {
                        // Calories
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.accentOrange)
                            Text("\(recipe.caloriesPerServing)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                        }

                        Text(" kcal")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)

                        Spacer()

                        // Servings
                        HStack(spacing: 3) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(Color.mintVibrant)
                            Text("\(recipe.servings)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        // Favorite
                        Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 12))
                            .foregroundStyle(recipe.isFavorite ? .red : .secondary.opacity(0.5))
                    }
                }
                .padding(.horizontal, Design.Spacing.sm)
                .padding(.vertical, Design.Spacing.sm)
                .frame(height: 75)
            }
            .frame(height: 215)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Design.Radius.card))
            .shadow(
                color: Design.Shadow.card.color.opacity(0.8),
                radius: Design.Shadow.card.radius,
                y: Design.Shadow.card.y
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Personalization Banner
struct PersonalizationBanner: View {
    var title: String = "Personalise Meal Plan"
    var subtitle: String = "To personalize your menu, we still need information."
    var buttonText: String = "Fill in Data"
    var onTap: () -> Void

    // Brown colors for text
    private let titleColor = Color(red: 0.30, green: 0.20, blue: 0.15)
    private let subtitleColor = Color(red: 0.45, green: 0.35, blue: 0.28)
    private let buttonTextColor = Color(red: 0.35, green: 0.25, blue: 0.18)

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Background
            RoundedRectangle(cornerRadius: Design.Radius.card)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.95, blue: 0.78),
                            Color(red: 0.99, green: 0.90, blue: 0.68)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Right side - Large Image (positioned to overflow bottom)
            Image("MealPlanBanner")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 170, height: 190)
                .offset(x: 5, y: 5)

            // Left side - Text and button
            VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(titleColor)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(subtitleColor)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 180, alignment: .leading)

                Spacer()

                Button(action: onTap) {
                    Text(buttonText)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(buttonTextColor)
                        .padding(.horizontal, Design.Spacing.xl)
                        .padding(.vertical, Design.Spacing.md)
                        .background(
                            Capsule()
                                .fill(Color.accentYellow)
                                .shadow(
                                    color: Color.accentYellow.opacity(0.4),
                                    radius: 8,
                                    y: 4
                                )
                        )
                }
            }
            .padding(.leading, Design.Spacing.lg)
            .padding(.top, Design.Spacing.lg)
            .padding(.bottom, Design.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: Design.Radius.card))
    }
}

// MARK: - Section Header (Updated)
struct NewSectionHeader: View {
    let title: String
    var emoji: String? = nil
    var icon: String? = nil
    var iconColor: Color = Color.accentPurple
    var showSeeAll: Bool = false
    var onSeeAll: (() -> Void)? = nil

    var body: some View {
        HStack {
            HStack(spacing: Design.Spacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(iconColor)
                } else if let emoji = emoji {
                    Text(emoji)
                }
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }

            Spacer()

            if showSeeAll, let onSeeAll = onSeeAll {
                Button(action: onSeeAll) {
                    Text("See all")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.accentPurple)
                }
            }
        }
    }
}

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

// MARK: - Quick Action Button
struct QuickActionCard: View {
    let icon: String
    let title: String
    let color: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Design.Spacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: Design.Radius.md)
                        .fill(color.opacity(0.15))
                        .frame(width: 52, height: 52)

                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(color)
                }

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Design.Spacing.md)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Design.Radius.card))
            .shadow(
                color: Design.Shadow.sm.color,
                radius: Design.Shadow.sm.radius,
                y: Design.Shadow.sm.y
            )
        }
        .buttonStyle(.plain)
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

// MARK: - Empty State View (Updated)
struct NewEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var buttonTitle: String? = nil
    var buttonIcon: String? = nil
    var buttonStyle: EmptyStateButtonStyle = .purple
    var onButtonTap: (() -> Void)? = nil

    enum EmptyStateButtonStyle {
        case purple, yellow, green
    }

    var body: some View {
        VStack(spacing: Design.Spacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.mintLight)
                    .frame(width: 120, height: 120)

                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundStyle(Color.mintVibrant)
            }

            VStack(spacing: Design.Spacing.sm) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Design.Spacing.xl)
            }

            if let buttonTitle = buttonTitle, let onButtonTap = onButtonTap {
                styledButton(title: buttonTitle, icon: buttonIcon, action: onButtonTap)
                    .padding(.top, Design.Spacing.md)
            }

            Spacer()
        }
    }

    @ViewBuilder
    private func styledButton(title: String, icon: String?, action: @escaping () -> Void) -> some View {
        switch buttonStyle {
        case .purple:
            Button(action: action) {
                HStack(spacing: Design.Spacing.sm) {
                    if let icon = icon {
                        Image(systemName: icon)
                    }
                    Text(title)
                }
            }
            .purpleButton()
        case .yellow:
            Button(action: action) {
                HStack(spacing: Design.Spacing.sm) {
                    if let icon = icon {
                        Image(systemName: icon)
                    }
                    Text(title)
                }
            }
            .yellowButton()
        case .green:
            Button(action: action) {
                HStack(spacing: Design.Spacing.sm) {
                    if let icon = icon {
                        Image(systemName: icon)
                    }
                    Text(title)
                }
            }
            .floatingButton()
        }
    }
}

// MARK: - Previews
#Preview("Greeting Header") {
    VStack {
        GreetingHeader(userName: "Emily Ava")
            .padding()

        RoundedSearchBar(text: .constant(""))
            .padding()
    }
    .background(Color.backgroundMint)
}

#Preview("Category Pills") {
    CategoryPillScroller(selectedCategory: .constant(.salad))
        .background(Color.backgroundMint)
}

#Preview("Section Header") {
    VStack(spacing: Design.Spacing.lg) {
        NewSectionHeader(title: "Explore Recipes", emoji: nil, showSeeAll: true) {}
        NewSectionHeader(title: "Meal Plan", emoji: nil, showSeeAll: false)
    }
    .padding()
}

#Preview("Personalization Banner") {
    PersonalizationBanner {}
        .padding()
}
