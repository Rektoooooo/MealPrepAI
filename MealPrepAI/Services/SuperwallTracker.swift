import SuperwallKit

enum SuperwallTracker {
    /// User starts their free trial (first plan generation)
    static func trackFreeTrialStarted() {
        Superwall.shared.register(placement: "free_trial_started")
    }

    /// User taps subscribe from paywall
    static func trackPaywallSubscribeTapped(plan: String) {
        Superwall.shared.register(
            placement: "paywall_subscribe_tapped",
            params: ["plan": plan]
        )
    }

    /// Paywall was shown to user
    static func trackPaywallShown() {
        Superwall.shared.register(placement: "paywall_shown")
    }

    /// User dismissed paywall without subscribing
    static func trackPaywallDismissed() {
        Superwall.shared.register(placement: "paywall_dismissed")
    }

    /// User tapped restore purchases
    static func trackRestoreTapped() {
        Superwall.shared.register(placement: "restore_tapped")
    }
}
