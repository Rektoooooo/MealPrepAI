import SwiftUI
import SwiftData

// MARK: - Meal Prep Setup View
/// Full-screen flow for collecting weekly meal prep preferences before generating a plan
struct MealPrepSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]

    @State private var viewModel: MealPrepSetupViewModel
    @Bindable var generator: MealPlanGenerator
    @State private var showingPaywall = false

    /// If true, skips the welcome screen and goes straight to customization
    let skipWelcome: Bool

    init(generator: MealPlanGenerator, skipWelcome: Bool = false) {
        self.generator = generator
        self.skipWelcome = skipWelcome
        self._viewModel = State(initialValue: MealPrepSetupViewModel(skipWelcome: skipWelcome))
    }

    private var userProfile: UserProfile? {
        userProfiles.first
    }

    var body: some View {
        ZStack {
            // Background
            OnboardingDesign.Colors.background
                .ignoresSafeArea()

            if showingPaywall {
                paywallView
            } else {
                VStack(spacing: 0) {
                    // Header with progress and back button
                    headerView

                    // Step Content
                    stepContent
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }

            // Loading overlay
            if viewModel.isGenerating {
                generatingOverlay
            }
        }
        .interactiveDismissDisabled(viewModel.isGenerating)
        .onAppear {
            // TESTING: Force subscription status for existing profiles
            if let profile = userProfile {
                profile.subscriptionStatus = "subscribed"
            }

            if let profile = userProfile, !profile.canCreatePlan {
                showingPaywall = true
            }
            // Lock free users to 7-day duration
            if let profile = userProfile, !profile.isSubscribed {
                viewModel.planDuration = 7
            }
        }
    }

    // MARK: - Paywall View
    private var paywallView: some View {
        PaywallStepView(
            onSubscribe: { _ in
                // For now, just simulate subscription
                if let profile = userProfile {
                    profile.subscriptionStatus = "subscribed"
                }
                showingPaywall = false
            },
            onRestorePurchases: {
                // Placeholder for restore logic
            }
        )
    }

    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: OnboardingDesign.Spacing.md) {
            // Top bar with back button and close
            HStack {
                // Back button (hidden on welcome)
                if viewModel.showBackButton {
                    OnboardingBackButton {
                        viewModel.goToPreviousStep()
                    }
                } else {
                    // Placeholder for alignment
                    Color.clear
                        .frame(width: 40, height: 40)
                }

                Spacer()

                // Close button
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(OnboardingDesign.Colors.cardBackground)
                        )
                }
                .disabled(viewModel.isGenerating)
            }
            .padding(.horizontal, OnboardingDesign.Spacing.md)
            .padding(.top, OnboardingDesign.Spacing.sm)

            // Progress bar (hidden on welcome)
            if viewModel.currentStep != .welcome {
                OnboardingProgressBar(
                    currentStep: viewModel.currentStep.rawValue,
                    totalSteps: MealPrepSetupStep.progressSteps
                )
                .padding(.horizontal, OnboardingDesign.Spacing.lg)
            }
        }
    }

    // MARK: - Step Content
    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .welcome:
            MealPrepWelcomeStep(viewModel: viewModel)

        case .weeklyFocus:
            WeeklyFocusStep(viewModel: viewModel)

        case .temporaryExclusions:
            TemporaryExclusionsStep(viewModel: viewModel)

        case .cookingAvailability:
            CookingAvailabilityStep(viewModel: viewModel)

        case .review:
            MealPrepReviewStep(
                viewModel: viewModel,
                userProfile: userProfile,
                onGenerate: generatePlan
            )
        }
    }

    // MARK: - Generating Overlay
    private var generatingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            GeneratingMealPlanView(progress: viewModel.generationProgress)
        }
        .transition(.opacity)
    }

    // MARK: - Actions
    private func generatePlan() {
        guard let profile = userProfile else { return }

        viewModel.generateMealPlan(
            for: profile,
            generator: generator,
            modelContext: modelContext
        ) {
            dismiss()
        }
    }
}

// MARK: - Preview
#Preview {
    MealPrepSetupView(generator: MealPlanGenerator())
        .modelContainer(for: [UserProfile.self, MealPlan.self], inMemory: true)
}
