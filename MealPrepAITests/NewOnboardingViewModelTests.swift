import Testing
import Foundation
@testable import MealPrepAI

struct NewOnboardingViewModelTests {

    // MARK: - TDEE Calculation (Mifflin-St Jeor)

    @MainActor
    @Test func tdeeMaleModerateActivity() {
        let vm = NewOnboardingViewModel()
        vm.gender = .male
        vm.age = 30
        vm.weightKg = 80
        vm.heightCm = 180
        vm.activityLevel = .moderate
        vm.weightGoal = .maintain

        // BMR = 10*80 + 6.25*180 - 5*30 + 5 = 800 + 1125 - 150 + 5 = 1780
        // TDEE = 1780 * 1.55 = 2759
        #expect(vm.recommendedCalories == 2759)
    }

    @MainActor
    @Test func tdeeFemaleModerateActivity() {
        let vm = NewOnboardingViewModel()
        vm.gender = .female
        vm.age = 25
        vm.weightKg = 60
        vm.heightCm = 165
        vm.activityLevel = .moderate
        vm.weightGoal = .maintain

        // BMR = 10*60 + 6.25*165 - 5*25 - 161 = 600 + 1031.25 - 125 - 161 = 1345.25
        // TDEE = 1345.25 * 1.55 = 2085.1375
        #expect(vm.recommendedCalories == 2085)
    }

    @MainActor
    @Test func tdeeOtherGenderUsesAverage() {
        let vm = NewOnboardingViewModel()
        vm.gender = .other
        vm.age = 30
        vm.weightKg = 70
        vm.heightCm = 170
        vm.activityLevel = .moderate
        vm.weightGoal = .maintain

        // BMR = 10*70 + 6.25*170 - 5*30 - 78 = 700 + 1062.5 - 150 - 78 = 1534.5
        // TDEE = 1534.5 * 1.55 = 2378.475
        #expect(vm.recommendedCalories == 2378)
    }

    // MARK: - Goal Adjustments

    @MainActor
    @Test func loseWeightAppliesDeficit() {
        let vm = NewOnboardingViewModel()
        vm.gender = .male
        vm.age = 30
        vm.weightKg = 90
        vm.targetWeightKg = 80
        vm.heightCm = 180
        vm.activityLevel = .moderate
        vm.weightGoal = .lose
        vm.goalPace = .moderate

        // 10 kg to lose = 22 lbs => maxSafeDeficit = 500
        // moderate pace deficit = 500, capped at 500
        let maintainCalories = vm.recommendedCalories
        vm.weightGoal = .maintain
        let tdee = vm.recommendedCalories
        vm.weightGoal = .lose
        #expect(vm.recommendedCalories == tdee - 500)
    }

    @MainActor
    @Test func gainWeightAppliesSurplus() {
        let vm = NewOnboardingViewModel()
        vm.gender = .male
        vm.age = 30
        vm.weightKg = 70
        vm.targetWeightKg = 80
        vm.heightCm = 175
        vm.activityLevel = .moderate
        vm.weightGoal = .maintain
        let tdee = vm.recommendedCalories

        vm.weightGoal = .gain
        vm.goalPace = .moderate
        // moderate surplus = 500
        #expect(vm.recommendedCalories == tdee + 500)
    }

    @MainActor
    @Test func recompApplies250Deficit() {
        let vm = NewOnboardingViewModel()
        vm.gender = .male
        vm.age = 30
        vm.weightKg = 80
        vm.heightCm = 180
        vm.activityLevel = .moderate
        vm.weightGoal = .maintain
        let tdee = vm.recommendedCalories

        vm.weightGoal = .recomp
        #expect(vm.recommendedCalories == tdee - 250)
    }

    // MARK: - Safe Deficit Caps

    @MainActor
    @Test func smallWeightLossCapsDeficit() {
        let vm = NewOnboardingViewModel()
        vm.gender = .male
        vm.age = 30
        vm.weightKg = 72
        vm.targetWeightKg = 70 // only 2 kg = ~4.4 lbs (<10)
        vm.heightCm = 175
        vm.activityLevel = .moderate
        vm.weightGoal = .lose
        vm.goalPace = .aggressive // requests 750, but capped at 350

        vm.weightGoal = .maintain
        let tdee = vm.recommendedCalories
        vm.weightGoal = .lose
        #expect(vm.recommendedCalories == tdee - 350)
    }

