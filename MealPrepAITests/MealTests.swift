import Testing
import Foundation
@testable import MealPrepAI

struct MealTests {

    @Test func mealTypeComputedProperty() {
        let meal = Meal(mealType: .dinner)
        #expect(meal.mealType == .dinner)
        #expect(meal.mealTypeRaw == "Dinner")
    }

    @Test func mealTypeDefaultsToBreakfast() {
        let meal = Meal()
        #expect(meal.mealType == .breakfast)
    }

    @Test func displayNameReturnsRecipeNameWhenAvailable() {
        let meal = Meal(mealType: .lunch)
        meal.recipe = Recipe(name: "Caesar Salad")
        #expect(meal.displayName == "Caesar Salad")
    }

    @Test func displayNameFallsBackToMealType() {
        let meal = Meal(mealType: .dinner)
        #expect(meal.displayName == "Dinner")
    }

    @Test func isEatenDefaultsFalse() {
        let meal = Meal()
        #expect(!meal.isEaten)
    }
}
