import Foundation
import SwiftUI

// MARK: - Meal Types
enum MealType: String, Codable, CaseIterable, Identifiable, Sendable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .breakfast: return "sun.horizon.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "leaf.fill"
        }
    }
}

// MARK: - Dietary Restrictions
enum DietaryRestriction: String, Codable, CaseIterable, Identifiable, Sendable {
    case none = "None"
    case vegetarian = "Vegetarian"
    case vegan = "Vegan"
    case pescatarian = "Pescatarian"
    case keto = "Keto"
    case paleo = "Paleo"
    case glutenFree = "Gluten-Free"
    case dairyFree = "Dairy-Free"
    case halal = "Halal"
    case kosher = "Kosher"
    case lowCarb = "Low Carb"
    case lowFat = "Low Fat"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .none: return "checkmark.circle"
        case .vegetarian: return "leaf.fill"
        case .vegan: return "leaf.circle.fill"
        case .pescatarian: return "fish.fill"
        case .keto: return "flame.fill"
        case .paleo: return "hare.fill"
        case .glutenFree: return "xmark.circle"
        case .dairyFree: return "drop.circle"
        case .halal: return "moon.stars.fill"
        case .kosher: return "star.circle.fill"
        case .lowCarb: return "chart.bar.fill"
        case .lowFat: return "heart.fill"
        }
    }
}

// MARK: - Allergies
enum Allergy: String, Codable, CaseIterable, Identifiable, Sendable {
    case none = "None"
    case peanuts = "Peanuts"
    case treeNuts = "Tree Nuts"
    case milk = "Milk"
    case eggs = "Eggs"
    case wheat = "Wheat"
    case soy = "Soy"
    case fish = "Fish"
    case shellfish = "Shellfish"
    case sesame = "Sesame"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .none: return "checkmark.circle"
        case .peanuts: return "leaf.circle"
        case .treeNuts: return "tree.circle"
        case .milk: return "drop.circle"
        case .eggs: return "oval.portrait"
        case .wheat: return "leaf.arrow.circlepath"
        case .soy: return "circle.grid.2x2"
        case .fish: return "fish"
        case .shellfish: return "fish.fill"
        case .sesame: return "circle.dotted"
        }
    }
}

// MARK: - Cooking Skill Level
enum CookingSkill: String, Codable, CaseIterable, Identifiable, Sendable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case chef = "Chef"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .beginner: return "Simple recipes, minimal prep"
        case .intermediate: return "Comfortable with most techniques"
        case .advanced: return "Complex recipes welcome"
        case .chef: return "Bring on the challenge!"
        }
    }

    var icon: String {
        switch self {
        case .beginner: return "1.circle.fill"
        case .intermediate: return "2.circle.fill"
        case .advanced: return "3.circle.fill"
        case .chef: return "star.circle.fill"
        }
    }
}

// MARK: - Cooking Time Preference
enum CookingTime: String, Codable, CaseIterable, Identifiable, Sendable {
    case quick = "Under 15 min"
    case moderate = "15-30 min"
    case standard = "30-60 min"
    case leisurely = "60+ min"

    var id: String { rawValue }

    var maxMinutes: Int {
        switch self {
        case .quick: return 15
        case .moderate: return 30
        case .standard: return 60
        case .leisurely: return 120
        }
    }
}

// MARK: - Cuisine Types
enum CuisineType: String, Codable, CaseIterable, Identifiable, Sendable {
    case american = "American"
    case mexican = "Mexican"
    case italian = "Italian"
    case chinese = "Chinese"
    case japanese = "Japanese"
    case indian = "Indian"
    case thai = "Thai"
    case mediterranean = "Mediterranean"
    case middleEastern = "Middle Eastern"
    case korean = "Korean"
    case vietnamese = "Vietnamese"
    case french = "French"
    case greek = "Greek"
    case spanish = "Spanish"
    case caribbean = "Caribbean"

    var id: String { rawValue }

    var flag: String {
        switch self {
        case .american: return "🇺🇸"
        case .mexican: return "🇲🇽"
        case .italian: return "🇮🇹"
        case .chinese: return "🇨🇳"
        case .japanese: return "🇯🇵"
        case .indian: return "🇮🇳"
        case .thai: return "🇹🇭"
        case .mediterranean: return "🌊"
        case .middleEastern: return "🕌"
        case .korean: return "🇰🇷"
        case .vietnamese: return "🇻🇳"
        case .french: return "🇫🇷"
        case .greek: return "🇬🇷"
        case .spanish: return "🇪🇸"
        case .caribbean: return "🏝️"
        }
    }
}

