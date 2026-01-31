import Testing
import Foundation
@testable import MealPrepAI

struct APIServiceTypesTests {

    // MARK: - GeneratePlanAPIResponse decoding

    @Test func generatePlanAPIResponseDecodesSuccess() throws {
        let json = """
        {
            "success": true,
            "mealPlan": {
                "id": "plan-123",
                "days": []
            },
            "recipesAdded": 21,
            "recipesDuplicate": 3
        }
        """
        let response = try JSONDecoder().decode(GeneratePlanAPIResponse.self, from: json.data(using: .utf8)!)
        #expect(response.success)
        #expect(response.mealPlan?.id == "plan-123")
        #expect(response.recipesAdded == 21)
        #expect(response.recipesDuplicate == 3)
        #expect(response.error == nil)
    }

    @Test func generatePlanAPIResponseDecodesError() throws {
        let json = """
        {
            "success": false,
            "error": "Rate limit exceeded"
        }
        """
        let response = try JSONDecoder().decode(GeneratePlanAPIResponse.self, from: json.data(using: .utf8)!)
        #expect(!response.success)
        #expect(response.error == "Rate limit exceeded")
        #expect(response.mealPlan == nil)
    }

    @Test func rateLimitInfoDecoding() throws {
        let json = """
        {
            "success": true,
            "rateLimitInfo": {
                "remaining": 5,
                "resetTime": "2026-02-01T00:00:00Z",
                "limit": 10
            }
        }
        """
        let response = try JSONDecoder().decode(GeneratePlanAPIResponse.self, from: json.data(using: .utf8)!)
        #expect(response.rateLimitInfo?.remaining == 5)
        #expect(response.rateLimitInfo?.limit == 10)
    }

    // MARK: - SwapMealAPIResponse decoding

    @Test func swapMealAPIResponseDecodes() throws {
        let json = """
        {
            "success": true,
            "recipe": {
                "name": "Grilled Salmon",
                "description": "Fresh salmon",
                "prepTimeMinutes": 10,
                "cookTimeMinutes": 15,
                "servings": 2,
                "complexity": "easy",
                "cuisineType": "American",
                "calories": 350,
                "proteinGrams": 40,
                "carbsGrams": 5,
                "fatGrams": 18,
                "ingredients": [],
                "instructions": ["Grill the salmon for 7 minutes each side."]
            }
        }
        """
        let response = try JSONDecoder().decode(SwapMealAPIResponse.self, from: json.data(using: .utf8)!)
        #expect(response.success)
        #expect(response.recipe?.name == "Grilled Salmon")
    }

    // MARK: - APIError descriptions

    @Test func apiErrorDescriptions() {
        let errors: [APIError] = [
            .invalidURL, .invalidResponse, .rateLimited, .subscriptionRequired
        ]
        for error in errors {
            #expect(!error.localizedDescription.isEmpty)
        }
    }

    @Test func apiErrorHttpError() {
        let error = APIError.httpError(statusCode: 404)
        #expect(error.localizedDescription.contains("404"))
    }

    @Test func apiErrorServerError() {
        let error = APIError.serverError("Something went wrong")
        #expect(error.localizedDescription.contains("Something went wrong"))
    }
}
