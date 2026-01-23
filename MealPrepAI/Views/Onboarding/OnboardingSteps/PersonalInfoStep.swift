import SwiftUI

// MARK: - Step 2: Personal Info
struct PersonalInfoStep: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Design.Spacing.xl) {
                OnboardingHeader(
                    icon: "person.fill",
                    title: "About You",
                    subtitle: "Tell us a bit about yourself so we can personalize your experience."
                )

                // Name Card
                VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                    Text("Name")
                        .font(Design.Typography.headline)
                        .foregroundStyle(Color.textPrimary)

                    TextField("Your name", text: $viewModel.name)
                        .textFieldStyle(PremiumTextFieldStyle())
                }
                .premiumCard()

                // Age & Gender Card
                VStack(alignment: .leading, spacing: Design.Spacing.lg) {
                    // Age Slider
                    VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                        HStack {
                            Text("Age")
                                .font(Design.Typography.headline)
                                .foregroundStyle(Color.textPrimary)
                            Spacer()
                            Text("\(viewModel.age)")
                                .font(Design.Typography.title3)
                                .foregroundStyle(Color.accentPurple)
                                .contentTransition(.numericText(value: Double(viewModel.age)))
                                .animation(.snappy, value: viewModel.age)
                        }

                        Slider(value: Binding(
                            get: { Double(viewModel.age) },
                            set: { viewModel.age = Int($0) }
                        ), in: 16...100, step: 1)
                        .tint(Color.accentPurple)
                    }

                    Divider()
                        .background(Color.mintMedium.opacity(0.3))

                    // Gender Selection
                    VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                        Text("Gender")
                            .font(Design.Typography.headline)
                            .foregroundStyle(Color.textPrimary)

                        HStack(spacing: Design.Spacing.sm) {
                            ForEach(Gender.allCases) { gender in
                                PremiumSelectionButton(
                                    title: gender.rawValue,
                                    isSelected: viewModel.gender == gender
                                ) {
                                    hapticSelection()
                                    withAnimation(Design.Animation.bouncy) {
                                        viewModel.gender = gender
                                    }
                                }
                            }
                        }
                    }
                }
                .premiumCard()

                // Height & Weight Card
                VStack(alignment: .leading, spacing: Design.Spacing.lg) {
                    // Height
                    VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                        HStack {
                            Text("Height")
                                .font(Design.Typography.headline)
                                .foregroundStyle(Color.textPrimary)
                            Spacer()
                            Text("\(Int(viewModel.heightCm)) cm")
                                .font(Design.Typography.title3)
                                .foregroundStyle(Color.accentPurple)
                                .contentTransition(.numericText(value: viewModel.heightCm))
                                .animation(.snappy, value: viewModel.heightCm)
                        }

                        Slider(value: $viewModel.heightCm, in: 120...220, step: 1)
                            .tint(Color.accentPurple)
                    }

                    Divider()
                        .background(Color.mintMedium.opacity(0.3))

                    // Weight
                    VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                        HStack {
                            Text("Weight")
                                .font(Design.Typography.headline)
                                .foregroundStyle(Color.textPrimary)
                            Spacer()
                            Text("\(Int(viewModel.weightKg)) kg")
                                .font(Design.Typography.title3)
                                .foregroundStyle(Color.accentPurple)
                                .contentTransition(.numericText(value: viewModel.weightKg))
                                .animation(.snappy, value: viewModel.weightKg)
                        }

                        Slider(value: $viewModel.weightKg, in: 30...200, step: 1)
                            .tint(Color.accentPurple)
                    }
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
