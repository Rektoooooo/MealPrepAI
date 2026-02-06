import Testing
import Foundation
import SwiftData
@testable import MealPrepAI

struct SwiftDataPersistenceTests {

    // MARK: - Container Creation

    @MainActor
    @Test func inMemoryContainerCreatesSuccessfully() throws {
        let container = try TestHelpers.makeModelContainer()
        #expect(container.schema.entities.count == 9)
    }

    // MARK: - UserProfile CRUD

    @MainActor
    @Test func insertAndFetchUserProfile() throws {
        let container = try TestHelpers.makeModelContainer()
        let context = container.mainContext

        let profile = UserProfile(
            name: "Test User",
            age: 25,
            gender: .female,
            heightCm: 165,
            weightKg: 60,
            activityLevel: .moderate,
            weightGoal: .lose,
            dailyCalorieTarget: 1800,
            proteinGrams: 120,
            carbsGrams: 180,
            fatGrams: 60,
            dietaryRestrictions: [.vegetarian],
            allergies: [.peanuts],
            preferredCuisines: [.italian, .japanese]
        )
        context.insert(profile)
        try context.save()

        let descriptor = FetchDescriptor<UserProfile>()
        let fetched = try context.fetch(descriptor)
        #expect(fetched.count == 1)
        #expect(fetched[0].name == "Test User")
        #expect(fetched[0].gender == .female)
        #expect(fetched[0].dietaryRestrictions.contains(.vegetarian))
        #expect(fetched[0].allergies.contains(.peanuts))
        #expect(fetched[0].preferredCuisines.count == 2)
    }

