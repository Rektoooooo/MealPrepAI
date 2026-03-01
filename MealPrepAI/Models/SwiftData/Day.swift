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

    // MARK: - Performance caches (not persisted)

    @Transient private var _cachedSortedMeals: [Meal]?
    @Transient private var _lastMealsCount: Int = -1

    var sortedMeals: [Meal] {
        if let cached = _cachedSortedMeals, _lastMealsCount == meals.count {
            return cached
        }
        let sorted = meals.sorted { meal1, meal2 in
            let order: [MealType] = [.breakfast, .lunch, .dinner, .snack]
            let index1 = order.firstIndex(of: meal1.mealType) ?? 0
            let index2 = order.firstIndex(of: meal2.mealType) ?? 0
            return index1 < index2
        }
        _cachedSortedMeals = sorted
        _lastMealsCount = meals.count
        return sorted
    }

    @Transient private var _cachedNutrition: (calories: Int, protein: Int, carbs: Int, fat: Int)?
    @Transient private var _lastNutritionMealsHash: Int = -1

    private var nutritionMealsHash: Int {
        meals.count + meals.filter { $0.isEaten }.count * 1000
    }

    var nutritionTotals: (calories: Int, protein: Int, carbs: Int, fat: Int) {
        let currentHash = nutritionMealsHash
        if let cached = _cachedNutrition, _lastNutritionMealsHash == currentHash {
            return cached
        }
        var cal = 0, pro = 0, carb = 0, fat = 0
        for m in meals {
            cal += m.recipe?.calories ?? 0
            pro += m.recipe?.proteinGrams ?? 0
            carb += m.recipe?.carbsGrams ?? 0
            fat += m.recipe?.fatGrams ?? 0
        }
        let result = (cal, pro, carb, fat)
        _cachedNutrition = result
        _lastNutritionMealsHash = currentHash
        return result
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
