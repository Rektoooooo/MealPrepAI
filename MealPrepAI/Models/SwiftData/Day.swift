import Foundation
import SwiftData

@Model
final class Day {
    var id: UUID = UUID()
    var date: Date = Date()
    var dayOfWeek: Int = 0

    // Relationship to meal plan
    var mealPlan: MealPlan?

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \Meal.day)
    var meals: [Meal]?

    var sortedMeals: [Meal] {
        (meals ?? []).sorted { meal1, meal2 in
            let order: [MealType] = [.breakfast, .lunch, .dinner, .snack]
            let index1 = order.firstIndex(of: meal1.mealType) ?? 0
            let index2 = order.firstIndex(of: meal2.mealType) ?? 0
            return index1 < index2
        }
    }

    var totalCalories: Int {
        (meals ?? []).reduce(0) { $0 + ($1.recipe?.calories ?? 0) }
    }

    var totalProtein: Int {
        (meals ?? []).reduce(0) { $0 + ($1.recipe?.proteinGrams ?? 0) }
    }

    var totalCarbs: Int {
        (meals ?? []).reduce(0) { $0 + ($1.recipe?.carbsGrams ?? 0) }
    }

    var totalFat: Int {
        (meals ?? []).reduce(0) { $0 + ($1.recipe?.fatGrams ?? 0) }
    }

    var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    var shortDayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    init(
        date: Date = Date(),
        dayOfWeek: Int = 0
    ) {
        self.id = UUID()
        self.date = date
        self.dayOfWeek = dayOfWeek
    }
}
