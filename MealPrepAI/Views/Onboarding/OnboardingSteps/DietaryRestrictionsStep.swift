import SwiftUI

// MARK: - Step 4: Dietary Restrictions
struct DietaryRestrictionsStep: View {
    @Bindable var viewModel: OnboardingViewModel
    @FocusState private var isCustomFieldFocused: Bool

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Design.Spacing.xl) {
                OnboardingHeader(
                    icon: "leaf.fill",
                    title: "Dietary Restrictions",
                    subtitle: "Select any diets you follow. Skip if none apply."
                )

                // Info Banner
                HStack(spacing: Design.Spacing.sm) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(Color.accentPurple)
                    Text("We'll tailor recipes to match your dietary needs.")
                        .font(Design.Typography.caption)
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(Design.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: Design.Radius.md)
                        .fill(Color.mintLight)
                )

                // Options Grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: Design.Spacing.sm),
                    GridItem(.flexible(), spacing: Design.Spacing.sm)
                ], spacing: Design.Spacing.sm) {
                    ForEach(DietaryRestriction.allCases.filter { $0 != .none }) { restriction in
                        PremiumMultiSelectChip(
                            title: restriction.rawValue,
                            icon: restriction.icon,
                            isSelected: viewModel.dietaryRestrictions.contains(restriction)
                        ) {
                            hapticSelection()
                            withAnimation(Design.Animation.bouncy) {
                                if viewModel.dietaryRestrictions.contains(restriction) {
                                    viewModel.dietaryRestrictions.remove(restriction)
                                } else {
                                    viewModel.dietaryRestrictions.insert(restriction)
                                }
                            }
                        }
                    }
                }

                // Custom Diet Field
                VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                    Text("Other dietary needs?")
                        .font(Design.Typography.headline)
                        .foregroundStyle(Color.textPrimary)

                    TextField("e.g., Low sodium, FODMAP, Whole30...", text: $viewModel.customDietaryRestrictions)
                        .textFieldStyle(PremiumTextFieldStyle())
                        .focused($isCustomFieldFocused)

                    Text("Separate multiple items with commas")
                        .font(Design.Typography.captionSmall)
                        .foregroundStyle(Color.textSecondary)
                }
                .premiumCard()
            }
            .padding(Design.Spacing.lg)
        }
    }

    private func hapticSelection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
