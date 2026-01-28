import Foundation

// MARK: - Data Transfer Objects for parsing Claude's JSON response
// These are separate from SwiftData models to cleanly handle JSON parsing

struct MealPlanResponse: Codable {
    let days: [DayDTO]

    init(days: [DayDTO]) {
        self.days = days
    }
}

struct DayDTO: Codable {
    let dayOfWeek: Int
    let meals: [MealDTO]

    init(dayOfWeek: Int, meals: [MealDTO]) {
        self.dayOfWeek = dayOfWeek
        self.meals = meals
    }
}

struct MealDTO: Codable {
    let mealType: String
    let recipe: RecipeDTO

    init(mealType: String, recipe: RecipeDTO) {
        self.mealType = mealType
        self.recipe = recipe
    }
}

struct RecipeDTO: Codable {
    let name: String
    let description: String
    let instructions: [String]
    let prepTimeMinutes: Int
    let cookTimeMinutes: Int
    let servings: Int
    let complexity: String
    let cuisineType: String?
    let calories: Int
    let proteinGrams: Int
    let carbsGrams: Int
    let fatGrams: Int
    let fiberGrams: Int
    let ingredients: [IngredientDTO]
    /// Image URL matched from Spoonacular database by ingredient similarity
    let matchedImageUrl: String?

    enum CodingKeys: String, CodingKey {
        case name, description, instructions, prepTimeMinutes, cookTimeMinutes
        case servings, complexity, cuisineType, calories, proteinGrams
        case carbsGrams, fatGrams, fiberGrams, ingredients, matchedImageUrl
    }

    /// Direct initializer for creating from API response
    init(
        name: String,
        description: String,
        instructions: [String],
        prepTimeMinutes: Int,
        cookTimeMinutes: Int,
        servings: Int,
        complexity: String,
        cuisineType: String?,
        calories: Int,
        proteinGrams: Int,
        carbsGrams: Int,
        fatGrams: Int,
        fiberGrams: Int,
        ingredients: [IngredientDTO],
        matchedImageUrl: String? = nil
    ) {
        self.name = name
        self.description = description
        self.instructions = instructions
        self.prepTimeMinutes = prepTimeMinutes
        self.cookTimeMinutes = cookTimeMinutes
        self.servings = servings
        self.complexity = complexity
        self.cuisineType = cuisineType
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.carbsGrams = carbsGrams
        self.fatGrams = fatGrams
        self.fiberGrams = fiberGrams
        self.ingredients = ingredients
        self.matchedImageUrl = matchedImageUrl
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        instructions = try container.decode([String].self, forKey: .instructions)
        prepTimeMinutes = try container.decode(Int.self, forKey: .prepTimeMinutes)
        cookTimeMinutes = try container.decode(Int.self, forKey: .cookTimeMinutes)
        servings = try container.decode(Int.self, forKey: .servings)
        complexity = try container.decode(String.self, forKey: .complexity)
        cuisineType = try container.decodeIfPresent(String.self, forKey: .cuisineType)
        calories = try container.decode(Int.self, forKey: .calories)
        proteinGrams = try container.decode(Int.self, forKey: .proteinGrams)
        carbsGrams = try container.decode(Int.self, forKey: .carbsGrams)
        fatGrams = try container.decode(Int.self, forKey: .fatGrams)
        fiberGrams = try container.decode(Int.self, forKey: .fiberGrams)
        ingredients = try container.decode([IngredientDTO].self, forKey: .ingredients)
        matchedImageUrl = try container.decodeIfPresent(String.self, forKey: .matchedImageUrl)
    }
}

struct IngredientDTO: Codable {
    let name: String
    let quantity: Double
    let unit: String
    let category: String
    let notes: String?

    /// Direct initializer for creating from API response
    init(name: String, quantity: Double, unit: String, category: String, notes: String? = nil) {
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.category = category
        self.notes = notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        unit = try container.decode(String.self, forKey: .unit)
        category = try container.decode(String.self, forKey: .category)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)

        // Handle quantity as either Int or Double
        if let intValue = try? container.decode(Int.self, forKey: .quantity) {
            quantity = Double(intValue)
        } else {
            quantity = try container.decode(Double.self, forKey: .quantity)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case name, quantity, unit, category, notes
    }
}