// MARK: - Weight Goal
enum WeightGoal: String, Codable, CaseIterable, Identifiable, Sendable {
    case lose = "Lose Weight"
    case maintain = "Maintain Weight"
    case gain = "Gain Weight"
    case recomp = "Body Recomposition"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .lose: return "arrow.down.circle.fill"
        case .maintain: return "equal.circle.fill"
        case .gain: return "arrow.up.circle.fill"
        case .recomp: return "arrow.triangle.2.circlepath.circle.fill"
        }
    }

    var description: String {
        switch self {
        case .lose: return "Calorie deficit for weight loss"
        case .maintain: return "Balanced calories to maintain"
        case .gain: return "Calorie surplus for muscle gain"
        case .recomp: return "Build muscle, lose fat"
        }
    }
}

// MARK: - Grocery Category
enum GroceryCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case produce = "Produce"
    case meat = "Meat & Seafood"
    case dairy = "Dairy & Eggs"
    case bakery = "Bakery"
    case frozen = "Frozen"
    case pantry = "Pantry"
    case canned = "Canned Goods"
    case condiments = "Condiments & Sauces"
    case snacks = "Snacks"
    case beverages = "Beverages"
    case spices = "Spices & Seasonings"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .produce: return "leaf.fill"
        case .meat: return "fish.fill"
        case .dairy: return "drop.fill"
        case .bakery: return "birthday.cake.fill"
        case .frozen: return "snowflake"
        case .pantry: return "cabinet.fill"
        case .canned: return "cylinder.fill"
        case .condiments: return "drop.halffull"
        case .snacks: return "popcorn.fill"
        case .beverages: return "cup.and.saucer.fill"
        case .spices: return "leaf.arrow.circlepath"
        case .other: return "bag.fill"
        }
    }
}

// MARK: - Measurement Unit
enum MeasurementUnit: String, Codable, CaseIterable, Identifiable, Sendable {
    // Volume
    case cup = "cup"
    case tablespoon = "tbsp"
    case teaspoon = "tsp"
    case fluidOunce = "fl oz"
    case milliliter = "ml"
    case liter = "L"

    // Weight
    case gram = "g"
    case kilogram = "kg"
    case ounce = "oz"
    case pound = "lb"

    // Count
    case piece = "piece"
    case slice = "slice"
    case clove = "clove"
    case bunch = "bunch"
    case can = "can"
    case package = "package"

    var id: String { rawValue }

    var isVolume: Bool {
        switch self {
        case .cup, .tablespoon, .teaspoon, .fluidOunce, .milliliter, .liter:
            return true
        default:
            return false
        }
    }

    var isWeight: Bool {
        switch self {
        case .gram, .kilogram, .ounce, .pound:
            return true
        default:
            return false
        }
    }

    var isCount: Bool {
        switch self {
        case .piece, .slice, .clove, .bunch, .can, .package:
            return true
        default:
            return false
        }
    }

    var isMetric: Bool {
        switch self {
        case .milliliter, .liter, .gram, .kilogram:
            return true
        default:
            return false
        }
    }

    var isImperial: Bool {
        switch self {
        case .cup, .tablespoon, .teaspoon, .fluidOunce, .ounce, .pound:
            return true
        default:
            return false
        }
    }

    /// Convert quantity and unit to the user's preferred measurement system
    func convert(_ quantity: Double, to system: MeasurementSystem) -> (quantity: Double, unit: MeasurementUnit) {
        // Count-based units don't convert
        if isCount {
            return (quantity, self)
        }

        // If already in the preferred system, no conversion needed
        if system == .metric && isMetric {
            return (quantity, self)
        }
        if system == .imperial && isImperial {
            return (quantity, self)
        }

        // Perform conversion
        switch (self, system) {
        // Imperial to Metric - Volume
        case (.cup, .metric):
            return (quantity * 236.588, .milliliter)
        case (.tablespoon, .metric):
            return (quantity * 14.787, .milliliter)
        case (.teaspoon, .metric):
            return (quantity * 4.929, .milliliter)
        case (.fluidOunce, .metric):
            return (quantity * 29.574, .milliliter)

        // Imperial to Metric - Weight
        case (.ounce, .metric):
            return (quantity * 28.3495, .gram)
        case (.pound, .metric):
            return (quantity * 453.592, .gram)

        // Metric to Imperial - Volume
        case (.milliliter, .imperial):
            // Small amounts stay as tsp/tbsp
            if quantity <= 15 {
                return (quantity / 4.929, .teaspoon)
            } else if quantity <= 60 {
                return (quantity / 14.787, .tablespoon)
            } else {
                return (quantity / 29.574, .fluidOunce)
            }
        case (.liter, .imperial):
            return (quantity * 4.227, .cup)

        // Metric to Imperial - Weight
        case (.gram, .imperial):
            if quantity >= 453.592 {
                return (quantity / 453.592, .pound)
            } else {
                return (quantity / 28.3495, .ounce)
            }
        case (.kilogram, .imperial):
            return (quantity * 2.205, .pound)

        default:
            return (quantity, self)
        }
    }

