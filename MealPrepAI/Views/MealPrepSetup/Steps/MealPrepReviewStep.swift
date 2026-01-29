import SwiftUI
import SwiftData

// MARK: - Meal Prep Review Step
/// Step 5: Review preferences and generate the plan
struct MealPrepReviewStep: View {
    @Bindable var viewModel: MealPrepSetupViewModel
    let userProfile: UserProfile?
    let isSubscribed: Bool
    let onGenerate: () -> Void

    @Query(sort: \MealPlan.createdAt, order: .reverse)
    private var allMealPlans: [MealPlan]

    @FocusState private var isTextFieldFocused: Bool
    @State private var showingMacroEditor = false

    private var existingPlanRanges: [ExistingPlanRange] {
        allMealPlans.compactMap { plan in
            let start = plan.weekStartDate
            let end = Calendar.current.date(byAdding: .day, value: plan.planDuration - 1, to: start) ?? start
            return ExistingPlanRange(start: start, end: end)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            OnboardingStepHeader(
                "Ready to generate!",
                subtitle: "Review your preferences and create your meal plan"
            )
            .padding(.horizontal, OnboardingDesign.Spacing.lg)
            .padding(.top, OnboardingDesign.Spacing.lg)

            ScrollView(showsIndicators: false) {
                VStack(spacing: OnboardingDesign.Spacing.lg) {
                    // Plan Dates Card
                    planDatesCard

                    // Profile Summary Card
                    if let profile = userProfile {
                        profileSummaryCard(profile)
                    }

                    // This Week's Preferences Card
                    weeklyPreferencesCard

                    // Special Request Input
                    specialRequestInput
                }
                .padding(.horizontal, OnboardingDesign.Spacing.lg)
                .padding(.top, OnboardingDesign.Spacing.lg)
                .padding(.bottom, 150)
            }
            .sheet(isPresented: $viewModel.showingDatePicker) {
                DateRangePickerSheet(
                    selectedDate: $viewModel.selectedStartDate,
                    planDuration: $viewModel.planDuration,
                    existingPlanRanges: existingPlanRanges,
                    maxDuration: viewModel.maxDuration(isSubscribed: isSubscribed)
                )
            }

            Spacer()

            // Bottom Section
            VStack(spacing: OnboardingDesign.Spacing.md) {
                // Save as default toggle
                Toggle(isOn: $viewModel.saveAsDefault) {
                    HStack(spacing: OnboardingDesign.Spacing.sm) {
                        Image(systemName: "bookmark.fill")
                            .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                            .accessibilityHidden(true)
                        Text("Save as my default preferences")
                            .font(OnboardingDesign.Typography.subheadline)
                            .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: OnboardingDesign.Colors.success))
                .accessibilityValue(viewModel.saveAsDefault ? "On" : "Off")
                .padding(.horizontal, OnboardingDesign.Spacing.lg)

                // Generate Button
                OnboardingCTAButton("Generate My Meal Plan") {
                    isTextFieldFocused = false
                    onGenerate()
                }
                .padding(.horizontal, OnboardingDesign.Spacing.lg)
            }
            .padding(.bottom, OnboardingDesign.Spacing.xxl)
        }
    }

    // MARK: - Plan Dates Card
    private var planDatesCard: some View {
        VStack(alignment: .leading, spacing: OnboardingDesign.Spacing.md) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                Text("Plan Dates")
                    .font(OnboardingDesign.Typography.headline)
                    .foregroundStyle(OnboardingDesign.Colors.textPrimary)

                Spacer()

                Button(action: { viewModel.showingDatePicker = true }) {
                    HStack(spacing: OnboardingDesign.Spacing.xs) {
                        Text("Change")
                        Image(systemName: "chevron.right")
                    }
                    .font(OnboardingDesign.Typography.subheadline)
                    .foregroundStyle(OnboardingDesign.Colors.accent)
                }
            }

