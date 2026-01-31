import Testing
import Foundation
@testable import MealPrepAI

struct AppEnumsTests {

    // MARK: - Codable Round-Trip

    @Test func mealTypeCodableRoundTrip() throws {
        let original = MealType.lunch
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MealType.self, from: data)
        #expect(decoded == original)
    }

    @Test func dietaryRestrictionCodableRoundTrip() throws {
        let original = DietaryRestriction.glutenFree
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DietaryRestriction.self, from: data)
        #expect(decoded == original)
    }

    @Test func allergyCodableRoundTrip() throws {
        let original = Allergy.shellfish
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Allergy.self, from: data)
        #expect(decoded == original)
    }

    @Test func cookingSkillCodableRoundTrip() throws {
        let original = CookingSkill.advanced
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CookingSkill.self, from: data)
        #expect(decoded == original)
    }

    @Test func cuisineTypeCodableRoundTrip() throws {
        let original = CuisineType.japanese
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CuisineType.self, from: data)
        #expect(decoded == original)
    }

    @Test func weightGoalCodableRoundTrip() throws {
        let original = WeightGoal.recomp
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WeightGoal.self, from: data)
        #expect(decoded == original)
    }

    @Test func groceryCategoryCodableRoundTrip() throws {
        let original = GroceryCategory.spices
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(GroceryCategory.self, from: data)
        #expect(decoded == original)
    }

    @Test func measurementUnitCodableRoundTrip() throws {
        let original = MeasurementUnit.tablespoon
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MeasurementUnit.self, from: data)
        #expect(decoded == original)
    }

    @Test func recipeComplexityCodableRoundTrip() throws {
        let original = RecipeComplexity.hard
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RecipeComplexity.self, from: data)
        #expect(decoded == original)
    }

    @Test func activityLevelCodableRoundTrip() throws {
        let original = ActivityLevel.extreme
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ActivityLevel.self, from: data)
        #expect(decoded == original)
    }

    @Test func genderCodableRoundTrip() throws {
        let original = Gender.female
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Gender.self, from: data)
        #expect(decoded == original)
    }

    @Test func goalPaceCodableRoundTrip() throws {
        let original = GoalPace.aggressive
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(GoalPace.self, from: data)
        #expect(decoded == original)
    }

    @Test func barrierCodableRoundTrip() throws {
        let original = Barrier.tooBusy
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Barrier.self, from: data)
        #expect(decoded == original)
    }

    // MARK: - MeasurementUnit Conversions

    @Test func measurementUnitConvertCupToMetric() {
        let result = MeasurementUnit.cup.convert(1, to: .metric)
        #expect(result.unit == .milliliter)
        #expect(abs(result.quantity - 236.588) < 0.01)
    }

    @Test func measurementUnitConvertGramToImperial() {
        let result = MeasurementUnit.gram.convert(100, to: .imperial)
        #expect(result.unit == .ounce)
        #expect(abs(result.quantity - 3.527) < 0.01)
    }

    @Test func measurementUnitCountDoesNotConvert() {
        let result = MeasurementUnit.piece.convert(3, to: .metric)
        #expect(result.unit == .piece)
        #expect(result.quantity == 3)
    }

    // MARK: - GroceryCategory.fromAisle

    @Test func fromAisleProduceMapping() {
        #expect(GroceryCategory.fromAisle("Fresh Vegetables") == .produce)
        #expect(GroceryCategory.fromAisle("Fruits") == .produce)
    }

    @Test func fromAisleMeatMapping() {
        #expect(GroceryCategory.fromAisle("Meat Counter") == .meat)
        #expect(GroceryCategory.fromAisle("Seafood") == .meat)
    }

    // MARK: - ActivityLevel Multipliers

    @Test func activityLevelMultipliers() {
        #expect(ActivityLevel.sedentary.multiplier == 1.2)
        #expect(ActivityLevel.light.multiplier == 1.375)
        #expect(ActivityLevel.moderate.multiplier == 1.55)
        #expect(ActivityLevel.active.multiplier == 1.725)
        #expect(ActivityLevel.extreme.multiplier == 1.9)
    }

    // MARK: - GoalPace calorie adjustments

    @Test func goalPaceDailyCalorieAdjustment() {
        // gradual: 0.5 lbs/week * 3500 / 7 = 250
        #expect(GoalPace.gradual.dailyCalorieAdjustment == 250)
        // moderate: 1.0 lbs/week * 3500 / 7 = 500
        #expect(GoalPace.moderate.dailyCalorieAdjustment == 500)
        // aggressive: 1.5 lbs/week * 3500 / 7 = 750
        #expect(GoalPace.aggressive.dailyCalorieAdjustment == 750)
    }

    // MARK: - CookingTime maxMinutes

    @Test func cookingTimeMaxMinutes() {
        #expect(CookingTime.quick.maxMinutes == 15)
        #expect(CookingTime.moderate.maxMinutes == 30)
        #expect(CookingTime.standard.maxMinutes == 60)
        #expect(CookingTime.leisurely.maxMinutes == 120)
    }

    // MARK: - MeasurementUnit.fromString

    @Test func measurementUnitFromString() {
        #expect(MeasurementUnit.fromString("cup") == .cup)
        #expect(MeasurementUnit.fromString("tablespoon") == .tablespoon)
        #expect(MeasurementUnit.fromString("grams") == .gram)
        #expect(MeasurementUnit.fromString("unknown-unit") == .piece)
    }

    // MARK: - MeasurementUnit categories

    @Test func measurementUnitCategories() {
        #expect(MeasurementUnit.cup.isVolume)
        #expect(!MeasurementUnit.cup.isWeight)
        #expect(MeasurementUnit.gram.isWeight)
        #expect(!MeasurementUnit.gram.isVolume)
        #expect(MeasurementUnit.piece.isCount)
        #expect(MeasurementUnit.gram.isMetric)
        #expect(MeasurementUnit.ounce.isImperial)
    }
}
