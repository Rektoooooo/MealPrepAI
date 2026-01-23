import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = OnboardingViewModel()
    @State private var currentStep = 0

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
                    viewModel.saveProfile(modelContext: modelContext)
                    onComplete?()
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

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Onboarding Header Component
struct OnboardingHeader: View {
    let icon: String
    let title: String
    let subtitle: String

    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.sm) {
            HStack(spacing: Design.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.purpleButtonGradient)
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .scaleEffect(appeared ? 1 : 0.5)
                .opacity(appeared ? 1 : 0)

                Text(title)
                    .font(Design.Typography.title)
                    .foregroundStyle(Color.textPrimary)
                    .offset(x: appeared ? 0 : -10)
                    .opacity(appeared ? 1 : 0)
            }

            Text(subtitle)
                .font(Design.Typography.subheadline)
                .foregroundStyle(Color.textSecondary)
                .offset(y: appeared ? 0 : 10)
                .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(Design.Animation.bouncy.delay(0.1)) {
                appeared = true
            }
        }
        .onDisappear {
            appeared = false
        }
    }
}

// MARK: - Step 1: Welcome
struct WelcomeStep: View {
    @State private var appeared = false
    @State private var pulseAnimation = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Design.Spacing.lg) {
                Spacer()
                    .frame(height: Design.Spacing.md)

                // Hero Icon with Pulsing Glow
                ZStack {
                    // Outer glow pulse
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.accentPurple.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 40,
                                endRadius: 80
                            )
                        )
                        .frame(width: 140, height: 140)
                        .scaleEffect(pulseAnimation ? 1.1 : 0.9)
                        .opacity(pulseAnimation ? 0.6 : 0.3)

                    // Main circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.mintVibrant.opacity(0.4), Color.accentPurple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 110, height: 110)

                    // Icon
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 55))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accentPurple, Color.mintVibrant],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .scaleEffect(appeared ? 1 : 0.5)
                .opacity(appeared ? 1 : 0)

                // Text Content
                VStack(spacing: Design.Spacing.sm) {
                    Text("Welcome to")
                        .font(Design.Typography.title3)
                        .foregroundStyle(Color.textSecondary)

                    Text("MealPrepAI")
                        .font(Design.Typography.largeTitle)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accentPurple, Color.mintVibrant],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("Your personalized meal planning assistant powered by AI")
                        .font(Design.Typography.subheadline)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Design.Spacing.lg)
                }
                .offset(y: appeared ? 0 : 30)
                .opacity(appeared ? 1 : 0)

                Spacer()
                    .frame(height: Design.Spacing.md)

                // Feature Highlights
                VStack(spacing: Design.Spacing.sm) {
                    FeatureHighlightRow(
                        icon: "sparkles",
                        title: "AI-Powered Meal Plans",
                        description: "Personalized recipes just for you",
                        delay: 0.4
                    )

                    FeatureHighlightRow(
                        icon: "heart.text.square.fill",
                        title: "Personalized Nutrition",
                        description: "Match your health goals",
                        delay: 0.5
                    )

                    FeatureHighlightRow(
                        icon: "cart.fill",
                        title: "Smart Grocery Lists",
                        description: "Shop efficiently every week",
                        delay: 0.6
                    )
                }
                .padding(.horizontal, Design.Spacing.lg)

                Spacer()
                    .frame(height: Design.Spacing.md)
            }
            .padding(.horizontal)
        }
        .onAppear {
            withAnimation(Design.Animation.bouncy) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }
}

// MARK: - Feature Highlight Row
struct FeatureHighlightRow: View {
    let icon: String
    let title: String
    let description: String
    let delay: Double

    @State private var appeared = false

    var body: some View {
        HStack(spacing: Design.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.mintLight)
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.accentPurple)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Design.Typography.headline)
                    .foregroundStyle(Color.textPrimary)

                Text(description)
                    .font(Design.Typography.caption)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()
        }
        .padding(Design.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Design.Radius.md)
                .fill(Color.cardBackground.opacity(0.8))
        )
        .offset(x: appeared ? 0 : -30)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(Design.Animation.bouncy.delay(delay)) {
                appeared = true
            }
        }
    }
}

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

// MARK: - Step 3: Goals
struct GoalsStep: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Design.Spacing.xl) {
                OnboardingHeader(
                    icon: "target",
                    title: "Your Goals",
                    subtitle: "What would you like to achieve with your meal plan?"
                )

