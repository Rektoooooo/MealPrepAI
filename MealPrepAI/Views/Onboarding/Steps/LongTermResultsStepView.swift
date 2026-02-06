import SwiftUI

struct LongTermResultsStepView: View {
    let onContinue: () -> Void

    @State private var appeared = false
    @State private var chartAnimating = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Title
            VStack(spacing: OnboardingDesign.Spacing.sm) {
                Text("MealPrepAI creates")
                    .font(OnboardingDesign.Typography.title)
                    .foregroundStyle(OnboardingDesign.Colors.textPrimary)

                Text("long-term results")
                    .font(OnboardingDesign.Typography.title)
                    .foregroundStyle(OnboardingDesign.Colors.accent)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxxl)

            // Weight graph comparison
            WeightComparisonChart(isAnimating: chartAnimating)
                .frame(height: 220)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 30)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.lg)

            // Legend
            HStack(spacing: OnboardingDesign.Spacing.xl) {
                LegendItem(color: OnboardingDesign.Colors.textTertiary, label: "Traditional diet", isDashed: true)
                LegendItem(color: OnboardingDesign.Colors.accent, label: "MealPrepAI", isDashed: false)
            }
            .opacity(appeared ? 1 : 0)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxl)

            // Stats
            VStack(spacing: OnboardingDesign.Spacing.md) {
                Text("80%")
                    .font(OnboardingDesign.Typography.heroDisplay)
                    .foregroundStyle(OnboardingDesign.Colors.accent)

                Text("of MealPrepAI users maintain their\nprogress after 6 months")
                    .font(OnboardingDesign.Typography.body)
                    .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
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
                chartAnimating = true
            }
        }
    }
}

// MARK: - Weight Comparison Chart
private struct WeightComparisonChart: View {
    let isAnimating: Bool

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let chartLeft: CGFloat = 50
            let chartRight: CGFloat = 20
            let chartTop: CGFloat = 20
            let chartBottom: CGFloat = 30
            let chartWidth = width - chartLeft - chartRight
            let chartHeight = height - chartTop - chartBottom

            ZStack(alignment: .topLeading) {
                // Y-axis labels
                VStack(alignment: .trailing, spacing: 0) {
                    Text("Starting")
                        .font(OnboardingDesign.Typography.captionSmall)
                        .foregroundStyle(OnboardingDesign.Colors.textTertiary)
                        .lineLimit(1)
                        .fixedSize()

                    Spacer()

                    Text("Goal")
                        .font(OnboardingDesign.Typography.captionSmall)
                        .foregroundStyle(OnboardingDesign.Colors.textTertiary)
                        .lineLimit(1)
                        .fixedSize()
                }
                .frame(width: 50, height: chartHeight)
                .offset(y: chartTop)

                // Chart area
                ZStack {
                    // Grid lines
                    VStack(spacing: chartHeight / 4) {
                        ForEach(0..<5) { _ in
                            Rectangle()
                                .fill(OnboardingDesign.Colors.cardBorder)
                                .frame(height: 1)
                        }
                    }
                    .frame(width: chartWidth, height: chartHeight)

                    // Traditional diet line (yo-yo pattern)
                    Path { path in
                        let points: [(CGFloat, CGFloat)] = [
                            (0, 0.15),
                            (0.15, 0.35),
                            (0.25, 0.2),
                            (0.4, 0.45),
                            (0.55, 0.25),
                            (0.7, 0.4),
                            (0.85, 0.2),
                            (1.0, 0.3)
                        ]
                        path.move(to: CGPoint(x: 0, y: chartHeight * 0.15))
                        for point in points.dropFirst() {
                            path.addLine(to: CGPoint(x: chartWidth * point.0, y: chartHeight * point.1))
                        }
                    }
                    .trim(from: 0, to: isAnimating ? 1 : 0)
                    .stroke(OnboardingDesign.Colors.textTertiary, style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [8, 4]))
                    .frame(width: chartWidth, height: chartHeight)

                    // MealPrepAI line (steady decline, then maintain)
                    Path { path in
                        let points: [(CGFloat, CGFloat)] = [
                            (0, 0.15),
                            (0.12, 0.25),
                            (0.25, 0.4),
                            (0.4, 0.55),
                            (0.55, 0.7),
                            (0.7, 0.8),
                            (0.85, 0.85),
                            (1.0, 0.85)
                        ]
                        path.move(to: CGPoint(x: 0, y: chartHeight * 0.15))
                        for point in points.dropFirst() {
                            path.addLine(to: CGPoint(x: chartWidth * point.0, y: chartHeight * point.1))
                        }
                    }
                    .trim(from: 0, to: isAnimating ? 1 : 0)
                    .stroke(OnboardingDesign.Colors.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: chartWidth, height: chartHeight)
                }
                .offset(x: chartLeft, y: chartTop)

                // X-axis labels
                HStack {
                    Text("Now")
                        .font(OnboardingDesign.Typography.caption)
                        .foregroundStyle(OnboardingDesign.Colors.textTertiary)
                    Spacer()
                    Text("6 months")
                        .font(OnboardingDesign.Typography.caption)
                        .foregroundStyle(OnboardingDesign.Colors.textTertiary)
                }
                .frame(width: chartWidth)
                .offset(x: chartLeft, y: height - 10)

                // Weight label on Y-axis
                Text("Weight")
                    .font(OnboardingDesign.Typography.captionSmall)
                    .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                    .rotationEffect(.degrees(-90))
                    .offset(x: -5, y: height / 2 - 20)
            }
        }
        .padding(OnboardingDesign.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: OnboardingDesign.Radius.xl)
                .fill(OnboardingDesign.Colors.cardBackground)
        )
    }
}

// MARK: - Legend Item
private struct LegendItem: View {
    let color: Color
    let label: String
    var isDashed: Bool = false

    var body: some View {
        HStack(spacing: OnboardingDesign.Spacing.xs) {
            if isDashed {
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(color)
                            .frame(width: 5, height: 3)
                    }
                }
                .frame(width: 20)
            } else {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 20, height: 4)
            }

            Text(label)
                .font(OnboardingDesign.Typography.footnote)
                .foregroundStyle(OnboardingDesign.Colors.textSecondary)
        }
    }
}

#Preview {
    LongTermResultsStepView(onContinue: {})
}
