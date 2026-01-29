import Testing
import Foundation
@testable import MealPrepAI

struct IngredientSubstitutionTests {

    // MARK: - API Types Encoding/Decoding

    @Test func substituteRecipeContextEncodesCorrectly() throws {
        let context = SubstituteRecipeContext(
            recipeName: "Herb Chicken",
            totalCalories: 480,
            totalProtein: 42,
            totalCarbs: 15,
            totalFat: 28,
            otherIngredients: ["Olive Oil", "Garlic", "Rosemary"]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(context)
        let decoded = try JSONDecoder().decode(SubstituteRecipeContext.self, from: data)

        #expect(decoded.recipeName == "Herb Chicken")
        #expect(decoded.totalCalories == 480)
        #expect(decoded.totalProtein == 42)
        #expect(decoded.totalCarbs == 15)
        #expect(decoded.totalFat == 28)
        #expect(decoded.otherIngredients.count == 3)
    }

    @Test func substituteIngredientRequestEncodesCorrectly() throws {
        let context = SubstituteRecipeContext(
            recipeName: "Test Recipe",
            totalCalories: 500,
            totalProtein: 30,
            totalCarbs: 50,
            totalFat: 20,
            otherIngredients: ["Salt"]
        )

        let request = SubstituteIngredientRequest(
            ingredientName: "Chicken Breast",
            ingredientQuantity: 200,
            ingredientUnit: "gram",
            recipeContext: context,
            dietaryRestrictions: ["vegetarian"],
            allergies: ["peanuts"],
            deviceId: "test-device"
        )

        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(SubstituteIngredientRequest.self, from: data)

        #expect(decoded.ingredientName == "Chicken Breast")
        #expect(decoded.ingredientQuantity == 200)
        #expect(decoded.ingredientUnit == "gram")
        #expect(decoded.dietaryRestrictions == ["vegetarian"])
        #expect(decoded.allergies == ["peanuts"])
        #expect(decoded.deviceId == "test-device")
    }

    @Test func substituteOptionDecodesFromJSON() throws {
        let json = """
        {
            "name": "Turkey Breast",
            "reason": "Similar protein, lower fat",
            "quantity": 200,
            "unit": "gram",
            "quantityGrams": 200,
            "category": "meat",
            "caloriesPer100g": 135,
            "proteinPer100g": 30,
            "carbsPer100g": 0,
            "fatPer100g": 1.5,
            "totalCalories": 270,
            "totalProtein": 60,
            "totalCarbs": 0,
            "totalFat": 3
        }
        """

        let data = json.data(using: .utf8)!
        let option = try JSONDecoder().decode(SubstituteOption.self, from: data)

        #expect(option.name == "Turkey Breast")
        #expect(option.reason == "Similar protein, lower fat")
        #expect(option.quantity == 200)
        #expect(option.unit == "gram")
        #expect(option.quantityGrams == 200)
        #expect(option.category == "meat")
        #expect(option.caloriesPer100g == 135)
        #expect(option.proteinPer100g == 30)
        #expect(option.carbsPer100g == 0)
        #expect(option.fatPer100g == 1.5)
        #expect(option.totalCalories == 270)
        #expect(option.totalProtein == 60)
        #expect(option.totalCarbs == 0)
        #expect(option.totalFat == 3)
    }

    @Test func substituteOptionIsIdentifiable() throws {
        let json = """
        {
            "name": "Tofu",
            "reason": "Plant-based option",
            "quantity": 250,
            "unit": "gram",
            "quantityGrams": 250,
            "category": "produce",
            "caloriesPer100g": 76,
            "proteinPer100g": 8,
            "carbsPer100g": 1.9,
            "fatPer100g": 4.8,
            "totalCalories": 190,
            "totalProtein": 20,
            "totalCarbs": 4.75,
            "totalFat": 12
        }
        """

        let data = json.data(using: .utf8)!
        let option = try JSONDecoder().decode(SubstituteOption.self, from: data)

        #expect(option.id == "Tofu")
    }

    @Test func substituteIngredientResponseDecodesSuccess() throws {
        let json = """
        {
            "success": true,
            "substitutes": [
                {
                    "name": "Turkey",
                    "reason": "Lean alternative",
                    "quantity": 200,
                    "unit": "gram",
                    "quantityGrams": 200,
                    "category": "meat",
                    "caloriesPer100g": 135,
                    "proteinPer100g": 30,
                    "carbsPer100g": 0,
                    "fatPer100g": 1.5,
                    "totalCalories": 270,
                    "totalProtein": 60,
                    "totalCarbs": 0,
                    "totalFat": 3
                }
            ],
            "rateLimitInfo": {
                "remaining": 99,
                "resetTime": "2026-01-30T00:00:00Z",
                "limit": 100
            }
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(SubstituteIngredientResponse.self, from: data)

        #expect(response.success == true)
        #expect(response.substitutes?.count == 1)
        #expect(response.substitutes?.first?.name == "Turkey")
        #expect(response.error == nil)
        #expect(response.rateLimitInfo?.remaining == 99)
        #expect(response.rateLimitInfo?.limit == 100)
    }

    @Test func substituteIngredientResponseDecodesError() throws {
        let json = """
        {
            "success": false,
            "error": "Rate limit exceeded. Please try again later.",
            "rateLimitInfo": {
                "remaining": 0,
                "resetTime": "2026-01-30T00:00:00Z",
                "limit": 100
            }
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(SubstituteIngredientResponse.self, from: data)

        #expect(response.success == false)
        #expect(response.substitutes == nil)
        #expect(response.error == "Rate limit exceeded. Please try again later.")
    }

    // MARK: - SwiftData Model Tests

    @Test func ingredientNutritionCalculation() {
        let ingredient = Ingredient(
            name: "Chicken Breast",
            category: .meat,
            defaultUnit: .gram,
            caloriesPer100g: 165,
            proteinPer100g: 31,
            carbsPer100g: 0,
            fatPer100g: 3.6
        )

        // 200g of chicken
        let grams: Double = 200
        let calories = Double(ingredient.caloriesPer100g) * grams / 100
        let protein = ingredient.proteinPer100g * grams / 100

        #expect(calories == 330)
        #expect(protein == 62)
    }

    @Test func recipeNutritionRecalculation() {
        // Simulate the swap math: subtract old, add new
        var recipeCalories = 480
        var recipeProtein = 42

        let oldCalories = 330  // old chicken contribution
        let oldProtein = 62

        let newCalories = 270  // turkey contribution
        let newProtein = 60

        recipeCalories = recipeCalories - oldCalories + newCalories
        recipeProtein = recipeProtein - oldProtein + newProtein

        #expect(recipeCalories == 420)
        #expect(recipeProtein == 40)
    }

    @Test func recipeIngredientDisplayQuantity() {
        let ri = RecipeIngredient(
            quantity: 2,
            unit: .cup,
            quantityGrams: 240
        )

        #expect(ri.displayQuantity == "2 cup")
        #expect(ri.displayWithGrams == "2 cup (240g)")
    }

    @Test func recipeIngredientUnitRawUpdate() {
        let ri = RecipeIngredient(quantity: 1, unit: .piece)

        // Test that unitRaw can be changed
        ri.unitRaw = "gram"
        #expect(ri.unitRaw == "gram")

        ri.quantity = 200
        ri.quantityGrams = 200
        #expect(ri.quantity == 200)
        #expect(ri.quantityGrams == 200)
    }
}
