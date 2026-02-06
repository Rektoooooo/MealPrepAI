import Foundation
import StoreKit

@MainActor
@Observable
final class SubscriptionManager {
    // MARK: - Properties
    var isSubscribed: Bool = false
    var products: [Product] = []
    var isLoading: Bool = false
    var purchaseError: String?

    var monthlyProduct: Product? {
        products.first { $0.id == Self.monthlyID }
    }

    var annualProduct: Product? {
        products.first { $0.id == Self.annualID }
    }

    // MARK: - Constants
    private static let monthlyID = "com.mealprepai.monthly"
    private static let annualID = "com.mealprepai.annual"
    private static let productIDs: Set<String> = [monthlyID, annualID]

    // MARK: - Private
    private var updateListenerTask: Task<Void, Never>?
    private var backendSyncFailCount = 0
    private static let maxSyncRetries = 3

    // MARK: - Init
    init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await checkEntitlements()
        }
    }

    /// Cancel the transaction update listener. Call this before releasing the
    /// object to prevent the detached Task from running indefinitely.
    func stopListening() {
        updateListenerTask?.cancel()
        updateListenerTask = nil
    }

    // MARK: - Load Products
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(for: Self.productIDs)
                .sorted { $0.price < $1.price }
        } catch {
            #if DEBUG
            print("[SubscriptionManager] Failed to load products: \(error)")
            #endif
        }
    }

    // MARK: - Purchase
    func purchase(plan: SubscriptionPlan) async -> Bool {
        let product: Product?
        switch plan {
        case .monthly: product = monthlyProduct
        case .annual: product = annualProduct
        }

        guard let product else {
            purchaseError = "Product not available"
            return false
        }

        isLoading = true
        purchaseError = nil
        defer { isLoading = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await checkEntitlements()
                await syncJWSToBackend(verification.jwsRepresentation)
                return true

            case .userCancelled:
                return false

            case .pending:
                purchaseError = "Purchase is pending approval"
                return false

            @unknown default:
                return false
            }
        } catch {
            purchaseError = error.localizedDescription
            #if DEBUG
            print("[SubscriptionManager] Purchase failed: \(error)")
            #endif
            return false
        }
    }

    // MARK: - Restore
    func restore() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await checkEntitlements()
        } catch {
            purchaseError = error.localizedDescription
            #if DEBUG
            print("[SubscriptionManager] Restore failed: \(error)")
            #endif
        }
    }

    // MARK: - Check Entitlements
    func checkEntitlements() async {
        var hasActiveSubscription = false

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.revocationDate == nil {
                hasActiveSubscription = true
                // Sync latest entitlement to backend on app launch
                await syncJWSToBackend(result.jwsRepresentation)
            }
        }

        isSubscribed = hasActiveSubscription
    }

    // MARK: - Transaction Listener
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                // Exit if the task has been cancelled (object deallocated)
                guard !Task.isCancelled else { return }
                // Exit if self is gone — prevents running with nil self
                guard let self else { return }

                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self.checkEntitlements()
                    await self.syncJWSToBackend(result.jwsRepresentation)
                }
            }
        }
    }

    // MARK: - Backend Sync
    /// Sync a verified transaction JWS to the backend with retry.
    /// Non-fatal on failure — local StoreKit remains the primary source of truth.
    private func syncJWSToBackend(_ jws: String) async {
        guard backendSyncFailCount < Self.maxSyncRetries else {
            #if DEBUG
            print("[SubscriptionManager] Skipping backend sync — reached \(Self.maxSyncRetries) failures this session")
            #endif
            return
        }

        do {
            let deviceId = DeviceIdentifier.shared.deviceId
            _ = try await APIService.shared.verifySubscription(
                deviceId: deviceId,
                signedTransactionJWS: jws
            )
            backendSyncFailCount = 0
            #if DEBUG
            print("[SubscriptionManager] Backend sync succeeded")
            #endif
        } catch {
            backendSyncFailCount += 1
            #if DEBUG
            print("[SubscriptionManager] Backend sync failed (\(backendSyncFailCount)/\(Self.maxSyncRetries)): \(error)")
            #endif
        }
    }

    // MARK: - Verification
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let value):
            return value
        }
    }
}

// MARK: - Store Error
private enum StoreError: LocalizedError {
    case verificationFailed

    var errorDescription: String? {
        switch self {
        case .verificationFailed: return "Transaction verification failed"
        }
    }
}
