import SwiftUI

struct PotentialStepView: View {
    let weightDifferenceKg: Double
    let weeksToGoal: Int
    let onContinue: () -> Void

    @State private var appeared = false
    @State private var graphAnimating = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Title
            VStack(spacing: OnboardingDesign.Spacing.sm) {
                Text("You have great potential")
                    .font(OnboardingDesign.Typography.title)
                    .foregroundStyle(OnboardingDesign.Colors.textPrimary)

                Text("to crush your goal")
                    .font(OnboardingDesign.Typography.title)
                    .foregroundStyle(OnboardingDesign.Colors.accent)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxxl)

            // Progress projection graph
            ProgressProjectionView(
                weeksToGoal: weeksToGoal,
                isAnimating: graphAnimating
            )
            .frame(height: 180)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 30)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxl)

            // Encouragement message
            VStack(spacing: OnboardingDesign.Spacing.md) {
                Image(systemName: "star.fill")
                    .font(OnboardingDesign.Typography.largeTitle)
                    .foregroundStyle(OnboardingDesign.Colors.success)

                Text("Based on your goals and preferences,\nyou're set up for success!")
                    .font(OnboardingDesign.Typography.body)
                    .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(OnboardingDesign.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: OnboardingDesign.Radius.xl)
                    .fill(OnboardingDesign.Colors.success.opacity(0.1))
            )
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
            withAnimation(.easeOut(duration: 1.5).delay(0.5)) {
                graphAnimating = true
            }
        }
    }
}

// MARK: - Progress Projection View
private struct ProgressProjectionView: View {
    let weeksToGoal: Int
    let isAnimating: Bool

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            ZStack {
                // Background card
                RoundedRectangle(cornerRadius: OnboardingDesign.Radius.xl)
                    .fill(OnboardingDesign.Colors.cardBackground)

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Your 30-day projection")
                            .font(OnboardingDesign.Typography.footnote)
                            .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                        Spacer()
                    }
                    .padding(.horizontal, OnboardingDesign.Spacing.md)
                    .padding(.top, OnboardingDesign.Spacing.md)

                    // Graph area
                    ZStack {
                        // Grid lines
                        VStack(spacing: (height - 60) / 4) {
                            ForEach(0..<4) { _ in
                                Rectangle()
                                    .fill(OnboardingDesign.Colors.cardBorder)
                                    .frame(height: 1)
                            }
                        }
                        .padding(.horizontal, OnboardingDesign.Spacing.md)

                        // Progress curve
                        Path { path in
                            let startY = (height - 60) * 0.2
                            let endY = (height - 60) * 0.85
                            let graphWidth = width - OnboardingDesign.Spacing.md * 2

                            path.move(to: CGPoint(x: OnboardingDesign.Spacing.md, y: startY))

                            // Smooth curve down
                            path.addCurve(
                                to: CGPoint(x: graphWidth + OnboardingDesign.Spacing.md, y: endY),
                                control1: CGPoint(x: graphWidth * 0.3 + OnboardingDesign.Spacing.md, y: startY + (endY - startY) * 0.2),
                                control2: CGPoint(x: graphWidth * 0.7 + OnboardingDesign.Spacing.md, y: endY - (endY - startY) * 0.1)
                            )
                        }
                        .trim(from: 0, to: isAnimating ? 1 : 0)
                        .stroke(
                            LinearGradient(
                                colors: [OnboardingDesign.Colors.accent, OnboardingDesign.Colors.success],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )

                        // End point dot
                        if isAnimating {
                            Circle()
                                .fill(OnboardingDesign.Colors.success)
                                .frame(width: 12, height: 12)
                                .position(x: width - OnboardingDesign.Spacing.md, y: (height - 60) * 0.85)
                        }
                    }
                    .frame(height: height - 60)

                    // X-axis labels
                    HStack {
                        Text("Today")
                            .font(OnboardingDesign.Typography.captionSmall)
                            .foregroundStyle(OnboardingDesign.Colors.textTertiary)
                        Spacer()
                        Text("30 days")
                            .font(OnboardingDesign.Typography.captionSmall)
                            .foregroundStyle(OnboardingDesign.Colors.textTertiary)
                    }
                    .padding(.horizontal, OnboardingDesign.Spacing.md)
                    .padding(.bottom, OnboardingDesign.Spacing.sm)
                }
            }
        }
    }
}

#Preview {
    PotentialStepView(
        weightDifferenceKg: 10,
        weeksToGoal: 20,
        onContinue: {}
    )
}
