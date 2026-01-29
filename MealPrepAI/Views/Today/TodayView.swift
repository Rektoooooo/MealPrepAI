import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(HealthKitManager.self) var healthKitManager
    @Environment(NotificationManager.self) var notificationManager
    @Query(filter: #Predicate<MealPlan> { $0.isActive }, sort: \MealPlan.createdAt, order: .reverse)
    private var mealPlans: [MealPlan]
    @Query private var userProfiles: [UserProfile]

    @State private var selectedDate = Date()
    @State private var showingMealDetail = false
    @State private var animateCards = false
    @State private var showingGenerateSheet = false
    @State private var showingSwapSheet = false
    @State private var showingAddMealSheet = false
    @State private var showingNotifications = false
    @State private var selectedRecipe: Recipe?
    @State private var generator = MealPlanGenerator()

    private var currentMealPlan: MealPlan? {
        mealPlans.first
    }

    private var userProfile: UserProfile? {
        userProfiles.first
    }

    private var todaysMeals: [Meal] {
        guard let plan = currentMealPlan else { return [] }
        let calendar = Calendar.current

        // Find the day that matches selected date
        if let day = plan.sortedDays.first(where: { calendar.isDate($0.date, inSameDayAs: selectedDate) }) {
            return day.sortedMeals
        }
        return []
    }

    private var todaysDay: Day? {
        guard let plan = currentMealPlan else { return nil }
        let calendar = Calendar.current
        return plan.sortedDays.first(where: { calendar.isDate($0.date, inSameDayAs: selectedDate) })
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: Design.Spacing.lg) {
                    // Greeting Header
                    GreetingHeader(
                        userName: userProfile?.name ?? "Chef",
                        avatarEmoji: userProfile?.avatarEmoji,
                        profileImageData: userProfile?.profileImageData
                    )
                    .opacity(animateCards ? 1 : 0)
                    .offset(y: animateCards ? 0 : 20)

                    if currentMealPlan == nil {
                        // No meal plan - show generate prompt
                        emptyStateView
                            .opacity(animateCards ? 1 : 0)
                            .offset(y: animateCards ? 0 : 20)
                    } else {
                        // Progress Hero Card
                        progressHeroCard
                            .opacity(animateCards ? 1 : 0)
                            .offset(y: animateCards ? 0 : 20)

                        // Date Selector
                        dateSelector
                            .opacity(animateCards ? 1 : 0)
                            .offset(y: animateCards ? 0 : 20)

                        // Nutrition Progress
                        if let day = todaysDay, let profile = userProfile {
                            NutritionSummaryCard(
                                consumed: day.totalCalories,
                                target: profile.dailyCalorieTarget,
                                protein: day.totalProtein,
                                proteinTarget: profile.proteinGrams,
                                carbs: day.totalCarbs,
                                carbsTarget: profile.carbsGrams,
                                fat: day.totalFat,
                                fatTarget: profile.fatGrams
                            )
                            .opacity(animateCards ? 1 : 0)
                            .offset(y: animateCards ? 0 : 20)
                        }

                        // Today's Meals
                        mealsSection
                            .opacity(animateCards ? 1 : 0)
                            .offset(y: animateCards ? 0 : 20)

                        // Quick Actions
                        quickActions
                            .opacity(animateCards ? 1 : 0)
                            .offset(y: animateCards ? 0 : 20)
                    }
                }
                .padding(.horizontal, Design.Spacing.md)
                .padding(.bottom, Design.Spacing.xxl)
            }
            .background(LinearGradient.mintBackgroundGradient.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingNotifications = true }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(Color.textPrimary)

                            if notificationManager.hasUnread {
                                Circle()
                                    .fill(Color.accentPurple)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 2, y: -2)
                            }
                        }
                    }
                    .accessibilityLabel(notificationManager.hasUnread ? "Notifications, unread" : "Notifications")
                    .accessibilityHint("Double tap to view notifications")
                }
            }
            .navigationDestination(isPresented: $showingNotifications) {
                NotificationsView()
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                    animateCards = true
                }
            }
            .fullScreenCover(isPresented: $showingGenerateSheet) {
                MealPrepSetupView(generator: generator)
            }
            .sheet(isPresented: $showingSwapSheet) {
                SwapMealSheet(
                    meals: todaysMeals,
                    generator: generator,
                    userProfile: userProfile
                )
            }
            .sheet(isPresented: $showingAddMealSheet) {
                AddMealToTodaySheet(
                    day: todaysDay,
                    generator: generator,
                    userProfile: userProfile
                )
            }
            .sheet(item: $selectedRecipe) { recipe in
                RecipeDetailSheet(recipe: recipe)
            }
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        NewEmptyStateView(
            icon: "fork.knife.circle.fill",
            title: "No Meal Plan Yet",
            message: "Generate your personalized meal plan based on your preferences and nutritional goals.",
            buttonTitle: "Generate Meal Plan",
            buttonIcon: "sparkles",
            buttonStyle: .purple,
            onButtonTap: { showingGenerateSheet = true }
        )
        .frame(height: 400)
    }

    // MARK: - Progress Hero Card
    private var progressHeroCard: some View {
        HStack(spacing: Design.Spacing.md) {
            VStack(alignment: .leading, spacing: Design.Spacing.xxs) {
                Text(greeting)
                    .font(Design.Typography.title3)
                    .foregroundStyle(.white)

                Text("You've eaten \(mealsEaten) of \(todaysMeals.count) meals")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
            }

            Spacer()

            // Compact Circular Progress
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 4)
                    .frame(width: 44, height: 44)

                Circle()
                    .trim(from: 0, to: todaysMeals.isEmpty ? 0 : CGFloat(mealsEaten) / CGFloat(todaysMeals.count))
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: mealsEaten)

                Text(todaysMeals.isEmpty ? "0%" : "\(Int((Double(mealsEaten) / Double(todaysMeals.count)) * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, Design.Spacing.lg)
        .padding(.vertical, Design.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Design.Radius.lg)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "34C759"), Color(hex: "30D158")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color(hex: "34C759").opacity(0.4), radius: 12, y: 6)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(greeting) You've eaten \(mealsEaten) of \(todaysMeals.count) meals, \(todaysMeals.isEmpty ? "0" : "\(Int((Double(mealsEaten) / Double(todaysMeals.count)) * 100))") percent complete")
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning!"
        case 12..<17: return "Good afternoon!"
        case 17..<21: return "Good evening!"
        default: return "Good night!"
        }
    }

    private var mealsEaten: Int {
        todaysMeals.filter { $0.isEaten }.count
    }

    // MARK: - Date Selector
    private var dateSelector: some View {
        HStack {
            Button(action: { moveDate(by: -1) }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "212121"))
                    .padding(Design.Spacing.sm)
                    .background(
                        Circle()
                            .fill(Color(hex: "212121").opacity(0.1))
                    )
            }
            .accessibilityLabel("Previous day")

            Spacer()

            VStack(spacing: 2) {
                Text(selectedDate.formatted(.dateTime.weekday(.wide)))
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)

                Text(selectedDate.formatted(.dateTime.month(.wide).day()))
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(selectedDate.formatted(.dateTime.weekday(.wide).month(.wide).day()))

            Spacer()

            Button(action: { moveDate(by: 1) }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "212121"))
                    .padding(Design.Spacing.sm)
                    .background(
                        Circle()
                            .fill(Color(hex: "212121").opacity(0.1))
                    )
            }
            .accessibilityLabel("Next day")
        }
        .padding(.vertical, Design.Spacing.sm)
        .padding(.horizontal, Design.Spacing.md)
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

    // MARK: - Meals Section
    private var mealsSection: some View {
        VStack(spacing: Design.Spacing.md) {
            NewSectionHeader(title: "Today's Meals", icon: "fork.knife", iconColor: Color(hex: "212121"), showSeeAll: true)

            if todaysMeals.isEmpty {
                Text("No meals planned for this day")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Design.Spacing.xl)
                    .background(
                        RoundedRectangle(cornerRadius: Design.Radius.card)
                            .fill(Color.cardBackground)
                    )
            } else {
                ForEach(Array(todaysMeals.enumerated()), id: \.element.id) { index, meal in
                    TodayMealCard(
                        meal: meal,
                        onTap: {
                            if let recipe = meal.recipe {
                                selectedRecipe = recipe
                            }
                        },
                        onToggleEaten: {
                            toggleMealEaten(meal)
                        }
                    )
                    .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.1), value: animateCards)
                }
            }
        }
    }

    // MARK: - Quick Actions
    private var quickActions: some View {
        VStack(spacing: Design.Spacing.md) {
            NewSectionHeader(title: "Quick Actions", icon: "bolt.fill", iconColor: Color(hex: "212121"))

            HStack(spacing: Design.Spacing.sm) {
                QuickActionCard(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Swap",
                    color: Color(hex: "667EEA"),  // Purple-blue
                    action: { showingSwapSheet = true }
                )

                QuickActionCard(
                    icon: "cart.badge.plus",
                    title: "Add",
                    color: Color(hex: "34C759"),  // Green
                    action: { showingAddMealSheet = true }
                )

                QuickActionCard(
                    icon: "sparkles",
                    title: "New Plan",
                    color: Color(hex: "FF6B6B"),  // Coral red
                    action: { showingGenerateSheet = true }
                )
            }
        }
    }

    private func moveDate(by days: Int) {
        withAnimation(Design.Animation.smooth) {
            if let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
                selectedDate = newDate
            }
        }
    }

    private func toggleMealEaten(_ meal: Meal) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            meal.isEaten.toggle()

            if meal.isEaten {
                meal.eatenAt = Date()

                // Sync to HealthKit if enabled
                if userProfile?.healthKitEnabled == true && userProfile?.syncNutritionToHealth == true {
                    Task {
                        do {
                            let sampleIDs = try await healthKitManager.logMealNutrition(meal: meal)
                            meal.healthKitSampleIDs = sampleIDs
                            userProfile?.lastHealthKitSync = Date()
                        } catch {
                            print("Failed to sync meal to HealthKit: \(error)")
                        }
                    }
                }
            } else {
                meal.eatenAt = nil

                // Remove from HealthKit if enabled
                if userProfile?.healthKitEnabled == true,
                   let sampleIDs = meal.healthKitSampleIDs {
                    Task {
                        do {
                            try await healthKitManager.deleteMealNutrition(sampleIDs: sampleIDs)
                            meal.healthKitSampleIDs = nil
                        } catch {
                            print("Failed to remove meal from HealthKit: \(error)")
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Today Meal Card
struct TodayMealCard: View {
    let meal: Meal
    let onTap: () -> Void
    let onToggleEaten: () -> Void

    private var mealTypeIcon: String {
        switch meal.mealType {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "leaf.fill"
        }
    }

    // Colorful icons for meal types
    private var mealTypeIconColor: Color {
        switch meal.mealType {
        case .breakfast: return Color(hex: "FF9500")  // Orange sunrise
        case .lunch: return Color(hex: "FFCC00")      // Yellow sun
        case .dinner: return Color(hex: "5856D6")     // Purple night
        case .snack: return Color(hex: "FF2D55")      // Pink
        }
    }

    var body: some View {
        HStack(spacing: Design.Spacing.md) {
            // Tappable content area
            Button(action: onTap) {
                HStack(spacing: Design.Spacing.md) {
                    // Meal Type Icon - Colorful
                    ZStack {
                        Circle()
                            .fill(mealTypeIconColor.opacity(0.15))
                            .frame(width: 50, height: 50)

                        Image(systemName: mealTypeIcon)
                            .font(.system(size: 22))
                            .foregroundStyle(mealTypeIconColor)
                    }

                    // Meal Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(meal.mealType.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.textSecondary)

                        Text(meal.recipe?.name ?? "Unknown Recipe")
                            .font(.headline)
                            .foregroundStyle(Color.textPrimary)
                            .lineLimit(1)

                        HStack(spacing: Design.Spacing.sm) {
                            // Orange kcal
                            Label("\(meal.recipe?.calories ?? 0) kcal", systemImage: "flame.fill")
                                .font(.caption)
                                .foregroundStyle(Color(hex: "FF9500"))

                            if let recipe = meal.recipe {
                                // Gray time - show total time (prep + cook)
                                Label("\(recipe.totalTimeMinutes) min", systemImage: "clock")
                                    .font(.caption)
                                    .foregroundStyle(Color.textSecondary)
                            }
                        }
                    }

                    Spacer()
                }
            }
            .buttonStyle(.plain)

            // Completion Button - Green checkmark
            Button(action: onToggleEaten) {
                ZStack {
                    Circle()
                        .fill(meal.isEaten ? Color(hex: "34C759") : Color.clear)
                        .frame(width: 36, height: 36)

                    Circle()
                        .strokeBorder(meal.isEaten ? Color(hex: "34C759") : Color.textSecondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 36, height: 36)

                    if meal.isEaten {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .accessibilityLabel(meal.isEaten ? "Mark as not eaten" : "Mark as eaten")
            .accessibilityHint("Double tap to toggle")
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
        .opacity(meal.isEaten ? 0.8 : 1)
    }
}

// MARK: - Generate Meal Plan Sheet
struct GenerateMealPlanSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationManager.self) var notificationManager
    @Environment(SubscriptionManager.self) var subscriptionManager
    @Query private var userProfiles: [UserProfile]
    @Bindable var generator: MealPlanGenerator

    /// Weekly preferences text input for custom requests
    @State private var weeklyPreferences: String = ""
    @FocusState private var isTextFieldFocused: Bool

    private var userProfile: UserProfile? {
        userProfiles.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.mintBackgroundGradient.ignoresSafeArea()

                if generator.isGenerating {
                    // Beautiful loading state
                    GeneratingMealPlanView(progress: generator.progress)
                } else {
                    // Ready state
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: Design.Spacing.xl) {
                            Spacer(minLength: 40)

                            // Hero Icon
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.accentPurple.opacity(0.2), Color.accentPurple.opacity(0.05)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 120, height: 120)

                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.accentPurple.opacity(0.3), Color.accentPurple.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 90, height: 90)

                                Image(systemName: "sparkles")
                                    .font(.system(size: 40, weight: .medium))
                                    .foregroundStyle(Color.accentPurple)
                            }

                            VStack(spacing: Design.Spacing.sm) {
                                Text("Generate Your Meal Plan")
                                    .font(.system(.title3, weight: .bold))
                                    .foregroundStyle(Color.textPrimary)

                                Text("We'll create a personalized meal plan based on your dietary preferences and nutritional goals.")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, Design.Spacing.lg)
                            }

                            if let profile = userProfile {
                                // Profile summary card
                                VStack(spacing: Design.Spacing.sm) {
                                    HStack(spacing: Design.Spacing.lg) {
                                        ProfileStatBadge(
                                            icon: "flame.fill",
                                            value: "\(profile.dailyCalorieTarget)",
                                            label: "Calories",
                                            color: .orange
                                        )

                                        ProfileStatBadge(
                                            icon: "bolt.fill",
                                            value: "\(profile.proteinGrams)g",
                                            label: "Protein",
                                            color: Color.accentPurple
                                        )

                                        ProfileStatBadge(
                                            icon: "fork.knife",
                                            value: "\(profile.mealsPerDay)",
                                            label: "Meals",
                                            color: Color.mintVibrant
                                        )
                                    }
                                }
                                .padding(Design.Spacing.lg)
                                .background(
                                    RoundedRectangle(cornerRadius: Design.Radius.lg)
                                        .fill(Color.cardBackground)
                                        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
                                )
                                .padding(.horizontal)
                            }

                            // Weekly Preferences Input
                            VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                                HStack {
                                    Image(systemName: "text.bubble")
                                        .foregroundStyle(Color.accentPurple)
                                    Text("Weekly Preferences")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Color.textPrimary)
                                }

                                TextField("Any special requests this week?", text: $weeklyPreferences, axis: .vertical)
                                    .textFieldStyle(.plain)
                                    .lineLimit(3...5)
                                    .padding(Design.Spacing.md)
                                    .background(
                                        RoundedRectangle(cornerRadius: Design.Radius.md)
                                            .fill(Color.cardBackground)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: Design.Radius.md)
                                                    .strokeBorder(isTextFieldFocused ? Color.accentPurple : Color.gray.opacity(0.2), lineWidth: 1.5)
                                            )
                                    )
                                    .focused($isTextFieldFocused)

                                Text("Examples: \"No fish this week\", \"Budget-friendly\", \"Quick recipes only\"")
                                    .font(.caption)
                                    .foregroundStyle(Color.textSecondary)
                            }
                            .padding(.horizontal)

                            Spacer(minLength: 30)

                            // Generate Button
                            Button(action: generatePlan) {
                                HStack(spacing: Design.Spacing.sm) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 18, weight: .semibold))
                                    Text("Generate Meal Plan")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient.purpleButtonGradient
                                )
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: Design.Radius.lg))
                                .shadow(color: Color.accentPurple.opacity(0.4), radius: 15, y: 8)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, Design.Spacing.xl)
                        }
                    }
                }
            }
            .navigationTitle(generator.isGenerating ? "" : "New Meal Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if !generator.isGenerating {
                        Button("Cancel") { dismiss() }
                            .foregroundStyle(Color.accentPurple)
                    }
                }
            }
            .interactiveDismissDisabled(generator.isGenerating)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func generatePlan() {
        guard let profile = userProfile else { return }
        isTextFieldFocused = false

        Task {
            do {
                let preferences = weeklyPreferences.trimmingCharacters(in: .whitespacesAndNewlines)
                _ = try await generator.generateMealPlan(
                    for: profile,
                    startDate: Date(),
                    weeklyPreferences: preferences.isEmpty ? nil : preferences,
                    modelContext: modelContext
                )

                // Reschedule notifications for the new plan
                let descriptor = FetchDescriptor<MealPlan>(
                    predicate: #Predicate { $0.isActive },
                    sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
                )
                let activePlan = try? modelContext.fetch(descriptor).first
                notificationManager.rescheduleAllNotifications(
                    activePlan: activePlan,
                    isSubscribed: subscriptionManager.isSubscribed,
                    trialStartDate: profile.createdAt
                )

                dismiss()
            } catch {
                print("Failed to generate meal plan: \(error)")
            }
        }
    }
}

