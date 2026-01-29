import SwiftUI
import SwiftData

// MARK: - Meal Prep Setup View
/// Full-screen flow for collecting weekly meal prep preferences before generating a plan
struct MealPrepSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionManager.self) var subscriptionManager
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
            if !subscriptionManager.isSubscribed && (userProfile?.hasUsedFreeTrial == true) {
                showingPaywall = true
                SuperwallTracker.trackPaywallShown()
            }
            if !subscriptionManager.isSubscribed {
                viewModel.planDuration = 7
            }
        }
    }

    // MARK: - Paywall View
    private var paywallView: some View {
        PaywallStepView(
            onSubscribe: { plan in
                SuperwallTracker.trackPaywallSubscribeTapped(plan: plan.rawValue)
                Task {
                    let success = await subscriptionManager.purchase(plan: plan)
                    if success {
                        showingPaywall = false
                    }
                }
            },
            onRestorePurchases: {
                SuperwallTracker.trackRestoreTapped()
                Task {
                    await subscriptionManager.restore()
                    if subscriptionManager.isSubscribed {
                        showingPaywall = false
                    }
                }
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
                isSubscribed: subscriptionManager.isSubscribed,
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
            isSubscribed: subscriptionManager.isSubscribed,
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