    @MainActor
    @Test func updateUserProfile() throws {
        let container = try TestHelpers.makeModelContainer()
        let context = container.mainContext

        let profile = UserProfile(name: "Original")
        context.insert(profile)
        try context.save()

        profile.name = "Updated"
        profile.weightGoal = .gain
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<UserProfile>())
        #expect(fetched[0].name == "Updated")
        #expect(fetched[0].weightGoal == .gain)
    }

    @MainActor
    @Test func deleteUserProfile() throws {
        let container = try TestHelpers.makeModelContainer()
        let context = container.mainContext

        let profile = UserProfile(name: "ToDelete")
        context.insert(profile)
        try context.save()

        context.delete(profile)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<UserProfile>())
        #expect(fetched.isEmpty)
    }

    // MARK: - MealPlan + Day + Meal Relationships

    @MainActor
    @Test func mealPlanDayRelationship() throws {
        let container = try TestHelpers.makeModelContainer()
        let context = container.mainContext

        let plan = MealPlan(weekStartDate: Date(), planDuration: 7)
        context.insert(plan)

        let day = Day(date: Date(), dayOfWeek: 0)
        day.mealPlan = plan
        context.insert(day)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<MealPlan>())
        #expect(fetched.count == 1)
        #expect(fetched[0].days.count == 1)
        #expect(fetched[0].days.first?.dayOfWeek == 0)
    }

    @MainActor
    @Test func dayMealRecipeRelationship() throws {
        let container = try TestHelpers.makeModelContainer()
        let context = container.mainContext

        let plan = MealPlan(weekStartDate: Date())
        context.insert(plan)

        let day = Day(date: Date(), dayOfWeek: 0)
        day.mealPlan = plan
        context.insert(day)

        let recipe = Recipe(name: "Pasta", calories: 500, proteinGrams: 20, carbsGrams: 60, fatGrams: 15)
        context.insert(recipe)

        let meal = Meal(mealType: .lunch)
        meal.day = day
        meal.recipe = recipe
        context.insert(meal)
        try context.save()

        let fetchedDays = try context.fetch(FetchDescriptor<Day>())
        #expect(fetchedDays[0].meals.count == 1)
        #expect(fetchedDays[0].meals.first?.recipe?.name == "Pasta")
        #expect(fetchedDays[0].totalCalories == 500)
    }

    @MainActor
    @Test func fullMealPlanWithMultipleDaysAndMeals() throws {
        let container = try TestHelpers.makeModelContainer()
        let context = container.mainContext

        let plan = MealPlan(weekStartDate: Date(), planDuration: 3)
        context.insert(plan)

        for dayIndex in 0..<3 {
            let day = Day(
                date: Calendar.current.date(byAdding: .day, value: dayIndex, to: Date())!,
                dayOfWeek: dayIndex
            )
            day.mealPlan = plan
            context.insert(day)

            for mealType in [MealType.breakfast, .lunch, .dinner] {
                let recipe = Recipe(
                    name: "\(mealType.rawValue) Day \(dayIndex)",
                    calories: 400 + dayIndex * 50
                )
                context.insert(recipe)

                let meal = Meal(mealType: mealType)
                meal.day = day
                meal.recipe = recipe
                context.insert(meal)
            }
        }
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<MealPlan>())
        #expect(fetched.count == 1)
        #expect(fetched[0].days.count == 3)

        let totalMeals = fetched[0].days.flatMap { $0.meals }.count
        #expect(totalMeals == 9)
    }

    // MARK: - Recipe + Ingredient Relationships

    @MainActor
    @Test func recipeIngredientRelationship() throws {
        let container = try TestHelpers.makeModelContainer()
        let context = container.mainContext

        let recipe = Recipe(name: "Salad", calories: 200)
        context.insert(recipe)

        let ingredient = Ingredient(name: "Lettuce", category: .produce, defaultUnit: .piece)
        context.insert(ingredient)

        let ri = RecipeIngredient(quantity: 1, unit: .piece)
        ri.recipe = recipe
        ri.ingredient = ingredient
        context.insert(ri)
        try context.save()

        let fetchedRecipes = try context.fetch(FetchDescriptor<Recipe>())
        #expect(fetchedRecipes[0].ingredients.count == 1)
        #expect(fetchedRecipes[0].ingredients.first?.ingredient?.name == "Lettuce")
    }

    @MainActor
    @Test func recipeWithMultipleIngredients() throws {
        let container = try TestHelpers.makeModelContainer()
        let context = container.mainContext

        let recipe = Recipe(name: "Stir Fry", calories: 450)
        context.insert(recipe)

        let ingredients = [
            ("Chicken Breast", GroceryCategory.meat, MeasurementUnit.gram, 200.0),
            ("Broccoli", GroceryCategory.produce, MeasurementUnit.cup, 1.0),
            ("Soy Sauce", GroceryCategory.condiments, MeasurementUnit.tablespoon, 2.0),
            ("Rice", GroceryCategory.pantry, MeasurementUnit.cup, 1.0)
        ]

        for (name, category, unit, qty) in ingredients {
            let ing = Ingredient(name: name, category: category, defaultUnit: unit)
            context.insert(ing)
            let ri = RecipeIngredient(quantity: qty, unit: unit)
            ri.recipe = recipe
            ri.ingredient = ing
            context.insert(ri)
        }
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Recipe>())
        #expect(fetched[0].ingredients.count == 4)
    }

    // MARK: - GroceryList + GroceryItem

    @MainActor
    @Test func groceryListWithItems() throws {
        let container = try TestHelpers.makeModelContainer()
        let context = container.mainContext

        let plan = MealPlan(weekStartDate: Date())
        context.insert(plan)

        let list = GroceryList()
        list.mealPlan = plan
        context.insert(list)

        let ing1 = Ingredient(name: "Apples", category: .produce)
        let ing2 = Ingredient(name: "Milk", category: .dairy)
        context.insert(ing1)
        context.insert(ing2)

        let item1 = GroceryItem(quantity: 6, unit: .piece)
        item1.groceryList = list
        item1.ingredient = ing1
        context.insert(item1)

        let item2 = GroceryItem(quantity: 1, unit: .liter)
        item2.groceryList = list
        item2.ingredient = ing2
        context.insert(item2)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<GroceryList>())
        #expect(fetched[0].totalCount == 2)
        #expect(fetched[0].progress == 0)

        // Check an item off
        item1.isChecked = true
        try context.save()
        #expect(fetched[0].checkedCount == 1)
        #expect(fetched[0].progress == 0.5)
    }

    @MainActor
    @Test func groceryItemsByCategoryFromDB() throws {
        let container = try TestHelpers.makeModelContainer()
        let context = container.mainContext

        let list = GroceryList()
        context.insert(list)

        let produce1 = Ingredient(name: "Carrots", category: .produce)
        let produce2 = Ingredient(name: "Onions", category: .produce)
        let meat = Ingredient(name: "Beef", category: .meat)
        context.insert(produce1)
        context.insert(produce2)
        context.insert(meat)

        for ing in [produce1, produce2, meat] {
            let item = GroceryItem(quantity: 1, unit: .piece)
            item.groceryList = list
            item.ingredient = ing
            context.insert(item)
        }
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<GroceryList>())
        let grouped = fetched[0].itemsByCategory
        #expect(grouped[.produce]?.count == 2)
        #expect(grouped[.meat]?.count == 1)
    }

    // MARK: - Cascade Delete

    @MainActor
    @Test func deleteMealPlanCascadesToDays() throws {
        let container = try TestHelpers.makeModelContainer()
        let context = container.mainContext

        let plan = MealPlan(weekStartDate: Date())
        context.insert(plan)

        let day = Day(date: Date(), dayOfWeek: 0)
        day.mealPlan = plan
        context.insert(day)

        let meal = Meal(mealType: .breakfast)
        meal.day = day
        context.insert(meal)
        try context.save()

        // Verify everything exists
        #expect(try context.fetch(FetchDescriptor<MealPlan>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<Day>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<Meal>()).count == 1)

        // Delete the plan - should cascade
        context.delete(plan)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<MealPlan>()).count == 0)
        #expect(try context.fetch(FetchDescriptor<Day>()).count == 0)
        #expect(try context.fetch(FetchDescriptor<Meal>()).count == 0)
    }

    @MainActor
    @Test func deleteRecipeCascadesToRecipeIngredients() throws {
        let container = try TestHelpers.makeModelContainer()
        let context = container.mainContext

        let recipe = Recipe(name: "Test")
        context.insert(recipe)

        let ing = Ingredient(name: "Salt", category: .spices)
        context.insert(ing)

        let ri = RecipeIngredient(quantity: 1, unit: .teaspoon)
        ri.recipe = recipe
        ri.ingredient = ing
        context.insert(ri)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<RecipeIngredient>()).count == 1)

        context.delete(recipe)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<Recipe>()).count == 0)
        #expect(try context.fetch(FetchDescriptor<RecipeIngredient>()).count == 0)
        // Ingredient should still exist (not cascade)
        #expect(try context.fetch(FetchDescriptor<Ingredient>()).count == 1)
    }

    @MainActor
    @Test func deleteGroceryListCascadesToItems() throws {
        let container = try TestHelpers.makeModelContainer()
        let context = container.mainContext

        let list = GroceryList()
        context.insert(list)

        let ing = Ingredient(name: "Flour", category: .pantry)
        context.insert(ing)

        let item = GroceryItem(quantity: 1, unit: .kilogram)
        item.groceryList = list
        item.ingredient = ing
        context.insert(item)
        try context.save()

        context.delete(list)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<GroceryList>()).count == 0)
        #expect(try context.fetch(FetchDescriptor<GroceryItem>()).count == 0)
        #expect(try context.fetch(FetchDescriptor<Ingredient>()).count == 1)
    }

    // MARK: - MealPlanDTO -> SwiftData Integration

    @MainActor
    @Test func mealPlanDTOToSwiftDataModels() throws {
        let container = try TestHelpers.makeModelContainer()
        let context = container.mainContext

        let dto = MealPlanResponse(days: [
            DayDTO(dayOfWeek: 0, meals: [
                MealDTO(mealType: "Breakfast", recipe: RecipeDTO(
                    name: "Oatmeal",
                    description: "Simple oats",
                    instructions: ["Cook oats in water for five minutes until creamy."],
                    prepTimeMinutes: 2,
                    cookTimeMinutes: 5,
                    servings: 1,
                    complexity: "easy",
                    cuisineType: "American",
                    calories: 300,
                    proteinGrams: 10,
                    carbsGrams: 50,
                    fatGrams: 8,
                    fiberGrams: 5,
                    ingredients: [
                        IngredientDTO(name: "Oats", quantity: 1, unit: "cup", category: "pantry"),
                        IngredientDTO(name: "Water", quantity: 2, unit: "cup", category: "beverages")
                    ]
                )),
                MealDTO(mealType: "Lunch", recipe: RecipeDTO(
                    name: "Grilled Chicken Salad",
                    description: "Fresh salad",
                    instructions: ["Grill chicken and slice thinly over mixed greens."],
                    prepTimeMinutes: 10,
                    cookTimeMinutes: 15,
                    servings: 1,
                    complexity: "easy",
                    cuisineType: "American",
                    calories: 450,
                    proteinGrams: 35,
                    carbsGrams: 20,
                    fatGrams: 22,
                    fiberGrams: 4,
                    ingredients: [
                        IngredientDTO(name: "Chicken Breast", quantity: 200, unit: "g", category: "meat"),
                        IngredientDTO(name: "Mixed Greens", quantity: 2, unit: "cup", category: "produce")
                    ]
                ))
            ])
        ])

        let result = dto.toSwiftDataModels(startDate: Date(), planDuration: 7)

        // Insert everything into context
        context.insert(result.mealPlan)
        for day in result.days { context.insert(day) }
        for meal in result.meals { context.insert(meal) }
        for recipe in result.recipes { context.insert(recipe) }
        for ingredient in result.ingredients { context.insert(ingredient) }
        for ri in result.recipeIngredients { context.insert(ri) }
        try context.save()

        // Verify persistence
        let plans = try context.fetch(FetchDescriptor<MealPlan>())
        #expect(plans.count == 1)
        #expect(plans[0].planDuration == 7)

        let days = try context.fetch(FetchDescriptor<Day>())
        #expect(days.count == 1)

        let meals = try context.fetch(FetchDescriptor<Meal>())
        #expect(meals.count == 2)

        let recipes = try context.fetch(FetchDescriptor<Recipe>())
        #expect(recipes.count == 2)
        #expect(recipes.contains { $0.name == "Oatmeal" })
        #expect(recipes.contains { $0.name == "Grilled Chicken Salad" })

        let ingredients = try context.fetch(FetchDescriptor<Ingredient>())
        #expect(ingredients.count == 4)

        let recipeIngredients = try context.fetch(FetchDescriptor<RecipeIngredient>())
        #expect(recipeIngredients.count == 4)
    }

    // MARK: - FetchDescriptor with Predicates

    @MainActor
    @Test func fetchActiveMealPlansOnly() throws {
        let container = try TestHelpers.makeModelContainer()
        let context = container.mainContext

        let activePlan = MealPlan(weekStartDate: Date(), isActive: true)
        let inactivePlan = MealPlan(weekStartDate: Date(), isActive: false)
        context.insert(activePlan)
        context.insert(inactivePlan)
        try context.save()

        let descriptor = FetchDescriptor<MealPlan>(
            predicate: #Predicate { $0.isActive }
        )
        let active = try context.fetch(descriptor)
        #expect(active.count == 1)
        #expect(active[0].isActive)
    }

    @MainActor
    @Test func fetchFavoriteRecipes() throws {
        let container = try TestHelpers.makeModelContainer()
        let context = container.mainContext

        let fav = Recipe(name: "Fav Recipe", isFavorite: true)
        let notFav = Recipe(name: "Regular Recipe", isFavorite: false)
        context.insert(fav)
        context.insert(notFav)
        try context.save()

        let descriptor = FetchDescriptor<Recipe>(
            predicate: #Predicate { $0.isFavorite }
        )
        let favorites = try context.fetch(descriptor)
        #expect(favorites.count == 1)
        #expect(favorites[0].name == "Fav Recipe")
    }

    // MARK: - UserProfile with MealPlan Relationship

    @MainActor
    @Test func userProfileMealPlanRelationship() throws {
        let container = try TestHelpers.makeModelContainer()
        let context = container.mainContext

        let profile = UserProfile(name: "User")
        context.insert(profile)

        let plan = MealPlan(weekStartDate: Date())
        plan.userProfile = profile
        context.insert(plan)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<UserProfile>())
        #expect(fetched[0].mealPlans.count == 1)
    }

    // MARK: - Onboarding Save (ViewModel -> DB)

    @MainActor
    @Test func onboardingViewModelSavesToDB() throws {
        let container = try TestHelpers.makeModelContainer()
        let context = container.mainContext

        let vm = NewOnboardingViewModel()
        vm.userName = "DB Test User"
        vm.gender = .male
        vm.age = 28
        vm.weightKg = 85
        vm.targetWeightKg = 78
        vm.heightCm = 182
        vm.activityLevel = .active
        vm.weightGoal = .lose
        vm.goalPace = .moderate
        vm.dietaryRestriction = .none
        vm.allergies = [.peanuts, .shellfish]
        vm.cookingSkill = .intermediate
        vm.pantryLevel = .wellStocked

        let success = vm.saveProfile(modelContext: context)
        #expect(success)

        let profiles = try context.fetch(FetchDescriptor<UserProfile>())
        #expect(profiles.count == 1)
        #expect(profiles[0].name == "DB Test User")
        #expect(profiles[0].gender == .male)
        #expect(profiles[0].age == 28)
        #expect(profiles[0].weightKg == 85)
        #expect(profiles[0].activityLevel == .active)
        #expect(profiles[0].weightGoal == .lose)
        #expect(profiles[0].allergies.contains(.peanuts))
        #expect(profiles[0].allergies.contains(.shellfish))
        #expect(profiles[0].hasCompletedOnboarding)
        #expect(profiles[0].dailyCalorieTarget == vm.recommendedCalories)
        #expect(profiles[0].proteinGrams == vm.proteinGrams)
    }
}
