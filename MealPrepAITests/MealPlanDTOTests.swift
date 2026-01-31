import Testing
import Foundation
@testable import MealPrepAI

struct MealPlanDTOTests {

    // MARK: - RecipeDTO.toRecipe

    @Test func recipeDTOToRecipeMapsCorrectly() {
        let dto = RecipeDTO(
            name: "Test Recipe",
            description: "A test recipe",
            instructions: ["Step 1", "Step 2"],
            prepTimeMinutes: 10,
            cookTimeMinutes: 20,
            servings: 4,
            complexity: "easy",
            cuisineType: "Italian",
            calories: 500,
            proteinGrams: 30,
            carbsGrams: 50,
            fatGrams: 20,
            fiberGrams: 5,
            ingredients: []
        )
        let recipe = dto.toRecipe()

        #expect(recipe.name == "Test Recipe")
        #expect(recipe.complexity == .easy)
        #expect(recipe.cuisineType == .italian)
        #expect(recipe.calories == 500)
        #expect(recipe.servings == 4)
    }

    @Test func recipeDTOComplexityMappingHard() {
        let dto = RecipeDTO(
            name: "Hard Recipe",
            description: "",
            instructions: [],
            prepTimeMinutes: 30,
            cookTimeMinutes: 60,
            servings: 2,
            complexity: "hard",
            cuisineType: nil,
            calories: 300,
            proteinGrams: 20,
            carbsGrams: 30,
            fatGrams: 15,
            fiberGrams: 3,
            ingredients: []
        )
        #expect(dto.toRecipe().complexity == .hard)
    }

    @Test func recipeDTOComplexityDefaultsMedium() {
        let dto = RecipeDTO(
            name: "Unknown",
            description: "",
            instructions: [],
            prepTimeMinutes: 0,
            cookTimeMinutes: 0,
            servings: 1,
            complexity: "unknown",
            cuisineType: nil,
            calories: 0,
            proteinGrams: 0,
            carbsGrams: 0,
            fatGrams: 0,
            fiberGrams: 0,
            ingredients: []
        )
        #expect(dto.toRecipe().complexity == .medium)
    }

    // MARK: - IngredientDTO

    @Test func ingredientDTOToIngredientMapsUnit() {
        let dto = IngredientDTO(name: "Flour", quantity: 2, unit: "cup", category: "pantry")
        let ingredient = dto.toIngredient()
        #expect(ingredient.name == "Flour")
        #expect(ingredient.category == .pantry)
    }

    @Test func ingredientDTOToRecipeIngredient() {
        let dto = IngredientDTO(name: "Salt", quantity: 1, unit: "tsp", category: "spices")
        let ri = dto.toRecipeIngredient()
        #expect(ri.quantity == 1)
        #expect(ri.unit == .teaspoon)
    }

    @Test func ingredientDTOCategoryMapping() {
        #expect(IngredientDTO(name: "A", quantity: 1, unit: "g", category: "produce").toIngredient().category == .produce)
        #expect(IngredientDTO(name: "A", quantity: 1, unit: "g", category: "meat").toIngredient().category == .meat)
        #expect(IngredientDTO(name: "A", quantity: 1, unit: "g", category: "dairy").toIngredient().category == .dairy)
        #expect(IngredientDTO(name: "A", quantity: 1, unit: "g", category: "xyz").toIngredient().category == .other)
    }

    // MARK: - IngredientDTO quantity decoding (int vs double)

    @Test func ingredientDTODecodesIntQuantity() throws {
        let json = """
        {"name": "Egg", "quantity": 2, "unit": "piece", "category": "dairy"}
        """
        let dto = try JSONDecoder().decode(IngredientDTO.self, from: json.data(using: .utf8)!)
        #expect(dto.quantity == 2.0)
    }

    @Test func ingredientDTODecodesDoubleQuantity() throws {
        let json = """
        {"name": "Milk", "quantity": 1.5, "unit": "cup", "category": "dairy"}
        """
        let dto = try JSONDecoder().decode(IngredientDTO.self, from: json.data(using: .utf8)!)
        #expect(dto.quantity == 1.5)
    }
}
