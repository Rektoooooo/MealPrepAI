import Testing
import Foundation
@testable import MealPrepAI

struct APIServiceTypesEncodingTests {

    @Test func generatePlanRequestEncodesCorrectly() throws {
        let userProfile = GeneratePlanUserProfile(
            age: 30,
            gender: "Male",
            weightKg: 80,
            heightCm: 180,
            activityLevel: "Moderately Active",
            dailyCalorieTarget: 2500,
            proteinGrams: 150,
            carbsGrams: 250,
            fatGrams: 80,
            weightGoal: "Lose Weight",
            dietaryRestrictions: ["Vegetarian"],
            allergies: ["Peanuts"],
            foodDislikes: ["Mushrooms"],
            preferredCuisines: ["Italian"],
            dislikedCuisines: [],
            cookingSkill: "Intermediate",
            maxCookingTimeMinutes: 45,
            simpleModeEnabled: false,
            mealsPerDay: 3,
            includeSnacks: true,
            pantryLevel: "Average",
            barriers: [],
            primaryGoals: ["Eat healthy"],
            goalPace: "Moderate",
            measurementSystem: "Metric"
        )

        let request = GeneratePlanRequest(
            userProfile: userProfile,
            weeklyPreferences: nil,
            excludeRecipeNames: nil,
            deviceId: "test-device",
            duration: 7,
            weeklyFocus: nil,
            temporaryExclusions: nil,
            weeklyBusyness: nil
        )

        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(GeneratePlanRequest.self, from: data)
        #expect(decoded.userProfile.age == 30)
        #expect(decoded.deviceId == "test-device")
        #expect(decoded.duration == 7)
    }

    @Test func swapMealRequestEncodesCorrectly() throws {
        let userProfile = SwapMealUserProfile(
            dailyCalorieTarget: 2000,
            proteinGrams: 150,
            carbsGrams: 200,
            fatGrams: 65,
            dietaryRestrictions: [],
            allergies: [],
            foodDislikes: nil,
            preferredCuisines: ["Italian"],
            dislikedCuisines: nil,
            cookingSkill: "Intermediate",
            maxCookingTimeMinutes: 45,
            simpleModeEnabled: false,
            measurementSystem: "Metric"
        )

        let request = SwapMealRequest(
            userProfile: userProfile,
            mealType: "Lunch",
            excludeRecipeNames: ["Old Recipe"],
            weeklyPreferences: nil,
            deviceId: "test-device"
        )

        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(SwapMealRequest.self, from: data)
        #expect(decoded.mealType == "Lunch")
        #expect(decoded.excludeRecipeNames?.first == "Old Recipe")
    }

    @Test func mealPlanResponseCodableRoundTrip() throws {
        let response = MealPlanResponse(days: [
            DayDTO(dayOfWeek: 0, meals: [
                MealDTO(mealType: "Breakfast", recipe: RecipeDTO(
                    name: "Oatmeal",
                    description: "Simple oatmeal",
                    instructions: ["Cook oats in water until soft and creamy."],
                    prepTimeMinutes: 5,
                    cookTimeMinutes: 10,
                    servings: 1,
                    complexity: "easy",
                    cuisineType: nil,
                    calories: 300,
                    proteinGrams: 10,
                    carbsGrams: 50,
                    fatGrams: 8,
                    fiberGrams: 5,
                    ingredients: []
                ))
            ])
        ])

        let data = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(MealPlanResponse.self, from: data)
        #expect(decoded.days.count == 1)
        #expect(decoded.days[0].meals[0].recipe.name == "Oatmeal")
    }
}