// MARK: - Profile Stat Badge
struct ProfileStatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)
            }

            Text(value)
                .font(.system(.body, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Generating Meal Plan View (Animated Loading)
struct GeneratingMealPlanView: View {
    let progress: String

    @State private var isAnimating = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var rotationAngle: Double = 0
    @State private var currentTipIndex = 0
    @State private var floatOffset: CGFloat = 0
    @State private var progressWidth: CGFloat = 0.05

    private let tips = [
        "Analyzing your preferences...",
        "Balancing macros for the week...",
        "Finding delicious recipes...",
        "Optimizing variety & nutrition...",
        "Creating your personalized plan...",
        "Matching your cooking style...",
        "Almost ready..."
    ]

    // Cooking icons for animation
    private let cookingIcons = ["fork.knife", "flame", "leaf.fill", "carrot.fill", "fish.fill", "cup.and.saucer.fill"]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Main animated area
            ZStack {
                // Outer pulsing ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.black.opacity(0.1), Color.black.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(pulseScale)
                    .opacity(2.2 - pulseScale)

                // Second pulsing ring (delayed)
                Circle()
                    .stroke(Color.black.opacity(0.08), lineWidth: 1.5)
                    .frame(width: 160, height: 160)
                    .scaleEffect(pulseScale * 0.9)
                    .opacity(2.2 - pulseScale)

                // Rotating dashed circle
                Circle()
                    .stroke(
                        Color.black.opacity(0.15),
                        style: StrokeStyle(lineWidth: 1.5, dash: [8, 6])
                    )
                    .frame(width: 130, height: 130)
                    .rotationEffect(.degrees(rotationAngle))

                // Center solid circle
                Circle()
                    .fill(Color(hex: "F5F5F5"))
                    .frame(width: 110, height: 110)
                    .shadow(color: Color.black.opacity(0.08), radius: 20, y: 8)

                // Center content - floating icon
                VStack(spacing: 6) {
                    Image(systemName: cookingIcons[currentTipIndex % cookingIcons.count])
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(Color.black)
                        .offset(y: floatOffset)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                        .id("icon-\(currentTipIndex)")
                }

                // Orbiting elements
                ForEach(0..<4, id: \.self) { index in
                    let angle = Double(index) * 90 + rotationAngle
                    let iconNames = ["sparkle", "circle.fill", "sparkle", "circle.fill"]

                    Image(systemName: iconNames[index])
                        .font(.system(size: index % 2 == 0 ? 10 : 6, weight: .medium))
                        .foregroundStyle(Color.black.opacity(index % 2 == 0 ? 0.6 : 0.3))
                        .offset(
                            x: cos(angle * .pi / 180) * 85,
                            y: sin(angle * .pi / 180) * 85
                        )
                }
            }
            .frame(height: 220)

            Spacer()
                .frame(height: 40)

            // Progress text
            VStack(spacing: 12) {
                Text("Creating Your Plan")
                    .font(.system(.title2, weight: .bold))
                    .foregroundStyle(Color.black)

                Text(progress.isEmpty ? tips[currentTipIndex % tips.count] : progress)
                    .font(.system(.body, weight: .medium))
                    .foregroundStyle(Color(hex: "6B6B6B"))
                    .multilineTextAlignment(.center)
                    .frame(height: 24)
                    .animation(.easeInOut(duration: 0.4), value: currentTipIndex)
                    .id("tip-\(currentTipIndex)")
            }
            .padding(.horizontal, 40)

            Spacer()
                .frame(height: 50)

            // Progress indicator
            VStack(spacing: 16) {
                // Clean progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(hex: "E5E5E5"))
                            .frame(height: 6)

                        // Progress fill
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.black)
                            .frame(width: geometry.size.width * progressWidth, height: 6)
                    }
                }
                .frame(height: 6)
                .padding(.horizontal, 50)

                // Time estimate
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 12, weight: .medium))
                    Text("This usually takes 30-60 seconds")
                        .font(.system(.caption, weight: .medium))
                }
                .foregroundStyle(Color(hex: "9CA3AF"))
            }

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        isAnimating = true

        // Pulse animation - smooth and elegant
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.2
        }

        // Rotation animation - slow and smooth
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }

        // Float animation for center icon
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            floatOffset = -8
        }

        // Progress bar animation - gradual fill
        withAnimation(.easeInOut(duration: 45)) {
            progressWidth = 0.92
        }

        // Tip cycling - every 4 seconds for better readability
        Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentTipIndex += 1
            }
        }
    }
}

