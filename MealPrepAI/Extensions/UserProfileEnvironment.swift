import SwiftUI

// MARK: - UserProfile Environment Key

private struct UserProfileKey: EnvironmentKey {
    static let defaultValue: UserProfile? = nil
}

extension EnvironmentValues {
    var userProfile: UserProfile? {
        get { self[UserProfileKey.self] }
        set { self[UserProfileKey.self] = newValue }
    }
}
