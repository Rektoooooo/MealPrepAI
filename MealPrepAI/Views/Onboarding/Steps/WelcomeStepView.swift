import SwiftUI

struct WelcomeStepView: View {
    let onContinue: () -> Void
    let onLogin: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo and app name
            VStack(spacing: OnboardingDesign.Spacing.lg) {
                // App icon placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(OnboardingDesign.Colors.accent)
                        .frame(width: 100, height: 100)
                        .shadow(
                            color: OnboardingDesign.Shadow.button.color,
                            radius: OnboardingDesign.Shadow.button.radius,
                            y: OnboardingDesign.Shadow.button.y
                        )

                    Text("🍳")
                        .font(.system(size: 50))
                }
                .scaleEffect(appeared ? 1 : 0.5)
                .opacity(appeared ? 1 : 0)

                Text("MealPrepAI")
                    .font(OnboardingDesign.Typography.largeTitle)
                    .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
            }

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxxl)

            // Feature checklist
            VStack(alignment: .leading, spacing: OnboardingDesign.Spacing.md) {
                FeatureCheckItem(icon: "checkmark", text: "Plan", delay: 0.1, appeared: appeared)
                FeatureCheckItem(icon: "checkmark", text: "Shop", delay: 0.2, appeared: appeared)
                FeatureCheckItem(icon: "checkmark", text: "Cook", delay: 0.3, appeared: appeared)
                FeatureCheckItem(icon: "checkmark", text: "Track", delay: 0.4, appeared: appeared)
            }
            .opacity(appeared ? 1 : 0)

            Text("All in one place")
                .font(OnboardingDesign.Typography.subheadline)
                .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                .padding(.top, OnboardingDesign.Spacing.md)
                .opacity(appeared ? 1 : 0)

            Spacer()

            // Food image grid at bottom
            FoodImageGrid()
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 50)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xl)

            // CTA Button
            VStack(spacing: OnboardingDesign.Spacing.md) {
                OnboardingCTAButton("Get Started") {
                    onContinue()
                }

                Button {
                    onLogin()
                } label: {
                    HStack(spacing: 0) {
                        Text("Already have an account? ")
                            .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                        Text("Login")
                            .foregroundStyle(OnboardingDesign.Colors.accent)
                    }
                }
                .font(OnboardingDesign.Typography.subheadline)
            }
            .opacity(appeared ? 1 : 0)
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

// MARK: - Feature Check Item
private struct FeatureCheckItem: View {
    let icon: String
    let text: String
    let delay: Double
    let appeared: Bool

    var body: some View {
        HStack(spacing: OnboardingDesign.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(OnboardingDesign.Colors.accent)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(OnboardingDesign.Colors.accent.opacity(0.2))
                )

            Text(text)
                .font(OnboardingDesign.Typography.bodyMedium)
                .foregroundStyle(OnboardingDesign.Colors.textPrimary)
        }
        .offset(x: appeared ? 0 : -30)
        .opacity(appeared ? 1 : 0)
        .animation(OnboardingDesign.Animation.bouncy.delay(delay), value: appeared)
    }
}

// MARK: - Food Image Grid
private struct FoodImageGrid: View {
    let foods = ["🥗", "🍱", "🥑", "🍳", "🍕", "🌮", "🍜", "🍣"]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60), spacing: 12)], spacing: 12) {
            ForEach(foods, id: \.self) { food in
                Text(food)
                    .font(.system(size: 32))
                    .frame(width: 60, height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(OnboardingDesign.Colors.cardBackground)
                    )
            }
        }
        .padding(.horizontal, OnboardingDesign.Spacing.xl)
    }
}

#Preview {
    WelcomeStepView(onContinue: {}, onLogin: {})
}
