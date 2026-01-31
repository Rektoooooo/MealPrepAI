import Foundation
import SwiftData
@testable import MealPrepAI

/// Shared test helpers for creating in-memory SwiftData containers
enum TestHelpers {
    /// Creates an in-memory ModelContainer with all 9 SwiftData models
    @MainActor
    static func makeModelContainer() throws -> ModelContainer {
        let schema = Schema([
            UserProfile.self,
            MealPlan.self,
            Day.self,
            Meal.self,
            Recipe.self,
            RecipeIngredient.self,
            Ingredient.self,
            GroceryList.self,
            GroceryItem.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }
}
