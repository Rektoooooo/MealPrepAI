import HealthKit
import SwiftUI

/// Manages HealthKit integration for syncing nutrition data when meals are marked as eaten
@MainActor @Observable
final class HealthKitManager {

    // MARK: - State
    private(set) var isAuthorized: Bool = false
    var isEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "healthKitEnabled")
        }
    }

    // MARK: - Private
    private let healthStore = HKHealthStore()

    // Data types to write (nutrition when meals eaten)
    private let writeTypes: Set<HKSampleType> = [
        HKQuantityType(.dietaryEnergyConsumed),
        HKQuantityType(.dietaryProtein),
        HKQuantityType(.dietaryCarbohydrates),
        HKQuantityType(.dietaryFatTotal),
        HKQuantityType(.dietaryFiber)
    ]

    // Data types to read (for personalization)
    private let readTypes: Set<HKObjectType> = [
        HKQuantityType(.bodyMass),
        HKQuantityType(.height),
        HKQuantityType(.activeEnergyBurned),
        HKQuantityType(.stepCount)
    ]

    // MARK: - Computed
    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Init
    init() {
        isEnabled = UserDefaults.standard.bool(forKey: "healthKitEnabled")
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    /// Request authorization to read and write HealthKit data
    func requestAuthorization() async throws {
        guard isHealthKitAvailable else { return }

        try await healthStore.requestAuthorization(
            toShare: writeTypes,
            read: readTypes
        )

        checkAuthorizationStatus()
    }

    private func checkAuthorizationStatus() {
        guard isHealthKitAvailable else {
            isAuthorized = false
            return
        }

        // Check if we have write permission for dietary energy
        let status = healthStore.authorizationStatus(for: HKQuantityType(.dietaryEnergyConsumed))
        isAuthorized = status == .sharingAuthorized
    }

    // MARK: - Write Nutrition Data

    /// Log nutrition data to HealthKit when a meal is marked as eaten
    /// - Parameters:
    ///   - meal: The meal that was eaten
    /// - Returns: Array of HealthKit sample UUIDs for tracking
    func logMealNutrition(meal: Meal) async throws -> [String] {
        guard isAuthorized, let recipe = meal.recipe else { return [] }

        let date = meal.eatenAt ?? Date()
        var sampleIDs: [String] = []

        // Create samples for each nutrition type
        let samples: [(HKQuantityType, Double, HKUnit)] = [
            (HKQuantityType(.dietaryEnergyConsumed), Double(recipe.calories), .kilocalorie()),
            (HKQuantityType(.dietaryProtein), Double(recipe.proteinGrams), .gram()),
            (HKQuantityType(.dietaryCarbohydrates), Double(recipe.carbsGrams), .gram()),
            (HKQuantityType(.dietaryFatTotal), Double(recipe.fatGrams), .gram()),
            (HKQuantityType(.dietaryFiber), Double(recipe.fiberGrams), .gram())
        ]

        for (type, value, unit) in samples where value > 0 {
            let quantity = HKQuantity(unit: unit, doubleValue: value)
            let sample = HKQuantitySample(
                type: type,
                quantity: quantity,
                start: date,
                end: date,
                metadata: [
                    HKMetadataKeyFoodType: recipe.name,
                    "MealPrepAI_MealID": meal.id.uuidString
                ]
            )

            try await healthStore.save(sample)
            sampleIDs.append(sample.uuid.uuidString)
        }

        return sampleIDs
    }

    /// Delete nutrition samples from HealthKit when a meal is unmarked
    /// - Parameter sampleIDs: Array of HealthKit sample UUID strings to delete
    func deleteMealNutrition(sampleIDs: [String]) async throws {
        guard isAuthorized else { return }

        for idString in sampleIDs {
            guard let uuid = UUID(uuidString: idString) else { continue }

            let predicate = HKQuery.predicateForObject(with: uuid)

            for type in writeTypes {
                let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
                    let query = HKSampleQuery(
                        sampleType: type,
                        predicate: predicate,
                        limit: 1,
                        sortDescriptors: nil
                    ) { _, samples, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: samples ?? [])
                        }
                    }
                    healthStore.execute(query)
                }

                for sample in samples {
                    try await healthStore.delete(sample)
                }
            }
        }
    }

    // MARK: - Read Health Data

    /// Fetch the latest weight from HealthKit
    /// - Returns: Weight in kilograms, or nil if not available
    func fetchLatestWeight() async throws -> Double? {
        guard isAuthorized else { return nil }

        let type = HKQuantityType(.bodyMass)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let sample = samples?.first as? HKQuantitySample {
                    let kg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                    continuation.resume(returning: kg)
                } else {
                    continuation.resume(returning: nil)
                }
            }
            healthStore.execute(query)
        }
    }

    /// Fetch the latest height from HealthKit
    /// - Returns: Height in centimeters, or nil if not available
    func fetchLatestHeight() async throws -> Double? {
        guard isAuthorized else { return nil }

        let type = HKQuantityType(.height)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let sample = samples?.first as? HKQuantitySample {
                    let cm = sample.quantity.doubleValue(for: .meterUnit(with: .centi))
                    continuation.resume(returning: cm)
                } else {
                    continuation.resume(returning: nil)
                }
            }
            healthStore.execute(query)
        }
    }

    /// Fetch today's active energy burned from HealthKit
    /// - Returns: Active calories burned today
    func fetchTodaysActiveCalories() async throws -> Int {
        guard isAuthorized else { return 0 }

        let type = HKQuantityType(.activeEnergyBurned)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let sum = statistics?.sumQuantity() {
                    let calories = Int(sum.doubleValue(for: .kilocalorie()))
                    continuation.resume(returning: calories)
                } else {
                    continuation.resume(returning: 0)
                }
            }
            healthStore.execute(query)
        }
    }

    /// Fetch today's step count from HealthKit
    /// - Returns: Steps taken today
    func fetchTodaysSteps() async throws -> Int {
        guard isAuthorized else { return 0 }

        let type = HKQuantityType(.stepCount)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let sum = statistics?.sumQuantity() {
                    let steps = Int(sum.doubleValue(for: .count()))
                    continuation.resume(returning: steps)
                } else {
                    continuation.resume(returning: 0)
                }
            }
            healthStore.execute(query)
        }
    }
}
