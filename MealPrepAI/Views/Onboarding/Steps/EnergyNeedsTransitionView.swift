import SwiftUI

struct EnergyNeedsTransitionView: View {
    let onContinue: () -> Void

    @State private var appeared = false
    @State private var heartPulsing = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(OnboardingDesign.Colors.accent.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .scaleEffect(heartPulsing ? 1.1 : 1.0)

                Circle()
                    .fill(OnboardingDesign.Colors.accent.opacity(0.3))
                    .frame(width: 90, height: 90)

                Image(systemName: "heart.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(OnboardingDesign.Colors.accent)
                    .scaleEffect(heartPulsing ? 1.1 : 1.0)
            }
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.5)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxxl)

            // Title
            Text("Energy needs")
                .font(OnboardingDesign.Typography.title)
                .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.md)

            // Subtitle
            Text("The next questions will help us calculate your daily energy needs")
                .font(OnboardingDesign.Typography.body)
                .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

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
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                heartPulsing = true
            }
        }
    }
}

#Preview {
    EnergyNeedsTransitionView(onContinue: {})
}
