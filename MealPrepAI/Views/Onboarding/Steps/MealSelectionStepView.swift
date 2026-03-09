import SwiftUI

struct MealSelectionStepView: View {
    @Binding var breakfastCount: Int
    @Binding var lunchCount: Int
    @Binding var dinnerCount: Int
    @Binding var snackCount: Int
    let onContinue: () -> Void

    @State private var appeared = false

    private var totalMeals: Int {
        breakfastCount + lunchCount + dinnerCount + snackCount
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            OnboardingStepHeader(
                "Your meals",
                subtitle: "How many of each meal do you want per day?"
            )
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .padding(.top, OnboardingDesign.Spacing.xl)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xxl)

            // Meal steppers
            VStack(spacing: OnboardingDesign.Spacing.md) {
                MealCountRow(
                    icon: "sunrise.fill",
                    iconColor: .orange,
                    title: "Breakfast",
                    count: $breakfastCount,
                    range: 0...2
                )

                MealCountRow(
                    icon: "sun.max.fill",
                    iconColor: .yellow,
                    title: "Lunch",
                    count: $lunchCount,
                    range: 0...2
                )

                MealCountRow(
                    icon: "moon.fill",
                    iconColor: .indigo,
                    title: "Dinner",
                    count: $dinnerCount,
                    range: 0...2
                )

                MealCountRow(
                    icon: "carrot.fill",
                    iconColor: .green,
                    title: "Snacks",
                    count: $snackCount,
                    range: 0...4
                )
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 30)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.lg)

            // Summary
            Text("\(totalMeals) meal\(totalMeals == 1 ? "" : "s") per day")
                .font(OnboardingDesign.Typography.body)
                .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                .opacity(appeared ? 1 : 0)

            Spacer()

            // CTA
            OnboardingCTAButton("Continue") {
                onContinue()
            }
            .disabled(totalMeals < 1)
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

// MARK: - Meal Count Row

private struct MealCountRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var count: Int
    let range: ClosedRange<Int>

    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 20
    @ScaledMetric(relativeTo: .title3) private var stepperButtonSize: CGFloat = 28

    var body: some View {
        HStack(spacing: OnboardingDesign.Spacing.md) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: iconSize))
                    .foregroundStyle(iconColor)
            }

            // Title
            Text(title)
                .font(OnboardingDesign.Typography.body)
                .foregroundStyle(OnboardingDesign.Colors.textPrimary)

            Spacer()

            // Stepper controls
            HStack(spacing: OnboardingDesign.Spacing.sm) {
                Button {
                    if count > range.lowerBound {
                        count -= 1
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: stepperButtonSize))
                        .foregroundStyle(count > range.lowerBound ? OnboardingDesign.Colors.textPrimary.opacity(0.6) : OnboardingDesign.Colors.textSecondary.opacity(0.3))
                }
                .disabled(count <= range.lowerBound)

                Text("\(count)")
                    .font(OnboardingDesign.Typography.title3)
                    .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                    .frame(width: 28, alignment: .center)
                    .monospacedDigit()

                Button {
                    if count < range.upperBound {
                        count += 1
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: stepperButtonSize))
                        .foregroundStyle(count < range.upperBound ? OnboardingDesign.Colors.accent : OnboardingDesign.Colors.textSecondary.opacity(0.3))
                }
                .disabled(count >= range.upperBound)
            }
        }
        .padding(OnboardingDesign.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: OnboardingDesign.Radius.sm)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
    }
}

#Preview {
    MealSelectionStepView(
        breakfastCount: .constant(1),
        lunchCount: .constant(1),
        dinnerCount: .constant(1),
        snackCount: .constant(2),
        onContinue: {}
    )
}