                // Weight Goal Section
                VStack(alignment: .leading, spacing: Design.Spacing.md) {
                    Text("Weight Goal")
                        .font(Design.Typography.headline)
                        .foregroundStyle(Color.textPrimary)

                    ForEach(WeightGoal.allCases) { goal in
                        PremiumGoalRow(
                            icon: goal.icon,
                            title: goal.rawValue,
                            description: goal.description,
                            isSelected: viewModel.weightGoal == goal
                        ) {
                            hapticSelection()
                            withAnimation(Design.Animation.bouncy) {
                                viewModel.weightGoal = goal
                            }
                        }
                    }
                }

                // Activity Level Section
                VStack(alignment: .leading, spacing: Design.Spacing.md) {
                    Text("Activity Level")
                        .font(Design.Typography.headline)
                        .foregroundStyle(Color.textPrimary)

                    ForEach(ActivityLevel.allCases) { level in
                        PremiumGoalRow(
                            icon: level.icon,
                            title: level.rawValue,
                            description: level.description,
                            isSelected: viewModel.activityLevel == level
                        ) {
                            hapticSelection()
                            withAnimation(Design.Animation.bouncy) {
                                viewModel.activityLevel = level
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

// MARK: - Step 7: Cooking Preferences
struct CookingPreferencesStep: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Design.Spacing.xl) {
                OnboardingHeader(
                    icon: "frying.pan.fill",
                    title: "Cooking Preferences",
                    subtitle: "Help us match recipes to your skill level and available time."
                )

                // Skill Level Section
                VStack(alignment: .leading, spacing: Design.Spacing.md) {
                    Text("Cooking Skill")
                        .font(Design.Typography.headline)
                        .foregroundStyle(Color.textPrimary)

                    ForEach(CookingSkill.allCases) { skill in
                        PremiumGoalRow(
                            icon: skill.icon,
                            title: skill.rawValue,
                            description: skill.description,
                            isSelected: viewModel.cookingSkill == skill
                        ) {
                            hapticSelection()
                            withAnimation(Design.Animation.bouncy) {
                                viewModel.cookingSkill = skill
                            }
                        }
                    }
                }

                // Max Cooking Time Section
                VStack(alignment: .leading, spacing: Design.Spacing.md) {
                    Text("Max Cooking Time")
                        .font(Design.Typography.headline)
                        .foregroundStyle(Color.textPrimary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Design.Spacing.sm) {
                            ForEach(CookingTime.allCases) { time in
                                PremiumTimeChip(
                                    title: time.rawValue,
                                    isSelected: viewModel.maxCookingTime == time
                                ) {
                                    hapticSelection()
                                    withAnimation(Design.Animation.bouncy) {
                                        viewModel.maxCookingTime = time
                                    }
                                }
                            }
                        }
                    }
                }

                // Simple Mode Toggle
                HStack {
                    VStack(alignment: .leading, spacing: Design.Spacing.xxs) {
                        Text("Simple Mode")
                            .font(Design.Typography.headline)
                            .foregroundStyle(Color.textPrimary)
                        Text("Prefer recipes with fewer ingredients and steps")
                            .font(Design.Typography.caption)
                            .foregroundStyle(Color.textSecondary)
                    }

                    Spacer()

                    Toggle("", isOn: $viewModel.simpleModeEnabled)
                        .tint(Color.accentPurple)
                        .labelsHidden()
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

// MARK: - Step 8: Meal Settings
struct MealSettingsStep: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var showCelebration = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Design.Spacing.xl) {
                OnboardingHeader(
                    icon: "slider.horizontal.3",
                    title: "Meal Settings",
                    subtitle: "Configure how many meals you'd like each day."
                )

                // Meals per Day
                VStack(alignment: .leading, spacing: Design.Spacing.md) {
                    Text("Meals per day")
                        .font(Design.Typography.headline)
                        .foregroundStyle(Color.textPrimary)

                    HStack(spacing: Design.Spacing.sm) {
                        ForEach(2...4, id: \.self) { count in
                            PremiumSelectionButton(
                                title: "\(count) Meals",
                                isSelected: viewModel.mealsPerDay == count
                            ) {
                                hapticSelection()
                                withAnimation(Design.Animation.bouncy) {
                                    viewModel.mealsPerDay = count
                                }
                            }
                        }
                    }
                }
                .premiumCard()

                // Include Snacks Toggle
                HStack {
                    VStack(alignment: .leading, spacing: Design.Spacing.xxs) {
                        Text("Include Snacks")
                            .font(Design.Typography.headline)
                            .foregroundStyle(Color.textPrimary)
                        Text("Add 1-2 healthy snacks to your daily plan")
                            .font(Design.Typography.caption)
                            .foregroundStyle(Color.textSecondary)
                    }

                    Spacer()

                    Toggle("", isOn: $viewModel.includeSnacks)
                        .tint(Color.accentPurple)
                        .labelsHidden()
                }
                .premiumCard()

                // Daily Calories Card
                VStack(alignment: .leading, spacing: Design.Spacing.md) {
                    HStack {
                        Text("Daily Calorie Target")
                            .font(Design.Typography.headline)
                            .foregroundStyle(Color.textPrimary)
                        Spacer()
                        Text("\(viewModel.dailyCalorieTarget)")
                            .font(Design.Typography.title2)
                            .foregroundStyle(Color.accentPurple)
                            .contentTransition(.numericText(value: Double(viewModel.dailyCalorieTarget)))
                            .animation(.snappy, value: viewModel.dailyCalorieTarget)
                        Text("cal")
                            .font(Design.Typography.subheadline)
                            .foregroundStyle(Color.textSecondary)
                    }

                    // Custom styled slider track
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // Track background
                            Capsule()
                                .fill(Color.mintMedium.opacity(0.3))
                                .frame(height: 8)

                            // Filled track
                            Capsule()
                                .fill(LinearGradient.purpleButtonGradient)
                                .frame(width: geo.size.width * CGFloat(viewModel.dailyCalorieTarget - 1200) / CGFloat(4000 - 1200), height: 8)
                        }
                    }
                    .frame(height: 8)

                    Slider(value: Binding(
                        get: { Double(viewModel.dailyCalorieTarget) },
                        set: { viewModel.dailyCalorieTarget = Int($0) }
                    ), in: 1200...4000, step: 50)
                    .tint(.clear)

                    HStack {
                        Text("Recommended: \(viewModel.recommendedCalories) cal")
                            .font(Design.Typography.caption)
                            .foregroundStyle(Color.textSecondary)

                        Spacer()

                        Button(action: {
                            hapticSelection()
                            withAnimation(Design.Animation.bouncy) {
                                viewModel.dailyCalorieTarget = viewModel.recommendedCalories
                            }
                        }) {
                            Text("Use Recommended")
                                .font(Design.Typography.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.accentPurple)
                        }
                    }
                }
                .premiumCard()

                // Macro Preview Card
                VStack(alignment: .leading, spacing: Design.Spacing.md) {
                    Text("Daily Macros Preview")
                        .font(Design.Typography.headline)
                        .foregroundStyle(Color.textPrimary)

                    HStack(spacing: Design.Spacing.md) {
                        MacroPreviewItem(
                            label: "Protein",
                            value: "\(viewModel.proteinGrams)g",
                            color: .proteinColor,
                            icon: "p.circle.fill"
                        )

                        MacroPreviewItem(
                            label: "Carbs",
                            value: "\(viewModel.carbsGrams)g",
                            color: .carbColor,
                            icon: "c.circle.fill"
                        )

                        MacroPreviewItem(
                            label: "Fat",
                            value: "\(viewModel.fatGrams)g",
                            color: .fatColor,
                            icon: "f.circle.fill"
                        )
                    }
                }
                .premiumCard()

                // Celebration Card
                VStack(spacing: Design.Spacing.lg) {
                    ZStack {
                        // Background circles
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.accentPurple.opacity(0.1 - Double(index) * 0.03))
                                .frame(width: CGFloat(80 + index * 30), height: CGFloat(80 + index * 30))
                                .scaleEffect(showCelebration ? 1 : 0.5)
                                .animation(
                                    Design.Animation.bouncy.delay(Double(index) * 0.1),
                                    value: showCelebration
                                )
                        }

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.accentPurple, Color.mintVibrant],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(showCelebration ? 1 : 0)
                            .animation(Design.Animation.bouncy.delay(0.2), value: showCelebration)
                    }

