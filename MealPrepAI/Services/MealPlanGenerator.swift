import Foundation
import SwiftUI
import SwiftData

// MARK: - Meal Plan Generator
@MainActor
@Observable
class MealPlanGenerator {
    var isGenerating = false
    var progress: String = ""
    var error: Error?

    private let apiService = APIService.shared

    // MARK: - Generate Full Week Meal Plan
    func generateMealPlan(
        for profile: UserProfile,
        startDate: Date = Date(),
        modelContext: ModelContext
    ) async throws -> MealPlan {
        isGenerating = true
        progress = "Building your personalized meal plan..."
        error = nil

        defer {
            isGenerating = false
            progress = ""
        }

        do {
            // Build the prompt from user profile
            let prompt = buildPrompt(for: profile)
            let systemPrompt = buildSystemPrompt()

            progress = "Generating recipes with AI..."

            // Call the API
            let responseJSON = try await apiService.sendMessage(
                prompt: prompt,
                systemPrompt: systemPrompt,
                maxTokens: 8000
            )

            progress = "Processing meal plan..."

            // Parse the response
            let mealPlanResponse = try parseResponse(responseJSON)

            progress = "Saving to your library..."

            // Convert to SwiftData models and save
            let result = mealPlanResponse.toSwiftDataModels(startDate: startDate)

            // Insert all models into context
            modelContext.insert(result.mealPlan)
            result.mealPlan.userProfile = profile

            for day in result.days {
                modelContext.insert(day)
            }

            for recipe in result.recipes {
                modelContext.insert(recipe)
            }

            for ingredient in result.ingredients {
                modelContext.insert(ingredient)
            }

            for recipeIngredient in result.recipeIngredients {
                modelContext.insert(recipeIngredient)
            }

            for meal in result.meals {
                modelContext.insert(meal)
            }

            try modelContext.save()

            return result.mealPlan

        } catch {
            self.error = error
            throw error
        }
    }

    // MARK: - Generate Single Meal Replacement
    func generateReplacementMeal(
        for mealType: MealType,
        profile: UserProfile,
        excludeRecipes: [String] = [],
        modelContext: ModelContext
    ) async throws -> (recipe: Recipe, ingredients: [Ingredient], recipeIngredients: [RecipeIngredient]) {
        isGenerating = true
        progress = "Finding a new \(mealType.rawValue.lowercased())..."
        error = nil

        defer {
            isGenerating = false
            progress = ""
        }

        do {
            let prompt = buildSingleMealPrompt(for: mealType, profile: profile, excludeRecipes: excludeRecipes)
            let systemPrompt = buildSystemPrompt()

            let responseJSON = try await apiService.sendMessage(
                prompt: prompt,
                systemPrompt: systemPrompt,
                maxTokens: 2000
            )

            // Parse single meal response
            guard let data = responseJSON.data(using: .utf8) else {
                throw APIError.invalidResponse
            }

            let recipeDTO = try JSONDecoder().decode(RecipeDTO.self, from: data)
            let recipe = recipeDTO.toRecipe()

            var ingredients: [Ingredient] = []
            var recipeIngredients: [RecipeIngredient] = []

            for ingredientDTO in recipeDTO.ingredients {
                let ingredient = ingredientDTO.toIngredient()
                let recipeIngredient = ingredientDTO.toRecipeIngredient()
                recipeIngredient.recipe = recipe
                recipeIngredient.ingredient = ingredient

                ingredients.append(ingredient)
                recipeIngredients.append(recipeIngredient)
            }

            // Save to context
            modelContext.insert(recipe)
            for ingredient in ingredients {
                modelContext.insert(ingredient)
            }
            for ri in recipeIngredients {
                modelContext.insert(ri)
            }
            try modelContext.save()

            return (recipe, ingredients, recipeIngredients)

        } catch {
            self.error = error
            throw error
        }
    }

    // MARK: - Build System Prompt
    private func buildSystemPrompt() -> String {
        return """
        You are a professional nutritionist and chef creating personalized meal plans.

        IMPORTANT: Respond ONLY with valid JSON. No markdown, no explanation, no code blocks.

        Guidelines:
        - Create balanced, nutritious meals that meet the user's calorie and macro targets
        - Respect all dietary restrictions and allergies strictly
        - Vary cuisines and ingredients throughout the week for diversity
        - Consider cooking skill level when selecting recipe complexity
        - Include practical, easy-to-find ingredients
        - Provide accurate nutritional information
        - Keep prep and cook times realistic
        """
    }

