import Foundation
import SwiftData

@MainActor
class SampleDataGenerator {

    static func generateSampleMealPlan(for profile: UserProfile, in context: ModelContext) {
        // Create sample recipes first
        let (breakfastRecipes, lunchRecipes, dinnerRecipes, snackRecipes) = createSampleRecipes(in: context)

        // Create a 7-day meal plan starting today
        let mealPlan = MealPlan(weekStartDate: Date(), isActive: true)
        context.insert(mealPlan)

        // Create days
        let calendar = Calendar.current
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: Date()) else { continue }

            let dayOfWeek = calendar.component(.weekday, from: date)
            let day = Day(date: date, dayOfWeek: dayOfWeek)
            context.insert(day)
            day.mealPlan = mealPlan

            // Add meals for each day
            addMealsToDay(
                day: day,
                breakfast: breakfastRecipes,
                lunch: lunchRecipes,
                dinner: dinnerRecipes,
                snacks: snackRecipes,
                dayOffset: dayOffset,
                context: context
            )
        }

        // Generate grocery list
        generateGroceryList(for: mealPlan, in: context)

        try? context.save()
    }

    private static func createSampleRecipes(in context: ModelContext) -> ([Recipe], [Recipe], [Recipe], [Recipe]) {
        var breakfastRecipes: [Recipe] = []
        var lunchRecipes: [Recipe] = []
        var dinnerRecipes: [Recipe] = []
        var snackRecipes: [Recipe] = []

        // Breakfast recipes
        let oatmeal = Recipe(
            name: "Berry Overnight Oats",
            recipeDescription: "Creamy overnight oats topped with fresh berries and honey",
            instructions: [
                "Mix oats with milk and yogurt",
                "Add honey and vanilla extract",
                "Refrigerate overnight",
                "Top with fresh berries before serving"
            ],
            prepTimeMinutes: 10,
            cookTimeMinutes: 0,
            servings: 1,
            complexity: .easy,
            cuisineType: .american,
            calories: 380,
            proteinGrams: 12,
            carbsGrams: 58,
            fatGrams: 10,
            fiberGrams: 6,
            isFavorite: true
        )
        context.insert(oatmeal)
        addIngredients(to: oatmeal, ingredients: [
            ("Rolled Oats", 0.5, .cup, .pantry),
            ("Milk", 0.5, .cup, .dairy),
            ("Greek Yogurt", 0.25, .cup, .dairy),
            ("Honey", 1, .tablespoon, .pantry),
            ("Mixed Berries", 0.5, .cup, .produce),
            ("Vanilla Extract", 0.5, .teaspoon, .pantry)
        ], in: context)
        breakfastRecipes.append(oatmeal)

        let avocadoToast = Recipe(
            name: "Avocado Toast with Eggs",
            recipeDescription: "Crispy sourdough topped with creamy avocado and poached eggs",
            instructions: [
                "Toast sourdough bread until golden",
                "Mash avocado with lemon juice and salt",
                "Spread avocado on toast",
                "Top with perfectly poached eggs"
            ],
            prepTimeMinutes: 5,
            cookTimeMinutes: 10,
            servings: 1,
            complexity: .easy,
            cuisineType: .american,
            calories: 420,
            proteinGrams: 18,
            carbsGrams: 32,
            fatGrams: 26,
            fiberGrams: 8
        )
        context.insert(avocadoToast)
        addIngredients(to: avocadoToast, ingredients: [
            ("Sourdough Bread", 2, .slice, .bakery),
            ("Avocado", 1, .piece, .produce),
            ("Eggs", 2, .piece, .dairy),
            ("Lemon Juice", 1, .teaspoon, .pantry),
            ("Salt", 0.25, .teaspoon, .pantry),
            ("Red Pepper Flakes", 0.25, .teaspoon, .pantry)
        ], in: context)
        breakfastRecipes.append(avocadoToast)

        let smoothieBowl = Recipe(
            name: "Tropical Smoothie Bowl",
            recipeDescription: "Thick and refreshing smoothie bowl with tropical fruits",
            instructions: [
                "Blend frozen mango, banana, and coconut milk",
                "Pour into a bowl",
                "Top with granola, coconut flakes, and fresh fruit",
                "Drizzle with honey"
            ],
            prepTimeMinutes: 10,
            cookTimeMinutes: 0,
            servings: 1,
            complexity: .easy,
            cuisineType: .american,
            calories: 340,
            proteinGrams: 8,
            carbsGrams: 62,
            fatGrams: 8,
            fiberGrams: 5
        )
        context.insert(smoothieBowl)
        addIngredients(to: smoothieBowl, ingredients: [
            ("Frozen Mango", 1, .cup, .frozen),
            ("Banana", 1, .piece, .produce),
            ("Coconut Milk", 0.5, .cup, .dairy),
            ("Granola", 0.25, .cup, .pantry),
            ("Coconut Flakes", 2, .tablespoon, .pantry),
            ("Honey", 1, .tablespoon, .pantry)
        ], in: context)
        breakfastRecipes.append(smoothieBowl)

        // Lunch recipes
        let chickenSalad = Recipe(
            name: "Mediterranean Chicken Salad",
            recipeDescription: "Fresh salad with grilled chicken, feta, and olives",
            instructions: [
                "Grill seasoned chicken breast",
                "Chop romaine, cucumber, and tomatoes",
                "Add crumbled feta and kalamata olives",
                "Drizzle with olive oil and lemon dressing"
            ],
            prepTimeMinutes: 15,
            cookTimeMinutes: 15,
            servings: 2,
            complexity: .medium,
            cuisineType: .mediterranean,
            calories: 480,
            proteinGrams: 42,
            carbsGrams: 18,
            fatGrams: 28,
            fiberGrams: 4,
            isFavorite: true
        )
        context.insert(chickenSalad)
        addIngredients(to: chickenSalad, ingredients: [
            ("Chicken Breast", 2, .piece, .meat),
            ("Romaine Lettuce", 4, .cup, .produce),
            ("Cucumber", 1, .piece, .produce),
            ("Cherry Tomatoes", 1, .cup, .produce),
            ("Feta Cheese", 0.5, .cup, .dairy),
            ("Kalamata Olives", 0.25, .cup, .pantry),
            ("Olive Oil", 2, .tablespoon, .pantry),
            ("Lemon Juice", 1, .tablespoon, .pantry)
        ], in: context)
        lunchRecipes.append(chickenSalad)

        let quinoaBowl = Recipe(
            name: "Rainbow Quinoa Power Bowl",
            recipeDescription: "Colorful quinoa bowl with roasted chickpeas and tahini",
            instructions: [
                "Cook quinoa according to package directions",
                "Roast chickpeas with cumin and paprika",
                "Arrange colorful vegetables in bowl",
                "Drizzle with creamy tahini dressing"
            ],
            prepTimeMinutes: 10,
            cookTimeMinutes: 25,
            servings: 2,
            complexity: .easy,
            cuisineType: .mediterranean,
            calories: 520,
            proteinGrams: 18,
            carbsGrams: 68,
            fatGrams: 20,
            fiberGrams: 12
        )
        context.insert(quinoaBowl)
        addIngredients(to: quinoaBowl, ingredients: [
            ("Quinoa", 1, .cup, .pantry),
            ("Chickpeas", 1, .cup, .pantry),
            ("Bell Pepper", 1, .piece, .produce),
            ("Carrot", 1, .piece, .produce),
            ("Red Cabbage", 1, .cup, .produce),
            ("Tahini", 2, .tablespoon, .condiments),
            ("Cumin", 1, .teaspoon, .pantry),
            ("Paprika", 0.5, .teaspoon, .pantry)
        ], in: context)
        lunchRecipes.append(quinoaBowl)

        let turkeyWrap = Recipe(
            name: "Turkey Avocado Wrap",
            recipeDescription: "Healthy wrap loaded with turkey and fresh vegetables",
            instructions: [
                "Spread hummus on whole wheat tortilla",
                "Layer sliced turkey and avocado",
                "Add spinach, tomatoes, and cheese",
                "Roll tightly and slice in half"
            ],
            prepTimeMinutes: 10,
            cookTimeMinutes: 0,
            servings: 1,
            complexity: .easy,
            cuisineType: .american,
            calories: 440,
            proteinGrams: 32,
            carbsGrams: 38,
            fatGrams: 18,
            fiberGrams: 8
        )
        context.insert(turkeyWrap)
        addIngredients(to: turkeyWrap, ingredients: [
            ("Whole Wheat Tortilla", 1, .piece, .bakery),
            ("Sliced Turkey", 4, .ounce, .meat),
            ("Avocado", 0.5, .piece, .produce),
            ("Hummus", 2, .tablespoon, .condiments),
            ("Spinach", 1, .cup, .produce),
            ("Tomato", 0.5, .piece, .produce),
            ("Swiss Cheese", 1, .slice, .dairy)
        ], in: context)
        lunchRecipes.append(turkeyWrap)

        // Dinner recipes
        let salmonDinner = Recipe(
            name: "Honey Glazed Salmon",
            recipeDescription: "Perfectly baked salmon with a sweet honey glaze",
            instructions: [
                "Mix honey, soy sauce, and minced garlic",
                "Marinate salmon for 15 minutes",
                "Bake at 400°F for 15-18 minutes",
                "Serve with roasted vegetables"
            ],
            prepTimeMinutes: 10,
            cookTimeMinutes: 20,
            servings: 2,
            complexity: .medium,
            cuisineType: .japanese,
            calories: 520,
            proteinGrams: 38,
            carbsGrams: 24,
            fatGrams: 30,
            fiberGrams: 2,
            isFavorite: true
        )
        context.insert(salmonDinner)
        addIngredients(to: salmonDinner, ingredients: [
            ("Salmon Fillet", 1, .pound, .meat),
            ("Honey", 3, .tablespoon, .pantry),
            ("Soy Sauce", 2, .tablespoon, .condiments),
            ("Garlic", 3, .clove, .produce),
            ("Olive Oil", 1, .tablespoon, .pantry),
            ("Asparagus", 1, .bunch, .produce),
            ("Lemon", 1, .piece, .produce)
        ], in: context)
        dinnerRecipes.append(salmonDinner)

        let chickenStirFry = Recipe(
            name: "Teriyaki Chicken Stir Fry",
            recipeDescription: "Quick and flavorful chicken stir fry with vegetables",
            instructions: [
                "Slice chicken and vegetables",
                "Stir fry chicken until golden brown",
                "Add vegetables and teriyaki sauce",
                "Serve hot over steamed rice"
            ],
            prepTimeMinutes: 15,
            cookTimeMinutes: 15,
            servings: 3,
            complexity: .medium,
            cuisineType: .japanese,
            calories: 480,
            proteinGrams: 35,
            carbsGrams: 45,
            fatGrams: 16,
            fiberGrams: 4
        )
        context.insert(chickenStirFry)
        addIngredients(to: chickenStirFry, ingredients: [
            ("Chicken Breast", 1, .pound, .meat),
            ("Broccoli", 2, .cup, .produce),
            ("Bell Pepper", 1, .piece, .produce),
            ("Snap Peas", 1, .cup, .produce),
            ("Teriyaki Sauce", 0.25, .cup, .condiments),
            ("Sesame Oil", 1, .tablespoon, .pantry),
            ("Garlic", 2, .clove, .produce),
            ("Ginger", 1, .teaspoon, .produce),
            ("Rice", 1.5, .cup, .pantry)
        ], in: context)
        dinnerRecipes.append(chickenStirFry)

        let tacos = Recipe(
            name: "Spicy Fish Tacos",
            recipeDescription: "Crispy fish tacos with tangy slaw and lime crema",
            instructions: [
                "Season fish with cumin and chili powder",
                "Grill until flaky and cooked through",
                "Prepare crunchy cabbage slaw",
                "Assemble in warm corn tortillas with lime crema"
            ],
            prepTimeMinutes: 15,
            cookTimeMinutes: 10,
            servings: 2,
            complexity: .medium,
            cuisineType: .mexican,
            calories: 420,
            proteinGrams: 28,
            carbsGrams: 36,
            fatGrams: 18,
            fiberGrams: 5
        )
        context.insert(tacos)
        addIngredients(to: tacos, ingredients: [
            ("White Fish Fillet", 1, .pound, .meat),
            ("Corn Tortillas", 8, .piece, .bakery),
            ("Cabbage", 2, .cup, .produce),
            ("Lime", 2, .piece, .produce),
            ("Sour Cream", 0.25, .cup, .dairy),
            ("Cumin", 1, .teaspoon, .pantry),
            ("Chili Powder", 1, .teaspoon, .pantry),
            ("Cilantro", 0.25, .cup, .produce)
        ], in: context)
        dinnerRecipes.append(tacos)

        let pasta = Recipe(
            name: "Creamy Tuscan Pasta",
            recipeDescription: "Rich and creamy pasta with sun-dried tomatoes and spinach",
            instructions: [
                "Cook pasta al dente according to package",
                "Sauté garlic and sun-dried tomatoes",
                "Add cream and fresh spinach",
                "Toss with pasta and top with parmesan"
            ],
            prepTimeMinutes: 10,
            cookTimeMinutes: 20,
            servings: 4,
            complexity: .easy,
            cuisineType: .italian,
            calories: 580,
            proteinGrams: 18,
            carbsGrams: 62,
            fatGrams: 28,
            fiberGrams: 4,
            isFavorite: true,
            imageURL: "CreamyTuscanPasta"
        )
        context.insert(pasta)
        addIngredients(to: pasta, ingredients: [
            ("Penne Pasta", 1, .pound, .pantry),
            ("Heavy Cream", 1, .cup, .dairy),
            ("Sun-Dried Tomatoes", 0.5, .cup, .pantry),
            ("Fresh Spinach", 3, .cup, .produce),
            ("Garlic", 4, .clove, .produce),
            ("Parmesan Cheese", 0.5, .cup, .dairy),
            ("Olive Oil", 2, .tablespoon, .pantry),
            ("Italian Seasoning", 1, .teaspoon, .pantry)
        ], in: context)
        dinnerRecipes.append(pasta)

        // Snacks
        let proteinBalls = Recipe(
            name: "Peanut Butter Protein Balls",
            recipeDescription: "No-bake energy bites perfect for a quick snack",
            instructions: [
                "Mix oats, protein powder, and peanut butter",
                "Add honey and chocolate chips",
                "Roll mixture into small balls",
                "Refrigerate for 30 minutes"
            ],
            prepTimeMinutes: 15,
            cookTimeMinutes: 0,
            servings: 12,
            complexity: .easy,
            cuisineType: .american,
            calories: 120,
            proteinGrams: 6,
            carbsGrams: 14,
            fatGrams: 5,
            fiberGrams: 2
        )
        context.insert(proteinBalls)
        addIngredients(to: proteinBalls, ingredients: [
            ("Rolled Oats", 1, .cup, .pantry),
            ("Peanut Butter", 0.5, .cup, .pantry),
            ("Honey", 0.25, .cup, .pantry),
            ("Protein Powder", 0.25, .cup, .pantry),
            ("Chocolate Chips", 0.25, .cup, .pantry)
        ], in: context)
        snackRecipes.append(proteinBalls)

        let greekYogurt = Recipe(
            name: "Greek Yogurt Parfait",
            recipeDescription: "Layered yogurt with crunchy granola and fresh berries",
            instructions: [
                "Layer Greek yogurt in a glass",
                "Add a layer of crunchy granola",
                "Top with mixed berries",
                "Drizzle with honey and add nuts"
            ],
            prepTimeMinutes: 5,
            cookTimeMinutes: 0,
            servings: 1,
            complexity: .easy,
            cuisineType: .mediterranean,
            calories: 280,
            proteinGrams: 18,
            carbsGrams: 32,
            fatGrams: 10,
            fiberGrams: 3
        )
        context.insert(greekYogurt)
        addIngredients(to: greekYogurt, ingredients: [
            ("Greek Yogurt", 1, .cup, .dairy),
            ("Granola", 0.25, .cup, .pantry),
            ("Mixed Berries", 0.5, .cup, .produce),
            ("Honey", 1, .tablespoon, .pantry),
            ("Almonds", 2, .tablespoon, .pantry)
        ], in: context)
        snackRecipes.append(greekYogurt)

        return (breakfastRecipes, lunchRecipes, dinnerRecipes, snackRecipes)
    }

    // Helper function to add ingredients to a recipe
    private static func addIngredients(
        to recipe: Recipe,
        ingredients: [(String, Double, MeasurementUnit, GroceryCategory)],
        in context: ModelContext
    ) {
        for (name, quantity, unit, category) in ingredients {
            let ingredient = Ingredient(name: name, category: category, defaultUnit: unit)
            context.insert(ingredient)

            let recipeIngredient = RecipeIngredient(quantity: quantity, unit: unit)
            recipeIngredient.ingredient = ingredient
            recipeIngredient.recipe = recipe
            context.insert(recipeIngredient)
        }
    }

    private static func addMealsToDay(
        day: Day,
        breakfast: [Recipe],
        lunch: [Recipe],
        dinner: [Recipe],
        snacks: [Recipe],
        dayOffset: Int,
        context: ModelContext
    ) {
        // Rotate through recipes based on day
        if let breakfastRecipe = breakfast[safe: dayOffset % breakfast.count] {
            let meal = Meal(mealType: .breakfast, isEaten: false)
            context.insert(meal)
            meal.recipe = breakfastRecipe
            meal.day = day
        }

        if let lunchRecipe = lunch[safe: dayOffset % lunch.count] {
            let meal = Meal(mealType: .lunch, isEaten: false)
            context.insert(meal)
            meal.recipe = lunchRecipe
            meal.day = day
        }

        if let dinnerRecipe = dinner[safe: dayOffset % dinner.count] {
            let meal = Meal(mealType: .dinner, isEaten: false)
            context.insert(meal)
            meal.recipe = dinnerRecipe
            meal.day = day
        }

        // Add snack every other day
        if dayOffset % 2 == 0, let snackRecipe = snacks[safe: (dayOffset / 2) % snacks.count] {
            let meal = Meal(mealType: .snack, isEaten: false)
            context.insert(meal)
            meal.recipe = snackRecipe
            meal.day = day
        }
    }

    private static func generateGroceryList(for mealPlan: MealPlan, in context: ModelContext) {
        let groceryList = GroceryList()
        context.insert(groceryList)
        mealPlan.groceryList = groceryList

        // Sample grocery items
        let groceryItems: [(String, GroceryCategory, Double, MeasurementUnit)] = [
            ("Chicken Breast", .meat, 2, .pound),
            ("Salmon Fillet", .meat, 1.5, .pound),
            ("Ground Turkey", .meat, 1, .pound),
            ("Greek Yogurt", .dairy, 2, .cup),
            ("Eggs", .dairy, 12, .piece),
            ("Feta Cheese", .dairy, 4, .ounce),
            ("Avocados", .produce, 4, .piece),
            ("Mixed Berries", .produce, 2, .cup),
            ("Spinach", .produce, 6, .ounce),
            ("Tomatoes", .produce, 4, .piece),
            ("Cucumber", .produce, 2, .piece),
            ("Quinoa", .pantry, 1, .cup),
            ("Oats", .pantry, 2, .cup),
            ("Honey", .pantry, 4, .tablespoon),
            ("Olive Oil", .pantry, 0.5, .cup),
            ("Soy Sauce", .condiments, 4, .tablespoon),
            ("Whole Wheat Tortillas", .bakery, 8, .piece),
            ("Sourdough Bread", .bakery, 6, .slice),
            ("Peanut Butter", .pantry, 0.5, .cup),
            ("Granola", .pantry, 1, .cup)
        ]

        for (name, category, quantity, unit) in groceryItems {
            let ingredient = Ingredient(name: name, category: category, defaultUnit: unit)
            context.insert(ingredient)

            let item = GroceryItem(
                quantity: quantity,
                unit: unit,
                isChecked: false,
                isLocked: false,
                isManuallyAdded: false
            )
            item.ingredient = ingredient
            item.groceryList = groceryList
            context.insert(item)
        }
    }

    static func clearAllData(in context: ModelContext) {
        // Delete all meal plans (cascades to days, meals)
        let mealPlanDescriptor = FetchDescriptor<MealPlan>()
        if let mealPlans = try? context.fetch(mealPlanDescriptor) {
            for plan in mealPlans {
                context.delete(plan)
            }
        }

        // Delete all recipes
        let recipeDescriptor = FetchDescriptor<Recipe>()
        if let recipes = try? context.fetch(recipeDescriptor) {
            for recipe in recipes {
                context.delete(recipe)
            }
        }

        // Delete all grocery lists
        let groceryDescriptor = FetchDescriptor<GroceryList>()
        if let lists = try? context.fetch(groceryDescriptor) {
            for list in lists {
                context.delete(list)
            }
        }

        // Delete all ingredients
        let ingredientDescriptor = FetchDescriptor<Ingredient>()
        if let ingredients = try? context.fetch(ingredientDescriptor) {
            for ingredient in ingredients {
                context.delete(ingredient)
            }
        }

        try? context.save()
    }
}

// Safe array access
extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
