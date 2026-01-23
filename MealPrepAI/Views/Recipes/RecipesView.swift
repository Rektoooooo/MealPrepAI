import SwiftUI
import SwiftData

struct RecipesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recipe.createdAt, order: .reverse) private var allRecipes: [Recipe]
    @Query private var userProfiles: [UserProfile]

    @State private var searchText = ""
    @State private var selectedCategory: FoodCategory = .all
    @State private var showingAddRecipe = false
    @State private var animateContent = false
    @State private var selectedRecipe: Recipe?

    private var userProfile: UserProfile? {
        userProfiles.first
    }

    private var filteredRecipes: [Recipe] {
        var recipes = allRecipes

        // Apply category filter
        if selectedCategory != .all {
            recipes = recipes.filter { recipe in
                recipe.matchesCategory(selectedCategory)
            }
        }

        // Apply search
        if !searchText.isEmpty {
            recipes = recipes.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.recipeDescription.localizedCaseInsensitiveContains(searchText)
            }
        }

        return recipes
    }

    private var featuredRecipe: Recipe? {
        allRecipes.first { $0.isFavorite } ?? allRecipes.first
    }

    private var gridRecipes: [Recipe] {
        if let featured = featuredRecipe, selectedCategory == .all && searchText.isEmpty {
            return filteredRecipes.filter { $0.id != featured.id }
        }
        return filteredRecipes
    }

    private var emptyStateTitle: String {
        if !searchText.isEmpty {
            return "No Results"
        } else if selectedCategory != .all {
            return "No \(selectedCategory.rawValue) Recipes"
        }
        return "No Recipes Yet"
    }

    private var emptyStateMessage: String {
        if !searchText.isEmpty {
            return "Try adjusting your search."
        } else if selectedCategory != .all {
            return "Try selecting a different category or generate a meal plan to add more recipes."
        }
        return "Generate a meal plan or add your own recipes to get started."
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: Design.Spacing.lg) {
                    // Greeting Header
                    GreetingHeader(userName: userProfile?.name ?? "Chef")
                        .padding(.horizontal, Design.Spacing.lg)
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)

                    // Title
                    HStack {
                        Text("Explore New Recipes")
                            .font(Design.Typography.title)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, Design.Spacing.lg)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)

                    // Search Bar
                    RoundedSearchBar(text: $searchText)
                        .padding(.horizontal, Design.Spacing.lg)
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)

                    // Category Pills
                    CategoryPillScroller(selectedCategory: $selectedCategory)
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)

                    if filteredRecipes.isEmpty {
                        // Empty State
                        emptyStateView
                            .opacity(animateContent ? 1 : 0)
                    } else {
                        // Featured Recipe Card (only show when not filtering)
                        if let featured = featuredRecipe, searchText.isEmpty && selectedCategory == .all {
                            VStack(alignment: .leading, spacing: Design.Spacing.md) {
                                NewSectionHeader(title: "Featured", emoji: nil)
                                    .padding(.horizontal, Design.Spacing.lg)

                                FeaturedRecipeCard(
                                    recipe: featured,
                                    onTap: { selectedRecipe = featured },
                                    onFavorite: { toggleFavorite(featured) }
                                )
                                .padding(.horizontal, Design.Spacing.lg)
                            }
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 20)
                        }

                        // Recipe Grid
                        VStack(alignment: .leading, spacing: Design.Spacing.md) {
                            NewSectionHeader(
                                title: searchText.isEmpty ? "All Recipes" : "Results",
                                showSeeAll: false
                            )
                            .padding(.horizontal, Design.Spacing.lg)

                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: Design.Spacing.md),
                                GridItem(.flexible(), spacing: Design.Spacing.md)
                            ], spacing: Design.Spacing.md) {
                                ForEach(Array(gridRecipes.enumerated()), id: \.element.id) { index, recipe in
                                    StackedRecipeCard(
                                        recipe: recipe,
                                        onTap: { selectedRecipe = recipe },
                                        onAdd: { addToMealPlan(recipe) }
                                    )
                                    .opacity(animateContent ? 1 : 0)
                                    .offset(y: animateContent ? 0 : 20)
                                    .animation(
                                        .easeOut(duration: 0.4).delay(Double(index) * 0.05),
                                        value: animateContent
                                    )
                                }
                            }
                            .padding(.horizontal, Design.Spacing.lg)
                        }
                        .opacity(animateContent ? 1 : 0)
                    }
                }
                .padding(.bottom, Design.Spacing.xxl)
            }
            .background(
                LinearGradient.mintBackgroundGradient
                    .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddRecipe = true }) {
                        ZStack {
                            Circle()
                                .fill(Color.accentPurple)
                                .frame(width: 36, height: 36)

                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddRecipe) {
                AddRecipeSheet()
            }
            .sheet(item: $selectedRecipe) { recipe in
                RecipeDetailSheet(recipe: recipe)
            }
            .onAppear {
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
        VStack(spacing: Design.Spacing.xl) {
            Spacer()
                .frame(height: 40)

            ZStack {
                Circle()
                    .fill(Color.mintLight)
                    .frame(width: 120, height: 120)

                Image(systemName: "book.closed.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(Color.mintVibrant)
            }

            VStack(spacing: Design.Spacing.sm) {
                Text(emptyStateTitle)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(emptyStateMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Design.Spacing.xl)
            }

            if searchText.isEmpty {
                Button(action: { showingAddRecipe = true }) {
                    HStack(spacing: Design.Spacing.sm) {
                        Image(systemName: "plus")
                        Text("Add Recipe")
                    }
                }
                .purpleButton()
            }

            Spacer()
        }
    }

    // MARK: - Actions
    private func toggleFavorite(_ recipe: Recipe) {
        withAnimation(Design.Animation.bouncy) {
            recipe.isFavorite.toggle()
        }
    }

    private func addToMealPlan(_ recipe: Recipe) {
        // TODO: Implement add to meal plan functionality
        print("Add \(recipe.name) to meal plan")
    }
}

// MARK: - Recipe Detail Sheet
struct RecipeDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<MealPlan> { $0.isActive }, sort: \MealPlan.createdAt, order: .reverse)
    private var mealPlans: [MealPlan]
    @AppStorage("measurementSystem") private var measurementSystem: MeasurementSystem = .metric

    let recipe: Recipe

    @State private var showingAddToPlan = false
    @State private var showingEditSheet = false
    @State private var showingShareSheet = false

    private var currentMealPlan: MealPlan? {
        mealPlans.first
    }

    /// Converts and formats quantity for a recipe ingredient
    private func formattedQuantity(for ingredient: RecipeIngredient) -> String {
        let (convertedQty, convertedUnit) = ingredient.unit.convert(ingredient.quantity, to: measurementSystem)
        return MeasurementUnit.formatQuantity(convertedQty, unit: convertedUnit)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Design.Spacing.lg) {
                    // Hero image - show real image if available
                    ZStack {
                        if let imageURL = recipe.imageURL, let uiImage = UIImage(named: imageURL) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: Design.Radius.featured))
                        } else {
                            FoodImagePlaceholder(
                                style: recipe.cuisineType?.foodStyle ?? .random,
                                height: 200,
                                cornerRadius: Design.Radius.featured,
                                showIcon: true,
                                iconSize: 60
                            )
                        }
                    }
                    .padding(.horizontal, Design.Spacing.lg)

                    // Info
                    VStack(alignment: .leading, spacing: Design.Spacing.md) {
                        Text(recipe.name)
                            .font(.title)
                            .fontWeight(.bold)

                        Text(recipe.recipeDescription)
                            .font(.body)
                            .foregroundStyle(.secondary)

                        // Action buttons
                        HStack(spacing: Design.Spacing.sm) {
                            RecipeActionButton(
                                icon: "calendar.badge.plus",
                                title: "Add to Plan",
                                color: Color.accentPurple,
                                action: { showingAddToPlan = true }
                            )

                            RecipeActionButton(
                                icon: "square.and.arrow.up",
                                title: "Share",
                                color: Color.mintVibrant,
                                action: { showingShareSheet = true }
                            )

                            if recipe.isCustom {
                                RecipeActionButton(
                                    icon: "pencil",
                                    title: "Edit",
                                    color: Color.accentYellow,
                                    action: { showingEditSheet = true }
                                )
                            }
                        }
                        .padding(.vertical, Design.Spacing.sm)

                        // Stats row
                        HStack(spacing: Design.Spacing.xl) {
                            statItem(icon: "clock", value: "\(recipe.totalTimeMinutes)m", label: "Time")
                            statItem(icon: "flame", value: "\(recipe.calories)", label: "Calories")
                            statItem(icon: "person.2", value: "\(recipe.servings)", label: "Servings")
                            statItem(icon: "chart.bar", value: recipe.complexity.label, label: "Level")
                        }
                        .padding(.vertical, Design.Spacing.md)

                        // Macros
                        NewSectionHeader(title: "Nutrition")
                        HStack(spacing: Design.Spacing.lg) {
                            macroChip(label: "Protein", value: "\(recipe.proteinGrams)g", color: .proteinColor)
                            macroChip(label: "Carbs", value: "\(recipe.carbsGrams)g", color: .carbColor)
                            macroChip(label: "Fat", value: "\(recipe.fatGrams)g", color: .fatColor)
                        }

                        // Ingredients
                        if let ingredients = recipe.ingredients, !ingredients.isEmpty {
                            NewSectionHeader(title: "Ingredients")
                            VStack(spacing: Design.Spacing.sm) {
                                ForEach(ingredients, id: \.id) { recipeIngredient in
                                    HStack {
                                        Image(systemName: "circle.fill")
                                            .font(.system(size: 6))
                                            .foregroundStyle(Color.accentPurple)

                                        Text(recipeIngredient.ingredient?.name ?? "Unknown")
                                            .font(.body)
                                            .foregroundStyle(.primary)

                                        Spacer()

                                        Text(formattedQuantity(for: recipeIngredient))
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, Design.Spacing.sm)
                                    .padding(.horizontal, Design.Spacing.md)
                                    .background(
                                        RoundedRectangle(cornerRadius: Design.Radius.md)
                                            .fill(Color.backgroundSecondary)
                                    )
                                }
                            }
                        }

                        // Instructions
                        if !recipe.instructions.isEmpty {
                            NewSectionHeader(title: "Instructions")
                            VStack(alignment: .leading, spacing: Design.Spacing.md) {
                                ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, instruction in
                                    HStack(alignment: .top, spacing: Design.Spacing.md) {
                                        Text("\(index + 1)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white)
                                            .frame(width: 24, height: 24)
                                            .background(Circle().fill(Color.accentPurple))

                                        Text(instruction)
                                            .font(.body)
                                            .foregroundStyle(.primary)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Design.Spacing.lg)
                }
                .padding(.bottom, Design.Spacing.xxl)
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.accentPurple)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { toggleFavorite() }) {
                        Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                            .foregroundStyle(recipe.isFavorite ? .red : Color.accentPurple)
                    }
                }
            }
            .sheet(isPresented: $showingAddToPlan) {
                AddRecipeToPlanSheet(recipe: recipe, mealPlan: currentMealPlan)
            }
            .sheet(isPresented: $showingEditSheet) {
                EditRecipeSheet(recipe: recipe)
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareRecipeSheet(recipe: recipe)
            }
        }
    }

    private func toggleFavorite() {
        withAnimation(Design.Animation.bouncy) {
            recipe.isFavorite.toggle()
        }
    }

    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: Design.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.accentPurple)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func macroChip(label: String, value: String, color: Color) -> some View {
        VStack(spacing: Design.Spacing.xs) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(color)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Design.Spacing.md)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: Design.Radius.md))
    }
}