    // MARK: - Build Full Week Prompt
    private func buildPrompt(for profile: UserProfile) -> String {
        let restrictions = profile.dietaryRestrictions.map { $0.rawValue }.joined(separator: ", ")
        let allergies = profile.allergies.map { $0.rawValue }.joined(separator: ", ")
        let cuisines = profile.preferredCuisines.map { $0.rawValue }.joined(separator: ", ")

        let mealTypes: String
        if profile.includeSnacks {
            mealTypes = "breakfast, lunch, dinner, and one snack"
        } else {
            mealTypes = "breakfast, lunch, and dinner"
        }

        let maxTime = profile.maxCookingTime.maxMinutes

        return """
        Create a 7-day meal plan for a person with the following profile:

        DAILY TARGETS:
        - Calories: \(profile.dailyCalorieTarget) kcal
        - Protein: \(profile.proteinGrams)g
        - Carbs: \(profile.carbsGrams)g
        - Fat: \(profile.fatGrams)g

        DIETARY RESTRICTIONS: \(restrictions.isEmpty ? "None" : restrictions)
        ALLERGIES (STRICT - never include): \(allergies.isEmpty ? "None" : allergies)
        PREFERRED CUISINES: \(cuisines.isEmpty ? "Varied" : cuisines)
        COOKING SKILL: \(profile.cookingSkill.rawValue)
        MAX COOKING TIME PER MEAL: \(maxTime) minutes
        SIMPLE MODE: \(profile.simpleModeEnabled ? "Yes - prefer recipes with fewer ingredients" : "No")

        Each day must include: \(mealTypes)

        Respond with JSON in this exact format:
        {
          "days": [
            {
              "dayOfWeek": 0,
              "meals": [
                {
                  "mealType": "breakfast",
                  "recipe": {
                    "name": "Recipe Name",
                    "description": "Brief description",
                    "instructions": ["Step 1", "Step 2"],
                    "prepTimeMinutes": 10,
                    "cookTimeMinutes": 15,
                    "servings": 2,
                    "complexity": "easy",
                    "cuisineType": "american",
                    "calories": 400,
                    "proteinGrams": 20,
                    "carbsGrams": 40,
                    "fatGrams": 15,
                    "fiberGrams": 5,
                    "ingredients": [
                      {"name": "Ingredient", "quantity": 1, "unit": "cup", "category": "produce"}
                    ]
                  }
                }
              ]
            }
          ]
        }

        Valid mealTypes: breakfast, lunch, dinner, snack
        Valid complexity: easy, medium, hard
        Valid cuisineTypes: american, italian, mexican, asian, mediterranean, indian, japanese, thai, french, greek, korean, vietnamese, middleEastern, african, caribbean
        Valid categories: produce, meat, dairy, pantry, frozen, bakery, beverages, other
        Valid units: gram, kilogram, milliliter, liter, cup, tablespoon, teaspoon, piece, slice, bunch, can, package, pound, ounce

        dayOfWeek should be 0-6 (0 = first day of the plan)
        """
    }

    // MARK: - Build Single Meal Prompt
    private func buildSingleMealPrompt(for mealType: MealType, profile: UserProfile, excludeRecipes: [String]) -> String {
        let restrictions = profile.dietaryRestrictions.map { $0.rawValue }.joined(separator: ", ")
        let allergies = profile.allergies.map { $0.rawValue }.joined(separator: ", ")
        let excludeList = excludeRecipes.joined(separator: ", ")

        return """
        Create a single \(mealType.rawValue.lowercased()) recipe for a person with:

        DAILY TARGETS (this meal should be approximately 1/\(mealType == .snack ? "6" : "3") of daily):
        - Total Daily Calories: \(profile.dailyCalorieTarget) kcal
        - Total Daily Protein: \(profile.proteinGrams)g

        DIETARY RESTRICTIONS: \(restrictions.isEmpty ? "None" : restrictions)
        ALLERGIES (STRICT): \(allergies.isEmpty ? "None" : allergies)
        COOKING SKILL: \(profile.cookingSkill.rawValue)
        MAX COOKING TIME: \(profile.maxCookingTime.maxMinutes) minutes

        \(excludeList.isEmpty ? "" : "DO NOT suggest these recipes (user wants variety): \(excludeList)")

        Respond with a single recipe JSON (no array, no "days" wrapper):
        {
          "name": "Recipe Name",
          "description": "Brief description",
          "instructions": ["Step 1", "Step 2"],
          "prepTimeMinutes": 10,
          "cookTimeMinutes": 15,
          "servings": 2,
          "complexity": "easy",
          "cuisineType": "american",
          "calories": 400,
          "proteinGrams": 20,
          "carbsGrams": 40,
          "fatGrams": 15,
          "fiberGrams": 5,
          "ingredients": [
            {"name": "Ingredient", "quantity": 1, "unit": "cup", "category": "produce"}
          ]
        }
        """
    }

    // MARK: - Parse Response
    private func parseResponse(_ jsonString: String) throws -> MealPlanResponse {
        // Clean up the response - remove any markdown code blocks if present
        var cleanJSON = jsonString
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Find the JSON object boundaries
        guard let startIndex = cleanJSON.firstIndex(of: "{"),
              let endIndex = cleanJSON.lastIndex(of: "}") else {
            throw APIError.invalidResponse
        }

        cleanJSON = String(cleanJSON[startIndex...endIndex])

        guard let data = cleanJSON.data(using: .utf8) else {
            throw APIError.invalidResponse
        }

        do {
            return try JSONDecoder().decode(MealPlanResponse.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
}
