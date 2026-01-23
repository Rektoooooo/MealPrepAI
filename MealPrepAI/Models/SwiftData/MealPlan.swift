import Foundation
import SwiftData

@Model
final class MealPlan {
    var id: UUID
    var weekStartDate: Date
    var createdAt: Date
    var isActive: Bool

    // Relationship to user
    var userProfile: UserProfile?

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \Day.mealPlan)
    var days: [Day]?

    @Relationship(deleteRule: .cascade, inverse: \GroceryList.mealPlan)
    var groceryList: GroceryList?

    var sortedDays: [Day] {
        (days ?? []).sorted { $0.date < $1.date }
    }

    init(
        weekStartDate: Date = Date(),
        isActive: Bool = true
    ) {
        self.id = UUID()
        self.weekStartDate = weekStartDate
        self.createdAt = Date()
        self.isActive = isActive
    }
}
