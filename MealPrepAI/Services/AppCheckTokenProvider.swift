//
//  AppCheckTokenProvider.swift
//  MealPrepAI
//
//  Provides Firebase App Check tokens for API authentication
//

import Foundation
import FirebaseAppCheck

/// Provides App Check tokens to verify requests come from the real app
actor AppCheckTokenProvider {
    static let shared = AppCheckTokenProvider()

    private init() {}

    /// Get a fresh App Check token for API requests
    /// Returns nil if App Check is not available (shouldn't happen in production)
    func getToken() async -> String? {
        do {
            let tokenResult = try await AppCheck.appCheck().token(forcingRefresh: false)
            #if DEBUG
            print("🔒 [AppCheck] Token obtained, expires: \(tokenResult.expirationDate)")
            #endif
            return tokenResult.token
        } catch {
            #if DEBUG
            print("🔒 [AppCheck] ERROR getting token: \(error.localizedDescription)")
            #endif
            return nil
        }
    }
}
