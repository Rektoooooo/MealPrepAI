import SwiftUI
import SwiftData

// MARK: - Onboarding Steps Enum
enum OnboardingStep: Int, CaseIterable {
    // Launch (no progress bar)
    case launch = 0

    // Opening
    case socialProof

    // Goals
    case primaryGoals
    case weightGoal
    case longTermResults

    // Preferences
    case foodPreferences
    case allergies
    case dislikes

    // Metrics
    case energyNeedsTransition
    case weightInput
    case desiredWeight
    case realisticTarget
    case goalTimeline
    case ageInput
    case sexInput
    case heightInput
    case activityLevel

    // Culinary
    case cuisinePreferences
    case cookingSkills
    case pantry

    // Motivation & Value
    case appComparison
    case barriers
    case potential

    // Permissions
    case healthKit
    case notifications

    // Calculation
    case calculating
    case planReady

    // Account & Conversion
    case login
    case paywall

    var title: String {
        switch self {
        case .launch: return "Launch"
        case .socialProof: return "Social Proof"
        case .primaryGoals: return "Goals"
        case .weightGoal: return "Weight Goal"
        case .longTermResults: return "Long-term"
        case .foodPreferences: return "Diet"
        case .allergies: return "Allergies"
        case .dislikes: return "Dislikes"
        case .energyNeedsTransition: return "Energy"
        case .weightInput: return "Weight"
        case .desiredWeight: return "Target"
        case .realisticTarget: return "Target"
        case .goalTimeline: return "Timeline"
        case .ageInput: return "Age"
        case .sexInput: return "Sex"
        case .heightInput: return "Height"
        case .activityLevel: return "Activity"
        case .cuisinePreferences: return "Cuisine"
        case .cookingSkills: return "Skills"
        case .pantry: return "Pantry"
        case .appComparison: return "Benefits"
        case .barriers: return "Challenges"
        case .potential: return "Potential"
        case .healthKit: return "Health"
        case .notifications: return "Notifications"
        case .calculating: return "Creating"
        case .planReady: return "Ready"
        case .login: return "Save"
        case .paywall: return "Subscribe"
        }
    }

    // Whether this step should show in the progress bar (ALL steps except launch and paywall)
    var showsInProgress: Bool {
        switch self {
        case .launch, .paywall:
            return false
        default:
            return true
        }
    }

    // Whether this step should show a back button
    var showsBackButton: Bool {
        switch self {
        case .launch:
            return false
        default:
            return true
        }
    }
}

