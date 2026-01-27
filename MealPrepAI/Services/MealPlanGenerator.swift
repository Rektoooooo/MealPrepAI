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
        weeklyPreferences: String? = nil,
        modelContext: ModelContext
    ) async throws -> MealPlan {
        let generationStartTime = Date()
        print("[DEBUG:Generator] ========== GENERATE MEAL PLAN START ==========")
        print("[DEBUG:Generator] Start Date: \(startDate)")
        print("[DEBUG:Generator] Weekly Preferences: \(weeklyPreferences ?? "None")")
        print("[DEBUG:Generator] Profile calories: \(profile.dailyCalorieTarget)")

        isGenerating = true
        progress = "Building your personalized meal plan..."
        error = nil

        defer {
            isGenerating = false
            progress = ""
            let elapsedTime = Date().timeIntervalSince(generationStartTime)
            print("[DEBUG:Generator] ⏱️ Total generation time: \(String(format: "%.2f", elapsedTime)) seconds")
            print("[DEBUG:Generator] ========== GENERATE MEAL PLAN END ==========")
        }

        do {
            // Build API user profile from SwiftData profile
            print("[DEBUG:Generator] Building API user profile...")
            let apiProfile = buildAPIUserProfile(from: profile)

            progress = "Generating recipes with AI..."
            print("[DEBUG:Generator] Calling generateMealPlan API...")

            // Call the new API endpoint
            let apiResponse = try await apiService.generateMealPlan(
                userProfile: apiProfile,
                weeklyPreferences: weeklyPreferences,
                excludeRecipeNames: []
            )

            print("[DEBUG:Generator] API response received")
            print("[DEBUG:Generator] Success: \(apiResponse.success)")
            print("[DEBUG:Generator] Recipes added: \(apiResponse.recipesAdded ?? 0)")
            print("[DEBUG:Generator] Recipes duplicate: \(apiResponse.recipesDuplicate ?? 0)")

            // Check for errors
            if !apiResponse.success {
                print("[DEBUG:Generator] ERROR: API returned failure - \(apiResponse.error ?? "Unknown error")")
                throw APIError.serverError(apiResponse.error ?? "Unknown error")
            }

            guard let apiMealPlan = apiResponse.mealPlan else {
                print("[DEBUG:Generator] ERROR: No meal plan in response")
                throw APIError.invalidResponse
            }

            progress = "Processing meal plan..."

            // Convert API response to MealPlanResponse format
            print("[DEBUG:Generator] Converting API response to MealPlanResponse...")
            let mealPlanResponse = convertAPIResponseToMealPlanResponse(apiMealPlan)
            print("[DEBUG:Generator] Converted \(mealPlanResponse.days.count) days")

            progress = "Saving to your library..."

            // Convert to SwiftData models and save
            print("[DEBUG:Generator] Converting to SwiftData models...")
            let result = mealPlanResponse.toSwiftDataModels(startDate: startDate)
            print("[DEBUG:Generator] Created: \(result.days.count) days, \(result.recipes.count) recipes, \(result.meals.count) meals")

            // Insert all models into context
            print("[DEBUG:Generator] Inserting models into context...")
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

            print("[DEBUG:Generator] Saving context...")
            try modelContext.save()
            print("[DEBUG:Generator] Context saved successfully")

            // Print weekly summary for analysis
            printWeeklySummary(mealPlan: result.mealPlan, profile: profile)

            return result.mealPlan

        } catch {
            print("[DEBUG:Generator] ERROR: \(error.localizedDescription)")
            print("[DEBUG:Generator] Error type: \(type(of: error))")
            self.error = error
            throw error
        }
    }

    // MARK: - Build API User Profile
    private func buildAPIUserProfile(from profile: UserProfile) -> GeneratePlanUserProfile {
        // Extract disliked cuisines from cuisinePreferencesMap
        let dislikedCuisines = profile.cuisinePreferencesMap
            .filter { $0.value == .dislike }
            .map { $0.key }

        return GeneratePlanUserProfile(
            age: profile.age,
            gender: profile.gender.rawValue,
            weightKg: profile.weightKg,
            heightCm: profile.heightCm,
            activityLevel: profile.activityLevel.rawValue,
            dailyCalorieTarget: profile.dailyCalorieTarget,
            proteinGrams: profile.proteinGrams,
            carbsGrams: profile.carbsGrams,
            fatGrams: profile.fatGrams,
            weightGoal: profile.weightGoal.rawValue,
            dietaryRestrictions: profile.dietaryRestrictions.map { $0.rawValue },
            allergies: profile.allergies.map { $0.rawValue },
            foodDislikes: profile.foodDislikes.map { $0.rawValue },
            preferredCuisines: profile.preferredCuisines.map { $0.rawValue },
            dislikedCuisines: dislikedCuisines,
            cookingSkill: profile.cookingSkill.rawValue,
            maxCookingTimeMinutes: profile.maxCookingTime.maxMinutes,
            simpleModeEnabled: profile.simpleModeEnabled,
            mealsPerDay: profile.mealsPerDay,
            includeSnacks: profile.includeSnacks,
            pantryLevel: profile.pantryLevel.rawValue,
            barriers: profile.barriers.map { $0.rawValue },
            primaryGoals: profile.primaryGoals.map { $0.rawValue },
            goalPace: profile.goalPace.rawValue
        )
    }

    // MARK: - Convert API Response to MealPlanResponse
    private func convertAPIResponseToMealPlanResponse(_ apiPlan: APIMealPlan) -> MealPlanResponse {
        let days = apiPlan.days.map { apiDay -> DayDTO in
            let meals = apiDay.meals.map { apiMeal -> MealDTO in
                let recipe = RecipeDTO(
                    name: apiMeal.recipe.name,
                    description: apiMeal.recipe.description,
                    instructions: apiMeal.recipe.instructions,
                    prepTimeMinutes: apiMeal.recipe.prepTimeMinutes,
                    cookTimeMinutes: apiMeal.recipe.cookTimeMinutes,
                    servings: apiMeal.recipe.servings,
                    complexity: apiMeal.recipe.complexity,
                    cuisineType: apiMeal.recipe.cuisineType,
                    calories: apiMeal.recipe.calories,
                    proteinGrams: apiMeal.recipe.proteinGrams,
                    carbsGrams: apiMeal.recipe.carbsGrams,
                    fatGrams: apiMeal.recipe.fatGrams,
                    fiberGrams: apiMeal.recipe.fiberGrams ?? 0,
                    ingredients: apiMeal.recipe.ingredients.map { apiIng in
                        IngredientDTO(
                            name: apiIng.name,
                            quantity: apiIng.quantity,
                            unit: apiIng.unit,
                            category: apiIng.category
                        )
                    },
                    matchedImageUrl: apiMeal.recipe.matchedImageUrl
                )
                return MealDTO(mealType: apiMeal.mealType, recipe: recipe)
            }
            return DayDTO(dayOfWeek: apiDay.dayOfWeek, meals: meals)
        }
        return MealPlanResponse(days: days)
    }

    // MARK: - Generate Single Meal Replacement
    func generateReplacementMeal(
        for mealType: MealType,
        profile: UserProfile,
        excludeRecipes: [String] = [],
        modelContext: ModelContext
    ) async throws -> (recipe: Recipe, ingredients: [Ingredient], recipeIngredients: [RecipeIngredient]) {
        let swapStartTime = Date()
        print("[DEBUG:Generator] ========== REPLACEMENT MEAL START ==========")
        print("[DEBUG:Generator] Meal Type: \(mealType.rawValue)")
        print("[DEBUG:Generator] Exclude Recipes: \(excludeRecipes.joined(separator: ", "))")

        isGenerating = true
        progress = "Finding a new \(mealType.rawValue.lowercased())..."
        error = nil

        defer {
            isGenerating = false
            progress = ""
            let elapsedTime = Date().timeIntervalSince(swapStartTime)
            print("[DEBUG:Generator] ⏱️ Swap generation time: \(String(format: "%.2f", elapsedTime)) seconds")
            print("[DEBUG:Generator] ========== REPLACEMENT MEAL END ==========")
        }

        do {
            // Build API user profile for swap
            print("[DEBUG:Generator] Building swap API profile...")
            let swapProfile = SwapMealUserProfile(
                dailyCalorieTarget: profile.dailyCalorieTarget,
                proteinGrams: profile.proteinGrams,
                carbsGrams: profile.carbsGrams,
                fatGrams: profile.fatGrams,
                dietaryRestrictions: profile.dietaryRestrictions.map { $0.rawValue },
                allergies: profile.allergies.map { $0.rawValue },
                preferredCuisines: profile.preferredCuisines.map { $0.rawValue },
                cookingSkill: profile.cookingSkill.rawValue,
                maxCookingTimeMinutes: profile.maxCookingTime.maxMinutes,
                simpleModeEnabled: profile.simpleModeEnabled
            )

            print("[DEBUG:Generator] Calling swapMeal API...")
            let apiResponse = try await apiService.swapMeal(
                userProfile: swapProfile,
                mealType: mealType.rawValue.lowercased(),
                excludeRecipeNames: excludeRecipes
            )

            print("[DEBUG:Generator] API response received")
            print("[DEBUG:Generator] Success: \(apiResponse.success)")

            // Check for errors
            if !apiResponse.success {
                print("[DEBUG:Generator] ERROR: API returned failure - \(apiResponse.error ?? "Unknown error")")
                throw APIError.serverError(apiResponse.error ?? "Unknown error")
            }

            guard let apiRecipe = apiResponse.recipe else {
                print("[DEBUG:Generator] ERROR: No recipe in response")
                throw APIError.invalidResponse
            }

            print("[DEBUG:Generator] Received recipe: \(apiRecipe.name)")

            // Convert API recipe to RecipeDTO
            let recipeDTO = RecipeDTO(
                name: apiRecipe.name,
                description: apiRecipe.description,
                instructions: apiRecipe.instructions,
                prepTimeMinutes: apiRecipe.prepTimeMinutes,
                cookTimeMinutes: apiRecipe.cookTimeMinutes,
                servings: apiRecipe.servings,
                complexity: apiRecipe.complexity,
                cuisineType: apiRecipe.cuisineType,
                calories: apiRecipe.calories,
                proteinGrams: apiRecipe.proteinGrams,
                carbsGrams: apiRecipe.carbsGrams,
                fatGrams: apiRecipe.fatGrams,
                fiberGrams: apiRecipe.fiberGrams ?? 0,
                ingredients: apiRecipe.ingredients.map { apiIng in
                    IngredientDTO(
                        name: apiIng.name,
                        quantity: apiIng.quantity,
                        unit: apiIng.unit,
                        category: apiIng.category
                    )
                },
                matchedImageUrl: apiRecipe.matchedImageUrl
            )

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

            print("[DEBUG:Generator] Created \(ingredients.count) ingredients")

            // Save to context
            print("[DEBUG:Generator] Saving to context...")
            modelContext.insert(recipe)
            for ingredient in ingredients {
                modelContext.insert(ingredient)
            }
            for ri in recipeIngredients {
                modelContext.insert(ri)
            }
            try modelContext.save()
            print("[DEBUG:Generator] Context saved successfully")

            return (recipe, ingredients, recipeIngredients)

        } catch {
            print("[DEBUG:Generator] ERROR: \(error.localizedDescription)")
            print("[DEBUG:Generator] Error type: \(type(of: error))")
            self.error = error
            throw error
        }
    }

    // MARK: - Print Weekly Summary
    private func printWeeklySummary(mealPlan: MealPlan, profile: UserProfile) {
        print("\n")
        print("╔══════════════════════════════════════════════════════════════════════════════╗")
        print("║                         WEEKLY MEAL PLAN SUMMARY                              ║")
        print("╠══════════════════════════════════════════════════════════════════════════════╣")
        print("║ TARGETS: \(profile.dailyCalorieTarget) cal | \(profile.proteinGrams)g protein | \(profile.carbsGrams)g carbs | \(profile.fatGrams)g fat")
        print("╚══════════════════════════════════════════════════════════════════════════════╝")

        let dayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        var weekTotalCal = 0
        var weekTotalProtein = 0
        var weekTotalCarbs = 0
        var weekTotalFat = 0

        for (index, day) in mealPlan.sortedDays.enumerated() {
            let dayName = index < dayNames.count ? dayNames[index] : "Day \(index + 1)"
            var dayCal = 0
            var dayProtein = 0
            var dayCarbs = 0
            var dayFat = 0

            print("\n┌─────────────────────────────────────────────────────────────────────────────┐")
            print("│ \(dayName.uppercased().padding(toLength: 75, withPad: " ", startingAt: 0)) │")
            print("├─────────────────────────────────────────────────────────────────────────────┤")

            for meal in day.sortedMeals {
                guard let recipe = meal.recipe else { continue }
                let mealType = meal.mealType.rawValue.padding(toLength: 10, withPad: " ", startingAt: 0)
                let recipeName = String(recipe.name.prefix(35)).padding(toLength: 35, withPad: " ", startingAt: 0)
                let cal = recipe.calories
                let protein = recipe.proteinGrams
                let carbs = recipe.carbsGrams
                let fat = recipe.fatGrams

                print("│ \(mealType) │ \(recipeName) │ \(String(cal).padding(toLength: 4, withPad: " ", startingAt: 0)) cal │ P:\(String(protein).padding(toLength: 3, withPad: " ", startingAt: 0))g C:\(String(carbs).padding(toLength: 3, withPad: " ", startingAt: 0))g F:\(String(fat).padding(toLength: 3, withPad: " ", startingAt: 0))g │")

                dayCal += cal
                dayProtein += protein
                dayCarbs += carbs
                dayFat += fat
            }

            let calDiff = dayCal - profile.dailyCalorieTarget
            let proteinDiff = dayProtein - profile.proteinGrams
            let calStatus = calDiff >= -100 && calDiff <= 100 ? "✅" : "❌"
            let proteinStatus = proteinDiff >= -10 && proteinDiff <= 10 ? "✅" : "❌"

            print("├─────────────────────────────────────────────────────────────────────────────┤")
            print("│ TOTAL: \(String(dayCal).padding(toLength: 4, withPad: " ", startingAt: 0)) cal (\(calDiff >= 0 ? "+" : "")\(calDiff)) \(calStatus) │ P:\(dayProtein)g (\(proteinDiff >= 0 ? "+" : "")\(proteinDiff)) \(proteinStatus) │ C:\(dayCarbs)g │ F:\(dayFat)g │")
            print("└─────────────────────────────────────────────────────────────────────────────┘")

            weekTotalCal += dayCal
            weekTotalProtein += dayProtein
            weekTotalCarbs += dayCarbs
            weekTotalFat += dayFat
        }

        let avgCal = weekTotalCal / max(mealPlan.sortedDays.count, 1)
        let avgProtein = weekTotalProtein / max(mealPlan.sortedDays.count, 1)
        let avgCarbs = weekTotalCarbs / max(mealPlan.sortedDays.count, 1)
        let avgFat = weekTotalFat / max(mealPlan.sortedDays.count, 1)

        print("\n╔══════════════════════════════════════════════════════════════════════════════╗")
        print("║ WEEKLY AVERAGES                                                               ║")
        print("╠══════════════════════════════════════════════════════════════════════════════╣")
        print("║ Avg Daily: \(avgCal) cal (target: \(profile.dailyCalorieTarget)) | \(avgProtein)g protein (target: \(profile.proteinGrams)g)")
        print("║ Avg Daily: \(avgCarbs)g carbs (target: \(profile.carbsGrams)g) | \(avgFat)g fat (target: \(profile.fatGrams)g)")
        print("╚══════════════════════════════════════════════════════════════════════════════╝")
        print("\n")
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
    private func buildPrompt(for profile: UserProfile, weeklyPreferences: String? = nil) -> String {
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

        let weeklyPreferencesSection: String
        if let prefs = weeklyPreferences, !prefs.isEmpty {
            weeklyPreferencesSection = """

            THIS WEEK'S SPECIAL REQUESTS:
            \(prefs)
            """
        } else {
            weeklyPreferencesSection = ""
        }

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
        SIMPLE MODE: \(profile.simpleModeEnabled ? "Yes - prefer recipes with fewer ingredients" : "No")\(weeklyPreferencesSection)

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
