import SwiftUI

// MARK: - Step 1: Welcome
struct WelcomeStep: View {
    @State private var appeared = false
    @State private var pulseAnimation = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Design.Spacing.lg) {
                Spacer()
                    .frame(height: Design.Spacing.md)

                // Hero Icon with Pulsing Glow
                ZStack {
                    // Outer glow pulse
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.accentPurple.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 40,
                                endRadius: 80
                            )
                        )
                        .frame(width: 140, height: 140)
                        .scaleEffect(pulseAnimation ? 1.1 : 0.9)
                        .opacity(pulseAnimation ? 0.6 : 0.3)

                    // Main circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.mintVibrant.opacity(0.4), Color.accentPurple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 110, height: 110)

                    // Icon
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 55))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accentPurple, Color.mintVibrant],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .scaleEffect(appeared ? 1 : 0.5)
                .opacity(appeared ? 1 : 0)

                // Text Content
                VStack(spacing: Design.Spacing.sm) {
                    Text("Welcome to")
                        .font(Design.Typography.title3)
                        .foregroundStyle(Color.textSecondary)

                    Text("MealPrepAI")
                        .font(Design.Typography.largeTitle)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accentPurple, Color.mintVibrant],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("Your personalized meal planning assistant powered by AI")
                        .font(Design.Typography.subheadline)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Design.Spacing.lg)
                }
                .offset(y: appeared ? 0 : 30)
                .opacity(appeared ? 1 : 0)

                Spacer()
                    .frame(height: Design.Spacing.md)

                // Feature Highlights
                VStack(spacing: Design.Spacing.sm) {
                    FeatureHighlightRow(
                        icon: "sparkles",
                        title: "AI-Powered Meal Plans",
                        description: "Personalized recipes just for you",
                        delay: 0.4
                    )

                    FeatureHighlightRow(
                        icon: "heart.text.square.fill",
                        title: "Personalized Nutrition",
                        description: "Match your health goals",
                        delay: 0.5
                    )

                    FeatureHighlightRow(
                        icon: "cart.fill",
                        title: "Smart Grocery Lists",
                        description: "Shop efficiently every week",
                        delay: 0.6
                    )
                }
                .padding(.horizontal, Design.Spacing.lg)

                Spacer()
                    .frame(height: Design.Spacing.md)
            }
            .padding(.horizontal)
        }
        .onAppear {
            withAnimation(Design.Animation.bouncy) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }
}

// MARK: - Feature Highlight Row
struct FeatureHighlightRow: View {
    let icon: String
    let title: String
    let description: String
    let delay: Double

    @State private var appeared = false

    var body: some View {
        HStack(spacing: Design.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.mintLight)
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.accentPurple)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Design.Typography.headline)
                    .foregroundStyle(Color.textPrimary)

                Text(description)
                    .font(Design.Typography.caption)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()
        }
        .padding(Design.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Design.Radius.md)
                .fill(Color.cardBackground.opacity(0.8))
        )
        .offset(x: appeared ? 0 : -30)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(Design.Animation.bouncy.delay(delay)) {
                appeared = true
            }
        }
    }
}