// MARK: - Add Recipe Sheet
struct AddRecipeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var recipeName = ""
    @State private var recipeDescription = ""
    @State private var servings = 2
    @State private var prepTime = 15
    @State private var cookTime = 30
    @State private var complexity: RecipeComplexity = .easy

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Design.Spacing.xl) {
                    // Recipe Name
                    VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                        Text("Recipe Name")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        TextField("e.g., Grilled Chicken Salad", text: $recipeName)
                            .font(.body)
                            .padding(Design.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: Design.Radius.md)
                                    .fill(Color.backgroundSecondary)
                            )
                    }

                    // Description
                    VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                        Text("Description")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        TextField("Brief description...", text: $recipeDescription, axis: .vertical)
                            .font(.body)
                            .lineLimit(3...6)
                            .padding(Design.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: Design.Radius.md)
                                    .fill(Color.backgroundSecondary)
                            )
                    }

                    // Complexity
                    VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                        Text("Difficulty")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        HStack(spacing: Design.Spacing.sm) {
                            ForEach(RecipeComplexity.allCases) { level in
                                Button(action: { complexity = level }) {
                                    Text(level.label)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(complexity == level ? .white : .primary)
                                        .padding(.horizontal, Design.Spacing.md)
                                        .padding(.vertical, Design.Spacing.sm)
                                        .background(
                                            Capsule()
                                                .fill(complexity == level ? Color.accentPurple : Color.backgroundSecondary)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Time & Servings
                    HStack(spacing: Design.Spacing.lg) {
                        // Prep Time
                        VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                            Text("Prep Time")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)

                            Stepper("\(prepTime) min", value: $prepTime, in: 5...180, step: 5)
                                .padding(Design.Spacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: Design.Radius.md)
                                        .fill(Color.backgroundSecondary)
                                )
                        }

                        // Cook Time
                        VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                            Text("Cook Time")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)

                            Stepper("\(cookTime) min", value: $cookTime, in: 0...180, step: 5)
                                .padding(Design.Spacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: Design.Radius.md)
                                        .fill(Color.backgroundSecondary)
                                )
                        }
                    }

                    // Servings
                    VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                        Text("Servings")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        Stepper("\(servings) servings", value: $servings, in: 1...12)
                            .padding(Design.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: Design.Radius.md)
                                    .fill(Color.backgroundSecondary)
                            )
                    }
                }
                .padding(Design.Spacing.lg)
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("New Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveRecipe() }
                        .fontWeight(.semibold)
                        .foregroundStyle(recipeName.isEmpty ? .gray : Color.accentPurple)
                        .disabled(recipeName.isEmpty)
                }
            }
        }
    }

    private func saveRecipe() {
        let recipe = Recipe(
            name: recipeName,
            recipeDescription: recipeDescription,
            instructions: [],
            prepTimeMinutes: prepTime,
            cookTimeMinutes: cookTime,
            servings: servings,
            complexity: complexity,
            cuisineType: nil,
            calories: 0,
            proteinGrams: 0,
            carbsGrams: 0,
            fatGrams: 0,
            fiberGrams: 0
        )
        recipe.isCustom = true

        modelContext.insert(recipe)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Recipe Action Button
struct RecipeActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))

                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Design.Spacing.sm)
            .foregroundStyle(color)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.md)
                    .fill(color.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Recipe To Plan Sheet
struct AddRecipeToPlanSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let recipe: Recipe
    let mealPlan: MealPlan?

    @State private var selectedMealType: MealType = .lunch
    @State private var selectedDayIndex: Int = 0

    private var availableDays: [Day] {
        mealPlan?.sortedDays ?? []
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Design.Spacing.xl) {
                if mealPlan == nil || availableDays.isEmpty {
                    Spacer()
                    VStack(spacing: Design.Spacing.md) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 50))
                            .foregroundStyle(Color.textSecondary)

                        Text("No Meal Plan")
                            .font(.headline)

                        Text("Generate a meal plan first to add recipes")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                } else {
                    // Recipe info
                    HStack(spacing: Design.Spacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: Design.Radius.md)
                                .fill(Color.mintMedium)
                                .frame(width: 60, height: 60)

                            Image(systemName: "fork.knife")
                                .font(.system(size: 24))
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(recipe.name)
                                .font(.headline)
                                .lineLimit(1)

                            Text("\(recipe.calories) kcal • \(recipe.totalTimeMinutes) min")
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: Design.Radius.card)
                            .fill(Color.cardBackground)
                    )
                    .padding(.horizontal)

                    // Day selector
                    VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                        Text("Select Day")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.textSecondary)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Design.Spacing.sm) {
                                ForEach(Array(availableDays.enumerated()), id: \.element.id) { index, day in
                                    DayPickerButton(
                                        day: day,
                                        isSelected: selectedDayIndex == index,
                                        onSelect: { selectedDayIndex = index }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Meal type selector
                    VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                        Text("Meal Type")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.textSecondary)

                        HStack(spacing: Design.Spacing.sm) {
                            ForEach(MealType.allCases) { type in
                                MealTypePicker(
                                    type: type,
                                    isSelected: selectedMealType == type,
                                    onSelect: { selectedMealType = type }
                                )
                            }
                        }
                    }
                    .padding(.horizontal)

                    Spacer()

                    Button(action: addToPlan) {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                            Text("Add to Plan")
                        }
                    }
                    .purpleButton()
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("Add to Plan")
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

    private func addToPlan() {
        guard selectedDayIndex < availableDays.count else { return }
        let day = availableDays[selectedDayIndex]

        let meal = Meal(mealType: selectedMealType)
        meal.recipe = recipe
        meal.day = day
        day.meals?.append(meal)

        modelContext.insert(meal)
        try? modelContext.save()

        dismiss()
    }
}

