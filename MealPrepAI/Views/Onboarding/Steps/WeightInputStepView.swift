import SwiftUI

struct WeightInputStepView: View {
    @Binding var weightKg: Double
    @Binding var measurementSystem: MeasurementSystem
    let onContinue: () -> Void

    @State private var appeared = false
    @State private var unitIndex = 0  // 0 = kg, 1 = lb

    // Weight ranges
    private let kgRange = Array(stride(from: 30.0, through: 200.0, by: 0.5))
    private let lbRange = Array(stride(from: 66.0, through: 440.0, by: 1.0))

    private var displayWeight: Double {
        if unitIndex == 1 {
            return weightKg * 2.20462
        }
        return weightKg
    }

    private var currentRange: [Double] {
        unitIndex == 0 ? kgRange : lbRange
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            OnboardingStepHeader(
                "Current weight",
                subtitle: "Weight is used to calculate your calories"
            )
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .padding(.top, OnboardingDesign.Spacing.xl)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xl)

            // Unit toggle
            OnboardingSegmentedControl(
                options: ["Kilograms", "Pounds"],
                selection: $unitIndex
            )
            .onChange(of: unitIndex) { oldValue, newValue in
                measurementSystem = newValue == 0 ? .metric : .imperial
            }
            .opacity(appeared ? 1 : 0)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxl)

            // Weight picker
            WeightPickerView(
                weightKg: $weightKg,
                isMetric: unitIndex == 0
            )
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 30)

            Spacer()

            // Privacy note
            PrivacyNote("Used to calculate your calories. Stored privately.")
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

// MARK: - Weight Picker
private struct WeightPickerView: View {
    @Binding var weightKg: Double
    let isMetric: Bool

    private var displayValue: Int {
        isMetric ? Int(weightKg) : Int(weightKg * 2.20462)
    }

    private var unit: String {
        isMetric ? "kg" : "lb"
    }

    var body: some View {
        VStack(spacing: OnboardingDesign.Spacing.md) {
            // Display value
            HStack(alignment: .firstTextBaseline, spacing: OnboardingDesign.Spacing.xs) {
                Text("\(displayValue)")
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                    .contentTransition(.numericText())

                Text(unit)
                    .font(OnboardingDesign.Typography.title2)
                    .foregroundStyle(OnboardingDesign.Colors.textSecondary)
            }

            // Slider
            Slider(
                value: $weightKg,
                in: 30...200,
                step: 0.5
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
    WeightInputStepView(
        weightKg: .constant(70),
        measurementSystem: .constant(.metric),
        onContinue: {}
    )
}
