import Testing
import Foundation
@testable import MealPrepAI

struct GroceryItemTests {

    @Test func displayQuantityFormatsWholeNumber() {
        let item = GroceryItem(quantity: 2, unit: .cup)
        #expect(item.displayQuantity == "2 cup")
    }

    @Test func displayQuantityFormatsDecimal() {
        let item = GroceryItem(quantity: 1.5, unit: .tablespoon)
        #expect(item.displayQuantity == "1.5 tbsp")
    }

    @Test func displayNameReturnsIngredientName() {
        let item = GroceryItem()
        let ingredient = Ingredient(name: "Olive Oil")
        item.ingredient = ingredient
        #expect(item.displayName == "Olive Oil")
    }

    @Test func displayNameFallsBackToUnknown() {
        let item = GroceryItem()
        #expect(item.displayName == "Unknown Item")
    }

    @Test func unitComputedProperty() {
        let item = GroceryItem(unit: .gram)
        #expect(item.unit == .gram)
        #expect(item.unitRaw == "g")
    }
}
