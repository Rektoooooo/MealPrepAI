import SuperwallKit
import StoreKit

@MainActor
final class SuperwallPurchaseController: PurchaseController {
    private let subscriptionManager: SubscriptionManager

    init(subscriptionManager: SubscriptionManager) {
        self.subscriptionManager = subscriptionManager
    }

    // MARK: - PurchaseController

    func purchase(product: StoreProduct) async -> PurchaseResult {
        guard let sk2Product = product.sk2Product else {
            return .failed(SuperwallPurchaseError.productUnavailable)
        }

        do {
            let result = try await sk2Product.purchase()

            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await subscriptionManager.checkEntitlements()
                    return .purchased

                case .unverified:
                    return .failed(SuperwallPurchaseError.verificationFailed)
                }

            case .userCancelled:
                return .cancelled

            case .pending:
                return .pending

            @unknown default:
                return .failed(SuperwallPurchaseError.unknown)
            }
        } catch {
            return .failed(error)
        }
    }

    func restorePurchases() async -> RestorationResult {
        do {
            try await AppStore.sync()
            await subscriptionManager.checkEntitlements()
            return .restored
        } catch {
            return .failed(error)
        }
    }
}

// MARK: - Errors

private enum SuperwallPurchaseError: LocalizedError {
    case productUnavailable
    case verificationFailed
    case unknown

    var errorDescription: String? {
        switch self {
        case .productUnavailable: return "StoreKit 2 product not available"
        case .verificationFailed: return "Transaction verification failed"
        case .unknown: return "An unknown purchase error occurred"
        }
    }
}
