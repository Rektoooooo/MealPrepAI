import SwiftData

// MARK: - Schema Versioning
// V1 captures the initial release schema. When models change in future updates,
// add a new VersionedSchema (V2, V3, etc.) and migration steps to the plan.

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            UserProfile.self,
            MealPlan.self,
            Day.self,
            Meal.self,
            Recipe.self,
            RecipeIngredient.self,
            Ingredient.self,
            GroceryList.self,
            GroceryItem.self
        ]
    }
}

enum MealPrepAIMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }

    // No migration stages needed for V1 (first release).
    // When V2 is added, define migration stages here:
    // static var stages: [MigrationStage] { [migrateV1toV2] }
    static var stages: [MigrationStage] { [] }
}
