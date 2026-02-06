import Foundation
import SwiftData

@Model
final class Ingredient {
    var id: UUID = UUID()
    var name: String = ""
    var categoryRaw: String = "Other"
    var defaultUnitRaw: String = "g"

    // Nutrition per 100g
    var caloriesPer100g: Int = 0
    var proteinPer100g: Double = 0
    var carbsPer100g: Double = 0
    var fatPer100g: Double = 0

    // Relationships
    @Relationship(inverse: \RecipeIngredient.ingredient)
    var recipeIngredients: [RecipeIngredient] = []

    @Relationship(inverse: \GroceryItem.ingredient)
    var groceryItems: [GroceryItem] = []

    var category: GroceryCategory {
        get { GroceryCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var defaultUnit: MeasurementUnit {
        get { MeasurementUnit(rawValue: defaultUnitRaw) ?? .gram }
        set { defaultUnitRaw = newValue.rawValue }
    }

    init(
        name: String = "",
        category: GroceryCategory = .other,
        defaultUnit: MeasurementUnit = .gram,
        caloriesPer100g: Int = 0,
        proteinPer100g: Double = 0,
        carbsPer100g: Double = 0,
        fatPer100g: Double = 0
    ) {
        self.id = UUID()
        self.name = name
        self.categoryRaw = category.rawValue
        self.defaultUnitRaw = defaultUnit.rawValue
        self.caloriesPer100g = caloriesPer100g
        self.proteinPer100g = proteinPer100g
        self.carbsPer100g = carbsPer100g
        self.fatPer100g = fatPer100g
    }
}
