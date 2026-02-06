import SwiftUI
import UIKit

struct LaunchScreenView: View {
    let onGetStarted: () -> Void
    let onSignIn: () -> Void

    @State private var appeared = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background to prevent bars during image load
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                    .accessibilityHidden(true)

                // Full screen hero image as background
                Image("meal-prep-hero")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .ignoresSafeArea()
                    .opacity(appeared ? 1 : 0)
                    .accessibilityHidden(true)

                // Content overlay
                VStack(spacing: 0) {
                    Spacer()

                    // Text content at bottom
                    VStack(spacing: 16) {
                        // Main title
                        Text("Meal prepping\nmade easier than\never")
                            .font(Design.Typography.largeTitle)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.primary)
                            .lineSpacing(2)

                        // Subtitle
                        Text("Make your week meal plan in less than 2 minutes")
                            .font(Design.Typography.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.primary.opacity(0.6))
                    }
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                    Spacer()
                        .frame(height: 32)
                        .accessibilityHidden(true)

                    // Button section
                    VStack(spacing: 16) {
                        // Get Started button - black pill
                        Button {
                            hapticFeedback(.medium)
                            onGetStarted()
                        } label: {
                            Text("Get Started")
                                .font(Design.Typography.bodyLarge.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 28)
                                        .fill(Color.primary)
                                )
                        }
                        .buttonStyle(LaunchButtonStyle())
                        .accessibilityLabel("Get Started")
                        .accessibilityHint("Begins the onboarding process")

                        // Sign in link
                        Button {
                            onSignIn()
                        } label: {
                            HStack(spacing: 4) {
                                Text("Already have an account?")
                                    .foregroundStyle(Color.primary.opacity(0.5))
                                Text("Sign In")
                                    .foregroundStyle(Color.primary)
                                    .fontWeight(.semibold)
                            }
                            .font(Design.Typography.footnote)
                        }
                        .accessibilityLabel("Already have an account? Sign In")
                        .accessibilityHint("Opens the sign in screen")
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 30)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
    }

    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Button Style
private struct LaunchButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    LaunchScreenView(
        onGetStarted: {},
        onSignIn: {}
    )
}
