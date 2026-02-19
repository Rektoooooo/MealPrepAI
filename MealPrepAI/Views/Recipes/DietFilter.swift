import SwiftUI

// MARK: - Recipe Filter (Combined Nutrition + Diet)
enum RecipeFilter: String, CaseIterable, Identifiable {
    // Nutrition filters
    case lowCalorie = "Low Cal"
    case highProtein = "Protein+"
    case lowCarb = "Low Carb"
    case lowFat = "Low Fat"

    // Diet filters
    case vegan = "Vegan"
    case vegetarian = "Vegetarian"
    case glutenFree = "Gluten-Free"
    case dairyFree = "Dairy-Free"

    var id: String { rawValue }

    var icon: String {
        switch self {
        // Nutrition
        case .lowCalorie: return "flame.fill"
        case .highProtein: return "bolt.fill"
        case .lowCarb: return "leaf.fill"
        case .lowFat: return "drop.fill"
        // Diet
        case .vegan: return "leaf.circle.fill"
        case .vegetarian: return "leaf"
        case .glutenFree: return "xmark.circle"
        case .dairyFree: return "cup.and.saucer"
        }
    }

    var color: Color {
        switch self {
        // Nutrition
        case .lowCalorie: return .accentOrange
        case .highProtein: return .proteinColor
        case .lowCarb: return .carbColor
        case .lowFat: return .fatColor
        // Diet
        case .vegan: return .mintVibrant
        case .vegetarian: return .green
        case .glutenFree: return .accentYellow
        case .dairyFree: return .accentBlue
        }
    }

    /// Check if this is a diet-based filter (vs nutrition-based)
    var isDietFilter: Bool {
        switch self {
        case .vegan, .vegetarian, .glutenFree, .dairyFree:
            return true
        default:
            return false
        }
    }

    /// The search terms to match against recipe diets array
    private var dietSearchTerms: [String] {
        switch self {
        case .vegan: return ["vegan"]
        case .vegetarian: return ["vegetarian", "lacto vegetarian", "ovo vegetarian", "lacto-ovo vegetarian"]
        case .glutenFree: return ["gluten free", "gluten-free"]
        case .dairyFree: return ["dairy free", "dairy-free", "lactose free", "lactose-free"]
        default: return []
        }
    }

    func matches(_ recipe: Recipe) -> Bool {
        switch self {
        // Nutrition filters
        case .lowCalorie:
            return recipe.calories < 400
        case .highProtein:
            return recipe.proteinGrams >= 25
        case .lowCarb:
            return recipe.carbsGrams < 30
        case .lowFat:
            return recipe.fatGrams < 15
        // Diet filters — uses cached lowercased diets to avoid re-allocating per call
        case .vegan, .vegetarian, .glutenFree, .dairyFree:
            let recipeDiets = recipe.cachedLowercasedDiets
            return dietSearchTerms.contains { term in
                recipeDiets.contains { diet in
                    diet.contains(term)
                }
            }
        }
    }
}

// MARK: - Diet Badge Helper
extension Recipe {
    /// Returns display-friendly diet labels for this recipe
    var displayDiets: [DietBadge] {
        var badges: [DietBadge] = []
        let lowercasedDiets = cachedLowercasedDiets

        // Check for each diet type
        if lowercasedDiets.contains(where: { $0.contains("vegan") }) {
            badges.append(DietBadge(name: "Vegan", color: .mintVibrant, icon: "leaf.circle.fill"))
        } else if lowercasedDiets.contains(where: { $0.contains("vegetarian") }) {
            badges.append(DietBadge(name: "Vegetarian", color: .green, icon: "leaf"))
        }

        if lowercasedDiets.contains(where: { $0.contains("gluten free") || $0.contains("gluten-free") }) {
            badges.append(DietBadge(name: "GF", color: .accentYellow, icon: "xmark.circle"))
        }

        if lowercasedDiets.contains(where: { $0.contains("dairy free") || $0.contains("dairy-free") || $0.contains("lactose") }) {
            badges.append(DietBadge(name: "DF", color: .accentBlue, icon: "cup.and.saucer"))
        }

        return badges
    }
}

struct DietBadge: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
    let icon: String
}
