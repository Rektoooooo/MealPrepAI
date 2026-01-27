import SwiftUI
import SwiftData

struct WeeklyPlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<MealPlan> { $0.isActive }, sort: \MealPlan.createdAt, order: .reverse)
    private var mealPlans: [MealPlan]
    @Query private var userProfiles: [UserProfile]

    @State private var selectedDayIndex = 0
    @State private var showingGenerateSheet = false
    @State private var showingPreferencesSheet = false
    @State private var selectedRecipe: Recipe?
    @State private var animateContent = false
    @State private var generator = MealPlanGenerator()
    @State private var weekOffset: Int = 0

    private var viewingWeekStart: Date {
        let calendar = Calendar.current
        let today = Date()
        // Get start of current week (Sunday)
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        // Apply offset
        return calendar.date(byAdding: .weekOfYear, value: weekOffset, to: startOfWeek) ?? startOfWeek
    }

    private var currentMealPlan: MealPlan? {
        let calendar = Calendar.current
        return mealPlans.first { plan in
            calendar.isDate(plan.weekStartDate, equalTo: viewingWeekStart, toGranularity: .weekOfYear)
        } ?? (weekOffset == 0 ? mealPlans.first : nil)
    }

    private var canNavigateToPreviousWeek: Bool {
        // Allow navigating back up to 4 weeks
        weekOffset > -4
    }

    private var canNavigateToNextWeek: Bool {
        // Allow navigating forward up to 4 weeks
        weekOffset < 4
    }

    private var userProfile: UserProfile? {
        userProfiles.first
    }

    private var sortedDays: [Day] {
        currentMealPlan?.sortedDays ?? []
    }

    private var selectedDay: Day? {
        guard selectedDayIndex < sortedDays.count else { return nil }
        return sortedDays[selectedDayIndex]
    }

    private var weekDays: [String] {
        sortedDays.map { $0.shortDayName }
    }

    private var dates: [Int] {
        sortedDays.map { Calendar.current.component(.day, from: $0.date) }
    }

    private var todayIndex: Int {
        let calendar = Calendar.current
        return sortedDays.firstIndex { calendar.isDateInToday($0.date) } ?? 0
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: Design.Spacing.lg) {
                    if currentMealPlan == nil {
                        // Empty State with Personalization Banner
                        PersonalizationBanner(
                            title: "Create Your Plan",
                            subtitle: "Generate a personalized meal plan tailored to your preferences",
                            buttonText: "Get Started",
                            onTap: { showingGenerateSheet = true }
                        )
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)

                        emptyStateView
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 20)
                    } else {
                        // Personalization Banner
                        PersonalizationBanner(
                            title: "Personalise Meal Plan",
                            subtitle: "Update your weekly meal preferences",
                            buttonText: "Update Preferences",
                            onTap: { showingPreferencesSheet = true }
                        )
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)

                        // Week Navigation
                        weekNavigation
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 20)

                        // Day Pills
                        if !weekDays.isEmpty {
                            dayPillsSection
                                .opacity(animateContent ? 1 : 0)
                                .offset(y: animateContent ? 0 : 20)
                        }

                        // Day Summary
                        if let day = selectedDay {
                            daySummarySection(for: day)
                                .opacity(animateContent ? 1 : 0)
                                .offset(y: animateContent ? 0 : 20)
                        }

                        // Meals By Type
                        if let day = selectedDay {
                            mealsByTypeSection(for: day)
                                .opacity(animateContent ? 1 : 0)
                                .offset(y: animateContent ? 0 : 20)
                        }
                    }
                }
                .padding(.horizontal, Design.Spacing.md)
                .padding(.bottom, Design.Spacing.xxl)
            }
            .background(LinearGradient.mintBackgroundGradient.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: Design.Spacing.xs) {
                        Text("Meal Plan")
                            .font(Design.Typography.headline)
                        Text("🔥")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingGenerateSheet = true }) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color.accentPurple)
                    }
                }
            }
            .fullScreenCover(isPresented: $showingGenerateSheet) {
                MealPrepSetupView(generator: generator)
            }
            .fullScreenCover(isPresented: $showingPreferencesSheet) {
                MealPrepSetupView(generator: generator, skipWelcome: true)
            }
            .sheet(item: $selectedRecipe) { recipe in
                RecipeDetailSheet(recipe: recipe)
            }
            .onAppear {
                selectedDayIndex = todayIndex
                if !animateContent {
                    withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                        animateContent = true
                    }
                }
            }
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        NewEmptyStateView(
            icon: "calendar.badge.plus",
            title: "No Meal Plan Yet",
            message: "Generate your first personalized meal plan based on your preferences and goals.",
            buttonTitle: "Create My Meal Plan",
            buttonIcon: "sparkles",
            buttonStyle: .purple,
            onButtonTap: { showingGenerateSheet = true }
        )
        .frame(height: 350)
    }

    // MARK: - Week Navigation
    private var weekNavigation: some View {
        HStack {
            Button(action: navigateToPreviousWeek) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(canNavigateToPreviousWeek ? Color.accentPurple : Color.gray.opacity(0.5))
                    .padding(Design.Spacing.sm)
                    .background(
                        Circle()
                            .fill(canNavigateToPreviousWeek ? Color.accentPurple.opacity(0.1) : Color.gray.opacity(0.05))
                    )
            }
            .disabled(!canNavigateToPreviousWeek)

            Spacer()

            VStack(spacing: 2) {
                Text(weekDateRangeForCurrentView)
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                HStack(spacing: Design.Spacing.xs) {
                    Text(weekLabelForCurrentView)
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                    if weekOffset == 0 {
                        Text("• This Week")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.accentPurple)
                    }
                }
            }

            Spacer()

            Button(action: navigateToNextWeek) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(canNavigateToNextWeek ? Color.accentPurple : Color.gray.opacity(0.5))
                    .padding(Design.Spacing.sm)
                    .background(
                        Circle()
                            .fill(canNavigateToNextWeek ? Color.accentPurple.opacity(0.1) : Color.gray.opacity(0.05))
                    )
            }
            .disabled(!canNavigateToNextWeek)
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
    }

    private func navigateToPreviousWeek() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            weekOffset -= 1
            selectedDayIndex = 0
        }
    }

    private func navigateToNextWeek() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            weekOffset += 1
            selectedDayIndex = 0
        }
    }

    private var weekDateRangeForCurrentView: String {
        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: .day, value: 6, to: viewingWeekStart) ?? viewingWeekStart
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: viewingWeekStart)) - \(formatter.string(from: endDate))"
    }

    private var weekLabelForCurrentView: String {
        let calendar = Calendar.current
        let weekOfYear = calendar.component(.weekOfYear, from: viewingWeekStart)
        let year = calendar.component(.year, from: viewingWeekStart)
        return "Week \(weekOfYear), \(year)"
    }

    // MARK: - Day Pills Section
    private var dayPillsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Design.Spacing.sm) {
                ForEach(Array(zip(weekDays.indices, zip(weekDays, dates))), id: \.0) { index, dayData in
                    let (dayName, date) = dayData
                    let isSelected = index == selectedDayIndex
                    let isToday = index == todayIndex

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedDayIndex = index
                        }
                    } label: {
                        VStack(spacing: Design.Spacing.xs) {
                            Text(dayName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(isSelected ? .white : Color.textSecondary)

                            Text("\(date)")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(isSelected ? .white : Color.textPrimary)

                            if isToday && !isSelected {
                                Circle()
                                    .fill(Color.accentPurple)
                                    .frame(width: 6, height: 6)
                            } else {
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 6, height: 6)
                            }
                        }
                        .frame(width: 50)
                        .padding(.vertical, Design.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: Design.Radius.md)
                                .fill(isSelected ? Color.accentPurple : Color.cardBackground)
                                .shadow(
                                    color: isSelected ? Color.accentPurple.opacity(0.3) : Design.Shadow.card.color,
                                    radius: isSelected ? 8 : Design.Shadow.card.radius,
                                    y: Design.Shadow.card.y
                                )
                        )
                    }
                }
            }
            .padding(.horizontal, Design.Spacing.xs)
        }
    }

    // MARK: - Day Summary Section
    private func daySummarySection(for day: Day) -> some View {
        VStack(spacing: Design.Spacing.md) {
            NewSectionHeader(title: "Daily Summary", icon: "chart.bar.fill", iconColor: Color.accentPurple)

            HStack(spacing: Design.Spacing.sm) {
                CompactStatsCard(
                    icon: "flame.fill",
                    value: "\(day.totalCalories)",
                    label: "kcal",
                    color: .orange
                )

                CompactStatsCard(
                    icon: "p.circle.fill",
                    value: "\(day.totalProtein)g",
                    label: "Protein",
                    color: .red
                )

                let totalTime = day.sortedMeals.reduce(0) { $0 + ($1.recipe?.totalTimeMinutes ?? 0) }
                CompactStatsCard(
                    icon: "clock.fill",
                    value: "\(totalTime)m",
                    label: "Cooking",
                    color: .gray
                )
            }
        }
    }

    // MARK: - Meals By Type Section
    private func mealsByTypeSection(for day: Day) -> some View {
        VStack(spacing: Design.Spacing.lg) {
            // Breakfast
            let breakfastMeals = day.sortedMeals.filter { $0.mealType == .breakfast }
            if !breakfastMeals.isEmpty {
                mealTypeSection(title: "Breakfast", icon: "sunrise.fill", iconColor: Color.accentYellow, meals: breakfastMeals)
            }

            // Lunch
            let lunchMeals = day.sortedMeals.filter { $0.mealType == .lunch }
            if !lunchMeals.isEmpty {
                mealTypeSection(title: "Lunch", icon: "sun.max.fill", iconColor: Color.mintVibrant, meals: lunchMeals)
            }

            // Dinner
            let dinnerMeals = day.sortedMeals.filter { $0.mealType == .dinner }
            if !dinnerMeals.isEmpty {
                mealTypeSection(title: "Dinner", icon: "moon.stars.fill", iconColor: Color.accentPurple, meals: dinnerMeals)
            }

            // Snack
            let snackMeals = day.sortedMeals.filter { $0.mealType == .snack }
            if !snackMeals.isEmpty {
                mealTypeSection(title: "Snack", icon: "leaf.fill", iconColor: Color.mintVibrant, meals: snackMeals)
            }

            // Show message if no meals
            if day.sortedMeals.isEmpty {
                VStack(spacing: Design.Spacing.md) {
                    NewSectionHeader(title: "Today's Meals", icon: "fork.knife", iconColor: Color.textSecondary)

                    Text("No meals planned for this day")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Design.Spacing.xl)
                        .background(
                            RoundedRectangle(cornerRadius: Design.Radius.card)
                                .fill(Color.cardBackground)
                        )
                }
            }
        }
    }

    private func mealTypeSection(title: String, icon: String, iconColor: Color, meals: [Meal]) -> some View {
        VStack(spacing: Design.Spacing.md) {
            NewSectionHeader(
                title: title,
                icon: icon,
                iconColor: iconColor
            )

            // Full-width centered meal cards
            VStack(spacing: Design.Spacing.md) {
                ForEach(meals) { meal in
                    if let recipe = meal.recipe {
                        WideMealCard(
                            recipe: recipe,
                            mealType: meal.mealType,
                            isCompleted: meal.isEaten,
                            onTap: {
                                selectedRecipe = recipe
                            },
                            onToggleCompleted: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    meal.isEaten.toggle()
                                    if meal.isEaten {
                                        meal.eatenAt = Date()
                                    } else {
                                        meal.eatenAt = nil
                                    }
                                }
                            }
                        )
                    }
                }
            }
        }
    }

    private func mealTypeIcon(for type: String) -> String {
        switch type.lowercased() {
        case "breakfast": return "sunrise.fill"
        case "lunch": return "sun.max.fill"
        case "dinner": return "moon.stars.fill"
        case "snack": return "leaf.fill"
        default: return "fork.knife"
        }
    }
}

#Preview {
    WeeklyPlanView()
        .modelContainer(for: [MealPlan.self, UserProfile.self], inMemory: true)
}
