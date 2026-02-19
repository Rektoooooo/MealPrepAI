//
//  AuthenticationManager.swift
//  MealPrepAI
//
//  Created by Claude on 22.01.2026.
//

import Foundation
import AuthenticationServices
import CryptoKit
import SwiftUI
import UIKit
import Security
import FirebaseAppCheck

/// Manages user authentication state using Sign in with Apple
@MainActor @Observable
final class AuthenticationManager {

    // MARK: - Types

    enum AuthState: Equatable {
        case unknown       // Initial state, checking stored credentials
        case unauthenticated  // No user, show auth screen
        case guest         // Using app without Apple ID
        case authenticated // Signed in with Apple ID
    }

    // MARK: - Published Properties

    private(set) var authState: AuthState = .unknown
    private(set) var currentUserID: String?
    private(set) var userEmail: String?
    private(set) var userFullName: PersonNameComponents?

    // MARK: - Private Properties

    private let guestModeKey = "com.mealprepai.isGuestMode"

    // Keychain service/account keys for secure credential storage
    private let keychainService = "com.mealprepai.auth"
    private let keychainUserIDAccount = "appleUserID"
    private let keychainAuthCodeAccount = "appleAuthCode"

    /// Nonce used for the current Sign In with Apple request
    private(set) var currentNonce: String?

    // MARK: - Initialization

    init() {
        migrateFromUserDefaultsIfNeeded()
        checkAuthState()
    }

    // MARK: - Public Methods

    /// Check the current authentication state on app launch
    func checkAuthState() {
        // Check if user was in guest mode
        if UserDefaults.standard.bool(forKey: guestModeKey) {
            authState = .guest
            return
        }

        // Check for stored Apple User ID in Keychain
        guard let storedUserID = keychainRead(account: keychainUserIDAccount) else {
            authState = .unauthenticated
            return
        }

        // Verify the credential is still valid with Apple
        Task {
            await verifyCredentialState(for: storedUserID)
        }
    }

    /// Verify credential state using async/await
    private func verifyCredentialState(for userID: String) async {
        let provider = ASAuthorizationAppleIDProvider()
        let state = await withCheckedContinuation { continuation in
            provider.getCredentialState(forUserID: userID) { state, _ in
                continuation.resume(returning: state)
            }
        }

        switch state {
        case .authorized:
            currentUserID = userID
            authState = .authenticated
        case .revoked, .notFound:
            // Credential no longer valid
            clearStoredCredentials()
            authState = .unauthenticated
        case .transferred:
            // User transferred to a different Apple ID
            clearStoredCredentials()
            authState = .unauthenticated
        @unknown default:
            authState = .unauthenticated
        }
    }

