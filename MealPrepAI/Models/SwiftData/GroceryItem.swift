import Foundation
import SwiftData

@Model
final class GroceryItem {
    var id: UUID
    var quantity: Double
    var unitRaw: String
    var isChecked: Bool
    var isLocked: Bool
    var isManuallyAdded: Bool
    var notes: String?

    // Relationship to grocery list
    var groceryList: GroceryList?

    // Relationship to ingredient
    var ingredient: Ingredient?

    var unit: MeasurementUnit {
        get { MeasurementUnit(rawValue: unitRaw) ?? .piece }
        set { unitRaw = newValue.rawValue }
    }

    var displayName: String {
        ingredient?.name ?? "Unknown Item"
    }

    var displayQuantity: String {
        let formatted = quantity.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", quantity)
            : String(format: "%.1f", quantity)
        return "\(formatted) \(unit.rawValue)"
    }

    init(
        quantity: Double = 1,
        unit: MeasurementUnit = .piece,
        isChecked: Bool = false,
        isLocked: Bool = false,
        isManuallyAdded: Bool = false,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.quantity = quantity
        self.unitRaw = unit.rawValue
        self.isChecked = isChecked
        self.isLocked = isLocked
        self.isManuallyAdded = isManuallyAdded
        self.notes = notes
    }
}