    /// Format a converted quantity with appropriate precision
    static func formatQuantity(_ quantity: Double, unit: MeasurementUnit) -> String {
        let formatted: String
        if quantity >= 100 {
            formatted = String(format: "%.0f", quantity)
        } else if quantity >= 10 {
            formatted = String(format: "%.1f", quantity)
        } else if quantity.truncatingRemainder(dividingBy: 1) == 0 {
            formatted = String(format: "%.0f", quantity)
        } else {
            formatted = String(format: "%.1f", quantity)
        }
        return "\(formatted) \(unit.rawValue)"
    }
}

// MARK: - Complexity Score
enum RecipeComplexity: Int, Codable, CaseIterable, Identifiable, Sendable {
    case easy = 1
    case medium = 2
    case hard = 3

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }

    var color: String {
        switch self {
        case .easy: return "green"
        case .medium: return "orange"
        case .hard: return "red"
        }
    }
}

// MARK: - Activity Level
enum ActivityLevel: String, Codable, CaseIterable, Identifiable, Sendable {
    case sedentary = "Sedentary"
    case light = "Lightly Active"
    case moderate = "Moderately Active"
    case active = "Very Active"
    case extreme = "Extremely Active"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .sedentary: return "Little or no exercise"
        case .light: return "Light exercise 1-3 days/week"
        case .moderate: return "Moderate exercise 3-5 days/week"
        case .active: return "Hard exercise 6-7 days/week"
        case .extreme: return "Very hard exercise & physical job"
        }
    }

    var icon: String {
        switch self {
        case .sedentary: return "figure.stand"
        case .light: return "figure.walk"
        case .moderate: return "figure.run"
        case .active: return "figure.highintensity.intervaltraining"
        case .extreme: return "figure.strengthtraining.traditional"
        }
    }

    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .light: return 1.375
        case .moderate: return 1.55
        case .active: return 1.725
        case .extreme: return 1.9
        }
    }
}

// MARK: - Gender (for calorie calculations)
enum Gender: String, Codable, CaseIterable, Identifiable, Sendable {
    case male = "Male"
    case female = "Female"
    case other = "Other"

    var id: String { rawValue }
}

// MARK: - Appearance Mode
enum AppearanceMode: String, CaseIterable, Identifiable, Sendable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .system: return "iphone"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Measurement System
enum MeasurementSystem: String, CaseIterable, Identifiable, Sendable {
    case metric = "Metric"
    case imperial = "Imperial"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .metric: return "scalemass"
        case .imperial: return "scalemass.fill"
        }
    }

    var description: String {
        switch self {
        case .metric: return "kg, g, L, ml, cm"
        case .imperial: return "lb, oz, cups, fl oz, in"
        }
    }

    // Weight units for this system
    var weightUnit: String {
        switch self {
        case .metric: return "kg"
        case .imperial: return "lb"
        }
    }

    var smallWeightUnit: String {
        switch self {
        case .metric: return "g"
        case .imperial: return "oz"
        }
    }

    // Volume units for this system
    var volumeUnit: String {
        switch self {
        case .metric: return "L"
        case .imperial: return "cups"
        }
    }

    var smallVolumeUnit: String {
        switch self {
        case .metric: return "ml"
        case .imperial: return "fl oz"
        }
    }

    // Length units for this system
    var lengthUnit: String {
        switch self {
        case .metric: return "cm"
        case .imperial: return "in"
        }
    }

    // Conversion helpers
    func convertWeight(_ value: Double, from sourceSystem: MeasurementSystem) -> Double {
        if self == sourceSystem { return value }
        switch (sourceSystem, self) {
        case (.metric, .imperial): return value * 2.20462 // kg to lb
        case (.imperial, .metric): return value / 2.20462 // lb to kg
        default: return value
        }
    }

    func convertSmallWeight(_ value: Double, from sourceSystem: MeasurementSystem) -> Double {
        if self == sourceSystem { return value }
        switch (sourceSystem, self) {
        case (.metric, .imperial): return value * 0.035274 // g to oz
        case (.imperial, .metric): return value / 0.035274 // oz to g
        default: return value
        }
    }

    func convertVolume(_ value: Double, from sourceSystem: MeasurementSystem) -> Double {
        if self == sourceSystem { return value }
        switch (sourceSystem, self) {
        case (.metric, .imperial): return value * 4.22675 // L to cups
        case (.imperial, .metric): return value / 4.22675 // cups to L
        default: return value
        }
    }

    func convertLength(_ value: Double, from sourceSystem: MeasurementSystem) -> Double {
        if self == sourceSystem { return value }
        switch (sourceSystem, self) {
        case (.metric, .imperial): return value * 0.393701 // cm to in
        case (.imperial, .metric): return value / 0.393701 // in to cm
        default: return value
        }
    }
}
