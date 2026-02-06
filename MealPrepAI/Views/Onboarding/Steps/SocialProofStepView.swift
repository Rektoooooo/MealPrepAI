import SwiftUI

struct SocialProofStepView: View {
    let onContinue: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Header
            VStack(spacing: OnboardingDesign.Spacing.md) {
                Text("You're in the right place")
                    .font(OnboardingDesign.Typography.title)
                    .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("🙌")
                    .font(Design.Typography.iconMedium)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxxl)

            // Stats
            VStack(spacing: OnboardingDesign.Spacing.sm) {
                Text("We've helped")
                    .font(OnboardingDesign.Typography.subheadline)
                    .foregroundStyle(OnboardingDesign.Colors.textSecondary)

                HStack(spacing: OnboardingDesign.Spacing.xs) {
                    Text("50,000+")
                        .font(OnboardingDesign.Typography.largeTitle)
                        .foregroundStyle(OnboardingDesign.Colors.accent)

                    Text("users")
                        .font(OnboardingDesign.Typography.title2)
                        .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                }

                Text("reach their nutrition goals")
                    .font(OnboardingDesign.Typography.subheadline)
                    .foregroundStyle(OnboardingDesign.Colors.textSecondary)
            }
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.9)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxxl)

            // Testimonial
            SocialProofCard(
                quote: "Finally an app that makes meal planning simple. I've lost 15 lbs and actually enjoy cooking now!",
                author: "Sarah M.",
                stars: 5
            )
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 30)

            Spacer()

            // CTA
            OnboardingCTAButton("Continue") {
                onContinue()
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

#Preview {
    SocialProofStepView(onContinue: {})
}
