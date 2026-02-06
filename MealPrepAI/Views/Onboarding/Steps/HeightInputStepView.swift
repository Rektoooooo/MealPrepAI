import SwiftUI

struct HeightInputStepView: View {
    @Binding var heightCm: Double
    @Binding var measurementSystem: MeasurementSystem
    let onContinue: () -> Void

    @State private var appeared = false
    @State private var unitIndex = 0  // 0 = cm, 1 = ft/in

    // Derived values for imperial
    private var feet: Int {
        let totalInches = heightCm / 2.54
        return Int(totalInches / 12)
    }

    private var inches: Int {
        let totalInches = heightCm / 2.54
        return Int(totalInches.truncatingRemainder(dividingBy: 12))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            OnboardingStepHeader(
                "Current height",
                subtitle: "Height is used to calculate your calories"
            )
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .padding(.top, OnboardingDesign.Spacing.xl)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xl)

            // Unit toggle
            OnboardingSegmentedControl(
                options: ["Centimeters", "Feet & Inches"],
                selection: $unitIndex
            )
            .onChange(of: unitIndex) { oldValue, newValue in
                measurementSystem = newValue == 0 ? .metric : .imperial
            }
            .opacity(appeared ? 1 : 0)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxl)

            // Height picker
            HeightPickerView(
                heightCm: $heightCm,
                isMetric: unitIndex == 0
            )
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 30)

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
            unitIndex = measurementSystem == .imperial ? 1 : 0
            withAnimation(OnboardingDesign.Animation.bouncy.delay(0.2)) {
                appeared = true
            }
        }
    }
}

// MARK: - Height Picker
private struct HeightPickerView: View {
    @Binding var heightCm: Double
    let isMetric: Bool

    private var displayValue: String {
        if isMetric {
            return "\(Int(heightCm))"
        } else {
            let totalInches = heightCm / 2.54
            let feet = Int(totalInches / 12)
            let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
            return "\(feet)'\(inches)\""
        }
    }

    private var unit: String {
        isMetric ? "cm" : ""
    }

    var body: some View {
        VStack(spacing: OnboardingDesign.Spacing.md) {
            // Display value
            HStack(alignment: .firstTextBaseline, spacing: OnboardingDesign.Spacing.xs) {
                Text(displayValue)
                    .font(OnboardingDesign.Typography.inputDisplay)
                    .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                    .contentTransition(.numericText())

                if !unit.isEmpty {
                    Text(unit)
                        .font(OnboardingDesign.Typography.title2)
                        .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                }
            }

            // Slider
            Slider(
                value: $heightCm,
                in: 100...250,
                step: 1
            )
            .tint(OnboardingDesign.Colors.accent)
            .padding(.horizontal, OnboardingDesign.Spacing.md)
        }
        .padding(OnboardingDesign.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: OnboardingDesign.Radius.xl)
                .fill(OnboardingDesign.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: OnboardingDesign.Radius.xl)
                .strokeBorder(OnboardingDesign.Colors.cardBorder, lineWidth: 1)
        )
    }
}

#Preview {
    HeightInputStepView(
        heightCm: .constant(170),
        measurementSystem: .constant(.metric),
        onContinue: {}
    )
}
