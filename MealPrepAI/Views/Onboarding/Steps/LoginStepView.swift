import SwiftUI
import AuthenticationServices

struct LoginStepView: View {
    @Environment(AuthenticationManager.self) private var authManager
    let onSignInWithApple: () -> Void
    let onContinueAsGuest: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Cloud icon
            ZStack {
                Circle()
                    .fill(OnboardingDesign.Colors.accent.opacity(0.15))
                    .frame(width: 120, height: 120)

                Circle()
                    .fill(OnboardingDesign.Colors.accent.opacity(0.25))
                    .frame(width: 90, height: 90)

                Image(systemName: "icloud.fill")
                    .font(Design.Typography.iconSmall)
                    .foregroundStyle(OnboardingDesign.Colors.accent)
            }
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.5)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxxl)

            // Title
            Text("Save your progress")
                .font(OnboardingDesign.Typography.title)
                .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.md)

            // Subtitle
            Text("Create an account to sync your data\nacross devices")
                .font(OnboardingDesign.Typography.body)
                .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxl)

            // Benefits
            VStack(alignment: .leading, spacing: OnboardingDesign.Spacing.md) {
                LoginBenefitRow(icon: "icloud.and.arrow.up", text: "Backup your meal plans")
                LoginBenefitRow(icon: "arrow.triangle.2.circlepath", text: "Sync across iPhone & iPad")
                LoginBenefitRow(icon: "lock.shield", text: "Secure & private")
            }
            .padding(OnboardingDesign.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: OnboardingDesign.Radius.xl)
                    .fill(OnboardingDesign.Colors.cardBackground)
            )
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 30)

            Spacer()

            // CTAs
            VStack(spacing: OnboardingDesign.Spacing.sm) {
                // Sign in with Apple button
                SignInWithAppleButton(
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                                authManager.signInWithApple(credential: credential)
                            }
                            onSignInWithApple()
                        case .failure:
                            // Handle error - user cancelled or error occurred
                            break
                        }
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: 54)
                .cornerRadius(OnboardingDesign.Radius.xl)
                .opacity(appeared ? 1 : 0)

                // Continue as guest
                Button {
                    authManager.continueAsGuest()
                    onContinueAsGuest()
                } label: {
                    Text("Continue as guest")
                        .font(OnboardingDesign.Typography.subheadline)
                        .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                }
                .padding(.top, OnboardingDesign.Spacing.xs)
                .opacity(appeared ? 1 : 0)
            }
        }
        .padding(.horizontal, OnboardingDesign.Spacing.xl)
        .padding(.bottom, OnboardingDesign.Spacing.xl)
        .onboardingBackground()
        .onAppear {
            withAnimation(OnboardingDesign.Animation.bouncy.delay(0.2)) {
                appeared = true
            }
        }
    }
}

// MARK: - Login Benefit Row
private struct LoginBenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: OnboardingDesign.Spacing.md) {
            Image(systemName: icon)
                .font(OnboardingDesign.Typography.title3)
                .foregroundStyle(OnboardingDesign.Colors.accent)
                .frame(width: 32, height: 32)

            Text(text)
                .font(OnboardingDesign.Typography.subheadline)
                .foregroundStyle(OnboardingDesign.Colors.textPrimary)
        }
    }
}

#Preview {
    LoginStepView(
        onSignInWithApple: {},
        onContinueAsGuest: {}
    )
    .environment(AuthenticationManager())
}
