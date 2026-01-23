//
//  AuthenticationView.swift
//  MealPrepAI
//
//  Created by Claude on 22.01.2026.
//

import SwiftUI
import AuthenticationServices

struct AuthenticationView: View {
    @Environment(AuthenticationManager.self) var authManager
    @State private var isSigningIn = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var animateContent = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient.mintBackgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo and Welcome Section
                VStack(spacing: Design.Spacing.lg) {
                    // App Logo
                    ZStack {
                        Circle()
                            .fill(LinearGradient.purpleButtonGradient)
                            .frame(width: 120, height: 120)
                            .shadow(
                                color: Design.Shadow.purple.color,
                                radius: Design.Shadow.purple.radius,
                                y: Design.Shadow.purple.y
                            )

                        Image(systemName: "fork.knife.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.white)
                    }
                    .scaleEffect(animateContent ? 1 : 0.8)
                    .opacity(animateContent ? 1 : 0)

                    VStack(spacing: Design.Spacing.sm) {
                        Text("MealPrepAI")
                            .font(Design.Typography.largeTitle)
                            .foregroundStyle(Color.textPrimary)

                        Text("Your AI-powered meal planning assistant")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                }

                Spacer()

                // Features Preview
                VStack(spacing: Design.Spacing.md) {
                    featureRow(icon: "sparkles", text: "AI-generated personalized meal plans")
                    featureRow(icon: "heart.fill", text: "Respect your dietary preferences")
                    featureRow(icon: "cart.fill", text: "Smart grocery lists")
                    featureRow(icon: "icloud.fill", text: "Sync across all your devices")
                }
                .padding(.horizontal, Design.Spacing.xl)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)

                Spacer()

                // Sign In Buttons
                VStack(spacing: Design.Spacing.md) {
                    // Sign in with Apple Button
                    SignInWithAppleButton(.signIn, onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    }, onCompletion: handleSignInResult)
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(Design.Radius.md)
                    .disabled(isSigningIn)
                    .opacity(isSigningIn ? 0.6 : 1)

                    // Continue as Guest Button
                    Button(action: {
                        withAnimation {
                            authManager.continueAsGuest()
                        }
                    }) {
                        Text("Continue as Guest")
                            .font(.headline)
                            .foregroundStyle(Color.accentPurple)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: Design.Radius.md)
                                    .stroke(Color.accentPurple, lineWidth: 2)
                            )
                    }
                    .disabled(isSigningIn)

                    // Privacy Info
                    Text("Sign in to sync your data across devices. Guest mode keeps data on this device only.")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, Design.Spacing.xs)
                }
                .padding(.horizontal, Design.Spacing.xl)
                .padding(.bottom, Design.Spacing.xxxl)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
            }

            // Loading Overlay
            if isSigningIn {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                    }
            }
        }
        .alert("Sign In Failed", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animateContent = true
            }
        }
    }

    // MARK: - Feature Row

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: Design.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.accentPurple)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.textPrimary)

            Spacer()
        }
    }

    // MARK: - Sign In Handler

    private func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                withAnimation {
                    authManager.signInWithApple(credential: credential)
                }
            }
        case .failure(let error):
            // Don't show error for user cancellation
            if let authError = error as? ASAuthorizationError,
               authError.code == .canceled {
                return
            }

            errorMessage = error.localizedDescription
            showError = true
        }

        isSigningIn = false
    }
}

#Preview {
    AuthenticationView()
        .environment(AuthenticationManager())
}
