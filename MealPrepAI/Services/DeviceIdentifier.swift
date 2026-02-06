import Foundation
import Security

/// Manages a unique device identifier stored securely in the Keychain.
/// The identifier persists across app reinstalls and is used for rate limiting.
@MainActor
final class DeviceIdentifier {
    static let shared = DeviceIdentifier()

    private let serviceName = "com.mealprepai.deviceid"
    private let accountName = "device_identifier"

    /// Cached device ID to avoid repeated Keychain lookups
    private var cachedDeviceId: String?

    private init() {}

    /// Get the unique device identifier, creating one if it doesn't exist
    var deviceId: String {
        #if DEBUG
        print("[DEBUG:DeviceId] Getting device identifier...")
        #endif

        if let cached = cachedDeviceId {
            #if DEBUG
            print("[DEBUG:DeviceId] Using cached device ID: \(cached.prefix(8))...")
            #endif
            return cached
        }

        if let existing = retrieveFromKeychain() {
            #if DEBUG
            print("[DEBUG:DeviceId] Retrieved from Keychain: \(existing.prefix(8))...")
            #endif
            cachedDeviceId = existing
            return existing
        }

        let newId = UUID().uuidString
        #if DEBUG
        print("[DEBUG:DeviceId] Created new device ID: \(newId.prefix(8))...")
        #endif
        saveToKeychain(newId)
        cachedDeviceId = newId
        return newId
    }

    // MARK: - Keychain Operations

    private func saveToKeychain(_ value: String) {
        guard let data = value.data(using: .utf8) else { return }

        // Delete any existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add the new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        if status != errSecSuccess {
            #if DEBUG
            print("DeviceIdentifier: Failed to save to Keychain: \(status)")
            #endif
        }
    }

    private func retrieveFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    /// Reset the device identifier (for testing purposes)
    func reset() {
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        cachedDeviceId = nil
    }
}
