import Foundation

// MARK: - API Configuration
// nonisolated(unsafe) required to opt out of default MainActor isolation for actor access
private let apiConfigBaseURL = "https://your-worker.your-subdomain.workers.dev"
private let apiConfigUseMockData = true

// MARK: - API Errors
enum APIError: LocalizedError, Sendable {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case networkError(Error)
    case rateLimited
    case serverError(String)

    nonisolated var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .serverError(let message):
            return message
        }
    }
}

// MARK: - Claude API Request/Response Models
// These structs need nonisolated Codable conformance for use in actor contexts
struct ClaudeRequest: Sendable {
    let model: String
    let maxTokens: Int
    let messages: [ClaudeMessage]
    let system: String?
}

extension ClaudeRequest: Codable {
    nonisolated enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case messages
        case system
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        model = try container.decode(String.self, forKey: .model)
        maxTokens = try container.decode(Int.self, forKey: .maxTokens)
        messages = try container.decode([ClaudeMessage].self, forKey: .messages)
        system = try container.decodeIfPresent(String.self, forKey: .system)
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(model, forKey: .model)
        try container.encode(maxTokens, forKey: .maxTokens)
        try container.encode(messages, forKey: .messages)
        try container.encodeIfPresent(system, forKey: .system)
    }
}

struct ClaudeMessage: Sendable {
    let role: String
    let content: String
}

extension ClaudeMessage: Codable {
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        role = try container.decode(String.self, forKey: .role)
        content = try container.decode(String.self, forKey: .content)
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(role, forKey: .role)
        try container.encode(content, forKey: .content)
    }

    nonisolated enum CodingKeys: String, CodingKey {
        case role
        case content
    }
}

struct ClaudeResponse: Sendable {
    let id: String
    let content: [ClaudeContent]
    let model: String
    let usage: ClaudeUsage?

    nonisolated var textContent: String? {
        content.first { $0.type == "text" }?.text
    }
}

extension ClaudeResponse: Codable {
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        content = try container.decode([ClaudeContent].self, forKey: .content)
        model = try container.decode(String.self, forKey: .model)
        usage = try container.decodeIfPresent(ClaudeUsage.self, forKey: .usage)
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(model, forKey: .model)
        try container.encodeIfPresent(usage, forKey: .usage)
    }

    nonisolated enum CodingKeys: String, CodingKey {
        case id
        case content
        case model
        case usage
    }
}

struct ClaudeContent: Sendable {
    let type: String
    let text: String?
}

extension ClaudeContent: Codable {
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        text = try container.decodeIfPresent(String.self, forKey: .text)
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(text, forKey: .text)
    }

    nonisolated enum CodingKeys: String, CodingKey {
        case type
        case text
    }
}

struct ClaudeUsage: Sendable {
    let inputTokens: Int
    let outputTokens: Int
}

extension ClaudeUsage: Codable {
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        inputTokens = try container.decode(Int.self, forKey: .inputTokens)
        outputTokens = try container.decode(Int.self, forKey: .outputTokens)
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(inputTokens, forKey: .inputTokens)
        try container.encode(outputTokens, forKey: .outputTokens)
    }

    nonisolated enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}

// MARK: - API Service
actor APIService {
    static let shared = APIService()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120 // Claude can take time for long responses
        config.timeoutIntervalForResource = 180
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    // MARK: - Send Message to Claude (via backend proxy)
    func sendMessage(
        prompt: String,
        systemPrompt: String? = nil,
        maxTokens: Int = 4096
    ) async throws -> String {
        // Use mock data for development
        if apiConfigUseMockData {
            return try await mockResponse(for: prompt)
        }

        guard let url = URL(string: apiConfigBaseURL) else {
            throw APIError.invalidURL
        }

        let request = ClaudeRequest(
            model: "claude-sonnet-4-20250514",
            maxTokens: maxTokens,
            messages: [ClaudeMessage(role: "user", content: prompt)],
            system: systemPrompt
        )

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try encoder.encode(request)

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            let claudeResponse = try decoder.decode(ClaudeResponse.self, from: data)
            guard let text = claudeResponse.textContent else {
                throw APIError.invalidResponse
            }
            return text

        case 429:
            throw APIError.rateLimited

        default:
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
    }

    // MARK: - Mock Response for Development
    private func mockResponse(for prompt: String) async throws -> String {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds

        // Return mock meal plan JSON
        return mockMealPlanJSON
    }
}

