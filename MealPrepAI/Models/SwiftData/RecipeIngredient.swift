import Foundation
import SwiftData

@Model
final class RecipeIngredient {
    var id: UUID = UUID()
    var quantity: Double = 1
    var unitRaw: String = "piece"
    var notes: String?
    var isOptional: Bool = false

    // For display: "2 cups" or "200g"
    var quantityGrams: Double?

    // Relationship to recipe
    var recipe: Recipe?

    // Relationship to ingredient
    var ingredient: Ingredient?

    var unit: MeasurementUnit {
        get { MeasurementUnit(rawValue: unitRaw) ?? .piece }
        set { unitRaw = newValue.rawValue }
    }

    var displayQuantity: String {
        let formatted = quantity.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", quantity)
            : String(format: "%.1f", quantity)
        return "\(formatted) \(unit.rawValue)"
    }

    var displayWithGrams: String {
        if let grams = quantityGrams {
            return "\(displayQuantity) (\(Int(grams))g)"
        }
        return displayQuantity
    }

    init(
        quantity: Double = 1,
        unit: MeasurementUnit = .piece,
        notes: String? = nil,
        isOptional: Bool = false,
        quantityGrams: Double? = nil
    ) {
        self.id = UUID()
        self.quantity = quantity
        self.unitRaw = unit.rawValue
        self.notes = notes
        self.isOptional = isOptional
        self.quantityGrams = quantityGrams
    }
}