                    VStack(spacing: Design.Spacing.xs) {
                        Text("You're all set!")
                            .font(Design.Typography.title2)
                            .foregroundStyle(Color.textPrimary)

                        Text("Tap 'Get Started' to generate your first personalized meal plan.")
                            .font(Design.Typography.subheadline)
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Design.Spacing.xl)
                .onAppear {
                    withAnimation {
                        showCelebration = true
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

// MARK: - Macro Preview Item
struct MacroPreviewItem: View {
    let label: String
    let value: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: Design.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(color)

            Text(value)
                .font(Design.Typography.headline)
                .foregroundStyle(Color.textPrimary)

            Text(label)
                .font(Design.Typography.captionSmall)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Design.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Design.Radius.sm)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Premium Reusable Components

struct PremiumTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(Design.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.md)
                    .fill(Color.mintLight)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Design.Radius.md)
                    .strokeBorder(Color.mintMedium.opacity(0.5), lineWidth: 1)
            )
    }
}

struct PremiumSelectionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Design.Typography.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : Color.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Design.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: Design.Radius.md)
                        .fill(isSelected ? AnyShapeStyle(LinearGradient.purpleButtonGradient) : AnyShapeStyle(Color.mintLight))
                        .shadow(
                            color: isSelected ? Design.Shadow.purple.color : .clear,
                            radius: isSelected ? 8 : 0,
                            y: isSelected ? 4 : 0
                        )
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct PremiumGoalRow: View {
    let icon: String
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Design.Spacing.md) {
                // Icon Circle
                ZStack {
                    Circle()
                        .fill(isSelected ? LinearGradient.purpleButtonGradient : LinearGradient(colors: [Color.mintLight, Color.mintLight], startPoint: .top, endPoint: .bottom))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : Color.accentPurple)
                }

                VStack(alignment: .leading, spacing: Design.Spacing.xxs) {
                    Text(title)
                        .font(Design.Typography.headline)
                        .foregroundStyle(Color.textPrimary)
                    Text(description)
                        .font(Design.Typography.caption)
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                // Checkmark
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.accentPurple : Color.mintMedium, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Color.accentPurple)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(Design.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.lg)
                    .fill(Color.cardBackground)
                    .shadow(
                        color: isSelected ? Design.Shadow.purple.color : Design.Shadow.sm.color,
                        radius: isSelected ? Design.Shadow.purple.radius : Design.Shadow.sm.radius,
                        y: isSelected ? Design.Shadow.purple.y : Design.Shadow.sm.y
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: Design.Radius.lg)
                    .strokeBorder(isSelected ? Color.accentPurple.opacity(0.5) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct PremiumMultiSelectChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Design.Spacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                }
                Text(title)
                    .font(Design.Typography.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundStyle(isSelected ? .white : Color.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Design.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.md)
                    .fill(isSelected ? AnyShapeStyle(LinearGradient.purpleButtonGradient) : AnyShapeStyle(Color.cardBackground))
                    .shadow(
                        color: isSelected ? Design.Shadow.purple.color : Design.Shadow.sm.color,
                        radius: isSelected ? 8 : Design.Shadow.sm.radius,
                        y: isSelected ? 4 : Design.Shadow.sm.y
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct PremiumCuisineChip: View {
    let flag: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Design.Spacing.xs) {
                Text(flag)
                    .font(.system(size: 28))
                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)

                Text(title)
                    .font(Design.Typography.captionSmall)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? .white : Color.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Design.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.md)
                    .fill(isSelected ? AnyShapeStyle(LinearGradient.purpleButtonGradient) : AnyShapeStyle(Color.cardBackground))
                    .shadow(
                        color: isSelected ? Design.Shadow.purple.color : Design.Shadow.sm.color,
                        radius: isSelected ? 8 : Design.Shadow.sm.radius,
                        y: isSelected ? 4 : Design.Shadow.sm.y
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: Design.Radius.md)
                    .strokeBorder(isSelected ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct PremiumTimeChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Design.Typography.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : Color.textPrimary)
                .padding(.horizontal, Design.Spacing.lg)
                .padding(.vertical, Design.Spacing.sm)
                .background(
                    Capsule()
                        .fill(isSelected ? AnyShapeStyle(LinearGradient.purpleButtonGradient) : AnyShapeStyle(Color.cardBackground))
                        .shadow(
                            color: isSelected ? Design.Shadow.purple.color : Design.Shadow.sm.color,
                            radius: isSelected ? 8 : Design.Shadow.sm.radius,
                            y: isSelected ? 4 : Design.Shadow.sm.y
                        )
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Legacy Components (kept for compatibility, updated styling)

struct OnboardingTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(Design.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.md)
                    .fill(Color.mintLight)
            )
    }
}

struct SelectionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        PremiumSelectionButton(title: title, isSelected: isSelected, action: action)
    }
}

struct GoalOptionRow: View {
    let icon: String
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        PremiumGoalRow(icon: icon, title: title, description: description, isSelected: isSelected, action: action)
    }
}

struct MultiSelectChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        PremiumMultiSelectChip(title: title, icon: icon, isSelected: isSelected, action: action)
    }
}

struct CuisineChip: View {
    let flag: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        PremiumCuisineChip(flag: flag, title: title, isSelected: isSelected, action: action)
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
