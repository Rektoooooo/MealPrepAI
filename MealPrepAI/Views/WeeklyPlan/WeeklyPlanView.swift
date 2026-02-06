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
        var calendar = Calendar.current
        calendar.firstWeekday = 1  // 1 = Sunday, ensures consistent week start
        let today = calendar.startOfDay(for: Date())

        // Get the weekday (1 = Sunday, 2 = Monday, etc.)
        let weekday = calendar.component(.weekday, from: today)
        // Calculate days to subtract to get to Sunday
        let daysToSubtract = weekday - 1

        // Get Sunday of current week
        let sundayOfCurrentWeek = calendar.date(byAdding: .day, value: -daysToSubtract, to: today)!

        // Apply week offset
        return calendar.date(byAdding: .day, value: weekOffset * 7, to: sundayOfCurrentWeek) ?? sundayOfCurrentWeek
    }

    private var currentMealPlan: MealPlan? {
        let calendar = Calendar.current
        // Calculate the end of the viewing week (Saturday)
        let viewingWeekEnd = calendar.date(byAdding: .day, value: 6, to: viewingWeekStart)!

        // Find meal plan that has any days overlapping with the viewing week
        return mealPlans.first { plan in
            // Check if any day in the meal plan falls within the viewing week
            plan.sortedDays.contains { day in
                day.date >= viewingWeekStart && day.date <= viewingWeekEnd
            }
        }
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
        guard selectedDayIndex < weekDaysFromViewingWeek.count else { return nil }
        let selectedDate = weekDaysFromViewingWeek[selectedDayIndex].fullDate
        let calendar = Calendar.current
        // Find the day in the meal plan that matches the selected date
        return sortedDays.first { calendar.isDate($0.date, inSameDayAs: selectedDate) }
    }

    // Week days based on viewingWeekStart (always available, not dependent on meal plan)
    private var weekDaysFromViewingWeek: [(dayName: String, date: Int, fullDate: Date)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        return (0..<7).compactMap { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: viewingWeekStart) else {
                return nil
            }
            let dayName = formatter.string(from: date)
            let dayOfMonth = calendar.component(.day, from: date)
            return (dayName: dayName, date: dayOfMonth, fullDate: date)
        }
    }

    private var todayIndex: Int {
        let calendar = Calendar.current
        return weekDaysFromViewingWeek.firstIndex { calendar.isDateInToday($0.fullDate) } ?? 0
    }

    // Calculate suggested next plan dates based on when current plan ends
    private var suggestedNextPlanDateRange: String? {
        guard let plan = currentMealPlan,
              let lastDay = plan.sortedDays.last else { return nil }

        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        // Next plan starts the day after current plan ends
        guard let nextStart = calendar.date(byAdding: .day, value: 1, to: lastDay.date),
              let nextEnd = calendar.date(byAdding: .day, value: 6, to: nextStart) else { return nil }

        return "\(formatter.string(from: nextStart)) - \(formatter.string(from: nextEnd))"
    }

    // Check if we're viewing a day after the current plan ends
    private var isViewingDayAfterPlanEnds: Bool {
        guard let plan = currentMealPlan,
              let lastDay = plan.sortedDays.last,
              selectedDayIndex < weekDaysFromViewingWeek.count else { return false }

        let selectedDate = weekDaysFromViewingWeek[selectedDayIndex].fullDate
        return selectedDate > lastDay.date
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: Design.Spacing.lg) {
                    // Personalization Banner - context aware
                    if currentMealPlan == nil {
                        // No plan at all
                        PersonalizationBanner(
                            title: "Create Your Plan",
                            subtitle: "Generate a personalized meal plan tailored to your preferences",
                            buttonText: "Get Started",
                            onTap: { showingGenerateSheet = true }
                        )
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)
                    } else if selectedDay == nil, let dateRange = suggestedNextPlanDateRange {
                        // Plan exists but selected day has no meals - suggest next plan
                        PersonalizationBanner(
                            title: "Plan Your Next Week",
                            subtitle: "Generate meals for \(dateRange)",
                            buttonText: "Generate Plan",
                            onTap: { showingGenerateSheet = true }
                        )
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)
                    } else {
                        // Plan exists and viewing a covered day
                        PersonalizationBanner(
                            title: "Personalise Meal Plan",
                            subtitle: "Update your weekly meal preferences",
                            buttonText: "Update Preferences",
                            onTap: { showingPreferencesSheet = true }
                        )
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)
                    }

                    // Week Navigation - always shown
                    weekNavigation
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)

                    // Day Pills - always shown
                    dayPillsSection
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)

                    // Content based on meal plan and day availability
                    if currentMealPlan == nil {
                        // No meal plan covers this week at all
                        noMealPlanForWeekView
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 20)
                    } else if let day = selectedDay {
                        // Meal plan exists and selected day has meals
                        daySummarySection(for: day)
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 20)

                        mealsByTypeSection(for: day)
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 20)

                    } else {
                        // Meal plan exists but selected day has no meals
                        noMealsForDayView
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 20)
                    }

                    // Insights preview cards — shown whenever a meal plan exists
                    if let plan = currentMealPlan {
                        NavigationLink {
                            InsightsView(
                                mealPlan: plan,
                                calorieTarget: userProfile?.dailyCalorieTarget ?? 2000,
                                proteinTarget: userProfile?.proteinGrams ?? 150,
                                carbsTarget: userProfile?.carbsGrams ?? 200,
                                fatTarget: userProfile?.fatGrams ?? 65
                            )
                        } label: {
                            InsightsPreviewCards(
                                days: plan.sortedDays,
                                calorieTarget: userProfile?.dailyCalorieTarget ?? 2000
                            )
                        }
                        .buttonStyle(.plain)
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)
                    }
                }
                .padding(.horizontal, Design.Spacing.md)
                .padding(.bottom, 100)
            }
            .warmBackground()
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
                    .accessibilityLabel("Generate new meal plan")
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

    // MARK: - Empty State for Week Without Plan
    private var noMealPlanForWeekView: some View {
        VStack(spacing: Design.Spacing.lg) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentPurple.opacity(0.6))

            VStack(spacing: Design.Spacing.sm) {
                Text("No Meal Plan for This Week")
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)

                Text("Generate a personalized meal plan for this week")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showingGenerateSheet = true
            } label: {
                HStack(spacing: Design.Spacing.sm) {
                    Image(systemName: "sparkles")
                    Text("Generate Meal Plan")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, Design.Spacing.xl)
                .padding(.vertical, Design.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Design.Radius.lg)
                        .fill(Color.accentPurple)
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Design.Spacing.xxl)
        .padding(.horizontal, Design.Spacing.lg)
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

    // MARK: - Empty State for Day Without Meals
    private var noMealsForDayView: some View {
        VStack(spacing: Design.Spacing.md) {
            Image(systemName: "fork.knife")
                .font(.system(size: 36))
                .foregroundStyle(Color.textSecondary.opacity(0.5))

            VStack(spacing: Design.Spacing.xs) {
                Text("No Meals for This Day")
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)

                Text("This day isn't part of your current meal plan")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Design.Spacing.xl)
        .padding(.horizontal, Design.Spacing.lg)
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
            .accessibilityLabel("Previous week")

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
            .accessibilityLabel("Next week")
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
        HStack(spacing: Design.Spacing.xs) {
            ForEach(Array(weekDaysFromViewingWeek.enumerated()), id: \.offset) { index, dayData in
                let isSelected = index == selectedDayIndex
                let calendar = Calendar.current
                let isToday = calendar.isDateInToday(dayData.fullDate)

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedDayIndex = index
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(dayData.dayName)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(isSelected ? .white : Color.textSecondary)

                        Text("\(dayData.date)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(isSelected ? .white : Color.textPrimary)

                        if isToday && !isSelected {
                            Circle()
                                .fill(Color.accentPurple)
                                .frame(width: 5, height: 5)
                        } else {
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 5, height: 5)
                        }
                    }
                    .frame(maxWidth: .infinity)
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
                .accessibilityLabel("\(dayData.dayName) \(dayData.date)")
                .accessibilityValue(isSelected ? "Selected" : (isToday ? "Today" : ""))
                .accessibilityHint("Double tap to select")
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
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
