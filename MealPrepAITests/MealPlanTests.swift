import Testing
import Foundation
@testable import MealPrepAI

struct MealPlanTests {

    @Test func sortedDaysOrdersByDate() {
        let plan = MealPlan(weekStartDate: Date())
        let day1 = Day(date: Date(), dayOfWeek: 0)
        let day2 = Day(date: Date().addingTimeInterval(86400), dayOfWeek: 1)
        let day3 = Day(date: Date().addingTimeInterval(172800), dayOfWeek: 2)
        plan.days = [day3, day1, day2]

        let sorted = plan.sortedDays
        #expect(sorted[0].dayOfWeek == 0)
        #expect(sorted[1].dayOfWeek == 1)
        #expect(sorted[2].dayOfWeek == 2)
    }

    @Test func endDateCalculation7Days() {
        let start = Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 1))!
        let plan = MealPlan(weekStartDate: start, planDuration: 7)
        let expected = Calendar.current.date(byAdding: .day, value: 6, to: start)!
        #expect(Calendar.current.isDate(plan.endDate, inSameDayAs: expected))
    }

    @Test func endDateCalculation14Days() {
        let start = Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 1))!
        let plan = MealPlan(weekStartDate: start, planDuration: 14)
        let expected = Calendar.current.date(byAdding: .day, value: 13, to: start)!
        #expect(Calendar.current.isDate(plan.endDate, inSameDayAs: expected))
    }

    @Test func sortedDaysEmptyWhenNil() {
        let plan = MealPlan()
        #expect(plan.sortedDays.isEmpty)
    }
}
