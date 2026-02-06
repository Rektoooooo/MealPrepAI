import Foundation
import SwiftData

extension ModelContext {

    /// Deletes orphaned Recipe records that are no longer attached to any Meal
    /// and are not marked as favorites. Also cascades to their RecipeIngredients
    /// (handled by Recipe's cascade delete rule) and cleans up orphaned Ingredients.
    @MainActor
    func deleteOrphanedRecipes() {
        let descriptor = FetchDescriptor<Recipe>()
        guard let allRecipes = try? fetch(descriptor) else { return }

        for recipe in allRecipes {
            let hasMeals = !recipe.meals.isEmpty
            if !hasMeals && !recipe.isFavorite {
                // Recipe.ingredients has cascade delete rule, so RecipeIngredients
                // are automatically deleted when the Recipe is deleted.
                delete(recipe)
            }
        }

        // After removing orphan recipes, clean up any ingredients that are
        // no longer referenced by any RecipeIngredient or GroceryItem.
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
