import SwiftUI

struct AvatarSelectionStepView: View {
    @Binding var selectedEmoji: String
    let onContinue: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: OnboardingDesign.Spacing.xl)

            // Header
            VStack(spacing: OnboardingDesign.Spacing.sm) {
                Text("Most important step...")
                    .font(OnboardingDesign.Typography.title)
                    .foregroundStyle(OnboardingDesign.Colors.textPrimary)

                Text("Pick your avatar")
                    .font(OnboardingDesign.Typography.subheadline)
                    .foregroundStyle(OnboardingDesign.Colors.textSecondary)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxl)

            // Avatar preview
            ZStack {
                Circle()
                    .fill(OnboardingDesign.Colors.accent.opacity(0.2))
                    .frame(width: 120, height: 120)

                Text(selectedEmoji)
                    .font(Design.Typography.iconLarge)
            }
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.8)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxl)

            // Avatar grid
            AvatarGrid(selectedEmoji: $selectedEmoji)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 30)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.lg)

            // Note
            Text("You can change it later")
                .font(OnboardingDesign.Typography.footnote)
                .foregroundStyle(OnboardingDesign.Colors.textMuted)
                .opacity(appeared ? 1 : 0)

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
    AvatarSelectionStepView(
        selectedEmoji: .constant("🍳"),
        onContinue: {}
    )
}