// MARK: - Day Picker Button
struct DayPickerButton: View {
    let day: Day
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 2) {
                Text(day.shortDayName)
                    .font(.caption)
                    .fontWeight(.medium)

                Text("\(Calendar.current.component(.day, from: day.date))")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .frame(width: 50, height: 55)
            .foregroundStyle(isSelected ? .white : Color.textPrimary)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.md)
                    .fill(isSelected ? Color.accentPurple : Color.cardBackground)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Meal Type Picker
struct MealTypePicker: View {
    let type: MealType
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 4) {
                Image(systemName: type.icon)
                    .font(.system(size: 18))

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

// MARK: - Edit Recipe Sheet
struct EditRecipeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let recipe: Recipe

    @State private var recipeName: String
    @State private var recipeDescription: String
    @State private var servings: Int
    @State private var prepTime: Int
    @State private var cookTime: Int
    @State private var complexity: RecipeComplexity

    init(recipe: Recipe) {
        self.recipe = recipe
        _recipeName = State(initialValue: recipe.name)
        _recipeDescription = State(initialValue: recipe.recipeDescription)
        _servings = State(initialValue: recipe.servings)
        _prepTime = State(initialValue: recipe.prepTimeMinutes)
        _cookTime = State(initialValue: recipe.cookTimeMinutes)
        _complexity = State(initialValue: recipe.complexity)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Design.Spacing.xl) {
                    // Recipe Name
                    VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                        Text("Recipe Name")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        TextField("Recipe name", text: $recipeName)
                            .font(.body)
                            .padding(Design.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: Design.Radius.md)
                                    .fill(Color.backgroundSecondary)
                            )
                    }

                    // Description
                    VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                        Text("Description")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        TextField("Description", text: $recipeDescription, axis: .vertical)
                            .font(.body)
                            .lineLimit(3...6)
                            .padding(Design.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: Design.Radius.md)
                                    .fill(Color.backgroundSecondary)
                            )
                    }

                    // Complexity
                    VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                        Text("Difficulty")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        HStack(spacing: Design.Spacing.sm) {
                            ForEach(RecipeComplexity.allCases) { level in
                                Button(action: { complexity = level }) {
                                    Text(level.label)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(complexity == level ? .white : .primary)
                                        .padding(.horizontal, Design.Spacing.md)
                                        .padding(.vertical, Design.Spacing.sm)
                                        .background(
                                            Capsule()
                                                .fill(complexity == level ? Color.accentPurple : Color.backgroundSecondary)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Time
                    HStack(spacing: Design.Spacing.lg) {
                        VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                            Text("Prep Time")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)

                            Stepper("\(prepTime) min", value: $prepTime, in: 5...180, step: 5)
                                .padding(Design.Spacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: Design.Radius.md)
                                        .fill(Color.backgroundSecondary)
                                )
                        }

                        VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                            Text("Cook Time")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)

                            Stepper("\(cookTime) min", value: $cookTime, in: 0...180, step: 5)
                                .padding(Design.Spacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: Design.Radius.md)
                                        .fill(Color.backgroundSecondary)
                                )
                        }
                    }

                    // Servings
                    VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                        Text("Servings")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        Stepper("\(servings) servings", value: $servings, in: 1...12)
                            .padding(Design.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: Design.Radius.md)
                                    .fill(Color.backgroundSecondary)
                            )
                    }
                }
                .padding(Design.Spacing.lg)
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("Edit Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                        .fontWeight(.semibold)
                        .foregroundStyle(recipeName.isEmpty ? .gray : Color.accentPurple)
                        .disabled(recipeName.isEmpty)
                }
            }
        }
    }

    private func saveChanges() {
        recipe.name = recipeName
        recipe.recipeDescription = recipeDescription
        recipe.servings = servings
        recipe.prepTimeMinutes = prepTime
        recipe.cookTimeMinutes = cookTime
        recipe.complexity = complexity

        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Share Recipe Sheet
struct ShareRecipeSheet: View {
    @Environment(\.dismiss) private var dismiss
    let recipe: Recipe

    private var shareText: String {
        var text = "🍽️ \(recipe.name)\n\n"
        text += "\(recipe.recipeDescription)\n\n"
        text += "📊 Nutrition:\n"
        text += "• \(recipe.calories) calories\n"
        text += "• \(recipe.proteinGrams)g protein\n"
        text += "• \(recipe.carbsGrams)g carbs\n"
        text += "• \(recipe.fatGrams)g fat\n\n"
        text += "⏱️ Total time: \(recipe.totalTimeMinutes) minutes\n"
        text += "👨‍🍳 Difficulty: \(recipe.complexity.label)\n\n"

        if !recipe.instructions.isEmpty {
            text += "📝 Instructions:\n"
            for (index, instruction) in recipe.instructions.enumerated() {
                text += "\(index + 1). \(instruction)\n"
            }
        }

        text += "\n\nShared from MealPrepAI"
        return text
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Design.Spacing.xl) {
                Spacer()

                // Preview card
                VStack(spacing: Design.Spacing.md) {
                    Image(systemName: "square.and.arrow.up.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.mintVibrant)

                    Text("Share Recipe")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Share \"\(recipe.name)\" with friends and family")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                // Share options
                VStack(spacing: Design.Spacing.sm) {
                    ShareLink(item: shareText) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Recipe")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundStyle(.white)
                        .background(
                            RoundedRectangle(cornerRadius: Design.Radius.xl)
                                .fill(LinearGradient.purpleButtonGradient)
                        )
                    }

                    Button(action: copyToClipboard) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Copy to Clipboard")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundStyle(Color.accentPurple)
                        .background(
                            RoundedRectangle(cornerRadius: Design.Radius.xl)
                                .fill(Color.accentPurple.opacity(0.1))
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(LinearGradient.mintBackgroundGradient.ignoresSafeArea())
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.accentPurple)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = shareText
        dismiss()
    }
}

#Preview {
    RecipesView()
        .modelContainer(for: [Recipe.self, UserProfile.self, MealPlan.self], inMemory: true)
}
