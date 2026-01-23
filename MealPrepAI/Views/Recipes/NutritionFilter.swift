import SwiftUI

// MARK: - Nutrition Filter Options
enum NutritionFilter: String, CaseIterable, Identifiable {
    case none = "All"
    case lowCalorie = "Low Cal"
    case highProtein = "Protein+"
    case lowCarb = "Low Carb"
    case lowFat = "Low Fat"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .none: return "slider.horizontal.3"
        case .lowCalorie: return "flame.fill"
        case .highProtein: return "bolt.fill"
        case .lowCarb: return "leaf.fill"
        case .lowFat: return "drop.fill"
        }
    }

    var color: Color {
        switch self {
        case .none: return .secondary
        case .lowCalorie: return .accentOrange
        case .highProtein: return .proteinColor
        case .lowCarb: return .carbColor
        case .lowFat: return .fatColor
        }
    }

    func matches(_ recipe: Recipe) -> Bool {
        switch self {
        case .none:
            return true
        case .lowCalorie:
            return recipe.calories < 400
        case .highProtein:
            return recipe.proteinGrams >= 25
        case .lowCarb:
            return recipe.carbsGrams < 30
        case .lowFat:
            return recipe.fatGrams < 15
        }
    }
}