    @MainActor
    @Test func mediumWeightLossCapsAt500() {
        let vm = NewOnboardingViewModel()
        vm.gender = .male
        vm.age = 30
        vm.weightKg = 80
        vm.targetWeightKg = 73 // 7 kg = ~15.4 lbs (10-25 range)
        vm.heightCm = 180
        vm.activityLevel = .moderate
        vm.weightGoal = .lose
        vm.goalPace = .aggressive // requests 750, capped at 500

        vm.weightGoal = .maintain
        let tdee = vm.recommendedCalories
        vm.weightGoal = .lose
        #expect(vm.recommendedCalories == tdee - 500)
    }

    @MainActor
    @Test func largeWeightLossAllowsAggressive() {
        let vm = NewOnboardingViewModel()
        vm.gender = .male
        vm.age = 30
        vm.weightKg = 100
        vm.targetWeightKg = 80 // 20 kg = ~44 lbs (>25)
        vm.heightCm = 180
        vm.activityLevel = .moderate
        vm.weightGoal = .lose
        vm.goalPace = .aggressive // requests 750, allowed

        vm.weightGoal = .maintain
        let tdee = vm.recommendedCalories
        vm.weightGoal = .lose
        #expect(vm.recommendedCalories == tdee - 750)
    }

    // MARK: - Macro Calculations

    @MainActor
    @Test func proteinGramsBasedOnWeight() {
        let vm = NewOnboardingViewModel()
        vm.weightKg = 80
        vm.weightGoal = .lose
        // proteinPerKg for lose = 1.8
        #expect(vm.proteinGrams == 144) // 80 * 1.8
    }

    @MainActor
    @Test func proteinGramsForMaintain() {
        let vm = NewOnboardingViewModel()
        vm.weightKg = 70
        vm.weightGoal = .maintain
        // proteinPerKg for maintain = 1.4
        #expect(vm.proteinGrams == 98) // 70 * 1.4
    }

    @MainActor
    @Test func proteinGramsForRecomp() {
        let vm = NewOnboardingViewModel()
        vm.weightKg = 75
        vm.weightGoal = .recomp
        // proteinPerKg for recomp = 2.0
        #expect(vm.proteinGrams == 150) // 75 * 2.0
    }

    @MainActor
    @Test func fatGramsPercentageBased() {
        let vm = NewOnboardingViewModel()
        vm.gender = .male
        vm.age = 30
        vm.weightKg = 80
        vm.heightCm = 180
        vm.activityLevel = .moderate
        vm.weightGoal = .maintain
        // fatPercentage for maintain = 0.30
        // fat = recommendedCalories * 0.30 / 9
        let expected = Int(Double(vm.recommendedCalories) * 0.30 / 9)
        #expect(vm.fatGrams == expected)
    }

    @MainActor
    @Test func carbsGramsFillsRemainder() {
        let vm = NewOnboardingViewModel()
        vm.gender = .male
        vm.age = 30
        vm.weightKg = 80
        vm.heightCm = 180
        vm.activityLevel = .moderate
        vm.weightGoal = .maintain

        let proteinCal = vm.proteinGrams * 4
        let fatCal = vm.fatGrams * 9
        let remaining = vm.recommendedCalories - proteinCal - fatCal
        #expect(vm.carbsGrams == max(0, remaining / 4))
    }

    // MARK: - weeksToGoal

    @MainActor
    @Test func weeksToGoalCalculation() {
        let vm = NewOnboardingViewModel()
        vm.weightKg = 80
        vm.targetWeightKg = 75
        vm.goalPace = .moderate
        // 5 kg / 0.45 kg/week = 11.11 => ceil = 12
        #expect(vm.weeksToGoal == 12)
    }

    @MainActor
    @Test func weightDifference() {
        let vm = NewOnboardingViewModel()
        vm.weightKg = 80
        vm.targetWeightKg = 75
        #expect(vm.weightDifferenceKg == 5)
        #expect(abs(vm.weightDifferenceLbs - 11.023) < 0.01)
    }
}
