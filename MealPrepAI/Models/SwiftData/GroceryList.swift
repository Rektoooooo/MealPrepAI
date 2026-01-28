import Foundation
import SwiftData

@Model
final class GroceryList {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var lastModified: Date = Date()

    // Completion tracking
    var isCompleted: Bool = false
    var completedAt: Date?

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

    /// Returns a formatted date range string from the associated meal plan (e.g., "Jan 20 - Jan 26")
    var dateRangeDescription: String {
        guard let mealPlan = mealPlan else { return "No meal plan" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let startDate = mealPlan.weekStartDate
        let endDate = Calendar.current.date(byAdding: .day, value: 6, to: startDate) ?? startDate
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }

    init() {
        self.id = UUID()
        self.createdAt = Date()
        self.lastModified = Date()
    }
}
