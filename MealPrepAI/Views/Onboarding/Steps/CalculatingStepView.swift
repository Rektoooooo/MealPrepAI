import SwiftUI

struct CalculatingStepView: View {
    let onComplete: () -> Void

    @State private var progress: Double = 0
    @State private var currentMessage = "Analyzing your preferences..."
    @State private var appeared = false
    @State private var foodIndex = 0

    private let messages = [
        "Analyzing your preferences...",
        "Calculating your macros...",
        "Finding perfect recipes...",
        "Building your meal plan..."
    ]

    private let foods = ["🥗", "🍱", "🥑", "🍳", "🍕", "🌮", "🍜", "🍣", "🥗", "🍱"]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Progress ring
            AnimatedProgressRing(
                progress: progress,
                lineWidth: 10,
                size: 150
            )
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.8)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxxl)

            // Title
            Text("Creating your plan")
                .font(OnboardingDesign.Typography.title)
                .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                .opacity(appeared ? 1 : 0)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.md)

            // Dynamic message
            Text(currentMessage)
                .font(OnboardingDesign.Typography.subheadline)
                .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                .opacity(appeared ? 1 : 0)
                .animation(.easeInOut, value: currentMessage)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxxl)

            // Stats
            VStack(spacing: OnboardingDesign.Spacing.sm) {
                HStack(spacing: OnboardingDesign.Spacing.xs) {
                    Text("1,000+")
                        .font(OnboardingDesign.Typography.headline)
                        .foregroundStyle(OnboardingDesign.Colors.accent)
                    Text("meal plans created every day")
                        .font(OnboardingDesign.Typography.subheadline)
                        .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                }
            }
            .opacity(appeared ? 1 : 0)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxl)

            // Food carousel
            HStack(spacing: OnboardingDesign.Spacing.md) {
                ForEach(0..<5) { index in
                    let actualIndex = (foodIndex + index) % foods.count
                    Text(foods[actualIndex])
                        .font(.system(size: 40))
                        .frame(width: 56, height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(OnboardingDesign.Colors.cardBackground)
                        )
                }
            }
            .opacity(appeared ? 1 : 0)

            Spacer()
        }
        .padding(.horizontal, OnboardingDesign.Spacing.xl)
        .onboardingBackground()
        .onAppear {
            withAnimation(OnboardingDesign.Animation.bouncy) {
                appeared = true
            }
        }
        .task {
            // Progress animation
            withAnimation(.linear(duration: 3.0)) {
                progress = 1.0
            }

            // Message cycling
            for (index, message) in messages.enumerated() {
                if index > 0 {
                    try? await Task.sleep(for: .milliseconds(750))
                    guard !Task.isCancelled else { return }
                }
                withAnimation {
                    currentMessage = message
                }
            }

            // Wait for remaining animation time then complete
            let messageTime = Double(messages.count - 1) * 0.75
            let remaining = max(0, 3.2 - messageTime)
            try? await Task.sleep(for: .seconds(remaining))
            guard !Task.isCancelled else { return }
            onComplete()
        }
        .task {
            // Food carousel — auto-cancelled when view disappears
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }
                withAnimation {
                    foodIndex = (foodIndex + 1) % foods.count
                }
            }
        }
    }
}

#Preview {
    CalculatingStepView(onComplete: {})
}
