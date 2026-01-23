import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = OnboardingViewModel()
    @State private var currentStep = 0
    @State private var showSaveErrorAlert = false

    var onComplete: (() -> Void)?

    private let totalSteps = 8
    private let stepTitles = [
        "Welcome",
        "About You",
        "Your Goals",
        "Diet",
        "Allergies",
        "Cuisines",
        "Cooking",
        "Finalize"
    ]

    init(onComplete: (() -> Void)? = nil) {
        self.onComplete = onComplete
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress Bar
            progressBar
                .padding(.top, Design.Spacing.sm)

            // Content
            TabView(selection: $currentStep) {
                WelcomeStep()
                    .tag(0)

                PersonalInfoStep(viewModel: viewModel)
                    .tag(1)

                GoalsStep(viewModel: viewModel)
                    .tag(2)

                DietaryRestrictionsStep(viewModel: viewModel)
                    .tag(3)

                AllergiesStep(viewModel: viewModel)
                    .tag(4)

                CuisinePreferencesStep(viewModel: viewModel)
                    .tag(5)

                CookingPreferencesStep(viewModel: viewModel)
                    .tag(6)

                MealSettingsStep(viewModel: viewModel)
                    .tag(7)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(Design.Animation.smooth, value: currentStep)

            // Navigation Buttons
            navigationButtons
        }
        .background(LinearGradient.mintBackgroundGradient.ignoresSafeArea())
        .alert("Unable to Save", isPresented: $showSaveErrorAlert) {
            Button("Try Again") {
                let success = viewModel.saveProfile(modelContext: modelContext)
                if success {
                    onComplete?()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("We couldn't save your profile. Please try again.")
        }
    }

    // MARK: - Segmented Pills Progress Bar
    private var progressBar: some View {
        VStack(spacing: Design.Spacing.sm) {
            // Segmented Pills
            HStack(spacing: Design.Spacing.xs) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Capsule()
                        .fill(step <= currentStep ? Color.accentPurple : Color.mintMedium.opacity(0.5))
                        .frame(height: step == currentStep ? 6 : 4)
                        .shadow(
                            color: step == currentStep ? Color.accentPurple.opacity(0.4) : .clear,
                            radius: 4,
                            y: 0
                        )
                        .animation(Design.Animation.bouncy, value: currentStep)
                }
            }
            .padding(.horizontal, Design.Spacing.lg)

            // Step Label
            Text(stepTitles[currentStep])
                .font(Design.Typography.caption)
                .foregroundStyle(Color.textSecondary)
                .contentTransition(.numericText())
                .animation(Design.Animation.quick, value: currentStep)
        }
        .padding(.vertical, Design.Spacing.sm)
    }

    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        HStack(spacing: Design.Spacing.md) {
            // Back Button
            if currentStep > 0 {
                Button(action: {
                    hapticFeedback(.light)
                    withAnimation(Design.Animation.smooth) {
                        currentStep -= 1
                    }
                }) {
                    HStack(spacing: Design.Spacing.xs) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                    }
                    .font(Design.Typography.headline)
                    .foregroundStyle(Color.accentPurple)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Design.Spacing.md)
                    .background(
                        Capsule()
                            .strokeBorder(Color.accentPurple.opacity(0.5), lineWidth: 1.5)
                            .background(Capsule().fill(Color.cardBackground))
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }

            // Continue / Get Started Button
            Button(action: {
                hapticFeedback(.medium)
                if currentStep < totalSteps - 1 {
                    withAnimation(Design.Animation.smooth) {
                        currentStep += 1
                    }
                } else {
                    // Save profile and complete onboarding
                    let success = viewModel.saveProfile(modelContext: modelContext)
                    if success {
                        onComplete?()
                    } else {
                        showSaveErrorAlert = true
                    }
                }
            }) {
                HStack(spacing: Design.Spacing.xs) {
                    Text(currentStep == totalSteps - 1 ? "Get Started" : "Continue")
                    if currentStep < totalSteps - 1 {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .font(Design.Typography.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Design.Spacing.md)
                .background(
                    Capsule()
                        .fill(LinearGradient.purpleButtonGradient)
                        .shadow(
                            color: Design.Shadow.purple.color,
                            radius: Design.Shadow.purple.radius,
                            y: Design.Shadow.purple.y
                        )
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, Design.Spacing.lg)
        .padding(.vertical, Design.Spacing.md)
        .padding(.bottom, Design.Spacing.sm)
    }

    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
