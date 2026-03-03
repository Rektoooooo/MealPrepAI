import SuperwallKit

enum SuperwallTracker {
    /// Register a placement without gating any feature.
    /// Use this for placements that may show a paywall but don't block access.
    static func registerPlacement(
        _ placement: String,
        params: [String: Any]? = nil
    ) {
        Superwall.shared.register(placement: placement, params: params) {
            // No feature to gate — placement fires and paywall may show
        }
    }

    /// Register a gated placement. The `feature` closure only runs
    /// if the user has an active subscription or the paywall is dismissed
    /// by Superwall's rules.
    static func registerFeatureGate(
        _ placement: String,
        params: [String: Any]? = nil,
        feature: @escaping () -> Void
    ) {
        Superwall.shared.register(
            placement: placement,
            params: params,
            feature: feature
        )
    }
}
