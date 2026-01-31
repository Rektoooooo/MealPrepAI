import Testing
import Foundation
@testable import MealPrepAI

struct MealPrepSetupViewModelTests {

    // MARK: - Step Progression

    @MainActor
    @Test func initialStepIsWelcome() {
        let vm = MealPrepSetupViewModel()
        #expect(vm.currentStep == .welcome)
    }

    @MainActor
    @Test func skipWelcomeStartsAtWeeklyFocus() {
        let vm = MealPrepSetupViewModel(skipWelcome: true)
        #expect(vm.currentStep == .weeklyFocus)
    }

    @MainActor
    @Test func goToNextStepAdvances() {
        let vm = MealPrepSetupViewModel()
        vm.goToNextStep()
        #expect(vm.currentStep == .weeklyFocus)
    }

    @MainActor
    @Test func goToPreviousStepAtWelcomeStays() {
        let vm = MealPrepSetupViewModel()
        vm.goToPreviousStep()
        #expect(vm.currentStep == .welcome)
    }

    @MainActor
    @Test func goToPreviousStepGoesBack() {
        let vm = MealPrepSetupViewModel()
        vm.goToNextStep() // -> weeklyFocus
        vm.goToPreviousStep() // -> welcome
        #expect(vm.currentStep == .welcome)
    }

    // MARK: - canProceed

    @MainActor
    @Test func canProceedWelcomeAlwaysTrue() {
        let vm = MealPrepSetupViewModel()
        #expect(vm.canProceed)
    }

    @MainActor
    @Test func canProceedWeeklyFocusRequiresSelection() {
        let vm = MealPrepSetupViewModel()
        vm.goToNextStep() // -> weeklyFocus
        #expect(!vm.canProceed) // empty focus

        vm.toggleFocus(.highProtein)
        #expect(vm.canProceed)
    }

    @MainActor
    @Test func canProceedTemporaryExclusionsAlwaysTrue() {
        let vm = MealPrepSetupViewModel()
        // Navigate to temporaryExclusions
        vm.goToNextStep() // weeklyFocus
        vm.toggleFocus(.quickEasy)
        vm.goToNextStep() // temporaryExclusions
        #expect(vm.canProceed)
    }

    // MARK: - Progress

    @MainActor
    @Test func progressAtWelcomeIsZero() {
        let vm = MealPrepSetupViewModel()
        #expect(vm.progress == 0)
    }

    @MainActor
    @Test func progressAtWeeklyFocus() {
        let vm = MealPrepSetupViewModel()
        vm.goToNextStep()
        // 1 / 4 = 0.25
        #expect(vm.progress == 0.25)
    }

    // MARK: - skipToReview

    @MainActor
    @Test func skipToReviewSetsStep() {
        let vm = MealPrepSetupViewModel()
        vm.skipToReview()
        #expect(vm.currentStep == .review)
        #expect(vm.useQuickStart)
    }

    // MARK: - maxDuration

    @MainActor
    @Test func maxDurationSubscribed() {
        let vm = MealPrepSetupViewModel()
        #expect(vm.maxDuration(isSubscribed: true) == 14)
    }

    @MainActor
    @Test func maxDurationFree() {
        let vm = MealPrepSetupViewModel()
        #expect(vm.maxDuration(isSubscribed: false) == 7)
    }

    // MARK: - effectiveMacros

    @MainActor
    @Test func effectiveMacrosUseOverrideWhenSet() {
        let vm = MealPrepSetupViewModel()
        let profile = UserProfile(dailyCalorieTarget: 2000, proteinGrams: 150, carbsGrams: 200, fatGrams: 65)
        vm.overrideCalories = 1800
        vm.overrideProtein = 160

        #expect(vm.effectiveCalories(profile: profile) == 1800)
        #expect(vm.effectiveProtein(profile: profile) == 160)
        #expect(vm.effectiveCarbs(profile: profile) == 200) // no override
        #expect(vm.effectiveFat(profile: profile) == 65)    // no override
    }

    @MainActor
    @Test func effectiveMacrosFallBackToProfile() {
        let vm = MealPrepSetupViewModel()
        let profile = UserProfile(dailyCalorieTarget: 2000, proteinGrams: 150, carbsGrams: 200, fatGrams: 65)

        #expect(vm.effectiveCalories(profile: profile) == 2000)
        #expect(vm.effectiveProtein(profile: profile) == 150)
    }
}
