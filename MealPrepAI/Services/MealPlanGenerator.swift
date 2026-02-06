import Foundation
import SwiftUI
import SwiftData

// MARK: - Macro Overrides
/// Temporary macro overrides for a single meal plan generation
struct MacroOverrides {
    var calories: Int?
    var protein: Int?
    var carbs: Int?
    var fat: Int?

    var hasOverrides: Bool {
        calories != nil || protein != nil || carbs != nil || fat != nil
    }
}

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
        macroOverrides: MacroOverrides? = nil,
        duration: Int = 7,
        measurementSystem: String = "Metric",
        modelContext: ModelContext
    ) async throws -> MealPlan {
        let generationStartTime = Date()
        #if DEBUG
        print("[DEBUG:Generator] ========== GENERATE MEAL PLAN START ==========")
        #if DEBUG
        print("[DEBUG:Generator] Start Date: \(startDate)")
        #endif
        #if DEBUG
        print("[DEBUG:Generator] Weekly Preferences: \(weeklyPreferences ?? "None")")
        #endif
        #if DEBUG
        print("[DEBUG:Generator] Profile calories: \(profile.dailyCalorieTarget)")
        #endif
        #endif

        isGenerating = true
        progress = "Building your personalized meal plan..."
        error = nil

        defer {
            isGenerating = false
            progress = ""
            #if DEBUG
            let elapsedTime = Date().timeIntervalSince(generationStartTime)
            #if DEBUG
            print("[DEBUG:Generator] ⏱️ Total generation time: \(String(format: "%.2f", elapsedTime)) seconds")
            #endif
            #if DEBUG
            print("[DEBUG:Generator] ========== GENERATE MEAL PLAN END ==========")
            #endif
            #endif
        }

        do {
            // Build API user profile from SwiftData profile
            #if DEBUG
            print("[DEBUG:Generator] Building API user profile...")
            #endif
            let apiProfile = buildAPIUserProfile(from: profile, overrides: macroOverrides, measurementSystem: measurementSystem)

            progress = "Generating recipes with AI..."
            #if DEBUG
            print("[DEBUG:Generator] Calling generateMealPlan API...")
            #endif

            // Gather recipe names from recent meal plans to avoid stale repeats
            let recentRecipeNames: [String] = {
                let planFetch = FetchDescriptor<MealPlan>(
                    sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
                )
                guard let recentPlans = try? modelContext.fetch(planFetch) else { return [] }
                var names: [String] = []
                for plan in recentPlans.prefix(2) {
                    for day in plan.sortedDays {
                        for meal in day.sortedMeals {
                            if let recipeName = meal.recipe?.name {
                                names.append(recipeName)
                            }
                        }
                    }
                }
                return Array(Set(names)) // deduplicate
            }()
            #if DEBUG
            if !recentRecipeNames.isEmpty {
                #if DEBUG
                print("[DEBUG:Generator] Excluding \(recentRecipeNames.count) recent recipe names")
                #endif
            }
            #endif

            // Call the new API endpoint
            let apiResponse = try await apiService.generateMealPlan(
                userProfile: apiProfile,
                weeklyPreferences: weeklyPreferences,
                excludeRecipeNames: recentRecipeNames,
                duration: duration
            )

            #if DEBUG
            print("[DEBUG:Generator] API response received")
            #if DEBUG
            print("[DEBUG:Generator] Success: \(apiResponse.success)")
            #endif
            #if DEBUG
            print("[DEBUG:Generator] Recipes added: \(apiResponse.recipesAdded ?? 0)")
            #endif
            #if DEBUG
            print("[DEBUG:Generator] Recipes duplicate: \(apiResponse.recipesDuplicate ?? 0)")
            #endif
            #endif

            // Check for errors
            if !apiResponse.success {
                #if DEBUG
                print("[DEBUG:Generator] ERROR: API returned failure - \(apiResponse.error ?? "Unknown error")")
                #endif
                throw APIError.serverError(apiResponse.error ?? "Unknown error")
            }

            guard let apiMealPlan = apiResponse.mealPlan else {
                #if DEBUG
                print("[DEBUG:Generator] ERROR: No meal plan in response")
                #endif
                throw APIError.invalidResponse
            }

            progress = "Processing meal plan..."

            // Convert API response to MealPlanResponse format
            #if DEBUG
            print("[DEBUG:Generator] Converting API response to MealPlanResponse...")
            #endif
            let mealPlanResponse = convertAPIResponseToMealPlanResponse(apiMealPlan)
            #if DEBUG
            print("[DEBUG:Generator] Converted \(mealPlanResponse.days.count) days")
            #endif

            progress = "Saving to your library..."

            // Convert to SwiftData models and save
            #if DEBUG
            print("[DEBUG:Generator] Converting to SwiftData models...")
            #endif
            let result = mealPlanResponse.toSwiftDataModels(startDate: startDate, planDuration: duration)
            #if DEBUG
            print("[DEBUG:Generator] Created: \(result.days.count) days, \(result.recipes.count) recipes, \(result.meals.count) meals")
            #endif

            // Insert all models into context
            #if DEBUG
            print("[DEBUG:Generator] Inserting models into context...")
            #endif
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

            // Migrate non-overlapping days from old active plans into the new plan
            let newPlanDates = Set(result.days.map { Calendar.current.startOfDay(for: $0.date) })
            let newPlan = result.mealPlan

            let fetchDescriptor = FetchDescriptor<MealPlan>(
                predicate: #Predicate<MealPlan> { $0.isActive },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            let existingPlans = (try? modelContext.fetch(fetchDescriptor)) ?? []

            for oldPlan in existingPlans where oldPlan.id != newPlan.id {
                let oldDays = oldPlan.days ?? []
                for oldDay in oldDays {
                    let oldDayDate = Calendar.current.startOfDay(for: oldDay.date)
                    if !newPlanDates.contains(oldDayDate) {
                        // Move this day to the new plan
                        oldDay.mealPlan = newPlan
                        #if DEBUG
                        print("[DEBUG:Generator] Migrated day \(oldDay.dayName) (\(oldDay.date)) from old plan to new plan")
                        #endif
                    }
                }
                // Deactivate old plan (remaining overlapping days will cascade-delete with it, which is fine)
                oldPlan.isActive = false
                #if DEBUG
                print("[DEBUG:Generator] Deactivated old plan \(oldPlan.id)")
                #endif
            }

            // Update new plan's duration to cover all days
            let allNewPlanDays = newPlan.days ?? []
            if let earliest = allNewPlanDays.min(by: { $0.date < $1.date }),
               let latest = allNewPlanDays.max(by: { $0.date < $1.date }) {
                let totalDays = Calendar.current.dateComponents([.day], from: earliest.date, to: latest.date).day! + 1
                newPlan.weekStartDate = earliest.date
                newPlan.planDuration = totalDays
                #if DEBUG
                print("[DEBUG:Generator] Updated plan range: \(totalDays) days from \(earliest.date) to \(latest.date)")
                #endif
            }

            // Clean up orphaned recipes from deactivated plans (recipes no longer
            // attached to any meal and not marked as favorites)
            modelContext.deleteOrphanedRecipes()

            #if DEBUG
            print("[DEBUG:Generator] Saving context...")
            #endif
            try modelContext.save()
            #if DEBUG
            print("[DEBUG:Generator] Context saved successfully")
            #endif

            // Print weekly summary for analysis
            printWeeklySummary(mealPlan: result.mealPlan, profile: profile)

            return result.mealPlan

        } catch {
            #if DEBUG
            print("[DEBUG:Generator] ERROR: \(error.localizedDescription)")
            #if DEBUG
            print("[DEBUG:Generator] Error type: \(type(of: error))")
            #endif
            #endif
            self.error = error
            throw error
        }
    }

    // MARK: - Build API User Profile
    private func buildAPIUserProfile(from profile: UserProfile, overrides: MacroOverrides?, measurementSystem: String = "Metric") -> GeneratePlanUserProfile {
        // Extract disliked cuisines from cuisinePreferencesMap
        let dislikedCuisines = profile.cuisinePreferencesMap
            .filter { $0.value == .dislike }
            .map { $0.key }

        // Use overrides if provided, otherwise use profile values
        let calories = overrides?.calories ?? profile.dailyCalorieTarget
        let protein = overrides?.protein ?? profile.proteinGrams
        let carbs = overrides?.carbs ?? profile.carbsGrams
        let fat = overrides?.fat ?? profile.fatGrams

        #if DEBUG
        if let overrides = overrides, overrides.hasOverrides {
            #if DEBUG
            print("[DEBUG:Generator] Using macro overrides - Calories: \(calories), Protein: \(protein)g, Carbs: \(carbs)g, Fat: \(fat)g")
            #endif
        }
        #endif

        return GeneratePlanUserProfile(
            age: profile.age,
            gender: profile.gender.rawValue,
            weightKg: profile.weightKg,
            heightCm: profile.heightCm,
            activityLevel: profile.activityLevel.rawValue,
            dailyCalorieTarget: calories,
            proteinGrams: protein,
            carbsGrams: carbs,
            fatGrams: fat,
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
            goalPace: profile.goalPace.rawValue,
            measurementSystem: measurementSystem
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
        measurementSystem: String = "Metric",
        modelContext: ModelContext
    ) async throws -> (recipe: Recipe, ingredients: [Ingredient], recipeIngredients: [RecipeIngredient]) {
        let swapStartTime = Date()
        #if DEBUG
        print("[DEBUG:Generator] ========== REPLACEMENT MEAL START ==========")
        #if DEBUG
        print("[DEBUG:Generator] Meal Type: \(mealType.rawValue)")
        #endif
        #if DEBUG
        print("[DEBUG:Generator] Exclude Recipes: \(excludeRecipes.joined(separator: ", "))")
        #endif
        #endif

        isGenerating = true
        progress = "Finding a new \(mealType.rawValue.lowercased())..."
        error = nil

        defer {
            isGenerating = false
            progress = ""
            #if DEBUG
            let elapsedTime = Date().timeIntervalSince(swapStartTime)
            #if DEBUG
            print("[DEBUG:Generator] ⏱️ Swap generation time: \(String(format: "%.2f", elapsedTime)) seconds")
            #endif
            #if DEBUG
            print("[DEBUG:Generator] ========== REPLACEMENT MEAL END ==========")
            #endif
            #endif
        }

        do {
            // Build API user profile for swap
            #if DEBUG
            print("[DEBUG:Generator] Building swap API profile...")
            #endif
            // Extract disliked cuisines from cuisinePreferencesMap
            let swapDislikedCuisines = profile.cuisinePreferencesMap
                .filter { $0.value == .dislike }
                .map { $0.key }

            let swapProfile = SwapMealUserProfile(
                dailyCalorieTarget: profile.dailyCalorieTarget,
                proteinGrams: profile.proteinGrams,
                carbsGrams: profile.carbsGrams,
                fatGrams: profile.fatGrams,
                dietaryRestrictions: profile.dietaryRestrictions.map { $0.rawValue },
                allergies: profile.allergies.map { $0.rawValue },
                foodDislikes: profile.foodDislikes.map { $0.rawValue },
                preferredCuisines: profile.preferredCuisines.map { $0.rawValue },
                dislikedCuisines: swapDislikedCuisines,
                cookingSkill: profile.cookingSkill.rawValue,
                maxCookingTimeMinutes: profile.maxCookingTime.maxMinutes,
                simpleModeEnabled: profile.simpleModeEnabled,
                measurementSystem: measurementSystem
            )

            #if DEBUG
            print("[DEBUG:Generator] Calling swapMeal API...")
            #endif
            let apiResponse = try await apiService.swapMeal(
                userProfile: swapProfile,
                mealType: mealType.rawValue.lowercased(),
                excludeRecipeNames: excludeRecipes
            )

            #if DEBUG
            print("[DEBUG:Generator] API response received")
            #if DEBUG
            print("[DEBUG:Generator] Success: \(apiResponse.success)")
            #endif
            #endif

            // Check for errors
            if !apiResponse.success {
                #if DEBUG
                print("[DEBUG:Generator] ERROR: API returned failure - \(apiResponse.error ?? "Unknown error")")
                #endif
                throw APIError.serverError(apiResponse.error ?? "Unknown error")
            }

            guard let apiRecipe = apiResponse.recipe else {
                #if DEBUG
                print("[DEBUG:Generator] ERROR: No recipe in response")
                #endif
                throw APIError.invalidResponse
            }

            #if DEBUG
            print("[DEBUG:Generator] Received recipe: \(apiRecipe.name)")
            #endif

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

            #if DEBUG
            print("[DEBUG:Generator] Created \(ingredients.count) ingredients")
            #endif

            // Save to context
            #if DEBUG
            print("[DEBUG:Generator] Saving to context...")
            #endif
            modelContext.insert(recipe)
            for ingredient in ingredients {
                modelContext.insert(ingredient)
            }
            for ri in recipeIngredients {
                modelContext.insert(ri)
            }
            try modelContext.save()
            #if DEBUG
            print("[DEBUG:Generator] Context saved successfully")
            #endif

            return (recipe, ingredients, recipeIngredients)

        } catch {
            #if DEBUG
            print("[DEBUG:Generator] ERROR: \(error.localizedDescription)")
            #if DEBUG
            print("[DEBUG:Generator] Error type: \(type(of: error))")
            #endif
            #endif
            self.error = error
            throw error
        }
    }

    // MARK: - Print Weekly Summary
    private func printWeeklySummary(mealPlan: MealPlan, profile: UserProfile) {
        #if DEBUG
        print("\n")
        #if DEBUG
        print("╔══════════════════════════════════════════════════════════════════════════════╗")
        #endif
        #if DEBUG
        print("║                         WEEKLY MEAL PLAN SUMMARY                              ║")
        #endif
        #if DEBUG
        print("╠══════════════════════════════════════════════════════════════════════════════╣")
        #endif
        #if DEBUG
        print("║ TARGETS: \(profile.dailyCalorieTarget) cal | \(profile.proteinGrams)g protein | \(profile.carbsGrams)g carbs | \(profile.fatGrams)g fat")
        #endif
        #if DEBUG
        print("╚══════════════════════════════════════════════════════════════════════════════╝")
        #endif

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

            #if DEBUG
            print("\n┌─────────────────────────────────────────────────────────────────────────────┐")
            #endif
            #if DEBUG
            print("│ \(dayName.uppercased().padding(toLength: 75, withPad: " ", startingAt: 0)) │")
            #endif
            #if DEBUG
            print("├─────────────────────────────────────────────────────────────────────────────┤")
            #endif

            for meal in day.sortedMeals {
                guard let recipe = meal.recipe else { continue }
                let mealType = meal.mealType.rawValue.padding(toLength: 10, withPad: " ", startingAt: 0)
                let recipeName = String(recipe.name.prefix(35)).padding(toLength: 35, withPad: " ", startingAt: 0)
                let cal = recipe.calories
                let protein = recipe.proteinGrams
                let carbs = recipe.carbsGrams
                let fat = recipe.fatGrams

                #if DEBUG
                print("│ \(mealType) │ \(recipeName) │ \(String(cal).padding(toLength: 4, withPad: " ", startingAt: 0)) cal │ P:\(String(protein).padding(toLength: 3, withPad: " ", startingAt: 0))g C:\(String(carbs).padding(toLength: 3, withPad: " ", startingAt: 0))g F:\(String(fat).padding(toLength: 3, withPad: " ", startingAt: 0))g │")
                #endif

                // Print ingredients
                if let ingredients = recipe.ingredients, !ingredients.isEmpty {
                    #if DEBUG
                    print("│   Ingredients:")
                    #endif
                    for ri in ingredients {
                        let name = ri.ingredient?.name ?? "Unknown"
                        #if DEBUG
                        print("│     - \(ri.displayWithGrams) \(name)\(ri.notes.map { " (\($0))" } ?? "")")
                        #endif
                    }
                }

                // Print instructions
                if !recipe.instructions.isEmpty {
                    #if DEBUG
                    print("│   Instructions:")
                    #endif
                    for (i, step) in recipe.instructions.enumerated() {
                        #if DEBUG
                        print("│     \(i + 1). \(step)")
                        #endif
                    }
                }
                #if DEBUG
                print("│")
                #endif

                dayCal += cal
                dayProtein += protein
                dayCarbs += carbs
                dayFat += fat
            }

            let calDiff = dayCal - profile.dailyCalorieTarget
            let proteinDiff = dayProtein - profile.proteinGrams
            let calStatus = calDiff >= -100 && calDiff <= 100 ? "✅" : "❌"
            let proteinStatus = proteinDiff >= -10 && proteinDiff <= 10 ? "✅" : "❌"

            #if DEBUG
            print("├─────────────────────────────────────────────────────────────────────────────┤")
            #endif
            #if DEBUG
            print("│ TOTAL: \(String(dayCal).padding(toLength: 4, withPad: " ", startingAt: 0)) cal (\(calDiff >= 0 ? "+" : "")\(calDiff)) \(calStatus) │ P:\(dayProtein)g (\(proteinDiff >= 0 ? "+" : "")\(proteinDiff)) \(proteinStatus) │ C:\(dayCarbs)g │ F:\(dayFat)g │")
            #endif
            #if DEBUG
            print("└─────────────────────────────────────────────────────────────────────────────┘")
            #endif

            weekTotalCal += dayCal
            weekTotalProtein += dayProtein
            weekTotalCarbs += dayCarbs
            weekTotalFat += dayFat
        }

        let avgCal = weekTotalCal / max(mealPlan.sortedDays.count, 1)
        let avgProtein = weekTotalProtein / max(mealPlan.sortedDays.count, 1)
        let avgCarbs = weekTotalCarbs / max(mealPlan.sortedDays.count, 1)
        let avgFat = weekTotalFat / max(mealPlan.sortedDays.count, 1)

        #if DEBUG
        print("\n╔══════════════════════════════════════════════════════════════════════════════╗")
        #endif
        #if DEBUG
        print("║ WEEKLY AVERAGES                                                               ║")
        #endif
        #if DEBUG
        print("╠══════════════════════════════════════════════════════════════════════════════╣")
        #endif
        #if DEBUG
        print("║ Avg Daily: \(avgCal) cal (target: \(profile.dailyCalorieTarget)) | \(avgProtein)g protein (target: \(profile.proteinGrams)g)")
        #endif
        #if DEBUG
        print("║ Avg Daily: \(avgCarbs)g carbs (target: \(profile.carbsGrams)g) | \(avgFat)g fat (target: \(profile.fatGrams)g)")
        #endif
        #if DEBUG
        print("╚══════════════════════════════════════════════════════════════════════════════╝")
        #endif
        #if DEBUG
        print("\n")
        #endif
        #endif
    }

}
