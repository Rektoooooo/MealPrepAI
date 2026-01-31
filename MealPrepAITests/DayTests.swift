import Testing
import Foundation
@testable import MealPrepAI

struct DayTests {

    @Test func totalCaloriesAggregatesFromMeals() {
        let day = Day(date: Date(), dayOfWeek: 0)
        let meal1 = Meal(mealType: .breakfast)
        meal1.recipe = Recipe(calories: 400)
        let meal2 = Meal(mealType: .lunch)
        meal2.recipe = Recipe(calories: 600)
        day.meals = [meal1, meal2]

        #expect(day.totalCalories == 1000)
    }

    @Test func totalProteinAggregatesFromMeals() {
        let day = Day(date: Date(), dayOfWeek: 0)
        let meal = Meal(mealType: .breakfast)
        meal.recipe = Recipe(proteinGrams: 30)
        day.meals = [meal]

        #expect(day.totalProtein == 30)
    }

    @Test func totalCarbsAggregatesFromMeals() {
        let day = Day(date: Date(), dayOfWeek: 0)
        let meal = Meal(mealType: .lunch)
        meal.recipe = Recipe(carbsGrams: 50)
        day.meals = [meal]

        #expect(day.totalCarbs == 50)
    }

    @Test func totalFatAggregatesFromMeals() {
        let day = Day(date: Date(), dayOfWeek: 0)
        let meal = Meal(mealType: .dinner)
        meal.recipe = Recipe(fatGrams: 25)
        day.meals = [meal]

        #expect(day.totalFat == 25)
    }

    @Test func sortedMealsOrdersCorrectly() {
        let day = Day(date: Date(), dayOfWeek: 0)
        let snack = Meal(mealType: .snack)
        let breakfast = Meal(mealType: .breakfast)
        let dinner = Meal(mealType: .dinner)
        let lunch = Meal(mealType: .lunch)
        day.meals = [snack, dinner, breakfast, lunch]

        let sorted = day.sortedMeals
        #expect(sorted[0].mealType == .breakfast)
        #expect(sorted[1].mealType == .lunch)
        #expect(sorted[2].mealType == .dinner)
        #expect(sorted[3].mealType == .snack)
    }

    @Test func totalCaloriesZeroWhenNilMeals() {
        let day = Day(date: Date(), dayOfWeek: 0)
        #expect(day.totalCalories == 0)
    }

    @Test func totalCaloriesHandlesNilRecipes() {
        let day = Day(date: Date(), dayOfWeek: 0)
        let meal = Meal(mealType: .breakfast)
        // No recipe set
        day.meals = [meal]
        #expect(day.totalCalories == 0)
    }
}
