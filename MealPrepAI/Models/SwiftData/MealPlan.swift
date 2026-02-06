import Foundation
import SwiftData

@Model
final class MealPlan {
    var id: UUID = UUID()
    var weekStartDate: Date = Date()
    var createdAt: Date = Date()
    var isActive: Bool = true
    var planDuration: Int = 7

    /// End date computed from start date and duration
    var endDate: Date {
        Calendar.current.date(byAdding: .day, value: planDuration - 1, to: weekStartDate) ?? weekStartDate
    }

    // Relationship to user
    var userProfile: UserProfile?

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \Day.mealPlan)
    var days: [Day] = []

    @Relationship(deleteRule: .cascade, inverse: \GroceryList.mealPlan)
    var groceryList: GroceryList?

    var sortedDays: [Day] {
        days.sorted { $0.date < $1.date }
    }

    init(
        weekStartDate: Date = Date(),
        isActive: Bool = true,
        planDuration: Int = 7
    ) {
        self.id = UUID()
        self.weekStartDate = weekStartDate
        self.createdAt = Date()
        self.isActive = isActive
        self.planDuration = planDuration
    }
}
