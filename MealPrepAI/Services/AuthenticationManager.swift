//
//  AuthenticationManager.swift
//  MealPrepAI
//
//  Created by Claude on 22.01.2026.
//

import Foundation
import AuthenticationServices
import SwiftUI
import UIKit

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

    private let userIDKey = "com.mealprepai.appleUserID"
    private let guestModeKey = "com.mealprepai.isGuestMode"

    // MARK: - Initialization

    init() {
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

        // Check for stored Apple User ID
        guard let storedUserID = UserDefaults.standard.string(forKey: userIDKey) else {
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

    /// Handle successful Sign in with Apple
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) {
        let userID = credential.user

        // Store the user ID
        UserDefaults.standard.set(userID, forKey: userIDKey)
        UserDefaults.standard.set(false, forKey: guestModeKey)

        // Store optional user info (only provided on first sign in)
        currentUserID = userID
        userEmail = credential.email
        userFullName = credential.fullName

        authState = .authenticated
    }

    /// Continue using the app as a guest without Apple ID
    func continueAsGuest() {
        UserDefaults.standard.set(true, forKey: guestModeKey)
        UserDefaults.standard.removeObject(forKey: userIDKey)

        currentUserID = nil
        authState = .guest
    }

    /// Sign out and clear all credentials
    func signOut() {
        clearStoredCredentials()
        authState = .unauthenticated
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
        UserDefaults.standard.removeObject(forKey: userIDKey)
        UserDefaults.standard.removeObject(forKey: guestModeKey)
        currentUserID = nil
        userEmail = nil
        userFullName = nil
    }
}

// MARK: - Sign in with Apple Coordinator

@MainActor
class SignInWithAppleCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    private var completion: ((Result<ASAuthorizationAppleIDCredential, Error>) -> Void)?

    func signIn(completion: @escaping (Result<ASAuthorizationAppleIDCredential, Error>) -> Void) {
        self.completion = completion

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

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
            // This should rarely happen as we already iterate scenes above
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                fatalError("No window scene available for Sign in with Apple")
            }
            let fallbackWindow = UIWindow(windowScene: windowScene)
            fallbackWindow.makeKeyAndVisible()
            return fallbackWindow
        }
    }
}
