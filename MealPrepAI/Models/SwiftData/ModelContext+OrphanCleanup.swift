import Foundation
import SwiftData

extension ModelContext {

    /// Cleans up orphaned ingredients that are no longer referenced.
    /// NOTE: Recipes are NEVER automatically deleted — they form the user's
    /// recipe library and must persist even when not attached to a meal plan.
    @MainActor
    func deleteOrphanedRecipes() {
        // Only clean up orphaned ingredients — recipes are kept as a library.
        deleteOrphanedIngredients()
        try? save()
    }

    /// Deletes Ingredient records that have no remaining RecipeIngredient
    /// or GroceryItem references.
    @MainActor
    func deleteOrphanedIngredients() {
        let descriptor = FetchDescriptor<Ingredient>()
        guard let allIngredients = try? fetch(descriptor) else { return }

        for ingredient in allIngredients {
            let hasRecipeIngredients = !ingredient.recipeIngredients.isEmpty
            let hasGroceryItems = !ingredient.groceryItems.isEmpty
            if !hasRecipeIngredients && !hasGroceryItems {
                delete(ingredient)
            }
        }
    }
}
