import Foundation
import SwiftData

@Model
final class Recipe {
    var id: UUID
    var name: String
    var recipeDescription: String
    var instructionsData: Data?  // Store as JSON Data
    var prepTimeMinutes: Int
    var cookTimeMinutes: Int
    var servings: Int
    var complexityRaw: Int
    var cuisineTypeRaw: String?
    var imageURL: String?

    // Nutrition
    var calories: Int
    var proteinGrams: Int
    var carbsGrams: Int
    var fatGrams: Int
    var fiberGrams: Int

    // Metadata
    var isFavorite: Bool
    var timesUsed: Int
    var lastUsedDate: Date?
    var isCustom: Bool
    var sourceURL: String?
    var createdAt: Date

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \RecipeIngredient.recipe)
    var ingredients: [RecipeIngredient]?

    @Relationship(inverse: \Meal.recipe)
    var meals: [Meal]?

    // Computed properties for enums and arrays
    var instructions: [String] {
        get {
            guard let data = instructionsData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            instructionsData = try? JSONEncoder().encode(newValue)
        }
    }

    var complexity: RecipeComplexity {
        get { RecipeComplexity(rawValue: complexityRaw) ?? .medium }
        set { complexityRaw = newValue.rawValue }
    }

    var cuisineType: CuisineType? {
        get { cuisineTypeRaw.flatMap { CuisineType(rawValue: $0) } }
        set { cuisineTypeRaw = newValue?.rawValue }
    }

    var totalTimeMinutes: Int {
        prepTimeMinutes + cookTimeMinutes
    }

    var totalTimeFormatted: String {
        let total = totalTimeMinutes
        if total < 60 {
            return "\(total) min"
        } else {
            let hours = total / 60
            let minutes = total % 60
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
    }

    func matchesCategory(_ category: FoodCategory) -> Bool {
        let searchText = (name + " " + recipeDescription).lowercased()

        switch category {
        case .all:
            return true
        case .salad:
            return searchText.contains("salad") || searchText.contains("greens") || searchText.contains("lettuce")
        case .pizza:
            return searchText.contains("pizza") || searchText.contains("flatbread")
        case .burger:
            return searchText.contains("burger") || searchText.contains("hamburger") || searchText.contains("patty")
        case .steak:
            return searchText.contains("steak") || searchText.contains("beef") || searchText.contains("ribeye") || searchText.contains("sirloin")
        case .seafood:
            return searchText.contains("fish") || searchText.contains("salmon") || searchText.contains("shrimp") ||
                   searchText.contains("tuna") || searchText.contains("seafood") || searchText.contains("lobster") ||
                   searchText.contains("crab") || searchText.contains("cod") || searchText.contains("tilapia")
        case .breakfast:
            return searchText.contains("breakfast") || searchText.contains("egg") || searchText.contains("pancake") ||
                   searchText.contains("waffle") || searchText.contains("oatmeal") || searchText.contains("omelette") ||
                   searchText.contains("toast") || searchText.contains("cereal") || searchText.contains("smoothie bowl")
        case .healthy:
            return searchText.contains("healthy") || searchText.contains("light") || searchText.contains("low-calorie") ||
                   searchText.contains("nutritious") || searchText.contains("wellness") || calories < 400
        case .dessert:
            return searchText.contains("dessert") || searchText.contains("cake") || searchText.contains("cookie") ||
                   searchText.contains("ice cream") || searchText.contains("chocolate") || searchText.contains("sweet") ||
                   searchText.contains("brownie") || searchText.contains("pie") || searchText.contains("pudding")
        }
    }

    init(
        name: String = "",
        recipeDescription: String = "",
        instructions: [String] = [],
        prepTimeMinutes: Int = 10,
        cookTimeMinutes: Int = 20,
        servings: Int = 2,
        complexity: RecipeComplexity = .medium,
        cuisineType: CuisineType? = nil,
        calories: Int = 0,
        proteinGrams: Int = 0,
        carbsGrams: Int = 0,
        fatGrams: Int = 0,
        fiberGrams: Int = 0,
        isFavorite: Bool = false,
        isCustom: Bool = false,
        imageURL: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.recipeDescription = recipeDescription
        self.instructionsData = try? JSONEncoder().encode(instructions)
        self.prepTimeMinutes = prepTimeMinutes
        self.cookTimeMinutes = cookTimeMinutes
        self.servings = servings
        self.complexityRaw = complexity.rawValue
        self.cuisineTypeRaw = cuisineType?.rawValue
        self.imageURL = imageURL
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.carbsGrams = carbsGrams
        self.fatGrams = fatGrams
        self.fiberGrams = fiberGrams
        self.isFavorite = isFavorite
        self.timesUsed = 0
        self.isCustom = isCustom
        self.createdAt = Date()
    }
}
