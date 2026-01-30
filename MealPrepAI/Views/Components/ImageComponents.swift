import SwiftUI
import SwiftData
import UIKit

// MARK: - Recipe Async Image with Fallback
struct RecipeAsyncImage: View {
    let recipe: Recipe
    let height: CGFloat
    let cornerRadius: CGFloat
    var matchedImageUrl: String?

    var body: some View {
        Group {
            if let imageData = recipe.localImageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: height)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            } else {
                FoodImagePlaceholder(
                    style: recipe.cuisineType?.foodStyle ?? recipe.mealType?.foodStyle ?? .random,
                    height: height,
                    cornerRadius: cornerRadius,
                    showIcon: recipe.imageURL == nil,
                    iconSize: height * 0.3,
                    imageName: matchedImageUrl ?? recipe.highResImageURL ?? recipe.imageURL
                )
            }
        }
        .frame(height: height)
        .accessibilityLabel("Recipe image for \(recipe.name)")
        .accessibilityAddTraits(.isImage)
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
    var imageName: String? = nil

    var body: some View {
        if let urlString = imageName, let url = URL(string: urlString) {
            GeometryReader { geo in
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: height)
                            .clipped()
                    case .failure:
                        gradientPlaceholder
                    case .empty:
                        gradientPlaceholder
                            .shimmer()
                    @unknown default:
                        gradientPlaceholder
                    }
                }
            }
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            gradientPlaceholder
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .frame(height: height)
        }
    }

    // Extracted gradient placeholder view (decorative)
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
        case .american: return .meat
        case .italian: return .pizza
        case .mexican: return .meat
        case .french: return .dessert
        case .japanese, .korean, .vietnamese, .chinese, .thai: return .seafood
        case .mediterranean, .greek: return .healthy
        case .indian, .middleEastern: return .pizza
        case .spanish: return .seafood
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
