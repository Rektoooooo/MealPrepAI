import Foundation

// MARK: - Firebase Recipe Model
/// Represents a recipe fetched from Firebase Firestore
/// This is a Codable struct that maps to the Firestore document structure
struct FirebaseRecipe: Codable, Identifiable, Sendable {
    /// Firebase document ID (set by Firestore)
    var id: String?

    /// Spoonacular external ID
    let externalId: Int

    /// Recipe title
    let title: String

    /// URL to recipe image (hosted by Spoonacular)
    let imageUrl: String?

    /// Total time to prepare in minutes
    let readyInMinutes: Int

    /// Number of servings
    let servings: Int

    // MARK: - Nutrition
    let calories: Int
    let proteinGrams: Int
    let carbsGrams: Int
    let fatGrams: Int

    // MARK: - Recipe Details
    /// Array of instruction steps
    let instructions: [String]

    /// Primary cuisine type (e.g., "italian", "mexican")
    let cuisineType: String

    /// Meal type: "breakfast", "lunch", "dinner", or "snack"
    let mealType: String

    /// Dietary tags (e.g., ["vegetarian", "gluten-free"])
    let diets: [String]

    /// Dish types (e.g., ["main course", "side dish"])
    let dishTypes: [String]

    /// Spoonacular health score (0-100)
    let healthScore: Int

    /// Original recipe source URL
    let sourceUrl: String?

    /// Attribution text for the recipe source
    let creditsText: String?

    // MARK: - Ingredients
    let ingredients: [FirebaseIngredient]

    /// Server timestamp when recipe was added to Firestore
    let createdAt: Date?

    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case externalId
        case title
        case imageUrl
        case readyInMinutes
        case servings
        case calories
        case proteinGrams
        case carbsGrams
        case fatGrams
        case instructions
        case cuisineType
        case mealType
        case diets
        case dishTypes
        case healthScore
        case sourceUrl
        case creditsText
        case ingredients
        case createdAt
    }
}

// MARK: - Firebase Ingredient Model
/// Represents an ingredient within a Firebase recipe
struct FirebaseIngredient: Codable, Identifiable, Sendable {
    var id: String { "\(name)-\(amount)-\(unit)" }

    /// Ingredient name
    let name: String

    /// Quantity amount
    let amount: Double

    /// Measurement unit (e.g., "cups", "grams", "pieces")
    let unit: String

    /// Grocery store aisle (e.g., "Produce", "Dairy")
    let aisle: String
}

// MARK: - Convenience Extensions
extension FirebaseRecipe {
    /// Maps Firebase mealType string to app's MealType enum
    var appMealType: MealType {
        switch mealType.lowercased() {
        case "breakfast": return .breakfast
        case "lunch": return .lunch
        case "dinner": return .dinner
        case "snack": return .snack
        default: return .dinner
        }
    }

    /// Maps Firebase cuisineType string to app's CuisineType enum
    var appCuisineType: CuisineType? {
        let lowercased = cuisineType.lowercased()
        return CuisineType.allCases.first {
            $0.rawValue.lowercased() == lowercased
        }
    }

    /// Checks if recipe matches a dietary restriction
    func matchesDiet(_ diet: DietaryRestriction) -> Bool {
        let dietString = diet.rawValue.lowercased()
        return diets.contains { $0.lowercased().contains(dietString) }
    }

    /// Determines recipe complexity based on instruction count and time
    var estimatedComplexity: RecipeComplexity {
        if readyInMinutes <= 20 && instructions.count <= 5 {
            return .easy
        } else if readyInMinutes >= 60 || instructions.count >= 12 {
            return .hard
        }
        return .medium
    }
}

extension FirebaseIngredient {
    /// Maps aisle string to app's GroceryCategory enum
    var appCategory: GroceryCategory {
        let lowercased = aisle.lowercased()

        if lowercased.contains("produce") || lowercased.contains("vegetable") || lowercased.contains("fruit") {
            return .produce
        } else if lowercased.contains("meat") || lowercased.contains("seafood") {
            return .meat
        } else if lowercased.contains("dairy") || lowercased.contains("milk") || lowercased.contains("cheese") || lowercased.contains("egg") {
            return .dairy
        } else if lowercased.contains("baking") || lowercased.contains("bread") || lowercased.contains("bakery") {
            return .bakery
        } else if lowercased.contains("frozen") {
            return .frozen
        } else if lowercased.contains("canned") {
            return .canned
        } else if lowercased.contains("condiment") || lowercased.contains("sauce") {
            return .condiments
        } else if lowercased.contains("spice") || lowercased.contains("season") {
            return .spices
        } else if lowercased.contains("beverage") || lowercased.contains("drink") {
            return .beverages
        } else if lowercased.contains("snack") {
            return .snacks
        } else if lowercased.contains("pasta") || lowercased.contains("rice") || lowercased.contains("grain") || lowercased.contains("cereal") {
            return .pantry
        }

        return .other
    }

    /// Maps unit string to app's MeasurementUnit enum
    var appUnit: MeasurementUnit {
        let lowercased = unit.lowercased()

        switch lowercased {
        case "cup", "cups": return .cup
        case "tbsp", "tablespoon", "tablespoons": return .tablespoon
        case "tsp", "teaspoon", "teaspoons": return .teaspoon
        case "fl oz", "fluid ounce", "fluid ounces": return .fluidOunce
        case "ml", "milliliter", "milliliters": return .milliliter
        case "l", "liter", "liters": return .liter
        case "g", "gram", "grams": return .gram
        case "kg", "kilogram", "kilograms": return .kilogram
        case "oz", "ounce", "ounces": return .ounce
        case "lb", "pound", "pounds": return .pound
        case "piece", "pieces": return .piece
        case "slice", "slices": return .slice
        case "clove", "cloves": return .clove
        case "bunch", "bunches": return .bunch
        case "can", "cans": return .can
        case "package", "packages", "pkg": return .package
        default: return .piece
        }
    }
}