// MARK: - Swap Meal Sheet
struct SwapMealSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let meals: [Meal]
    @Bindable var generator: MealPlanGenerator
    let userProfile: UserProfile?

    @State private var selectedMeal: Meal?
    @State private var isSwapping = false
    @State private var swapRingProgress: CGFloat = 0
    @State private var swapMessageIndex = 0
    @State private var swapEmojiOffset: CGFloat = 0

    private let swapMessages = [
        "Finding the perfect recipe...",
        "Checking your preferences...",
        "Balancing the macros...",
        "Crafting something delicious...",
        "Almost ready..."
    ]

    private let foodEmojis = ["🍳", "🥗", "🍲", "🥩", "🍝", "🥑", "🍜", "🫕", "🥘", "🍱"]

    var body: some View {
        NavigationStack {
            VStack(spacing: Design.Spacing.lg) {
                if generator.isGenerating || isSwapping {
                    Spacer()

                    // Animated progress ring
                    ZStack {
                        Circle()
                            .stroke(Color.accentPurple.opacity(0.15), lineWidth: 6)
                            .frame(width: 130, height: 130)

                        Circle()
                            .trim(from: 0, to: swapRingProgress)
                            .stroke(
                                AngularGradient(
                                    colors: [Color.accentPurple, Color.brandGreen, Color.accentPurple],
                                    center: .center
                                ),
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .frame(width: 130, height: 130)
                            .rotationEffect(.degrees(-90))

                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundStyle(Color.accentPurple)
                            .symbolEffect(.rotate, options: .repeating)
                    }
                    .padding(.bottom, Design.Spacing.lg)

                    // Cycling messages
                    Text(swapMessages[swapMessageIndex % swapMessages.count])
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                        .contentTransition(.numericText())
                        .animation(.easeInOut, value: swapMessageIndex)

                    // Food emoji carousel
                    HStack(spacing: Design.Spacing.md) {
                        ForEach(0..<5, id: \.self) { i in
                            Text(foodEmojis[(i + Int(swapEmojiOffset)) % foodEmojis.count])
                                .font(.title)
                                .scaleEffect(i == 2 ? 1.3 : 0.8)
                                .opacity(i == 2 ? 1 : 0.5)
                        }
                    }
                    .padding(.top, Design.Spacing.sm)

                    Spacer()

                    Text(generator.progress.isEmpty ? "Preparing your swap..." : generator.progress)
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                        .padding(.bottom, Design.Spacing.xl)

                } else if meals.isEmpty {
                    Spacer()
                    VStack(spacing: Design.Spacing.md) {
                        Image(systemName: "fork.knife.circle")
                            .font(.system(size: 50))
                            .foregroundStyle(Color.textSecondary)

                        Text("No meals to swap")
                            .font(.headline)

                        Text("Add meals to your plan first")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                    }
                    Spacer()
                } else {
                    Text("Select a meal to swap for a new recipe")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                        .padding(.top)

                    ScrollView {
                        VStack(spacing: Design.Spacing.sm) {
                            ForEach(meals) { meal in
                                SwapMealRow(
                                    meal: meal,
                                    isSelected: selectedMeal?.id == meal.id,
                                    onSelect: { selectedMeal = meal }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }

                    if selectedMeal != nil {
                        Button(action: swapSelectedMeal) {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("Swap Meal")
                            }
                        }
                        .purpleButton()
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("Swap Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.accentPurple)
                }
            }
        }
        .presentationDetents([.large])
        .onChange(of: generator.isGenerating) { _, isGen in
            if isGen { startSwapAnimations() }
        }
        .onChange(of: isSwapping) { _, swapping in
            if swapping { startSwapAnimations() }
        }
    }

    private func startSwapAnimations() {
        swapRingProgress = 0
        swapMessageIndex = 0
        swapEmojiOffset = 0

        withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: false)) {
            swapRingProgress = 0.85
        }

        Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [generator] timer in
            Task { @MainActor in
                if !generator.isGenerating && !isSwapping { timer.invalidate(); return }
                withAnimation(.easeInOut(duration: 0.5)) { swapMessageIndex += 1 }
            }
        }

        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [generator] timer in
            Task { @MainActor in
                if !generator.isGenerating && !isSwapping { timer.invalidate(); return }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { swapEmojiOffset += 1 }
            }
        }
    }

    private func swapSelectedMeal() {
        guard let meal = selectedMeal, let profile = userProfile else { return }

        isSwapping = true
        Task {
            do {
                let existingRecipeNames = meals.compactMap { $0.recipe?.name }
                let result = try await generator.generateReplacementMeal(
                    for: meal.mealType,
                    profile: profile,
                    excludeRecipes: existingRecipeNames,
                    modelContext: modelContext
                )

                meal.recipe = result.recipe
                try modelContext.save()

                // Brief success pause then dismiss
                try? await Task.sleep(for: .seconds(0.5))
                dismiss()
            } catch {
                print("Failed to swap meal: \(error)")
                isSwapping = false
            }
        }
    }
}

