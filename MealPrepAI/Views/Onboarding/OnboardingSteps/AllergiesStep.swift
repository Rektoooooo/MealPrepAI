import SwiftUI

// MARK: - Step 5: Allergies
struct AllergiesStep: View {
    @Bindable var viewModel: OnboardingViewModel
    @FocusState private var isCustomFieldFocused: Bool

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Design.Spacing.xl) {
                OnboardingHeader(
                    icon: "exclamationmark.shield.fill",
                    title: "Food Allergies",
                    subtitle: "Select any allergies so we can keep you safe."
                )

                // Warning Banner
                HStack(spacing: Design.Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("We'll exclude all selected allergens from your meal plans.")
                        .font(Design.Typography.caption)
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(Design.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: Design.Radius.md)
                        .fill(Color.orange.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: Design.Radius.md)
                                .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                )

                // Options Grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: Design.Spacing.sm),
                    GridItem(.flexible(), spacing: Design.Spacing.sm)
                ], spacing: Design.Spacing.sm) {
                    ForEach(Allergy.allCases.filter { $0 != .none }) { allergy in
                        PremiumMultiSelectChip(
                            title: allergy.rawValue,
                            icon: allergy.icon,
                            isSelected: viewModel.allergies.contains(allergy)
                        ) {
                            hapticSelection()
                            withAnimation(Design.Animation.bouncy) {
                                if viewModel.allergies.contains(allergy) {
                                    viewModel.allergies.remove(allergy)
                                } else {
                                    viewModel.allergies.insert(allergy)
                                }
                            }
                        }
                    }
                }

                // Custom Allergy Field
                VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                    Text("Other allergies or intolerances?")
                        .font(Design.Typography.headline)
                        .foregroundStyle(Color.textPrimary)

                    TextField("e.g., Corn, Nightshades, Sulfites...", text: $viewModel.customAllergies)
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
