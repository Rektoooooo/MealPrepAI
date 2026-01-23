import Foundation
import SwiftData

@Model
final class GroceryList {
    var id: UUID
    var createdAt: Date
    var lastModified: Date

    // Relationship to meal plan
    var mealPlan: MealPlan?

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \GroceryItem.groceryList)
    var items: [GroceryItem]?

    var sortedItems: [GroceryItem] {
        (items ?? []).sorted { $0.ingredient?.category.rawValue ?? "" < $1.ingredient?.category.rawValue ?? "" }
    }

    var itemsByCategory: [GroceryCategory: [GroceryItem]] {
        Dictionary(grouping: items ?? []) { $0.ingredient?.category ?? .other }
    }

    var checkedCount: Int {
        (items ?? []).filter { $0.isChecked }.count
    }

    var totalCount: Int {
        items?.count ?? 0
    }

    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(checkedCount) / Double(totalCount)
    }

    init() {
        self.id = UUID()
        self.createdAt = Date()
        self.lastModified = Date()
    }
}
