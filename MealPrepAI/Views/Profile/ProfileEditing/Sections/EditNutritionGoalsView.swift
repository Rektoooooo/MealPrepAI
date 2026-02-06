import SwiftUI
import SwiftData

struct EditNutritionGoalsView: View {
    @Bindable var profile: UserProfile
    @AppStorage("measurementSystem") private var measurementSystem: MeasurementSystem = .metric

    @State private var showRecalculateAlert = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Design.Spacing.lg) {
                // Daily Calories
                sectionCard(title: "Daily Calories", icon: "flame.fill", iconColor: Color.calorieColor) {
                    VStack(spacing: Design.Spacing.md) {
                        Text("\(profile.dailyCalorieTarget)")
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .foregroundStyle(Color.textPrimary)

                        Text("calories per day")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)

                        Stepper("", value: $profile.dailyCalorieTarget, in: 1000...5000, step: 50)
                            .labelsHidden()
                            .accessibilityLabel("Daily calorie target")
                            .accessibilityValue("\(profile.dailyCalorieTarget) calories")

                        HStack {
                            Button {
                                if profile.dailyCalorieTarget >= 1100 {
                                    profile.dailyCalorieTarget -= 100
                                }
                            } label: {
                                Text("-100")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color.accentPurple)
                                    .padding(.horizontal, Design.Spacing.md)
                                    .padding(.vertical, Design.Spacing.xs)
                                    .background(
                                        Capsule()
                                            .fill(Color.accentPurple.opacity(0.1))
                                    )
                            }
                            .accessibilityLabel("Decrease calories by 100")

                            Spacer()

                            Button {
                                if profile.dailyCalorieTarget <= 4900 {
                                    profile.dailyCalorieTarget += 100
                                }
                            } label: {
                                Text("+100")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color.accentPurple)
                                    .padding(.horizontal, Design.Spacing.md)
                                    .padding(.vertical, Design.Spacing.xs)
                                    .background(
                                        Capsule()
                                            .fill(Color.accentPurple.opacity(0.1))
                                    )
                            }
                            .accessibilityLabel("Increase calories by 100")
                        }
                    }
                }

                // Macros Section
                sectionCard(title: "Daily Macros", icon: "chart.pie.fill", iconColor: Color.accentPurple) {
                    VStack(spacing: Design.Spacing.lg) {
                        macroRow(
                            label: "Protein",
                            value: $profile.proteinGrams,
                            color: Color.proteinColor,
                            icon: "p.circle.fill",
                            range: 50...300
                        )

                        macroRow(
                            label: "Carbs",
                            value: $profile.carbsGrams,
                            color: Color.carbColor,
                            icon: "c.circle.fill",
                            range: 50...500
                        )

                        macroRow(
                            label: "Fat",
                            value: $profile.fatGrams,
                            color: Color.fatColor,
                            icon: "f.circle.fill",
                            range: 20...200
                        )

                        // Macro calories breakdown
                        macroCaloriesBreakdown
                    }
                }

                // Weight Goal
                sectionCard(title: "Weight Goal", icon: "target", iconColor: Color.mintVibrant) {
                    VStack(spacing: Design.Spacing.sm) {
                        ForEach(WeightGoal.allCases) { goal in
                            OnboardingSelectionCard(
                                title: goal.rawValue,
                                description: goal.description,
                                icon: goal.icon,
                                isSelected: profile.weightGoal == goal
                            ) {
                                profile.weightGoal = goal
                            }
                        }
                    }
                }

                // Target Weight (only for lose/gain goals)
                if profile.weightGoal != .maintain {
                    sectionCard(title: "Target Weight", icon: "scalemass.fill", iconColor: Color.accentBlue) {
                        VStack(spacing: Design.Spacing.md) {
                            let targetWeight = profile.targetWeightKg ?? profile.weightKg

                            if measurementSystem == .metric {
                                Text("\(Int(targetWeight)) kg")
                                    .font(.system(.title, design: .rounded, weight: .bold))
                                    .foregroundStyle(Color.textPrimary)

                                Slider(
                                    value: Binding(
                                        get: { profile.targetWeightKg ?? profile.weightKg },
                                        set: { profile.targetWeightKg = $0 }
                                    ),
                                    in: 30...200,
                                    step: 1
                                )
                                .tint(Color.accentPurple)
                            } else {
                                let lbs = targetWeight * 2.20462
                                Text("\(Int(lbs)) lbs")
                                    .font(.system(.title, design: .rounded, weight: .bold))
                                    .foregroundStyle(Color.textPrimary)

                                Slider(
                                    value: Binding(
                                        get: { profile.targetWeightKg ?? profile.weightKg },
                                        set: { profile.targetWeightKg = $0 }
                                    ),
                                    in: 30...200,
                                    step: 0.45359237
                                )
                                .tint(Color.accentPurple)
                            }

                            // Show difference
                            let diff = (profile.targetWeightKg ?? profile.weightKg) - profile.weightKg
                            let diffText = measurementSystem == .metric
                                ? "\(abs(Int(diff))) kg"
                                : "\(abs(Int(diff * 2.20462))) lbs"

                            Text(diff > 0 ? "Gain \(diffText)" : diff < 0 ? "Lose \(diffText)" : "No change")
                                .font(.subheadline)
                                .foregroundStyle(Color.textSecondary)
                        }
                    }

                    // Goal Pace
                    sectionCard(title: "Goal Pace", icon: "speedometer", iconColor: Color.accentOrange) {
                        VStack(spacing: Design.Spacing.sm) {
                            ForEach(GoalPace.allCases) { pace in
                                OnboardingSelectionCard(
                                    title: pace.rawValue,
                                    description: pace.description,
                                    icon: pace.icon,
                                    isSelected: profile.goalPace == pace
                                ) {
                                    profile.goalPace = pace
                                }
                            }
                        }
                    }
                }

                // Recalculate Button
                Button {
                    showRecalculateAlert = true
                } label: {
                    HStack(spacing: Design.Spacing.sm) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Recalculate from Profile")
                    }
                    .font(.headline)
                    .foregroundStyle(Color.accentPurple)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Design.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: Design.Radius.md)
                            .fill(Color.accentPurple.opacity(0.1))
                    )
                }
                .padding(.horizontal, Design.Spacing.md)
                .accessibilityLabel("Recalculate nutrition goals from profile")
                .accessibilityHint("Replaces custom values with calculated ones based on your physical stats")
            }
            .padding(.horizontal, Design.Spacing.md)
            .padding(.bottom, Design.Spacing.xxl)
        }
        .background(LinearGradient.mintBackgroundGradient.ignoresSafeArea())
        .navigationTitle("Nutrition Goals")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Recalculate Goals", isPresented: $showRecalculateAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Recalculate") {
                recalculateNutrition()
            }
        } message: {
            Text("This will recalculate your daily calories and macros based on your current physical stats and weight goal. Your custom values will be replaced.")
        }
    }

    // MARK: - Macro Row

    private func macroRow(
        label: String,
        value: Binding<Int>,
        color: Color,
        icon: String,
        range: ClosedRange<Int>
    ) -> some View {
        HStack(spacing: Design.Spacing.md) {
            Image(systemName: icon)
                .font(Design.Typography.title3)
                .foregroundStyle(color)
                .frame(width: 28)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .frame(width: 60, alignment: .leading)

            Spacer()

            HStack(spacing: Design.Spacing.sm) {
                Button {
                    if value.wrappedValue > range.lowerBound + 5 {
                        value.wrappedValue -= 5
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(Design.Typography.title2)
                        .foregroundStyle(color.opacity(0.7))
                }
                .accessibilityLabel("Decrease \(label)")
                .accessibilityHint("Decreases by 5 grams")

                Text("\(value.wrappedValue)g")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .frame(width: 60)

                Button {
                    if value.wrappedValue < range.upperBound - 5 {
                        value.wrappedValue += 5
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(Design.Typography.title2)
                        .foregroundStyle(color.opacity(0.7))
                }
                .accessibilityLabel("Increase \(label)")
                .accessibilityHint("Increases by 5 grams")
            }
        }
    }

    // MARK: - Macro Calories Breakdown

    private var macroCaloriesBreakdown: some View {
        let proteinCal = profile.proteinGrams * 4
        let carbsCal = profile.carbsGrams * 4
        let fatCal = profile.fatGrams * 9
        let totalMacroCal = proteinCal + carbsCal + fatCal

        return VStack(spacing: Design.Spacing.sm) {
            Divider()
                .accessibilityHidden(true)

            HStack {
                Text("Macro Calories")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                Spacer()
                Text("\(totalMacroCal) cal")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(totalMacroCal == profile.dailyCalorieTarget ? Color.mintVibrant : Color.accentOrange)
            }

            if totalMacroCal != profile.dailyCalorieTarget {
                let diff = profile.dailyCalorieTarget - totalMacroCal
                Text(diff > 0 ? "\(diff) cal under target" : "\(abs(diff)) cal over target")
                    .font(.caption)
                    .foregroundStyle(Color.accentOrange)
            }
        }
    }

    // MARK: - Section Card Builder

    private func sectionCard<Content: View>(
        title: String,
        icon: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            HStack(spacing: Design.Spacing.sm) {
                Image(systemName: icon)
                    .font(Design.Typography.footnote)
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
            }

            content()
        }
        .padding(Design.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Design.Radius.card)
                .fill(Color.cardBackground)
                .shadow(
                    color: Design.Shadow.card.color,
                    radius: Design.Shadow.card.radius,
                    y: Design.Shadow.card.y
                )
        )
    }

    // MARK: - Recalculate Nutrition

    private func recalculateNutrition() {
        // BMR using Mifflin-St Jeor Equation
        let bmr: Double
        switch profile.gender {
        case .male:
            bmr = (10 * profile.weightKg) + (6.25 * profile.heightCm) - (5 * Double(profile.age)) + 5
        case .female:
            bmr = (10 * profile.weightKg) + (6.25 * profile.heightCm) - (5 * Double(profile.age)) - 161
        case .other:
            bmr = (10 * profile.weightKg) + (6.25 * profile.heightCm) - (5 * Double(profile.age)) - 78
        }

        // Activity multiplier
        let activityMultiplier: Double
        switch profile.activityLevel {
        case .sedentary: activityMultiplier = 1.2
        case .light: activityMultiplier = 1.375
        case .moderate: activityMultiplier = 1.55
        case .active: activityMultiplier = 1.725
        case .extreme: activityMultiplier = 1.9
        }

        // TDEE
        var tdee = bmr * activityMultiplier

        // Adjust for weight goal
        switch profile.weightGoal {
        case .lose:
            switch profile.goalPace {
            case .gradual: tdee -= 250
            case .moderate: tdee -= 500
            case .aggressive: tdee -= 750
            }
        case .gain:
            switch profile.goalPace {
            case .gradual: tdee += 250
            case .moderate: tdee += 500
            case .aggressive: tdee += 750
            }
        case .maintain, .recomp:
            break
        }

        profile.dailyCalorieTarget = max(1200, Int(tdee))

        // Calculate macros (balanced approach)
        // Protein: 0.8-1g per lb of body weight (1.76-2.2g per kg)
        let proteinRatio: Double = profile.weightGoal == .gain ? 2.0 : 1.8
        profile.proteinGrams = Int(profile.weightKg * proteinRatio)

        // Fat: 25% of calories
        let fatCalories = Double(profile.dailyCalorieTarget) * 0.25
        profile.fatGrams = Int(fatCalories / 9)

        // Carbs: remaining calories
        let remainingCalories = profile.dailyCalorieTarget - (profile.proteinGrams * 4) - (profile.fatGrams * 9)
        profile.carbsGrams = max(50, Int(Double(remainingCalories) / 4))
    }
}


#Preview {
    NavigationStack {
        EditNutritionGoalsView(profile: UserProfile(name: "Test"))
    }
    .modelContainer(for: UserProfile.self, inMemory: true)
}