// MARK: - New Onboarding Container View
struct NewOnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthenticationManager.self) private var authManager
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(CloudKitSyncManager.self) private var syncManager
    @State private var viewModel = NewOnboardingViewModel()
    @State private var currentStep: OnboardingStep = .socialProof  // Skip launch - shown by RootView
    @State private var showSaveErrorAlert = false
    @State private var isNavigatingBack = false

    var onComplete: (() -> Void)?
    var onLogin: (() -> Void)?

    init(onComplete: (() -> Void)? = nil, onLogin: (() -> Void)? = nil) {
        self.onComplete = onComplete
        self.onLogin = onLogin
    }

    // Steps that show in progress bar
    private var progressSteps: [OnboardingStep] {
        OnboardingStep.allCases.filter { $0.showsInProgress }
    }

    private var progressIndex: Int {
        progressSteps.firstIndex(of: currentStep) ?? 0
    }

    var body: some View {
        ZStack {
            // Background - white
            OnboardingDesign.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with back button and progress bar (Cal AI style)
                if currentStep.showsInProgress {
                    HStack(spacing: OnboardingDesign.Spacing.md) {
                        // Back button
                        if currentStep.showsBackButton {
                            OnboardingBackButton {
                                goToPrevious()
                            }
                        }

                        // Progress bar
                        OnboardingProgressBar(
                            currentStep: progressIndex + 1,
                            totalSteps: progressSteps.count
                        )
                    }
                    .padding(.horizontal, OnboardingDesign.Spacing.xl)
                    .padding(.top, OnboardingDesign.Spacing.sm)
                } else if currentStep.showsBackButton {
                    // Show just the back button without progress bar (e.g., for paywall)
                    HStack {
                        OnboardingBackButton {
                            goToPrevious()
                        }
                        Spacer()
                    }
                    .padding(.horizontal, OnboardingDesign.Spacing.xl)
                    .padding(.top, OnboardingDesign.Spacing.sm)
                }

                // Content
                currentStepView
                    .id(currentStep)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(x: isNavigatingBack ? -50 : 50)),
                        removal: .opacity.combined(with: .offset(x: isNavigatingBack ? 50 : -50))
                    ))
            }
        }
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

    // MARK: - Step Views
    @ViewBuilder
    private var currentStepView: some View {
        switch currentStep {
        case .launch:
            LaunchScreenView(
                onGetStarted: { goToNext() },
                onSignIn: { onLogin?() }
            )

        case .socialProof:
            SocialProofStepView(onContinue: { goToNext() })

        case .primaryGoals:
            PrimaryGoalsStepView(
                selectedGoals: $viewModel.primaryGoals,
                onContinue: { goToNext() }
            )

        case .weightGoal:
            WeightGoalStepView(
                weightGoal: $viewModel.weightGoal,
                onContinue: { goToNext() }
            )

        case .longTermResults:
            LongTermResultsStepView(onContinue: { goToNext() })

        case .foodPreferences:
            FoodPreferencesStepView(
                dietaryRestriction: $viewModel.dietaryRestriction,
                onContinue: { goToNext() }
            )

        case .allergies:
            AllergiesStepView(
                selectedAllergies: $viewModel.allergies,
                onContinue: { goToNext() }
            )

        case .dislikes:
            DislikesStepView(
                selectedDislikes: $viewModel.foodDislikes,
                onContinue: { goToNext() }
            )

        case .energyNeedsTransition:
            EnergyNeedsTransitionView(onContinue: { goToNext() })

        case .weightInput:
            WeightInputStepView(
                weightKg: $viewModel.weightKg,
                measurementSystem: $viewModel.measurementSystem,
                onContinue: { goToNext() }
            )

        case .desiredWeight:
            DesiredWeightStepView(
                currentWeightKg: $viewModel.weightKg,
                targetWeightKg: $viewModel.targetWeightKg,
                measurementSystem: $viewModel.measurementSystem,
                onContinue: { goToNext() }
            )

        case .realisticTarget:
            RealisticTargetStepView(
                weightDifferenceKg: viewModel.weightDifferenceKg,
                measurementSystem: viewModel.measurementSystem,
                onContinue: { goToNext() }
            )

        case .goalTimeline:
            GoalTimelineStepView(
                goalPace: $viewModel.goalPace,
                weightDifferenceKg: viewModel.weightDifferenceKg,
                measurementSystem: viewModel.measurementSystem,
                onContinue: { goToNext() }
            )

        case .ageInput:
            AgeInputStepView(
                age: $viewModel.age,
                onContinue: { goToNext() }
            )

        case .sexInput:
            SexInputStepView(
                gender: $viewModel.gender,
                onContinue: { goToNext() }
            )

        case .heightInput:
            HeightInputStepView(
                heightCm: $viewModel.heightCm,
                measurementSystem: $viewModel.measurementSystem,
                onContinue: { goToNext() }
            )

        case .activityLevel:
            ActivityLevelStepView(
                activityLevel: $viewModel.activityLevel,
                onContinue: { goToNext() }
            )

        case .cuisinePreferences:
            CuisinePreferencesStepView(
                cuisinePreferences: $viewModel.cuisinePreferences,
                onContinue: { goToNext() }
            )

        case .cookingSkills:
            CookingSkillsStepView(
                cookingSkill: $viewModel.cookingSkill,
                onContinue: { goToNext() }
            )

        case .pantry:
            PantryStepView(
                pantryLevel: $viewModel.pantryLevel,
                onContinue: { goToNext() }
            )

        case .appComparison:
            AppComparisonStepView(onContinue: { goToNext() })

        case .barriers:
            BarriersStepView(
                selectedBarriers: $viewModel.barriers,
                onContinue: { goToNext() }
            )

        case .potential:
            PotentialStepView(
                weightDifferenceKg: viewModel.weightDifferenceKg,
                weeksToGoal: viewModel.weeksToGoal,
                onContinue: { goToNext() }
            )

        case .healthKit:
            HealthKitStepView(
                healthKitEnabled: $viewModel.healthKitEnabled,
                onContinue: { goToNext() },
                onSkip: { goToNext() }
            )

        case .notifications:
            NotificationsStepView(
                notificationsEnabled: $viewModel.notificationsEnabled,
                onContinue: { goToNext() },
                onSkip: { goToNext() }
            )

        case .calculating:
            CalculatingStepView(onComplete: { goToNext() })

        case .planReady:
            PlanReadyStepView(
                calculatedCalories: viewModel.recommendedCalories,
                weightKg: viewModel.weightKg,
                age: viewModel.age,
                gender: viewModel.gender,
                heightCm: viewModel.heightCm,
                weightGoal: viewModel.weightGoal,
                onContinue: { goToNext() }
            )

        case .login:
            LoginStepView(
                onSignInWithApple: {
                    // Capture user's name from Apple Sign In
                    if let fullName = authManager.userFullName {
                        let givenName = fullName.givenName ?? ""
                        let familyName = fullName.familyName ?? ""
                        viewModel.userName = [givenName, familyName]
                            .filter { !$0.isEmpty }
                            .joined(separator: " ")
                    }

                    // Enable CloudKit sync for signed-in users
                    if authManager.hasAppleID, let userID = authManager.currentUserID {
                        syncManager.enableSync(for: userID)
                    }

                    goToNext()
                },
                onContinueAsGuest: { goToNext() }
            )

        case .paywall:
            PaywallStepView(
                onSubscribe: { plan in
                    Task {
                        let success = await subscriptionManager.purchase(plan: plan)
                        if success {
                            let saved = viewModel.saveProfile(modelContext: modelContext)
                            if saved {
                                onComplete?()
                            } else {
                                showSaveErrorAlert = true
                            }
                        }
                    }
                },
                onRestorePurchases: {
                    Task {
                        await subscriptionManager.restore()
                        if subscriptionManager.isSubscribed {
                            let saved = viewModel.saveProfile(modelContext: modelContext)
                            if saved {
                                onComplete?()
                            } else {
                                showSaveErrorAlert = true
                            }
                        }
                    }
                }
            )
        }
    }

    // MARK: - Navigation
    private func goToNext() {
        let allSteps = OnboardingStep.allCases
        if let currentIndex = allSteps.firstIndex(of: currentStep),
           currentIndex < allSteps.count - 1 {
            isNavigatingBack = false
            withAnimation(OnboardingDesign.Animation.stepTransition) {
                currentStep = allSteps[currentIndex + 1]
            }
        }
    }

    private func goToPrevious() {
        // If on first real step (socialProof), go back to RootView's launch screen
        if currentStep == .socialProof {
            onLogin?()
            return
        }

        let allSteps = OnboardingStep.allCases
        if let currentIndex = allSteps.firstIndex(of: currentStep),
           currentIndex > 0 {
            // Skip the .launch step since it's handled by RootView
            let previousIndex = currentIndex - 1
            let previousStep = allSteps[previousIndex]

            if previousStep == .launch {
                // Go back to RootView's launch screen
                onLogin?()
            } else {
                isNavigatingBack = true
                withAnimation(OnboardingDesign.Animation.stepTransition) {
                    currentStep = previousStep
                }
            }
        }
    }
}

#Preview {
    NewOnboardingView()
        .modelContainer(for: UserProfile.self, inMemory: true)
        .environment(AuthenticationManager())
        .environment(CloudKitSyncManager())
}