// MARK: - Swap Meal Row
struct SwapMealRow: View {
    let meal: Meal
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Design.Spacing.md) {
                // Meal type icon
                ZStack {
                    Circle()
                        .fill(mealTypeColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: meal.mealType.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(mealTypeColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(meal.mealType.rawValue)
                        .font(.caption)
                        .foregroundStyle(mealTypeColor)

                    Text(meal.recipe?.name ?? "Unknown")
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)
                }

                Spacer()

                // Selection indicator
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.accentPurple : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Color.accentPurple)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(Design.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.md)
                    .fill(isSelected ? Color.accentPurple.opacity(0.08) : Color.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: Design.Radius.md)
                            .strokeBorder(isSelected ? Color.accentPurple : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var mealTypeColor: Color {
        switch meal.mealType {
        case .breakfast: return Color.accentYellow
        case .lunch: return Color.mintVibrant
        case .dinner: return Color.accentPurple
        case .snack: return Color(hex: "FF6B9D")
        }
    }
}

// MARK: - Add Meal To Today Sheet
struct AddMealToTodaySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let day: Day?
    @Bindable var generator: MealPlanGenerator
    let userProfile: UserProfile?

    @State private var selectedMealType: MealType = .lunch

    var body: some View {
        NavigationStack {
            VStack(spacing: Design.Spacing.xl) {
                if generator.isGenerating {
                    Spacer()
                    VStack(spacing: Design.Spacing.md) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(Color.accentPurple)

                        Text(generator.progress)
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                    }
                    Spacer()
                } else {
                    Spacer()

                    ZStack {
                        Circle()
                            .fill(Color.mintVibrant.opacity(0.1))
                            .frame(width: 100, height: 100)

                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(Color.mintVibrant)
                    }

                    VStack(spacing: Design.Spacing.sm) {
                        Text("Add a Meal")
                            .font(Design.Typography.title)

                        Text("Generate a new meal for today")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                    }

                    // Meal type picker
                    VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                        Text("Meal Type")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.textSecondary)

                        HStack(spacing: Design.Spacing.sm) {
                            ForEach(MealType.allCases) { type in
                                MealTypeButton(
                                    type: type,
                                    isSelected: selectedMealType == type,
                                    onSelect: { selectedMealType = type }
                                )
                            }
                        }
                    }
                    .padding(.horizontal)

                    Spacer()

                    Button(action: addMeal) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Generate \(selectedMealType.rawValue)")
                        }
                    }
                    .purpleButton()
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .background(LinearGradient.mintBackgroundGradient.ignoresSafeArea())
            .navigationTitle("Add Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.accentPurple)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func addMeal() {
        guard let day = day, let profile = userProfile else { return }

        Task {
            do {
                let existingRecipeNames = day.sortedMeals.compactMap { $0.recipe?.name }
                let result = try await generator.generateReplacementMeal(
                    for: selectedMealType,
                    profile: profile,
                    excludeRecipes: existingRecipeNames,
                    modelContext: modelContext
                )

                // Create a new meal with the generated recipe
                let newMeal = Meal(mealType: selectedMealType)
                newMeal.recipe = result.recipe
                newMeal.day = day
                day.meals?.append(newMeal)

                modelContext.insert(newMeal)
                try modelContext.save()

                dismiss()
            } catch {
                print("Failed to add meal: \(error)")
            }
        }
    }
}