    /// Generate a nonce and prepare an Apple ID request with nonce set
    func prepareRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.nonce = sha256(nonce)
    }

    /// Handle successful Sign in with Apple
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) {
        // Validate nonce if one was set
        if let expectedNonce = currentNonce {
            guard let identityToken = credential.identityToken,
                  let tokenString = String(data: identityToken, encoding: .utf8) else {
                #if DEBUG
                print("Sign In with Apple: missing identity token for nonce validation")
                #endif
                currentNonce = nil
                return
            }

            // Decode JWT payload to verify nonce
            let segments = tokenString.split(separator: ".")
            if segments.count >= 2 {
                var base64 = String(segments[1])
                // Pad base64 string
                while base64.count % 4 != 0 { base64.append("=") }
                if let data = Data(base64Encoded: base64),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let tokenNonce = json["nonce"] as? String {
                    guard tokenNonce == expectedNonce else {
                        #if DEBUG
                        print("Sign In with Apple: nonce mismatch")
                        #endif
                        currentNonce = nil
                        return
                    }
                }
            }
            currentNonce = nil
        }

        let userID = credential.user

        // Store the user ID in Keychain
        keychainSave(value: userID, account: keychainUserIDAccount)
        UserDefaults.standard.set(false, forKey: guestModeKey)

        // Store authorization code in Keychain for future token revocation (account deletion)
        if let authorizationCode = credential.authorizationCode,
           let codeString = String(data: authorizationCode, encoding: .utf8) {
            keychainSave(value: codeString, account: keychainAuthCodeAccount)
        }

        // Store optional user info (only provided on first sign in)
        currentUserID = userID
        userEmail = credential.email
        userFullName = credential.fullName

        authState = .authenticated
    }

    /// Continue using the app as a guest without Apple ID
    func continueAsGuest() {
        UserDefaults.standard.set(true, forKey: guestModeKey)
        keychainDelete(account: keychainUserIDAccount)

        currentUserID = nil
        authState = .guest
    }

    /// Sign out and clear all credentials
    func signOut() {
        clearStoredCredentials()
        authState = .unauthenticated
    }

    private static let revokeTokenURL = URL(string: "https://us-central1-mealprepai-b6ac0.cloudfunctions.net/api/revokeAppleToken")

    /// Revoke Sign in with Apple token for account deletion (Apple requirement)
    func revokeAppleSignIn() async {
        guard let storedCode = keychainRead(account: keychainAuthCodeAccount) else {
            // No stored authorization code - just clear credentials
            clearStoredCredentials()
            return
        }

        // Call backend to revoke the Apple token using the stored authorization code
        // The backend exchanges the code for a token and calls Apple's revoke endpoint
        guard let url = Self.revokeTokenURL else {
            clearStoredCredentials()
            return
        }

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(["authorizationCode": storedCode])

            // Add App Check token for security
            if let tokenResult = try? await AppCheck.appCheck().token(forcingRefresh: false) {
                request.setValue(tokenResult.token, forHTTPHeaderField: "X-Firebase-AppCheck")
            }

            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                #if DEBUG
                print("Apple token revoked successfully")
                #endif
            }
        } catch {
            // Token revocation failed - still proceed with local cleanup
            #if DEBUG
            print("Apple token revocation failed: \(error.localizedDescription)")
            #endif
        }

        clearStoredCredentials()
    }

    /// Upgrade from guest to authenticated user
    func upgradeFromGuest(credential: ASAuthorizationAppleIDCredential) {
        signInWithApple(credential: credential)
    }

    /// Check if user is signed in (either as guest or authenticated)
    var isSignedIn: Bool {
        authState == .guest || authState == .authenticated
    }

    /// Check if user has an Apple ID linked
    var hasAppleID: Bool {
        authState == .authenticated && currentUserID != nil
    }

    // MARK: - Private Methods

    private func clearStoredCredentials() {
        keychainDelete(account: keychainUserIDAccount)
        keychainDelete(account: keychainAuthCodeAccount)
        UserDefaults.standard.removeObject(forKey: guestModeKey)
        currentUserID = nil
        userEmail = nil
        userFullName = nil
    }

    // MARK: - Keychain Helpers

    private func keychainSave(value: String, account: String) {
        guard let data = value.data(using: .utf8) else { return }

        // Delete any existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add the new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        if status != errSecSuccess {
            #if DEBUG
            print("AuthenticationManager: Failed to save to Keychain (\(account)): \(status)")
            #endif
        }
    }

    private func keychainRead(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account,
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

    private func keychainDelete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Migration from UserDefaults to Keychain

    private func migrateFromUserDefaultsIfNeeded() {
        let legacyUserIDKey = "com.mealprepai.appleUserID"
        let legacyAuthCodeKey = "com.mealprepai.appleAuthCode"

        if let legacyUserID = UserDefaults.standard.string(forKey: legacyUserIDKey) {
            keychainSave(value: legacyUserID, account: keychainUserIDAccount)
            UserDefaults.standard.removeObject(forKey: legacyUserIDKey)
        }

        if let legacyAuthCode = UserDefaults.standard.string(forKey: legacyAuthCodeKey) {
            keychainSave(value: legacyAuthCode, account: keychainAuthCodeAccount)
            UserDefaults.standard.removeObject(forKey: legacyAuthCodeKey)
        }
    }

    // MARK: - Nonce Helpers

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            // Fallback to UUID-based nonce if SecRandom fails
            return UUID().uuidString.replacingOccurrences(of: "-", with: "")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Sign in with Apple Coordinator

@MainActor
class SignInWithAppleCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    private var completion: ((Result<ASAuthorizationAppleIDCredential, Error>) -> Void)?

    func signIn(authManager: AuthenticationManager, completion: @escaping (Result<ASAuthorizationAppleIDCredential, Error>) -> Void) {
        self.completion = completion

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        authManager.prepareRequest(request)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    // MARK: - ASAuthorizationControllerDelegate

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
            Task { @MainActor in
                completion?(.success(credential))
                completion = nil  // Clear to prevent retain cycles
            }
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Task { @MainActor in
            completion?(.failure(error))
            completion = nil  // Clear to prevent retain cycles
        }
    }

    // MARK: - ASAuthorizationControllerPresentationContextProviding

    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Must access UI on main thread
        return MainActor.assumeIsolated {
            // Find the first available window from connected scenes
            for scene in UIApplication.shared.connectedScenes {
                if let windowScene = scene as? UIWindowScene {
                    if let window = windowScene.windows.first {
                        return window
                    }
                    // No windows yet, create one for this scene
                    return UIWindow(windowScene: windowScene)
                }
            }

            // Fallback: create a new window from first available scene
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                let fallbackWindow = UIWindow(windowScene: windowScene)
                fallbackWindow.makeKeyAndVisible()
                return fallbackWindow
            }

            // Last resort: return an empty window (should never happen in practice)
            return UIWindow()
        }
    }
}