            Text(viewModel.formattedDateRange)
                .font(OnboardingDesign.Typography.title3)
                .foregroundStyle(OnboardingDesign.Colors.textPrimary)
        }
        .padding(OnboardingDesign.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: OnboardingDesign.Radius.lg)
                .fill(OnboardingDesign.Colors.unselectedBackground)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Plan dates: \(viewModel.formattedDateRange)")
    }

    // MARK: - Profile Summary Card
    private func profileSummaryCard(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: OnboardingDesign.Spacing.md) {
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                Text("Your Targets")
                    .font(OnboardingDesign.Typography.headline)
                    .foregroundStyle(OnboardingDesign.Colors.textPrimary)

                Spacer()

                // Edit button
                Button(action: { showingMacroEditor = true }) {
                    HStack(spacing: OnboardingDesign.Spacing.xs) {
                        Image(systemName: "slider.horizontal.3")
                        Text("Adjust")
                    }
                    .font(OnboardingDesign.Typography.subheadline)
                    .foregroundStyle(OnboardingDesign.Colors.accent)
                }
            }

            HStack(spacing: OnboardingDesign.Spacing.sm) {
                profileStat(
                    icon: "flame.fill",
                    value: "\(viewModel.effectiveCalories(profile: profile))",
                    label: "Calories",
                    color: .orange,
                    isOverridden: viewModel.overrideCalories != nil
                )

                profileStat(
                    icon: "bolt.fill",
                    value: "\(viewModel.effectiveProtein(profile: profile))g",
                    label: "Protein",
                    color: Color.accentPurple,
                    isOverridden: viewModel.overrideProtein != nil
                )

                profileStat(
                    icon: "leaf.fill",
                    value: "\(viewModel.effectiveCarbs(profile: profile))g",
                    label: "Carbs",
                    color: Color.carbColor,
                    isOverridden: viewModel.overrideCarbs != nil
                )

                profileStat(
                    icon: "drop.fill",
                    value: "\(viewModel.effectiveFat(profile: profile))g",
                    label: "Fat",
                    color: Color.fatColor,
                    isOverridden: viewModel.overrideFat != nil
                )
            }
        }
        .padding(OnboardingDesign.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: OnboardingDesign.Radius.lg)
                .fill(OnboardingDesign.Colors.unselectedBackground)
        )
        .sheet(isPresented: $showingMacroEditor) {
            MacroEditorSheet(viewModel: viewModel, profile: profile)
        }
    }

    private func profileStat(icon: String, value: String, label: String, color: Color, isOverridden: Bool = false) -> some View {
        VStack(spacing: OnboardingDesign.Spacing.xs) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(color)
            }
            .accessibilityHidden(true)

            Text(value)
                .font(OnboardingDesign.Typography.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(isOverridden ? color : OnboardingDesign.Colors.textPrimary)

            Text(label)
                .font(OnboardingDesign.Typography.captionSmall)
                .foregroundStyle(OnboardingDesign.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)\(isOverridden ? ", custom" : "")")
    }

    // MARK: - Weekly Preferences Card
    private var weeklyPreferencesCard: some View {
        VStack(alignment: .leading, spacing: OnboardingDesign.Spacing.md) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                Text("This Week's Preferences")
                    .font(OnboardingDesign.Typography.headline)
                    .foregroundStyle(OnboardingDesign.Colors.textPrimary)
            }

            VStack(alignment: .leading, spacing: OnboardingDesign.Spacing.sm) {
                // Weekly Focus
                if !viewModel.preferences.weeklyFocus.isEmpty {
                    preferenceRow(
                        label: "Focus",
                        value: viewModel.preferences.weeklyFocus.map { "\($0.emoji) \($0.rawValue)" }.joined(separator: ", ")
                    )
                }

                // Cooking Availability
                preferenceRow(
                    label: "Schedule",
                    value: "\(viewModel.preferences.weeklyBusyness.emoji) \(viewModel.preferences.weeklyBusyness.rawValue)"
                )

                // Exclusions
                if !viewModel.preferences.temporaryExclusions.isEmpty || !viewModel.preferences.customExclusions.isEmpty {
                    let exclusionText = viewModel.preferences.temporaryExclusionsForAPI.joined(separator: ", ")
                    preferenceRow(
                        label: "Avoiding",
                        value: exclusionText
                    )
                }
            }

            // Edit button
            Button(action: {
                viewModel.goToPreviousStep()
                viewModel.goToPreviousStep()
                viewModel.goToPreviousStep()
            }) {
                HStack(spacing: OnboardingDesign.Spacing.xs) {
                    Image(systemName: "pencil")
                    Text("Edit Preferences")
                }
                .font(OnboardingDesign.Typography.subheadline)
                .foregroundStyle(OnboardingDesign.Colors.accent)
            }
            .padding(.top, OnboardingDesign.Spacing.xs)
        }
        .padding(OnboardingDesign.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: OnboardingDesign.Radius.lg)
                .fill(OnboardingDesign.Colors.unselectedBackground)
        )
    }

    private func preferenceRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(OnboardingDesign.Typography.subheadline)
                .foregroundStyle(OnboardingDesign.Colors.textTertiary)
                .frame(width: 70, alignment: .leading)

            Text(value)
                .font(OnboardingDesign.Typography.subheadline)
                .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                .lineLimit(2)

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: - Special Request Input
    private var specialRequestInput: some View {
        VStack(alignment: .leading, spacing: OnboardingDesign.Spacing.sm) {
            HStack {
                Image(systemName: "text.bubble")
                    .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                Text("Special Requests")
                    .font(OnboardingDesign.Typography.headline)
                    .foregroundStyle(OnboardingDesign.Colors.textPrimary)

                Spacer()

                Text("Optional")
                    .font(OnboardingDesign.Typography.caption)
                    .foregroundStyle(OnboardingDesign.Colors.textTertiary)
            }

            TextField(
                "Any specific requests for this week?",
                text: $viewModel.specialRequest,
                axis: .vertical
            )
            .textFieldStyle(.plain)
            .lineLimit(3...5)
            .padding(OnboardingDesign.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: OnboardingDesign.Radius.md)
                    .fill(OnboardingDesign.Colors.unselectedBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: OnboardingDesign.Radius.md)
                            .strokeBorder(
                                isTextFieldFocused ? OnboardingDesign.Colors.accent : Color.clear,
                                lineWidth: 1.5
                            )
                    )
            )
            .focused($isTextFieldFocused)

            Text("Examples: \"More vegetarian options\", \"Include one pasta dish\", \"No repeats from last week\"")
                .font(OnboardingDesign.Typography.caption)
                .foregroundStyle(OnboardingDesign.Colors.textTertiary)
        }
        .padding(OnboardingDesign.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: OnboardingDesign.Radius.lg)
                .fill(OnboardingDesign.Colors.unselectedBackground)
        )
    }
}

