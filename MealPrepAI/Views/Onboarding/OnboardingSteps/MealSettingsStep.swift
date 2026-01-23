import SwiftUI

// MARK: - Step 8: Meal Settings
struct MealSettingsStep: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var showCelebration = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Design.Spacing.xl) {
                OnboardingHeader(
                    icon: "slider.horizontal.3",
                    title: "Meal Settings",
                    subtitle: "Configure how many meals you'd like each day."
                )

                // Meals per Day
                VStack(alignment: .leading, spacing: Design.Spacing.md) {
                    Text("Meals per day")
                        .font(Design.Typography.headline)
                        .foregroundStyle(Color.textPrimary)

                    HStack(spacing: Design.Spacing.sm) {
                        ForEach(2...4, id: \.self) { count in
                            PremiumSelectionButton(
                                title: "\(count) Meals",
                                isSelected: viewModel.mealsPerDay == count
                            ) {
                                hapticSelection()
                                withAnimation(Design.Animation.bouncy) {
                                    viewModel.mealsPerDay = count
                                }
                            }
                        }
                    }
                }
                .premiumCard()

                // Include Snacks Toggle
                HStack {
                    VStack(alignment: .leading, spacing: Design.Spacing.xxs) {
                        Text("Include Snacks")
                            .font(Design.Typography.headline)
                            .foregroundStyle(Color.textPrimary)
                        Text("Add 1-2 healthy snacks to your daily plan")
                            .font(Design.Typography.caption)
                            .foregroundStyle(Color.textSecondary)
                    }

                    Spacer()

                    Toggle("", isOn: $viewModel.includeSnacks)
                        .tint(Color.accentPurple)
                        .labelsHidden()
                }
                .premiumCard()

                // Daily Calories Card
                VStack(alignment: .leading, spacing: Design.Spacing.md) {
                    HStack {
                        Text("Daily Calorie Target")
                            .font(Design.Typography.headline)
                            .foregroundStyle(Color.textPrimary)
                        Spacer()
                        Text("\(viewModel.dailyCalorieTarget)")
                            .font(Design.Typography.title2)
                            .foregroundStyle(Color.accentPurple)
                            .contentTransition(.numericText(value: Double(viewModel.dailyCalorieTarget)))
                            .animation(.snappy, value: viewModel.dailyCalorieTarget)
                        Text("cal")
                            .font(Design.Typography.subheadline)
                            .foregroundStyle(Color.textSecondary)
                    }

                    // Custom styled slider track
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // Track background
                            Capsule()
                                .fill(Color.mintMedium.opacity(0.3))
                                .frame(height: 8)

                            // Filled track
                            Capsule()
                                .fill(LinearGradient.purpleButtonGradient)
                                .frame(width: geo.size.width * CGFloat(viewModel.dailyCalorieTarget - 1200) / CGFloat(4000 - 1200), height: 8)
                        }
                    }
                    .frame(height: 8)

                    Slider(value: Binding(
                        get: { Double(viewModel.dailyCalorieTarget) },
                        set: { viewModel.dailyCalorieTarget = Int($0) }
                    ), in: 1200...4000, step: 50)
                    .tint(.clear)

                    HStack {
                        Text("Recommended: \(viewModel.recommendedCalories) cal")
                            .font(Design.Typography.caption)
                            .foregroundStyle(Color.textSecondary)

                        Spacer()

                        Button(action: {
                            hapticSelection()
                            withAnimation(Design.Animation.bouncy) {
                                viewModel.dailyCalorieTarget = viewModel.recommendedCalories
                            }
                        }) {
                            Text("Use Recommended")
                                .font(Design.Typography.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.accentPurple)
                        }
                    }
                }
                .premiumCard()

                // Macro Preview Card
                VStack(alignment: .leading, spacing: Design.Spacing.md) {
                    Text("Daily Macros Preview")
                        .font(Design.Typography.headline)
                        .foregroundStyle(Color.textPrimary)

                    HStack(spacing: Design.Spacing.md) {
                        MacroPreviewItem(
                            label: "Protein",
                            value: "\(viewModel.proteinGrams)g",
                            color: .proteinColor,
                            icon: "p.circle.fill"
                        )

                        MacroPreviewItem(
                            label: "Carbs",
                            value: "\(viewModel.carbsGrams)g",
                            color: .carbColor,
                            icon: "c.circle.fill"
                        )

                        MacroPreviewItem(
                            label: "Fat",
                            value: "\(viewModel.fatGrams)g",
                            color: .fatColor,
                            icon: "f.circle.fill"
                        )
                    }
                }
                .premiumCard()

                // Celebration Card
                VStack(spacing: Design.Spacing.lg) {
                    ZStack {
                        // Background circles
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.accentPurple.opacity(0.1 - Double(index) * 0.03))
                                .frame(width: CGFloat(80 + index * 30), height: CGFloat(80 + index * 30))
                                .scaleEffect(showCelebration ? 1 : 0.5)
                                .animation(
                                    Design.Animation.bouncy.delay(Double(index) * 0.1),
                                    value: showCelebration
                                )
                        }

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.accentPurple, Color.mintVibrant],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(showCelebration ? 1 : 0)
                            .animation(Design.Animation.bouncy.delay(0.2), value: showCelebration)
                    }

                    VStack(spacing: Design.Spacing.xs) {
                        Text("You're all set!")
                            .font(Design.Typography.title2)
                            .foregroundStyle(Color.textPrimary)

                        Text("Tap 'Get Started' to generate your first personalized meal plan.")
                            .font(Design.Typography.subheadline)
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Design.Spacing.xl)
                .onAppear {
                    withAnimation {
                        showCelebration = true
                    }
                }
            }
            .padding(Design.Spacing.lg)
        }
    }

    private func hapticSelection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

// MARK: - Macro Preview Item
struct MacroPreviewItem: View {
    let label: String
    let value: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: Design.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(color)

            Text(value)
                .font(Design.Typography.headline)
                .foregroundStyle(Color.textPrimary)

            Text(label)
                .font(Design.Typography.captionSmall)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Design.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Design.Radius.sm)
                .fill(color.opacity(0.1))
        )
    }
}
