import SwiftUI
import SwiftData

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var profile: UserProfile

    // Local state for editing (allows cancel without saving)
    @State private var editedName: String = ""
    @State private var editedEmoji: String = ""
    @State private var editedImageData: Data?
    @State private var hasChanges = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: Design.Spacing.lg) {
                    // Identity Section (inline)
                    identitySection

                    // Physical Stats Section
                    navigationSection(
                        title: "Physical Stats",
                        icon: "figure.stand",
                        iconColor: Color.accentBlue,
                        summary: physicalStatsSummary
                    ) {
                        EditPhysicalStatsView(profile: profile)
                    }

                    // Nutrition Goals Section
                    navigationSection(
                        title: "Nutrition Goals",
                        icon: "target",
                        iconColor: Color.mintVibrant,
                        summary: nutritionGoalsSummary
                    ) {
                        EditNutritionGoalsView(profile: profile)
                    }

                    // Dietary Preferences Section
                    navigationSection(
                        title: "Dietary Preferences",
                        icon: "leaf.fill",
                        iconColor: Color.lunchGradientEnd,
                        summary: dietaryPrefsSummary
                    ) {
                        EditDietaryPrefsView(profile: profile)
                    }

                    // Cooking Preferences Section
                    navigationSection(
                        title: "Cooking Preferences",
                        icon: "frying.pan.fill",
                        iconColor: Color.accentOrange,
                        summary: cookingPrefsSummary
                    ) {
                        EditCookingPrefsView(profile: profile)
                    }
                }
                .padding(.horizontal, Design.Spacing.md)
                .padding(.bottom, Design.Spacing.xxl)
            }
            .background(LinearGradient.mintBackgroundGradient.ignoresSafeArea())
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.textSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveChanges()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.accentPurple)
                }
            }
            .onAppear {
                loadCurrentValues()
            }
        }
    }

    // MARK: - Identity Section

    private var identitySection: some View {
        VStack(spacing: Design.Spacing.lg) {
            ProfileImagePicker(
                selectedEmoji: $editedEmoji,
                profileImageData: $editedImageData
            )
            .onChange(of: editedEmoji) { _, _ in hasChanges = true }
            .onChange(of: editedImageData) { _, _ in hasChanges = true }

            // Name TextField
            VStack(alignment: .leading, spacing: Design.Spacing.xs) {
                Text("Name")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)

                TextField("Your name", text: $editedName)
                    .font(.headline)
                    .padding(Design.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: Design.Radius.md)
                            .fill(Color.cardBackground)
                    )
                    .accessibilityLabel("Name")
                    .accessibilityValue(editedName.isEmpty ? "Empty" : editedName)
                    .onChange(of: editedName) { _, _ in hasChanges = true }
            }
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

    // MARK: - Navigation Section Builder

    private func navigationSection<Destination: View>(
        title: String,
        icon: String,
        iconColor: Color,
        summary: String,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: Design.Spacing.md) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(Design.Typography.bodyLarge)
                        .foregroundStyle(iconColor)
                }

                // Title and Summary
                VStack(alignment: .leading, spacing: Design.Spacing.xxs) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)

                    Text(summary)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(Design.Typography.footnote.weight(.semibold))
                    .foregroundStyle(Color.textSecondary.opacity(0.5))
                    .accessibilityHidden(true)
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
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens \(title) settings")
    }

    // MARK: - Summary Strings

    private var physicalStatsSummary: String {
        let gender = profile.gender.rawValue
        let age = profile.age
        let activity = profile.activityLevel.rawValue
        return "\(gender), \(age) years old, \(activity)"
    }

    private var nutritionGoalsSummary: String {
        let calories = profile.dailyCalorieTarget
        let goal = profile.weightGoal.rawValue
        return "\(calories) cal/day, \(goal)"
    }

    private var dietaryPrefsSummary: String {
        var parts: [String] = []

        if !profile.dietaryRestrictions.isEmpty {
            parts.append(profile.dietaryRestrictions.map { $0.rawValue }.joined(separator: ", "))
        }

        if !profile.allergies.isEmpty {
            parts.append("\(profile.allergies.count) allergies")
        }

        if !profile.foodDislikes.isEmpty {
            parts.append("\(profile.foodDislikes.count) dislikes")
        }

        return parts.isEmpty ? "No restrictions set" : parts.joined(separator: " · ")
    }

    private var cookingPrefsSummary: String {
        let skill = profile.cookingSkill.rawValue
        let time = profile.maxCookingTime.rawValue
        return "\(skill), \(time)"
    }

    // MARK: - Data Management

    private func loadCurrentValues() {
        editedName = profile.name
        editedEmoji = profile.avatarEmoji
        editedImageData = profile.profileImageData
    }

    private func saveChanges() {
        profile.name = editedName
        profile.avatarEmoji = editedEmoji
        profile.profileImageData = editedImageData
    }
}

#Preview {
    EditProfileView(profile: UserProfile(name: "John Doe"))
        .modelContainer(for: UserProfile.self, inMemory: true)
}