// MARK: - Meal Type Button
struct MealTypeButton: View {
    let type: MealType
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 4) {
                Image(systemName: type.icon)
                    .font(.system(size: 20))

                Text(type.rawValue)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Design.Spacing.sm)
            .foregroundStyle(isSelected ? .white : Color.textPrimary)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.md)
                    .fill(isSelected ? Color.accentPurple : Color.cardBackground)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview Helper
private struct TodayViewPreview: View {
    @State private var container: ModelContainer

    init() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: UserProfile.self, MealPlan.self, Day.self, Meal.self, Recipe.self, RecipeIngredient.self, Ingredient.self, configurations: config)

        // Create sample user profile
        let profile = UserProfile()
        profile.name = "Chef"
        profile.dailyCalorieTarget = 2000
        profile.proteinGrams = 150
        profile.carbsGrams = 200
        profile.fatGrams = 65
        profile.hasCompletedOnboarding = true
        container.mainContext.insert(profile)

        // Create sample meal plan
        let mealPlan = MealPlan(weekStartDate: Date(), isActive: true)
        container.mainContext.insert(mealPlan)

        // Create today's day
        let today = Day(date: Date(), dayOfWeek: Calendar.current.component(.weekday, from: Date()))
        today.mealPlan = mealPlan
        container.mainContext.insert(today)

        // Create sample recipes and meals
        let breakfastRecipe = Recipe(
            name: "Avocado Toast with Eggs",
            recipeDescription: "Healthy breakfast",
            cookTimeMinutes: 15,
            calories: 450,
            proteinGrams: 20,
            carbsGrams: 35,
            fatGrams: 25
        )
        container.mainContext.insert(breakfastRecipe)

        let breakfast = Meal(mealType: .breakfast)
        breakfast.recipe = breakfastRecipe
        breakfast.day = today
        breakfast.isEaten = true
        container.mainContext.insert(breakfast)

        let lunchRecipe = Recipe(
            name: "Grilled Chicken Salad",
            recipeDescription: "Fresh and filling",
            cookTimeMinutes: 25,
            calories: 550,
            proteinGrams: 45,
            carbsGrams: 20,
            fatGrams: 30
        )
        container.mainContext.insert(lunchRecipe)

        let lunch = Meal(mealType: .lunch)
        lunch.recipe = lunchRecipe
        lunch.day = today
        container.mainContext.insert(lunch)

        let dinnerRecipe = Recipe(
            name: "Salmon with Vegetables",
            recipeDescription: "Omega-3 rich dinner",
            cookTimeMinutes: 30,
            calories: 600,
            proteinGrams: 40,
            carbsGrams: 30,
            fatGrams: 35
        )
        container.mainContext.insert(dinnerRecipe)

        let dinner = Meal(mealType: .dinner)
        dinner.recipe = dinnerRecipe
        dinner.day = today
        container.mainContext.insert(dinner)

        _container = State(initialValue: container)
    }

    var body: some View {
        TodayView()
            .modelContainer(container)
            .environment(HealthKitManager())
            .environment(NotificationManager())
    }
}

#Preview {
    TodayViewPreview()
}
