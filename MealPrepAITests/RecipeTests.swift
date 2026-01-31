import Testing
import Foundation
@testable import MealPrepAI

struct RecipeTests {

    // MARK: - totalTime

    @Test func totalTimeMinutesSumsPrepAndCook() {
        let recipe = Recipe(prepTimeMinutes: 15, cookTimeMinutes: 30)
        #expect(recipe.totalTimeMinutes == 45)
    }

    @Test func totalTimeZeroWhenBothZero() {
        let recipe = Recipe(prepTimeMinutes: 0, cookTimeMinutes: 0)
        #expect(recipe.totalTimeMinutes == 0)
    }

    @Test func totalTimeFormattedUnderOneHour() {
        let recipe = Recipe(prepTimeMinutes: 10, cookTimeMinutes: 20)
        #expect(recipe.totalTimeFormatted == "30 min")
    }

    @Test func totalTimeFormattedExactlyOneHour() {
        let recipe = Recipe(prepTimeMinutes: 30, cookTimeMinutes: 30)
        #expect(recipe.totalTimeFormatted == "1h")
    }

    @Test func totalTimeFormattedOverOneHour() {
        let recipe = Recipe(prepTimeMinutes: 30, cookTimeMinutes: 45)
        #expect(recipe.totalTimeFormatted == "1h 15m")
    }

    // MARK: - caloriesPerServing

    @Test func caloriesPerServingReturnsCalories() {
        let recipe = Recipe(calories: 400)
        #expect(recipe.caloriesPerServing == 400)
    }

    @Test func totalCaloriesMultipliesByServings() {
        let recipe = Recipe(servings: 4, calories: 300)
        #expect(recipe.totalCalories == 1200)
    }

    @Test func totalCaloriesHandlesZeroServings() {
        let recipe = Recipe(servings: 0, calories: 300)
        // max(servings, 1) => 1
        #expect(recipe.totalCalories == 300)
    }

    // MARK: - parsedInstructions

    @Test func parsedInstructionsReturnsPlaceholderWhenEmpty() {
        let recipe = Recipe(instructions: [])
        #expect(recipe.parsedInstructions == ["No instructions available."])
    }

    @Test func parsedInstructionsReturnsStepsForMultipleInstructions() {
        let recipe = Recipe(instructions: [
            "Preheat the oven to 375 degrees Fahrenheit.",
            "Season the chicken with salt and pepper generously.",
            "Bake for 25 minutes until golden brown on top."
        ])
        let parsed = recipe.parsedInstructions
        #expect(parsed.count == 3)
        #expect(parsed[0].contains("Preheat"))
    }

    @Test func parsedInstructionsFiltersGarbageContent() {
        let recipe = Recipe(instructions: [
            "Preheat the oven to 375 degrees Fahrenheit.",
            "Follow us on Facebook for more recipes!"
        ])
        let parsed = recipe.parsedInstructions
        #expect(parsed.count == 1)
        #expect(!parsed.contains { $0.lowercased().contains("facebook") })
    }

    @Test func parsedInstructionsCustomRecipeNoFiltering() {
        let recipe = Recipe(instructions: ["Mix it up well and serve immediately."], isCustom: true)
        let parsed = recipe.parsedInstructions
        #expect(parsed.count == 1)
    }

    @Test func hasValidInstructionsFalseWhenEmpty() {
        let recipe = Recipe(instructions: [])
        #expect(!recipe.hasValidInstructions)
    }

    @Test func hasValidInstructionsTrueWithRealSteps() {
        let recipe = Recipe(instructions: [
            "Preheat the oven to 375 degrees Fahrenheit."
        ])
        #expect(recipe.hasValidInstructions)
    }

    // MARK: - advancePrep

    @Test func inferredAdvancePrepDetectsOvernight() {
        let recipe = Recipe(instructions: ["Marinate overnight in the refrigerator for best results."])
        #expect(recipe.inferredAdvancePrep)
    }

    @Test func inferredAdvancePrepFalseForNormalRecipe() {
        let recipe = Recipe(instructions: ["Cook the pasta in boiling water until al dente."])
        #expect(!recipe.inferredAdvancePrep)
    }

    @Test func needsAdvancePrepCombinesExplicitAndInferred() {
        let recipe = Recipe(instructions: ["Cook for 20 minutes on the stovetop over medium heat."])
        recipe.requiresAdvancePrep = true
        #expect(recipe.needsAdvancePrep)
    }

    // MARK: - matchesCategory

    @Test func matchesCategoryAllReturnsTrue() {
        let recipe = Recipe(name: "Random Dish")
        #expect(recipe.matchesCategory(.all))
    }

    @Test func matchesCategoryChicken() {
        let recipe = Recipe(name: "Grilled Chicken Salad")
        #expect(recipe.matchesCategory(.chicken))
    }

    @Test func matchesCategoryQuickByTime() {
        let recipe = Recipe(prepTimeMinutes: 10, cookTimeMinutes: 15)
        #expect(recipe.matchesCategory(.quick))
    }

    @Test func matchesCategoryQuickFalseForLong() {
        let recipe = Recipe(prepTimeMinutes: 20, cookTimeMinutes: 25)
        #expect(!recipe.matchesCategory(.quick))
    }

    // MARK: - highResImageURL

    @Test func highResImageURLUpgradesSmallerSize() {
        let recipe = Recipe(imageURL: "https://spoonacular.com/recipeImages/123-312x231.jpg")
        #expect(recipe.highResImageURL == "https://spoonacular.com/recipeImages/123-636x393.jpg")
    }

    @Test func highResImageURLReturnsNilWhenNoImage() {
        let recipe = Recipe()
        #expect(recipe.highResImageURL == nil)
    }

    @Test func highResImageURLKeepsAlreadyMaxSize() {
        let url = "https://spoonacular.com/recipeImages/123-636x393.jpg"
        let recipe = Recipe(imageURL: url)
        #expect(recipe.highResImageURL == url)
    }

    // MARK: - complexity

    @Test func complexityDefaultsMedium() {
        let recipe = Recipe()
        #expect(recipe.complexity == .medium)
    }

    @Test func complexitySetAndGet() {
        let recipe = Recipe(complexity: .hard)
        #expect(recipe.complexity == .hard)
        #expect(recipe.complexityRaw == 3)
    }

    // MARK: - diets

    @Test func dietsEmptyByDefault() {
        let recipe = Recipe()
        #expect(recipe.diets.isEmpty)
    }

    @Test func dietsParseFromCommaSeparated() {
        let recipe = Recipe()
        recipe.dietsRaw = "vegetarian,gluten-free"
        #expect(recipe.diets.count == 2)
        #expect(recipe.diets.contains("vegetarian"))
    }

    @Test func matchesDietFindsMatch() {
        let recipe = Recipe()
        recipe.dietsRaw = "vegetarian,gluten-free"
        #expect(recipe.matchesDiet(.vegetarian))
        #expect(recipe.matchesDiet(.glutenFree))
    }

    @Test func matchesDietReturnsFalseForNoMatch() {
        let recipe = Recipe()
        recipe.dietsRaw = "vegetarian"
        #expect(!recipe.matchesDiet(.keto))
    }

    // MARK: - hasVideo

    @Test func hasVideoDetectsYouTube() {
        let recipe = Recipe()
        recipe.sourceURL = "https://youtube.com/watch?v=abc123"
        #expect(recipe.hasVideo)
    }

    @Test func hasVideoFalseForNormalURL() {
        let recipe = Recipe()
        recipe.sourceURL = "https://allrecipes.com/recipe/123"
        #expect(!recipe.hasVideo)
    }
}
