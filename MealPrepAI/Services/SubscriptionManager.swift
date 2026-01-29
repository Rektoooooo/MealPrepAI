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

    // MARK: - Init
    init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await checkEntitlements()
        }
    }

    func cancelListener() {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(for: Self.productIDs)
                .sorted { $0.price < $1.price }
        } catch {
            print("[SubscriptionManager] Failed to load products: \(error)")
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
            print("[SubscriptionManager] Purchase failed: \(error)")
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
            print("[SubscriptionManager] Restore failed: \(error)")
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
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self?.checkEntitlements()
                    await self?.syncJWSToBackend(result.jwsRepresentation)
                }
            }
        }
    }

    // MARK: - Backend Sync
    /// Fire-and-forget sync of a verified transaction JWS to the backend.
    /// Non-fatal on failure — local StoreKit remains the primary source of truth.
    private func syncJWSToBackend(_ jws: String) async {
        do {
            let deviceId = await DeviceIdentifier.shared.deviceId
            _ = try await APIService.shared.verifySubscription(
                deviceId: deviceId,
                signedTransactionJWS: jws
            )
            print("[SubscriptionManager] Backend sync succeeded")
        } catch {
            print("[SubscriptionManager] Backend sync failed (non-fatal): \(error)")
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