// MARK: - Mock Data
private let mockMealPlanJSON = """
{
  "days": [
    {
      "dayOfWeek": 0,
      "meals": [
        {
          "mealType": "breakfast",
          "recipe": {
            "name": "Greek Yogurt Parfait",
            "description": "Creamy Greek yogurt layered with fresh berries and crunchy granola",
            "instructions": [
              "Add Greek yogurt to a bowl or glass",
              "Layer with fresh mixed berries",
              "Top with granola and a drizzle of honey",
              "Serve immediately"
            ],
            "prepTimeMinutes": 5,
            "cookTimeMinutes": 0,
            "servings": 1,
            "complexity": "easy",
            "cuisineType": "american",
            "calories": 350,
            "proteinGrams": 20,
            "carbsGrams": 45,
            "fatGrams": 10,
            "fiberGrams": 5,
            "ingredients": [
              {"name": "Greek Yogurt", "quantity": 1, "unit": "cup", "category": "dairy"},
              {"name": "Mixed Berries", "quantity": 0.5, "unit": "cup", "category": "produce"},
              {"name": "Granola", "quantity": 0.25, "unit": "cup", "category": "pantry"},
              {"name": "Honey", "quantity": 1, "unit": "tablespoon", "category": "pantry"}
            ]
          }
        },
        {
          "mealType": "lunch",
          "recipe": {
            "name": "Mediterranean Quinoa Bowl",
            "description": "Protein-packed quinoa with fresh vegetables, feta, and lemon herb dressing",
            "instructions": [
              "Cook quinoa according to package directions and let cool slightly",
              "Dice cucumber, tomatoes, and red onion",
              "Combine quinoa with vegetables in a large bowl",
              "Add chickpeas and crumbled feta",
              "Drizzle with olive oil and lemon juice",
              "Season with salt, pepper, and dried oregano"
            ],
            "prepTimeMinutes": 15,
            "cookTimeMinutes": 20,
            "servings": 2,
            "complexity": "easy",
            "cuisineType": "mediterranean",
            "calories": 520,
            "proteinGrams": 18,
            "carbsGrams": 62,
            "fatGrams": 22,
            "fiberGrams": 10,
            "ingredients": [
              {"name": "Quinoa", "quantity": 1, "unit": "cup", "category": "pantry"},
              {"name": "Cucumber", "quantity": 1, "unit": "piece", "category": "produce"},
              {"name": "Cherry Tomatoes", "quantity": 1, "unit": "cup", "category": "produce"},
              {"name": "Red Onion", "quantity": 0.25, "unit": "piece", "category": "produce"},
              {"name": "Chickpeas", "quantity": 0.5, "unit": "cup", "category": "pantry"},
              {"name": "Feta Cheese", "quantity": 0.5, "unit": "cup", "category": "dairy"},
              {"name": "Olive Oil", "quantity": 2, "unit": "tablespoon", "category": "pantry"},
              {"name": "Lemon", "quantity": 1, "unit": "piece", "category": "produce"}
            ]
          }
        },
        {
          "mealType": "dinner",
          "recipe": {
            "name": "Herb-Crusted Salmon",
            "description": "Tender salmon fillet with a crispy herb crust, served with roasted asparagus",
            "instructions": [
              "Preheat oven to 400°F (200°C)",
              "Mix breadcrumbs with fresh herbs, garlic, and olive oil",
              "Season salmon with salt and pepper",
              "Press herb mixture onto top of salmon",
              "Place salmon and asparagus on baking sheet",
              "Drizzle asparagus with olive oil and season",
              "Bake for 15-18 minutes until salmon is cooked through"
            ],
            "prepTimeMinutes": 15,
            "cookTimeMinutes": 18,
            "servings": 2,
            "complexity": "medium",
            "cuisineType": "american",
            "calories": 480,
            "proteinGrams": 42,
            "carbsGrams": 15,
            "fatGrams": 28,
            "fiberGrams": 4,
            "ingredients": [
              {"name": "Salmon Fillet", "quantity": 2, "unit": "piece", "category": "meat"},
              {"name": "Asparagus", "quantity": 1, "unit": "bunch", "category": "produce"},
              {"name": "Breadcrumbs", "quantity": 0.5, "unit": "cup", "category": "pantry"},
              {"name": "Fresh Parsley", "quantity": 2, "unit": "tablespoon", "category": "produce"},
              {"name": "Garlic", "quantity": 2, "unit": "clove", "category": "produce"},
              {"name": "Olive Oil", "quantity": 3, "unit": "tablespoon", "category": "pantry"},
              {"name": "Lemon", "quantity": 1, "unit": "piece", "category": "produce"}
            ]
          }
        },
        {
          "mealType": "snack",
          "recipe": {
            "name": "Apple Slices with Almond Butter",
            "description": "Crisp apple slices paired with creamy almond butter",
            "instructions": [
              "Wash and slice apple into wedges",
              "Serve with almond butter for dipping"
            ],
            "prepTimeMinutes": 5,
            "cookTimeMinutes": 0,
            "servings": 1,
            "complexity": "easy",
            "cuisineType": "american",
            "calories": 200,
            "proteinGrams": 5,
            "carbsGrams": 25,
            "fatGrams": 10,
            "fiberGrams": 4,
            "ingredients": [
              {"name": "Apple", "quantity": 1, "unit": "piece", "category": "produce"},
              {"name": "Almond Butter", "quantity": 2, "unit": "tablespoon", "category": "pantry"}
            ]
          }
        }
      ]
    },
    {
      "dayOfWeek": 1,
      "meals": [
        {
          "mealType": "breakfast",
          "recipe": {
            "name": "Avocado Toast with Eggs",
            "description": "Whole grain toast topped with creamy avocado and perfectly poached eggs",
            "instructions": [
              "Toast bread until golden",
              "Mash avocado with salt, pepper, and lime juice",
              "Poach or fry eggs to desired doneness",
              "Spread avocado on toast and top with eggs",
              "Garnish with red pepper flakes and fresh herbs"
            ],
            "prepTimeMinutes": 10,
            "cookTimeMinutes": 5,
            "servings": 1,
            "complexity": "easy",
            "cuisineType": "american",
            "calories": 420,
            "proteinGrams": 18,
            "carbsGrams": 35,
            "fatGrams": 24,
            "fiberGrams": 8,
            "ingredients": [
              {"name": "Whole Grain Bread", "quantity": 2, "unit": "slice", "category": "pantry"},
              {"name": "Avocado", "quantity": 1, "unit": "piece", "category": "produce"},
              {"name": "Eggs", "quantity": 2, "unit": "piece", "category": "dairy"},
              {"name": "Lime", "quantity": 0.5, "unit": "piece", "category": "produce"},
              {"name": "Red Pepper Flakes", "quantity": 0.25, "unit": "teaspoon", "category": "pantry"}
            ]
          }
        },
        {
          "mealType": "lunch",
          "recipe": {
            "name": "Asian Chicken Salad",
            "description": "Crunchy salad with grilled chicken, mandarin oranges, and sesame ginger dressing",
            "instructions": [
              "Grill or pan-sear chicken breast until cooked through",
              "Let chicken rest, then slice",
              "Combine mixed greens, cabbage, and carrots",
              "Add mandarin oranges and sliced almonds",
              "Top with sliced chicken",
              "Drizzle with sesame ginger dressing"
            ],
            "prepTimeMinutes": 15,
            "cookTimeMinutes": 15,
            "servings": 2,
            "complexity": "easy",
            "cuisineType": "asian",
            "calories": 450,
            "proteinGrams": 35,
            "carbsGrams": 28,
            "fatGrams": 22,
            "fiberGrams": 6,
            "ingredients": [
              {"name": "Chicken Breast", "quantity": 2, "unit": "piece", "category": "meat"},
              {"name": "Mixed Greens", "quantity": 4, "unit": "cup", "category": "produce"},
              {"name": "Red Cabbage", "quantity": 1, "unit": "cup", "category": "produce"},
              {"name": "Carrots", "quantity": 2, "unit": "piece", "category": "produce"},
              {"name": "Mandarin Oranges", "quantity": 1, "unit": "can", "category": "pantry"},
              {"name": "Sliced Almonds", "quantity": 0.25, "unit": "cup", "category": "pantry"},
              {"name": "Sesame Ginger Dressing", "quantity": 3, "unit": "tablespoon", "category": "pantry"}
            ]
          }
        },
        {
          "mealType": "dinner",
          "recipe": {
            "name": "Turkey Meatballs with Zucchini Noodles",
            "description": "Lean turkey meatballs in marinara sauce over spiralized zucchini",
            "instructions": [
              "Mix ground turkey with breadcrumbs, egg, garlic, and Italian seasoning",
              "Form into meatballs and bake at 400°F for 20 minutes",
              "Spiralize zucchini into noodles",
              "Sauté zucchini noodles briefly in olive oil",
              "Heat marinara sauce and add cooked meatballs",
              "Serve meatballs and sauce over zucchini noodles"
            ],
            "prepTimeMinutes": 20,
            "cookTimeMinutes": 25,
            "servings": 2,
            "complexity": "medium",
            "cuisineType": "italian",
            "calories": 420,
            "proteinGrams": 38,
            "carbsGrams": 22,
            "fatGrams": 20,
            "fiberGrams": 5,
            "ingredients": [
              {"name": "Ground Turkey", "quantity": 1, "unit": "pound", "category": "meat"},
              {"name": "Zucchini", "quantity": 3, "unit": "piece", "category": "produce"},
              {"name": "Marinara Sauce", "quantity": 2, "unit": "cup", "category": "pantry"},
              {"name": "Breadcrumbs", "quantity": 0.25, "unit": "cup", "category": "pantry"},
              {"name": "Egg", "quantity": 1, "unit": "piece", "category": "dairy"},
              {"name": "Garlic", "quantity": 3, "unit": "clove", "category": "produce"},
              {"name": "Italian Seasoning", "quantity": 1, "unit": "teaspoon", "category": "pantry"}
            ]
          }
        },
        {
          "mealType": "snack",
          "recipe": {
            "name": "Hummus with Veggie Sticks",
            "description": "Creamy hummus served with fresh cucumber and carrot sticks",
            "instructions": [
              "Cut cucumber and carrots into sticks",
              "Serve with hummus for dipping"
            ],
            "prepTimeMinutes": 5,
            "cookTimeMinutes": 0,
            "servings": 1,
            "complexity": "easy",
            "cuisineType": "mediterranean",
            "calories": 180,
            "proteinGrams": 6,
            "carbsGrams": 20,
            "fatGrams": 8,
            "fiberGrams": 5,
            "ingredients": [
              {"name": "Hummus", "quantity": 0.5, "unit": "cup", "category": "dairy"},
              {"name": "Cucumber", "quantity": 1, "unit": "piece", "category": "produce"},
              {"name": "Carrots", "quantity": 2, "unit": "piece", "category": "produce"}
            ]
          }
        }
      ]
    }
  ]
}
"""
