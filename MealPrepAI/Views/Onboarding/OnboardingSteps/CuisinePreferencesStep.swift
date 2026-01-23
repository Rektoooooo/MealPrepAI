import SwiftUI

// MARK: - Step 6: Cuisine Preferences
struct CuisinePreferencesStep: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Design.Spacing.xl) {
                OnboardingHeader(
                    icon: "globe.americas.fill",
                    title: "Favorite Cuisines",
                    subtitle: "Select cuisines you enjoy. We'll prioritize these in your meal plans."
                )

                // Selection Counter
                if !viewModel.preferredCuisines.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.accentPurple)
                        Text("\(viewModel.preferredCuisines.count) selected")
                            .font(Design.Typography.caption)
                            .foregroundStyle(Color.accentPurple)
                    }
                    .padding(.horizontal, Design.Spacing.md)
                    .padding(.vertical, Design.Spacing.xs)
                    .background(
                        Capsule()
                            .fill(Color.accentPurple.opacity(0.1))
                    )
                }

                // Options Grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: Design.Spacing.sm),
                    GridItem(.flexible(), spacing: Design.Spacing.sm),
                    GridItem(.flexible(), spacing: Design.Spacing.sm)
                ], spacing: Design.Spacing.sm) {
                    ForEach(CuisineType.allCases) { cuisine in
                        PremiumCuisineChip(
                            flag: cuisine.flag,
                            title: cuisine.rawValue,
                            isSelected: viewModel.preferredCuisines.contains(cuisine)
                        ) {
                            hapticSelection()
                            withAnimation(Design.Animation.bouncy) {
                                if viewModel.preferredCuisines.contains(cuisine) {
                                    viewModel.preferredCuisines.remove(cuisine)
                                } else {
                                    viewModel.preferredCuisines.insert(cuisine)
                                }
                            }
                        }
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
