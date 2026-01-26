import SwiftUI

// MARK: - Meal Prep Review Step
/// Step 5: Review preferences and generate the plan
struct MealPrepReviewStep: View {
    @Bindable var viewModel: MealPrepSetupViewModel
    let userProfile: UserProfile?
    let onGenerate: () -> Void

    @FocusState private var isTextFieldFocused: Bool

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

            Spacer()

            // Bottom Section
            VStack(spacing: OnboardingDesign.Spacing.md) {
                // Save as default toggle
                Toggle(isOn: $viewModel.saveAsDefault) {
                    HStack(spacing: OnboardingDesign.Spacing.sm) {
                        Image(systemName: "bookmark.fill")
                            .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                        Text("Save as my default preferences")
                            .font(OnboardingDesign.Typography.subheadline)
                            .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: OnboardingDesign.Colors.success))
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

    // MARK: - Profile Summary Card
    private func profileSummaryCard(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: OnboardingDesign.Spacing.md) {
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                Text("Your Profile")
                    .font(OnboardingDesign.Typography.headline)
                    .foregroundStyle(OnboardingDesign.Colors.textPrimary)
            }

            HStack(spacing: OnboardingDesign.Spacing.lg) {
                profileStat(
                    icon: "flame.fill",
                    value: "\(profile.dailyCalorieTarget)",
                    label: "Calories",
                    color: .orange
                )

                profileStat(
                    icon: "bolt.fill",
                    value: "\(profile.proteinGrams)g",
                    label: "Protein",
                    color: Color.accentPurple
                )

                profileStat(
                    icon: "clock.fill",
                    value: "\(profile.maxCookingTime.maxMinutes)m",
                    label: "Max Time",
                    color: Color.mintVibrant
                )
            }
        }
        .padding(OnboardingDesign.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: OnboardingDesign.Radius.lg)
                .fill(OnboardingDesign.Colors.unselectedBackground)
        )
    }

    private func profileStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: OnboardingDesign.Spacing.xs) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color)
            }

            Text(value)
                .font(OnboardingDesign.Typography.headline)
                .foregroundStyle(OnboardingDesign.Colors.textPrimary)

            Text(label)
                .font(OnboardingDesign.Typography.captionSmall)
                .foregroundStyle(OnboardingDesign.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
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

// MARK: - Preview
#Preview {
    MealPrepReviewStep(
        viewModel: MealPrepSetupViewModel(),
        userProfile: nil,
        onGenerate: {}
    )
    .onboardingBackground()
}