// MARK: - Mapping DTOs to SwiftData Models
extension MealPlanResponse {
    /// Creates SwiftData models from the parsed response
    func toSwiftDataModels(startDate: Date, planDuration: Int = 7) -> (mealPlan: MealPlan, days: [Day], meals: [Meal], recipes: [Recipe], ingredients: [Ingredient], recipeIngredients: [RecipeIngredient]) {
        let mealPlan = MealPlan(weekStartDate: startDate, isActive: true, planDuration: planDuration)

        var allDays: [Day] = []
        var allMeals: [Meal] = []
        var allRecipes: [Recipe] = []
        var allIngredients: [Ingredient] = []
        var allRecipeIngredients: [RecipeIngredient] = []

        let calendar = Calendar.current

        for dayDTO in days {
            // Calculate the actual date for this day
            let dayDate = calendar.date(byAdding: .day, value: dayDTO.dayOfWeek, to: startDate) ?? startDate

            let day = Day(date: dayDate, dayOfWeek: dayDTO.dayOfWeek)
            day.mealPlan = mealPlan

            for mealDTO in dayDTO.meals {
                let mealType = MealType(rawValue: mealDTO.mealType.capitalized) ?? .breakfast

                // Create Recipe
                let recipe = mealDTO.recipe.toRecipe()
                allRecipes.append(recipe)

                // Create Ingredients and RecipeIngredients
                for ingredientDTO in mealDTO.recipe.ingredients {
                    let ingredient = ingredientDTO.toIngredient()
                    allIngredients.append(ingredient)

                    let recipeIngredient = ingredientDTO.toRecipeIngredient()
                    recipeIngredient.recipe = recipe
                    recipeIngredient.ingredient = ingredient
                    allRecipeIngredients.append(recipeIngredient)
                }

                // Create Meal
                let meal = Meal(mealType: mealType)
                meal.day = day
                meal.recipe = recipe
                allMeals.append(meal)
            }

            allDays.append(day)
        }

        return (mealPlan, allDays, allMeals, allRecipes, allIngredients, allRecipeIngredients)
    }
}

extension RecipeDTO {
    func toRecipe() -> Recipe {
        // Map string complexity to enum
        let complexityEnum: RecipeComplexity
        switch complexity.lowercased() {
        case "easy": complexityEnum = .easy
        case "hard": complexityEnum = .hard
        default: complexityEnum = .medium
        }

        // Map string cuisineType to enum
        let cuisineEnum = cuisineType.flatMap { cuisine -> CuisineType? in
            CuisineType.allCases.first { $0.rawValue.lowercased() == cuisine.lowercased() }
        }

        let recipe = Recipe(
            name: name,
            recipeDescription: description,
            instructions: instructions,
            prepTimeMinutes: prepTimeMinutes,
            cookTimeMinutes: cookTimeMinutes,
            servings: servings,
            complexity: complexityEnum,
            cuisineType: cuisineEnum,
            calories: calories,
            proteinGrams: proteinGrams,
            carbsGrams: carbsGrams,
            fatGrams: fatGrams,
            fiberGrams: fiberGrams,
            imageURL: matchedImageUrl
        )
        return recipe
    }
}

extension IngredientDTO {
    func toIngredient() -> Ingredient {
        // Map category string from API to GroceryCategory enum
        let groceryCategory: GroceryCategory
        switch category.lowercased() {
        case "produce": groceryCategory = .produce
        case "meat", "seafood", "meat & seafood": groceryCategory = .meat
        case "dairy", "eggs", "dairy & eggs": groceryCategory = .dairy
        case "bakery": groceryCategory = .bakery
        case "frozen": groceryCategory = .frozen
        case "pantry": groceryCategory = .pantry
        case "canned", "canned goods": groceryCategory = .canned
        case "condiments", "sauces", "condiments & sauces": groceryCategory = .condiments
        case "snacks": groceryCategory = .snacks
        case "beverages": groceryCategory = .beverages
        case "spices", "seasonings", "spices & seasonings": groceryCategory = .spices
        default: groceryCategory = .other
        }

        // Map unit string to MeasurementUnit enum
        let measurementUnit = mapUnit(unit)

        return Ingredient(
            name: name,
            category: groceryCategory,
            defaultUnit: measurementUnit
        )
    }

    func toRecipeIngredient() -> RecipeIngredient {
        return RecipeIngredient(
            quantity: quantity,
            unit: mapUnit(unit),
            notes: notes,
            isOptional: false
        )
    }

    private func mapUnit(_ unitString: String) -> MeasurementUnit {
        switch unitString.lowercased() {
        case "g", "gram", "grams": return .gram
        case "kg", "kilogram", "kilograms": return .kilogram
        case "ml", "milliliter", "milliliters": return .milliliter
        case "l", "liter", "liters": return .liter
        case "cup", "cups": return .cup
        case "tbsp", "tablespoon", "tablespoons": return .tablespoon
        case "tsp", "teaspoon", "teaspoons": return .teaspoon
        case "piece", "pieces", "pc", "pcs": return .piece
        case "slice", "slices": return .slice
        case "bunch", "bunches": return .bunch
        case "can", "cans": return .can
        case "package", "packages", "pkg": return .package
        case "lb", "pound", "pounds": return .pound
        case "oz", "ounce", "ounces": return .ounce
        case "clove", "cloves": return .piece
        default: return .piece
        }
    }
}
