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
    var meals: [Meal] = []

    var sortedMeals: [Meal] {
        meals.sorted { meal1, meal2 in
            let order: [MealType] = [.breakfast, .lunch, .dinner, .snack]
            let index1 = order.firstIndex(of: meal1.mealType) ?? 0
            let index2 = order.firstIndex(of: meal2.mealType) ?? 0
            return index1 < index2
        }
    }

    var nutritionTotals: (calories: Int, protein: Int, carbs: Int, fat: Int) {
        var cal = 0, pro = 0, carb = 0, fat = 0
        for m in meals {
            cal += m.recipe?.calories ?? 0
            pro += m.recipe?.proteinGrams ?? 0
            carb += m.recipe?.carbsGrams ?? 0
            fat += m.recipe?.fatGrams ?? 0
        }
        return (cal, pro, carb, fat)
    }

    var totalCalories: Int { nutritionTotals.calories }
    var totalProtein: Int { nutritionTotals.protein }
    var totalCarbs: Int { nutritionTotals.carbs }
    var totalFat: Int { nutritionTotals.fat }

    private static let dayNameFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f
    }()

    private static let shortDayNameFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()

    var dayName: String {
        Day.dayNameFormatter.string(from: date)
    }

    var shortDayName: String {
        Day.shortDayNameFormatter.string(from: date)
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