// MARK: - Macro Editor Sheet
struct MacroEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: MealPrepSetupViewModel
    let profile: UserProfile

    // Local state for editing
    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var carbs: String = ""
    @State private var fat: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: OnboardingDesign.Spacing.lg) {
                Text("Adjust your macro targets for this meal plan")
                    .font(OnboardingDesign.Typography.subheadline)
                    .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(spacing: OnboardingDesign.Spacing.md) {
                    macroInput(
                        label: "Calories",
                        icon: "flame.fill",
                        color: .orange,
                        value: $calories,
                        unit: "kcal"
                    )

                    macroInput(
                        label: "Protein",
                        icon: "bolt.fill",
                        color: Color.accentPurple,
                        value: $protein,
                        unit: "g"
                    )

                    macroInput(
                        label: "Carbs",
                        icon: "leaf.fill",
                        color: Color.carbColor,
                        value: $carbs,
                        unit: "g"
                    )

                    macroInput(
                        label: "Fat",
                        icon: "drop.fill",
                        color: Color.fatColor,
                        value: $fat,
                        unit: "g"
                    )
                }
                .padding()

                // Reset button
                Button(action: resetToDefaults) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset to Profile Defaults")
                    }
                    .font(OnboardingDesign.Typography.subheadline)
                    .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                }
                .accessibilityHint("Resets all macro values to your profile defaults")
                .padding(.top)

                Spacer()
            }
            .padding(.top, OnboardingDesign.Spacing.lg)
            .navigationTitle("Adjust Macros")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            // Initialize with current values
            calories = "\(viewModel.effectiveCalories(profile: profile))"
            protein = "\(viewModel.effectiveProtein(profile: profile))"
            carbs = "\(viewModel.effectiveCarbs(profile: profile))"
            fat = "\(viewModel.effectiveFat(profile: profile))"
        }
        .presentationDetents([.medium])
    }

    private func macroInput(label: String, icon: String, color: Color, value: Binding<String>, unit: String) -> some View {
        HStack(spacing: OnboardingDesign.Spacing.md) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color)
            }
            .accessibilityHidden(true)

            Text(label)
                .font(OnboardingDesign.Typography.body)
                .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                .frame(width: 70, alignment: .leading)

            Spacer()

            HStack(spacing: OnboardingDesign.Spacing.xs) {
                TextField("0", text: value)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .font(OnboardingDesign.Typography.headline)
                    .frame(width: 80)
                    .padding(OnboardingDesign.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: OnboardingDesign.Radius.sm)
                            .fill(OnboardingDesign.Colors.unselectedBackground)
                    )

                Text(unit)
                    .font(OnboardingDesign.Typography.subheadline)
                    .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                    .frame(width: 35, alignment: .leading)
            }
        }
        .padding(.horizontal)
    }

    private func saveChanges() {
        // Parse and save overrides (only if different from profile)
        if let cal = Int(calories), cal != profile.dailyCalorieTarget {
            viewModel.overrideCalories = cal
        } else {
            viewModel.overrideCalories = nil
        }

        if let prot = Int(protein), prot != profile.proteinGrams {
            viewModel.overrideProtein = prot
        } else {
            viewModel.overrideProtein = nil
        }

        if let carb = Int(carbs), carb != profile.carbsGrams {
            viewModel.overrideCarbs = carb
        } else {
            viewModel.overrideCarbs = nil
        }

        if let fatVal = Int(fat), fatVal != profile.fatGrams {
            viewModel.overrideFat = fatVal
        } else {
            viewModel.overrideFat = nil
        }
    }

    private func resetToDefaults() {
        calories = "\(profile.dailyCalorieTarget)"
        protein = "\(profile.proteinGrams)"
        carbs = "\(profile.carbsGrams)"
        fat = "\(profile.fatGrams)"

        // Clear overrides
        viewModel.overrideCalories = nil
        viewModel.overrideProtein = nil
        viewModel.overrideCarbs = nil
        viewModel.overrideFat = nil
    }
}

// MARK: - Preview
#Preview {
    MealPrepReviewStep(
        viewModel: MealPrepSetupViewModel(),
        userProfile: nil,
        isSubscribed: false,
        onGenerate: {}
    )
    .onboardingBackground()
}
