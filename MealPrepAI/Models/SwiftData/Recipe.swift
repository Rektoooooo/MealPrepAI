import Foundation
import SwiftData

@Model
final class Recipe {
    var id: UUID = UUID()
    var name: String = ""
    var recipeDescription: String = ""
    var instructionsData: Data?  // Store as JSON Data
    var prepTimeMinutes: Int = 10
    var cookTimeMinutes: Int = 20
    var servings: Int = 2
    var complexityRaw: Int = 1
    var cuisineTypeRaw: String?
    var imageURL: String?
    @Attribute(.externalStorage) var localImageData: Data?

    // Nutrition
    var calories: Int = 0
    var proteinGrams: Int = 0
    var carbsGrams: Int = 0
    var fatGrams: Int = 0
    var fiberGrams: Int = 0

    // Metadata
    var isFavorite: Bool = false
    var timesUsed: Int = 0
    var lastUsedDate: Date?
    var isCustom: Bool = false
    var sourceURL: String?
    var createdAt: Date = Date()

    /// Manually flagged as requiring advance prep (overnight marinating, soaking, etc.)
    var requiresAdvancePrep: Bool = false

    // Firebase Sync Fields
    /// Firebase document ID for recipes synced from Firestore
    var firebaseId: String?
    /// Spoonacular external ID for recipes from API
    var externalId: Int?
    /// When this recipe was last synced from Firebase
    var lastSyncedAt: Date?
    /// True if this recipe originated from Firebase, false if locally created
    var isFromFirebase: Bool = false
    /// Health score from Spoonacular (0-100)
    var healthScore: Int?
    /// Meal type for categorization (breakfast, lunch, dinner, snack)
    var mealTypeRaw: String?
    /// Dietary tags (e.g., "vegetarian,gluten-free")
    var dietsRaw: String?

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \RecipeIngredient.recipe)
    var ingredients: [RecipeIngredient] = []

    @Relationship(inverse: \Meal.recipe)
    var meals: [Meal] = []

    // Computed properties for enums and arrays
    var instructions: [String] {
        get {
            guard let data = instructionsData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            instructionsData = try? JSONEncoder().encode(newValue)
        }
    }

    var complexity: RecipeComplexity {
        get { RecipeComplexity(rawValue: complexityRaw) ?? .medium }
        set { complexityRaw = newValue.rawValue }
    }

    var cuisineType: CuisineType? {
        get { cuisineTypeRaw.flatMap { CuisineType(rawValue: $0) } }
        set { cuisineTypeRaw = newValue?.rawValue }
    }

    var totalTimeMinutes: Int {
        prepTimeMinutes + cookTimeMinutes
    }

    // MARK: - Performance caches (not persisted)

    /// Cached lowercased "(name) (description)" for category matching — avoids
    /// re-allocating and lowercasing on every `matchesCategory` call.
    @Transient private var _cachedSearchText: String?

    /// Cached lowercased diets array — avoids re-splitting `dietsRaw` and
    /// lowercasing each element on every `RecipeFilter.matches` / `displayDiets` call.
    @Transient private var _cachedLowercasedDiets: [String]?

    var cachedSearchText: String {
        if let cached = _cachedSearchText { return cached }
        let text = (name + " " + recipeDescription).lowercased()
        _cachedSearchText = text
        return text
    }

    var cachedLowercasedDiets: [String] {
        if let cached = _cachedLowercasedDiets { return cached }
        let result = diets.map { $0.lowercased() }
        _cachedLowercasedDiets = result
        return result
    }

    /// Invalidate transient caches when recipe data changes (e.g. after update from Firebase).
    func invalidateCaches() {
        _cachedSearchText = nil
        _cachedLowercasedDiets = nil
        _cachedInferredAdvancePrep = nil
        _cachedParsedInstructions = nil
    }

    @Transient private var _cachedInferredAdvancePrep: Bool?

    var inferredAdvancePrep: Bool {
        if let cached = _cachedInferredAdvancePrep { return cached }
        let keywords = ["overnight", "marinate", "refrigerate for", "soak", "chill for", "rest overnight", "freeze for"]
        let text = instructions.joined(separator: " ").lowercased()
        let result = keywords.contains { text.contains($0) }
        _cachedInferredAdvancePrep = result
        return result
    }

    /// Whether this recipe needs advance prep (explicit flag or inferred from instructions)
    var needsAdvancePrep: Bool {
        requiresAdvancePrep || inferredAdvancePrep
    }

    var totalTimeFormatted: String {
        let total = totalTimeMinutes
        if total < 60 {
            return "\(total) min"
        } else {
            let hours = total / 60
            let minutes = total % 60
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
    }

    /// Calories per serving
    /// Note: Spoonacular API returns nutrition data PER SERVING, so `calories` is already per serving
    var caloriesPerServing: Int {
        return calories
    }

    /// Total calories for entire recipe (all servings)
    var totalCalories: Int {
        return calories * max(servings, 1)
    }

    /// High-resolution image URL (converts Spoonacular URLs to max size 636x393)
    var highResImageURL: String? {
        guard let url = imageURL else { return nil }

        // Spoonacular image URL pattern: https://spoonacular.com/recipeImages/{id}-{size}.{ext}
        // Available sizes: 90x90, 240x150, 312x150, 312x231, 480x360, 556x370, 636x393
        let sizePatterns = ["90x90", "240x150", "312x150", "312x231", "480x360", "556x370"]
        let maxSize = "636x393"

        var highResUrl = url
        for size in sizePatterns {
            if url.contains(size) {
                highResUrl = url.replacingOccurrences(of: size, with: maxSize)
                break
            }
        }

        return highResUrl
    }

    /// Check if recipe has a video (source URL that looks like a video)
    var hasVideo: Bool {
        guard let url = sourceURL?.lowercased() else { return false }
        return url.contains("youtube") || url.contains("vimeo") ||
               url.contains("video") || url.contains("watch")
    }

    /// Whether recipe has valid, usable instructions
    var hasValidInstructions: Bool {
        let validSteps = parsedInstructions
        return !validSteps.isEmpty && validSteps.first != "No instructions available."
    }

    @Transient private var _cachedParsedInstructions: [String]?

    var parsedInstructions: [String] {
        if let cached = _cachedParsedInstructions { return cached }
        let result = computeParsedInstructions()
        _cachedParsedInstructions = result
        return result
    }

    private func computeParsedInstructions() -> [String] {
        let rawInstructions = instructions

        // Handle empty instructions
        if rawInstructions.isEmpty {
            return ["No instructions available."]
        }

        // Custom recipes: return instructions as-is (user-written, no garbage filtering needed)
        if isCustom {
            let cleaned = rawInstructions
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            return cleaned.isEmpty ? ["No instructions available."] : cleaned
        }

        var steps: [String]

        // If already has multiple steps, use them directly
        if rawInstructions.count > 1 {
            steps = rawInstructions
        } else {
            // Single instruction block - try to split it
            guard let singleBlock = rawInstructions.first, !singleBlock.isEmpty else {
                return ["No instructions available."]
            }
            steps = splitInstructionBlock(singleBlock)
        }

        // Clean and filter out garbage content
        steps = steps
            .map { cleanInstruction($0) }
            .filter { isValidInstruction($0) }

        // If all steps were filtered out, return placeholder
        if steps.isEmpty {
            return ["No instructions available."]
        }

        return steps
    }

    /// Check if an instruction step is valid (not garbage/promotional content)
    private func isValidInstruction(_ text: String) -> Bool {
        let lowercased = text.lowercased()

        // Filter out social media and promotional garbage
        let garbagePatterns = [
            "facebook", "pinterest", "twitter", "instagram", "yummly",
            "google+", "email", "subscribe", "follow us", "click here",
            "check out", "visit our", "join the", "sign up",
            "watch video", "whatch video", // typo from data
            "if you are looking for", "make sure you head over",
            "seriously soupy", // blog signature
            "what do you usually add" // questions, not instructions
        ]

        for pattern in garbagePatterns {
            if lowercased.contains(pattern) {
                return false
            }
        }

        // Filter out steps that are too short (less than 15 chars after cleaning)
        if text.count < 15 {
            return false
        }

        // Filter out steps that are just single words or very short phrases
        let wordCount = text.components(separatedBy: .whitespaces).filter { !$0.isEmpty }.count
        if wordCount < 3 {
            return false
        }

        return true
    }

    /// Clean up an instruction string
    private func cleanInstruction(_ text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove HTML entities
        cleaned = cleaned.replacingOccurrences(of: "&amp;", with: "&")
        cleaned = cleaned.replacingOccurrences(of: "&nbsp;", with: " ")
        cleaned = cleaned.replacingOccurrences(of: "&#39;", with: "'")
        cleaned = cleaned.replacingOccurrences(of: "&quot;", with: "\"")

        // Remove multiple spaces
        while cleaned.contains("  ") {
            cleaned = cleaned.replacingOccurrences(of: "  ", with: " ")
        }

        // Capitalize first letter
        if let first = cleaned.first {
            cleaned = first.uppercased() + cleaned.dropFirst()
        }

        // Ensure it ends with a period
        if !cleaned.hasSuffix(".") && !cleaned.hasSuffix("!") && !cleaned.hasSuffix("?") {
            cleaned += "."
        }

        return cleaned
    }

    /// Split a single instruction block into multiple steps
    private func splitInstructionBlock(_ block: String) -> [String] {
        var steps: [String] = []

        // Common sentence-ending patterns that indicate step boundaries
        let sentencePattern = #"(?<=[.!?])\s+(?=[A-Z])"#

        // Try to split by sentences
        if let regex = try? NSRegularExpression(pattern: sentencePattern, options: []) {
            let range = NSRange(block.startIndex..., in: block)
            var lastEnd = block.startIndex

            regex.enumerateMatches(in: block, options: [], range: range) { match, _, _ in
                if let matchRange = match?.range, let swiftRange = Range(matchRange, in: block) {
                    let sentence = String(block[lastEnd..<swiftRange.lowerBound])
                    if !sentence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        steps.append(sentence)
                    }
                    lastEnd = swiftRange.upperBound
                }
            }

            // Add the last part
            let lastPart = String(block[lastEnd...])
            if !lastPart.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                steps.append(lastPart)
            }
        }

        // If splitting didn't work well, try alternative approaches
        if steps.count <= 1 {
            // Try splitting by common cooking step indicators
            let stepIndicators = [
                "Then ", "Next ", "After that ", "Finally ",
                "Meanwhile ", "While ", "Once ", "When ",
                "Now ", "Add ", "Place ", "Pour ", "Mix ",
                "Stir ", "Cook ", "Bake ", "Heat ", "Preheat "
            ]

            var currentStep = ""
            let words = block.components(separatedBy: " ")

            for (index, word) in words.enumerated() {
                let testPhrase = word + " "
                let shouldSplit = stepIndicators.contains { testPhrase.hasPrefix($0) } && !currentStep.isEmpty

                if shouldSplit {
                    if !currentStep.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        steps.append(currentStep.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                    currentStep = word + " "
                } else {
                    currentStep += word + (index < words.count - 1 ? " " : "")
                }
            }

            if !currentStep.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                steps.append(currentStep.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }

        // Clean up and validate steps
        steps = steps.map { cleanInstruction($0) }
            .filter { $0.count > 10 } // Filter out very short fragments

        // If we still only have 1 step or none, return original
        if steps.count <= 1 {
            return [cleanInstruction(block)]
        }

        return steps
    }

    /// Meal type for Firebase recipes
    var mealType: MealType? {
        get { mealTypeRaw.flatMap { MealType(rawValue: $0) } }
        set { mealTypeRaw = newValue?.rawValue }
    }

    /// Dietary tags as array
    var diets: [String] {
        get { dietsRaw?.components(separatedBy: ",").filter { !$0.isEmpty } ?? [] }
        set { dietsRaw = newValue.isEmpty ? nil : newValue.joined(separator: ",") }
    }

    /// Check if recipe matches a dietary restriction
    func matchesDiet(_ diet: DietaryRestriction) -> Bool {
        let dietString = diet.rawValue.lowercased()
        return diets.contains { $0.lowercased().contains(dietString) }
    }

    func matchesCategory(_ category: FoodCategory) -> Bool {
        let searchText = cachedSearchText

        switch category {
        case .all:
            return true
        case .chicken:
            return searchText.contains("chicken") || searchText.contains("poultry") ||
                   searchText.contains("turkey") || searchText.contains("hen")
        case .pasta:
            return searchText.contains("pasta") || searchText.contains("spaghetti") ||
                   searchText.contains("penne") || searchText.contains("fettuccine") ||
                   searchText.contains("linguine") || searchText.contains("macaroni") ||
                   searchText.contains("lasagna") || searchText.contains("noodle") ||
                   searchText.contains("rigatoni") || searchText.contains("ravioli")
        case .salad:
            return searchText.contains("salad") || searchText.contains("greens") ||
                   searchText.contains("lettuce") || searchText.contains("caesar")
        case .soup:
            return searchText.contains("soup") || searchText.contains("stew") ||
                   searchText.contains("broth") || searchText.contains("chowder") ||
                   searchText.contains("bisque") || searchText.contains("gumbo")
        case .asian:
            return searchText.contains("asian") || searchText.contains("chinese") ||
                   searchText.contains("japanese") || searchText.contains("korean") ||
                   searchText.contains("thai") || searchText.contains("vietnamese") ||
                   searchText.contains("stir fry") || searchText.contains("teriyaki") ||
                   searchText.contains("sushi") || searchText.contains("ramen") ||
                   searchText.contains("pad thai") || searchText.contains("curry") ||
                   cuisineType == .chinese || cuisineType == .japanese ||
                   cuisineType == .korean || cuisineType == .thai
        case .mexican:
            return searchText.contains("mexican") || searchText.contains("taco") ||
                   searchText.contains("burrito") || searchText.contains("enchilada") ||
                   searchText.contains("quesadilla") || searchText.contains("salsa") ||
                   searchText.contains("guacamole") || searchText.contains("fajita") ||
                   searchText.contains("nachos") || searchText.contains("chimichanga") ||
                   cuisineType == .mexican
        case .seafood:
            return searchText.contains("fish") || searchText.contains("salmon") ||
                   searchText.contains("shrimp") || searchText.contains("tuna") ||
                   searchText.contains("seafood") || searchText.contains("lobster") ||
                   searchText.contains("crab") || searchText.contains("cod") ||
                   searchText.contains("tilapia") || searchText.contains("scallop") ||
                   searchText.contains("prawns") || searchText.contains("mussels")
        case .vegetarian:
            let lowerDiets = cachedLowercasedDiets
            return lowerDiets.contains { $0.contains("vegetarian") } ||
                   lowerDiets.contains { $0.contains("vegan") } ||
                   searchText.contains("vegetarian") || searchText.contains("vegan") ||
                   searchText.contains("plant-based") || searchText.contains("meatless")
        case .quick:
            return totalTimeMinutes <= 30
        }
    }

    init(
        name: String = "",
        recipeDescription: String = "",
        instructions: [String] = [],
        prepTimeMinutes: Int = 10,
        cookTimeMinutes: Int = 20,
        servings: Int = 2,
        complexity: RecipeComplexity = .medium,
        cuisineType: CuisineType? = nil,
        calories: Int = 0,
        proteinGrams: Int = 0,
        carbsGrams: Int = 0,
        fatGrams: Int = 0,
        fiberGrams: Int = 0,
        isFavorite: Bool = false,
        isCustom: Bool = false,
        imageURL: String? = nil,
        isFromFirebase: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.recipeDescription = recipeDescription
        self.instructionsData = try? JSONEncoder().encode(instructions)
        self.prepTimeMinutes = prepTimeMinutes
        self.cookTimeMinutes = cookTimeMinutes
        self.servings = servings
        self.complexityRaw = complexity.rawValue
        self.cuisineTypeRaw = cuisineType?.rawValue
        self.imageURL = imageURL
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.carbsGrams = carbsGrams
        self.fatGrams = fatGrams
        self.fiberGrams = fiberGrams
        self.isFavorite = isFavorite
        self.timesUsed = 0
        self.isCustom = isCustom
        self.createdAt = Date()
        self.isFromFirebase = isFromFirebase
        self.firebaseId = nil
        self.externalId = nil
        self.lastSyncedAt = nil
        self.healthScore = nil
        self.mealTypeRaw = nil
        self.dietsRaw = nil
    }

    /// Convenience initializer for creating a Recipe from a FirebaseRecipe
    convenience init(from firebaseRecipe: FirebaseRecipe) {
        self.init(
            name: firebaseRecipe.title,
            recipeDescription: "",
            instructions: firebaseRecipe.instructions,
            prepTimeMinutes: firebaseRecipe.readyInMinutes,
            cookTimeMinutes: 0,
            servings: firebaseRecipe.servings,
            complexity: firebaseRecipe.estimatedComplexity,
            cuisineType: firebaseRecipe.appCuisineType,
            calories: firebaseRecipe.calories,
            proteinGrams: firebaseRecipe.proteinGrams,
            carbsGrams: firebaseRecipe.carbsGrams,
            fatGrams: firebaseRecipe.fatGrams,
            fiberGrams: 0,
            isFavorite: false,
            isCustom: false,
            imageURL: firebaseRecipe.imageUrl,
            isFromFirebase: true
        )

        self.firebaseId = firebaseRecipe.id
        self.externalId = firebaseRecipe.externalId
        self.lastSyncedAt = Date()
        self.healthScore = firebaseRecipe.healthScore
        self.mealTypeRaw = firebaseRecipe.mealType.capitalized
        self.dietsRaw = firebaseRecipe.diets.joined(separator: ",")
        self.sourceURL = firebaseRecipe.sourceUrl
    }

    /// Update this recipe with data from a FirebaseRecipe
    func update(from firebaseRecipe: FirebaseRecipe) {
        self.name = firebaseRecipe.title
        self.instructions = firebaseRecipe.instructions
        self.prepTimeMinutes = firebaseRecipe.readyInMinutes
        self.servings = firebaseRecipe.servings
        self.complexity = firebaseRecipe.estimatedComplexity
        self.cuisineType = firebaseRecipe.appCuisineType
        self.calories = firebaseRecipe.calories
        self.proteinGrams = firebaseRecipe.proteinGrams
        self.carbsGrams = firebaseRecipe.carbsGrams
        self.fatGrams = firebaseRecipe.fatGrams
        self.imageURL = firebaseRecipe.imageUrl
        self.healthScore = firebaseRecipe.healthScore
        self.mealTypeRaw = firebaseRecipe.mealType.capitalized
        self.dietsRaw = firebaseRecipe.diets.joined(separator: ",")
        self.sourceURL = firebaseRecipe.sourceUrl
        self.lastSyncedAt = Date()
        invalidateCaches()
    }
}
