import SwiftUI

struct DesiredWeightStepView: View {
    @Binding var currentWeightKg: Double
    @Binding var targetWeightKg: Double
    @Binding var measurementSystem: MeasurementSystem
    let onContinue: () -> Void

    @State private var appeared = false

    private var currentWeightDisplay: Int {
        measurementSystem == .metric ? Int(currentWeightKg) : Int(currentWeightKg * 2.20462)
    }

    private var targetWeightDisplay: Int {
        measurementSystem == .metric ? Int(targetWeightKg) : Int(targetWeightKg * 2.20462)
    }

    private var weightDifference: Int {
        abs(currentWeightDisplay - targetWeightDisplay)
    }

    private var weightChangeText: String {
        let diff = currentWeightDisplay - targetWeightDisplay
        let unit = measurementSystem == .metric ? "kg" : "lbs"
        if diff > 0 {
            return "Lose \(weightDifference) \(unit)"
        } else if diff < 0 {
            return "Gain \(weightDifference) \(unit)"
        } else {
            return "Maintain weight"
        }
    }

    private var unit: String {
        measurementSystem == .metric ? "kg" : "lbs"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            OnboardingStepHeader(
                "Target weight",
                subtitle: "What weight do you want to reach?"
            )
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .padding(.top, OnboardingDesign.Spacing.xl)

            Spacer()

            // Current weight indicator
            HStack(spacing: OnboardingDesign.Spacing.xs) {
                Image(systemName: "scalemass")
                    .font(.system(size: 14))
                    .foregroundStyle(OnboardingDesign.Colors.textTertiary)
                Text("Current: \(currentWeightDisplay) \(unit)")
                    .font(OnboardingDesign.Typography.subheadline)
                    .foregroundStyle(OnboardingDesign.Colors.textSecondary)
            }
            .opacity(appeared ? 1 : 0)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxl)

            // Target weight picker with +/- buttons
            HStack(spacing: OnboardingDesign.Spacing.xl) {
                // Minus button
                WeightAdjustButton(icon: "minus", isEnabled: targetWeightKg > 30) {
                    adjustWeight(by: -1)
                }

                // Target weight display
                VStack(spacing: OnboardingDesign.Spacing.xxs) {
                    Text("\(targetWeightDisplay)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: targetWeightDisplay)

                    Text(unit)
                        .font(OnboardingDesign.Typography.title2)
                        .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                }
                .frame(minWidth: 140)

                // Plus button
                WeightAdjustButton(icon: "plus", isEnabled: targetWeightKg < 200) {
                    adjustWeight(by: 1)
                }
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 30)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxl)

            // Weight difference badge
            HStack(spacing: OnboardingDesign.Spacing.xs) {
                Image(systemName: weightChangeIcon)
                    .font(.system(size: 16, weight: .semibold))
                Text(weightChangeText)
                    .font(OnboardingDesign.Typography.headline)
            }
            .foregroundStyle(OnboardingDesign.Colors.textOnDark)
            .padding(.horizontal, OnboardingDesign.Spacing.lg)
            .padding(.vertical, OnboardingDesign.Spacing.sm)
            .background(
                Capsule()
                    .fill(OnboardingDesign.Colors.accent)
            )
            .opacity(appeared ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: weightChangeText)

            Spacer()

            // Privacy note
            PrivacyNote()
                .opacity(appeared ? 1 : 0)
                .padding(.bottom, OnboardingDesign.Spacing.md)

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
            // Initialize target weight if not set
            if targetWeightKg == 0 || targetWeightKg == 65 {
                targetWeightKg = max(30, currentWeightKg - 5) // Default to 5kg less
            }
            withAnimation(OnboardingDesign.Animation.bouncy.delay(0.2)) {
                appeared = true
            }
        }
    }

    private var weightChangeIcon: String {
        let diff = currentWeightDisplay - targetWeightDisplay
        if diff > 0 {
            return "arrow.down"
        } else if diff < 0 {
            return "arrow.up"
        } else {
            return "equal"
        }
    }

    private func adjustWeight(by amount: Double) {
        let newValue = targetWeightKg + amount
        if newValue >= 30 && newValue <= 200 {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            targetWeightKg = newValue
        }
    }
}

// MARK: - Weight Adjust Button
private struct WeightAdjustButton: View {
    let icon: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isEnabled ? OnboardingDesign.Colors.cardBackground : OnboardingDesign.Colors.cardBackground.opacity(0.5))
                    .frame(width: 64, height: 64)

                Circle()
                    .strokeBorder(isEnabled ? OnboardingDesign.Colors.cardBorder : OnboardingDesign.Colors.cardBorder.opacity(0.5), lineWidth: 1)
                    .frame(width: 64, height: 64)

                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(isEnabled ? OnboardingDesign.Colors.textPrimary : OnboardingDesign.Colors.textMuted)
            }
        }
        .disabled(!isEnabled)
        .buttonStyle(OnboardingScaleButtonStyle())
    }
}

#Preview {
    DesiredWeightStepView(
        currentWeightKg: .constant(80),
        targetWeightKg: .constant(70),
        measurementSystem: .constant(.metric),
        onContinue: {}
    )
}
