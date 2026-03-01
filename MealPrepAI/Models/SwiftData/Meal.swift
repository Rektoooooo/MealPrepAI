import Foundation
import SwiftData

@Model
final class Meal {
    // MARK: - Static Codecs (avoid allocating per-access)
    private static let decoder = JSONDecoder()
    private static let encoder = JSONEncoder()

    var id: UUID = UUID()
    var mealTypeRaw: String = "Breakfast"
    var isEaten: Bool = false
    var eatenAt: Date?
    var isLocked: Bool = false

    // HealthKit integration - stored as JSON Data
    var healthKitSampleIDsData: Data?

    // Relationship to day
    var day: Day?

    // Relationship to recipe
    var recipe: Recipe?

    var mealType: MealType {
        get { MealType(rawValue: mealTypeRaw) ?? .breakfast }
        set { mealTypeRaw = newValue.rawValue }
    }

    var healthKitSampleIDs: [String]? {
        get {
            guard let data = healthKitSampleIDsData else { return nil }
            return try? Self.decoder.decode([String].self, from: data)
        }
        set {
            healthKitSampleIDsData = newValue.flatMap { try? Self.encoder.encode($0) }
        }
    }

    var displayName: String {
        recipe?.name ?? mealType.rawValue
    }

    init(
        mealType: MealType = .breakfast,
        isEaten: Bool = false,
        isLocked: Bool = false
    ) {
        self.id = UUID()
        self.mealTypeRaw = mealType.rawValue
        self.isEaten = isEaten
        self.isLocked = isLocked
    }
}
