import SwiftUI
import SwiftData
import UIKit

struct RecipesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(FirebaseRecipeService.self) private var firebaseService
    @Query(sort: \Recipe.createdAt, order: .reverse) private var allRecipes: [Recipe]
    @Query private var userProfiles: [UserProfile]
    @Query(filter: #Predicate<MealPlan> { $0.isActive }, sort: \MealPlan.createdAt, order: .reverse)
    private var mealPlans: [MealPlan]
    @Query private var allIngredients: [Ingredient]

    // MARK: - State
    @State private var searchText = ""
    @State private var debouncedSearchText = ""
    @State private var searchTask: Task<Void, Never>?
    @State private var selectedCategory: FoodCategory = .all
    @State private var selectedFilters: Set<RecipeFilter> = []
    @State private var showingAddRecipe = false
    @State private var showingFilterSheet = false
    @State private var animateContent = false
    @State private var selectedRecipe: Recipe?
    @State private var recipeToAddToPlan: Recipe?

    // MARK: - Firebase Integration State
    @State private var isLoading = false
    @State private var isRefreshing = false
    @State private var isLoadingMore = false
    @State private var isSearchingFirebase = false
    @State private var isSyncing = false  // Mutex for sync operations
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    @State private var lastSyncDate: Date?
    @State private var firebaseSearchResults: [Recipe] = []
    @State private var showFirebaseSearchPrompt = false
    @State private var isOffline = false
    @State private var loadMoreError: String?
    @State private var searchError: String?
    @State private var showSyncSuccessToast = false
    @State private var syncSuccessMessage = ""

    private var userProfile: UserProfile? {
        userProfiles.first
    }

    private var filteredRecipes: [Recipe] {
        // Start with recipes that have valid instructions and are from Firebase (not AI-generated)
        var recipes = allRecipes.filter { $0.isCustom || ($0.hasValidInstructions && $0.isFromFirebase) }

        // Apply category filter
        if selectedCategory != .all {
            recipes = recipes.filter { recipe in
                recipe.matchesCategory(selectedCategory)
            }
        }

        // Apply all selected filters (recipe must match ALL selected filters)
        for filter in selectedFilters {
            recipes = recipes.filter { recipe in
                filter.matches(recipe)
            }
        }

        // Apply search to local recipes (uses debounced text to avoid filtering on every keystroke)
        if !debouncedSearchText.isEmpty {
            recipes = recipes.filter {
                $0.name.localizedCaseInsensitiveContains(debouncedSearchText) ||
                $0.recipeDescription.localizedCaseInsensitiveContains(debouncedSearchText)
            }

            // Merge with Firebase search results (avoiding duplicates)
            // Use non-nil firebaseIds for deduplication, also check by recipe ID
            let localFirebaseIds = Set(recipes.compactMap { $0.firebaseId })
            let localRecipeIds = Set(recipes.map { $0.id })
            let uniqueFirebaseResults = firebaseSearchResults.filter { recipe in
                // Exclude if we already have this recipe by firebaseId or by persistentModelID
                if let fbId = recipe.firebaseId, localFirebaseIds.contains(fbId) {
                    return false
                }
                if localRecipeIds.contains(recipe.id) {
                    return false
                }
                return true
            }
            recipes.append(contentsOf: uniqueFirebaseResults)
        }

        return recipes
    }

    /// Check if any filter is active
    private var hasActiveFilter: Bool {
        selectedCategory != .all || !selectedFilters.isEmpty
    }

    /// Check if we should show "Search Firebase" prompt
    private var shouldShowSearchFirebasePrompt: Bool {
        // Show if there's a search error (for retry)
        if searchError != nil { return true }

        // Show if searching with few local results
        return !debouncedSearchText.isEmpty &&
               filteredRecipes.count < 5 &&
               !isSearchingFirebase &&
               firebaseSearchResults.isEmpty
    }

    private var featuredRecipe: Recipe? {
        allRecipes.first { $0.isFavorite } ?? allRecipes.first
    }

    private var gridRecipes: [Recipe] {
        if let featured = featuredRecipe, selectedCategory == .all && debouncedSearchText.isEmpty {
            return filteredRecipes.filter { $0.id != featured.id }
        }
        return filteredRecipes
    }

    private var emptyStateTitle: String {
        if isLoading {
            return "Loading Recipes"
        } else if !debouncedSearchText.isEmpty {
            return "No Results"
        } else if selectedCategory != .all {
            return "No \(selectedCategory.rawValue) Recipes"
        }
        return "No Recipes Yet"
    }

    private var emptyStateMessage: String {
        if isLoading {
            return "Fetching delicious recipes for you..."
        } else if !debouncedSearchText.isEmpty {
            return "Try adjusting your search."
        } else if selectedCategory != .all {
            return "Try selecting a different category or pull down to refresh."
        }
        return "Pull down to fetch recipes from our collection, or add your own."
    }

    // MARK: - Sync Status Text
    private var syncStatusText: String? {
        if let lastSync = lastSyncDate {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return "Updated \(formatter.localizedString(for: lastSync, relativeTo: Date()))"
        }
        return nil
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: Design.Spacing.lg) {
                    // Title with sync status
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Explore New Recipes")
                                .font(Design.Typography.title)
                                .foregroundStyle(.primary)

                            if let status = syncStatusText {
                                Text(status)
                                    .font(.caption)
                                    .foregroundStyle(Color.textSecondary)
                            }
                        }
                        Spacer()

                        // Refresh indicator
                        if isRefreshing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
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

                    // Nutrition Filter Chips
                    nutritionFilterChips
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)

                    // Offline Banner
                    if isOffline {
                        offlineBanner
                            .padding(.horizontal, Design.Spacing.lg)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Loading State
                    if isLoading && filteredRecipes.isEmpty {
                        recipeSkeletonView
                            .transition(.opacity)
                    } else if filteredRecipes.isEmpty {
                        // Empty State
                        emptyStateView
                            .opacity(animateContent ? 1 : 0)
                    } else {
                        // Featured Recipe Card (only show when not filtering)
                        if let featured = featuredRecipe, debouncedSearchText.isEmpty && !hasActiveFilter {
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
                            HStack {
                                NewSectionHeader(
                                    title: debouncedSearchText.isEmpty ? "All Recipes" : "Results",
                                    showSeeAll: false
                                )

                                Spacer()

                                // Recipe count badge
                                if firebaseService.totalRecipesCount > 0 {
                                    Text("\(allRecipes.count)/\(firebaseService.totalRecipesCount)")
                                        .font(.caption)
                                        .foregroundStyle(Color.textSecondary)
                                        .padding(.horizontal, Design.Spacing.sm)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(Color.backgroundSecondary)
                                        )
                                }
                            }
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
                                        .easeOut(duration: 0.4).delay(Double(min(index, 10)) * 0.05),
                                        value: animateContent
                                    )
                                }
                            }
                            .padding(.horizontal, Design.Spacing.lg)

                            // Search Firebase prompt when local results are insufficient
                            if shouldShowSearchFirebasePrompt && debouncedSearchText.count >= 2 {
                                searchFirebasePromptView
                                    .padding(.horizontal, Design.Spacing.lg)
                                    .padding(.top, Design.Spacing.md)
                            }

                            // Load More button
                            if debouncedSearchText.isEmpty && firebaseService.hasMoreRecipes {
                                loadMoreButton
                                    .padding(.horizontal, Design.Spacing.lg)
                                    .padding(.top, Design.Spacing.lg)
                            }
                        }
                        .opacity(animateContent ? 1 : 0)
                    }
                }
                .padding(.bottom, Design.Spacing.xxl)
            }
            .refreshable {
                await refreshRecipes()
            }
            .background(
                LinearGradient.mintBackgroundGradient
                    .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddRecipe = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.accentPurple)
                    }
                    .accessibilityLabel("Add custom recipe")
                }
            }
            .sheet(isPresented: $showingAddRecipe) {
                AddRecipeSheet()
            }
            .sheet(item: $selectedRecipe) { recipe in
                RecipeDetailSheet(recipe: recipe)
            }
            .sheet(item: $recipeToAddToPlan) { recipe in
                AddRecipeToPlanSheet(recipe: recipe, mealPlan: currentMealPlan)
            }
            .alert("Sync Error", isPresented: $showErrorAlert) {
                Button("Retry") {
                    Task { await refreshRecipes() }
                }
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Failed to fetch recipes. Please try again.")
            }
            .overlay(alignment: .top) {
                // Success toast
                if showSyncSuccessToast {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)

                        Text(syncSuccessMessage)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.mintVibrant, .mintVibrant.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .mintVibrant.opacity(0.4), radius: 12, y: 6)
                    )
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
                }
            }
            .onAppear {
                if !animateContent {
                    withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                        animateContent = true
                    }
                }
                // Load last sync date from UserDefaults
                lastSyncDate = UserDefaults.standard.object(forKey: "lastRecipeSyncDate") as? Date
            }
            .onChange(of: searchText) { _, newValue in
                // Debounce search - cancel previous task and start new one
                searchTask?.cancel()
                searchTask = Task {
                    // Wait 500ms before updating debounced text
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    if !Task.isCancelled {
                        debouncedSearchText = newValue
                        // Only clear Firebase results AFTER debounce when search is cleared
                        // This prevents UI flickering while typing
                        if newValue.isEmpty {
                            firebaseSearchResults = []
                        }
                    }
                }
            }
            .task {
                // Attempt initial sync if needed
                await initialSyncIfNeeded()
            }
        }
    }

    // MARK: - Offline Banner
    private var offlineBanner: some View {
        HStack(spacing: Design.Spacing.sm) {
            Image(systemName: "wifi.slash")
                .font(.subheadline)
                .foregroundStyle(.white)

            Text("You're offline. Showing cached recipes.")
                .font(.subheadline)
                .foregroundStyle(.white)

            Spacer()

            Button(action: {
                Task { await refreshRecipes() }
            }) {
                Text("Retry")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Design.Spacing.sm)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .stroke(Color.white, lineWidth: 1)
                    )
            }
        }
        .padding(Design.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Design.Radius.md)
                .fill(Color.accentOrange)
        )
    }

    // MARK: - Recipe Skeleton View (Loading Placeholder)
    private var recipeSkeletonView: some View {
        VStack(spacing: Design.Spacing.lg) {
            // Featured skeleton
            skeletonCard(height: 200)
                .padding(.horizontal, Design.Spacing.lg)

            // Grid skeletons
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Design.Spacing.md),
                GridItem(.flexible(), spacing: Design.Spacing.md)
            ], spacing: Design.Spacing.md) {
                ForEach(0..<4, id: \.self) { _ in
                    skeletonCard(height: 180)
                }
            }
            .padding(.horizontal, Design.Spacing.lg)
        }
        .shimmer()
    }

    private func skeletonCard(height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: Design.Radius.card)
            .fill(Color.cardBackground)
            .frame(height: height)
            .overlay(
                VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                    Spacer()
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.backgroundSecondary)
                        .frame(height: 16)
                        .frame(maxWidth: 120)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.backgroundSecondary)
                        .frame(height: 12)
                        .frame(maxWidth: 80)
                }
                .padding(Design.Spacing.md),
                alignment: .bottomLeading
            )
    }

    // MARK: - Recipe Filter Chips (Multi-select)
    private var nutritionFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Design.Spacing.sm) {
                ForEach(RecipeFilter.allCases) { filter in
                    let isSelected = selectedFilters.contains(filter)

                    Button(action: {
                        withAnimation(Design.Animation.smooth) {
                            if isSelected {
                                selectedFilters.remove(filter)
                            } else {
                                selectedFilters.insert(filter)
                            }
                        }
                    }) {
                        HStack(spacing: 6) {
                            // Icon with circle background
                            ZStack {
                                Circle()
                                    .fill(isSelected ? .white.opacity(0.25) : filter.color.opacity(0.15))
                                    .frame(width: 28, height: 28)

                                Image(systemName: filter.icon)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(isSelected ? .white : filter.color)
                            }

                            Text(filter.rawValue)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(isSelected ? .white : .primary)
                        }
                        .padding(.leading, 4)
                        .padding(.trailing, 14)
                        .padding(.vertical, 4)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [filter.color, filter.color.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: filter.color.opacity(0.4), radius: 8, y: 4)
                            } else {
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(isSelected ? 1.02 : 1.0)
                    .accessibilityLabel("\(filter.rawValue) filter")
                    .accessibilityValue(isSelected ? "Selected" : "Not selected")
                    .accessibilityHint("Double tap to toggle filter")
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }

                // Clear filters button (when any filter is active)
                if hasActiveFilter {
                    Button(action: {
                        withAnimation(Design.Animation.smooth) {
                            selectedCategory = .all
                            selectedFilters.removeAll()
                        }
                    }) {
                        HStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(.white.opacity(0.25))
                                    .frame(width: 28, height: 28)

                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                            }

                            Text("Clear")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                        }
                        .padding(.leading, 4)
                        .padding(.trailing, 14)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.red.opacity(0.9), Color.red.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.red.opacity(0.3), radius: 6, y: 3)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Design.Spacing.lg)
            .padding(.vertical, 4)
        }
    }

    // MARK: - Load More Button
    private var loadMoreButton: some View {
        VStack(spacing: Design.Spacing.sm) {
            // Error message if load more failed
            if let error = loadMoreError {
                HStack(spacing: Design.Spacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.accentOrange)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.bottom, Design.Spacing.xs)
            }

            Button(action: {
                loadMoreError = nil
                Task { await loadMoreRecipes() }
            }) {
                HStack(spacing: Design.Spacing.sm) {
                    if isLoadingMore {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else if loadMoreError != nil {
                        Image(systemName: "arrow.clockwise")
                    } else {
                        Image(systemName: "arrow.down.circle")
                    }
                    Text(isLoadingMore ? "Loading..." : (loadMoreError != nil ? "Retry" : "Load More Recipes"))
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(loadMoreError != nil ? Color.accentOrange : Color.accentPurple)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Design.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Design.Radius.lg)
                        .fill(loadMoreError != nil ? Color.accentOrange.opacity(0.1) : Color.accentPurple.opacity(0.1))
                )
            }
            .disabled(isLoadingMore)
        }
    }

    // MARK: - Search Firebase Prompt
    private var searchFirebasePromptView: some View {
        VStack(spacing: Design.Spacing.sm) {
            // Error message if search failed
            if let error = searchError {
                HStack(spacing: Design.Spacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.accentOrange)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                    Spacer()
                }
                .padding(.horizontal, Design.Spacing.md)
                .padding(.top, Design.Spacing.sm)
            }

            HStack(spacing: Design.Spacing.sm) {
                Image(systemName: searchError != nil ? "exclamationmark.magnifyingglass" : "magnifyingglass.circle")
                    .font(.title2)
                    .foregroundStyle(searchError != nil ? Color.accentOrange : Color.accentPurple)

                VStack(alignment: .leading, spacing: 2) {
                    Text(searchError != nil ? "Search failed" : "Can't find what you're looking for?")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(searchError != nil ? "Check your connection and try again" : "Search our full recipe database")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                Button(action: {
                    searchError = nil
                    Task { await searchFirebase() }
                }) {
                    if isSearchingFirebase {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text(searchError != nil ? "Retry" : "Search")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, Design.Spacing.md)
                            .padding(.vertical, Design.Spacing.sm)
                            .background(
                                Capsule()
                                    .fill(searchError != nil ? Color.accentOrange : Color.accentPurple)
                            )
                    }
                }
                .disabled(isSearchingFirebase)
            }
            .padding(Design.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.card)
                    .fill(Color.cardBackground)
            )
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

                Image(systemName: isLoading ? "arrow.triangle.2.circlepath" : "book.closed.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(Color.mintVibrant)
                    .rotationEffect(.degrees(isLoading ? 360 : 0))
                    .animation(isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isLoading)
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

            if !isLoading && debouncedSearchText.isEmpty {
                VStack(spacing: Design.Spacing.sm) {
                    Button(action: {
                        Task { await refreshRecipes() }
                    }) {
                        HStack(spacing: Design.Spacing.sm) {
                            Image(systemName: "arrow.clockwise")
                            Text("Fetch Recipes")
                        }
                    }
                    .purpleButton()

                    Button(action: { showingAddRecipe = true }) {
                        HStack(spacing: Design.Spacing.sm) {
                            Image(systemName: "plus")
                            Text("Add Custom Recipe")
                        }
                        .font(.subheadline)
                        .foregroundStyle(Color.accentPurple)
                    }
                }
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

    private var currentMealPlan: MealPlan? {
        mealPlans.first
    }

    private func addToMealPlan(_ recipe: Recipe) {
        recipeToAddToPlan = recipe
    }

    // MARK: - Firebase Sync Helpers

    /// Normalize ingredient name for comparison (handles plurals, common variations)
    private func normalizeIngredientName(_ name: String) -> String {
        var normalized = name.lowercased().trimmingCharacters(in: .whitespaces)

        // Remove common plural suffixes
        let pluralSuffixes = ["ies", "es", "s"]
        for suffix in pluralSuffixes {
            if normalized.count > suffix.count + 2 && normalized.hasSuffix(suffix) {
                // Special case: "ies" -> "y" (e.g., "berries" -> "berry")
                if suffix == "ies" {
                    normalized = String(normalized.dropLast(3)) + "y"
                } else {
                    normalized = String(normalized.dropLast(suffix.count))
                }
                break
            }
        }

        // Normalize common variations
        let variations: [String: String] = [
            "tomatos": "tomato",
            "potatos": "potato",
            "chili": "chile",
            "chilis": "chile",
            "chiles": "chile",
            "pepperoni": "pepperoni", // Don't singularize
            "broccoli": "broccoli",   // Don't singularize
            "zucchini": "zucchini",   // Don't singularize
            "spaghetti": "spaghetti", // Don't singularize
        ]

        if let mapped = variations[normalized] {
            normalized = mapped
        }

        return normalized
    }

    /// Find or create an ingredient (prevents duplicates, handles plurals)
    private func findOrCreateIngredient(
        name: String,
        category: GroceryCategory,
        unit: MeasurementUnit
    ) -> Ingredient {
        let displayName = name.capitalized.trimmingCharacters(in: .whitespaces)
        let normalizedName = normalizeIngredientName(name)

        // Search existing ingredients by normalized name (handles plurals)
        if let existing = allIngredients.first(where: {
            normalizeIngredientName($0.name) == normalizedName
        }) {
            return existing
        }

        // Create new ingredient with display name
        let ingredient = Ingredient(
            name: displayName,
            category: category,
            defaultUnit: unit
        )
        modelContext.insert(ingredient)
        return ingredient
    }

    /// Sync a single Firebase recipe to SwiftData (handles deduplication and updates)
    private func syncFirebaseRecipe(_ fbRecipe: FirebaseRecipe) -> (recipe: Recipe, isNew: Bool) {
        // Check if recipe already exists locally
        if let existingRecipe = allRecipes.first(where: { $0.firebaseId == fbRecipe.id }) {
            // Update existing recipe with latest data
            existingRecipe.update(from: fbRecipe)
            return (existingRecipe, false)
        }

        // Create new local recipe from Firebase data
        let recipe = Recipe(from: fbRecipe)
        modelContext.insert(recipe)

        // Create ingredients for this recipe (with deduplication)
        for fbIngredient in fbRecipe.ingredients {
            let ingredient = findOrCreateIngredient(
                name: fbIngredient.name,
                category: GroceryCategory.fromAisle(fbIngredient.aisle),
                unit: MeasurementUnit.fromString(fbIngredient.unit)
            )

            // Create the recipe-ingredient link
            let recipeIngredient = RecipeIngredient(
                quantity: fbIngredient.amount,
                unit: MeasurementUnit.fromString(fbIngredient.unit)
            )
            recipeIngredient.ingredient = ingredient
            recipeIngredient.recipe = recipe
            modelContext.insert(recipeIngredient)
        }

        return (recipe, true)
    }

    /// Save model context with proper error handling
    private func saveContext() throws {
        do {
            try modelContext.save()
        } catch {
            print("❌ [RecipesView] Failed to save context: \(error)")
            throw error
        }
    }

    /// Show success feedback with toast
    private func showSyncSuccess(count: Int) {
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Show toast
        syncSuccessMessage = count == 1 ? "1 new recipe added" : "\(count) new recipes added"
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showSyncSuccessToast = true
        }

        // Auto-dismiss after 2.5 seconds
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            withAnimation(.easeOut(duration: 0.3)) {
                showSyncSuccessToast = false
            }
        }
    }

    // MARK: - Firebase Sync Actions

    /// Load more recipes from Firebase (pagination)
    private func loadMoreRecipes() async {
        // Mutex: prevent concurrent sync operations
        guard !isLoadingMore && !isSyncing else { return }
        print("📥 [RecipesView] Loading more recipes...")

        // If pagination state is not initialized, do a full refresh instead
        if !firebaseService.isPaginationInitialized {
            print("📥 [RecipesView] Pagination not initialized, doing full refresh...")
            await refreshRecipes()
            return
        }

        isLoadingMore = true
        isSyncing = true
        loadMoreError = nil

        defer {
            isLoadingMore = false
            isSyncing = false
        }

        do {
            let moreRecipes = try await firebaseService.fetchMoreRecipes()
            print("✅ [RecipesView] Got \(moreRecipes.count) more recipes from Firebase")

            // Save to SwiftData with deduplication
            var newCount = 0
            for fbRecipe in moreRecipes {
                let (_, isNew) = syncFirebaseRecipe(fbRecipe)
                if isNew { newCount += 1 }
            }

            try saveContext()
            print("✅ [RecipesView] Saved \(newCount) new recipes locally")

            if newCount > 0 {
                showSyncSuccess(count: newCount)
            }

            withAnimation {
                isOffline = false
            }
        } catch {
            print("❌ [RecipesView] Load more error: \(error)")
            loadMoreError = isNetworkError(error) ? "No internet connection" : "Failed to load recipes"
            withAnimation {
                isOffline = isNetworkError(error)
            }
        }
    }

    /// Search recipes in Firebase database
    private func searchFirebase() async {
        // Capture search text at call time to avoid races
        let query = debouncedSearchText
        // Mutex: prevent concurrent operations
        guard !query.isEmpty && !isSyncing else { return }
        print("🔍 [RecipesView] Searching Firebase for: '\(query)'")
        isSearchingFirebase = true
        isSyncing = true
        searchError = nil

        // Clear old search results when starting a new search
        firebaseSearchResults = []

        defer {
            isSearchingFirebase = false
            isSyncing = false
        }

        do {
            let searchResults = try await firebaseService.searchRecipes(query: query)
            print("✅ [RecipesView] Firebase search returned \(searchResults.count) results")

            // Convert to local Recipe objects and save (with deduplication)
            var newRecipes: [Recipe] = []
            for fbRecipe in searchResults {
                let (recipe, isNew) = syncFirebaseRecipe(fbRecipe)
                if isNew {
                    newRecipes.append(recipe)
                }
            }

            try saveContext()
            firebaseSearchResults = newRecipes

            withAnimation {
                isOffline = false
            }
            print("✅ [RecipesView] Added \(newRecipes.count) new recipes from search")

            if newRecipes.count > 0 {
                showSyncSuccess(count: newRecipes.count)
            }
        } catch {
            print("❌ [RecipesView] Firebase search error: \(error)")
            searchError = isNetworkError(error) ? "No internet connection" : "Search failed"
            withAnimation {
                isOffline = isNetworkError(error)
            }
        }
    }

    /// Clear Firebase search results when search text changes
    private func clearFirebaseSearch() {
        firebaseSearchResults = []
    }

    /// Initial sync if cache is empty or stale
    private func initialSyncIfNeeded() async {
        let hasFirebaseRecipes = allRecipes.contains { $0.isFromFirebase }
        print("📋 [RecipesView] Initial sync check: hasFirebaseRecipes=\(hasFirebaseRecipes)")

        if !hasFirebaseRecipes {
            await refreshRecipes()
        }
    }

    /// Refresh recipes from Firebase (resets pagination)
    private func refreshRecipes() async {
        // Mutex: prevent concurrent sync operations
        guard !isSyncing else {
            print("⚠️ [RecipesView] Sync already in progress, skipping refresh")
            return
        }

        print("🔄 [RecipesView] Starting refresh...")
        isRefreshing = true
        isLoading = true
        isSyncing = true
        errorMessage = nil
        firebaseSearchResults = []
        loadMoreError = nil
        searchError = nil

        defer {
            isRefreshing = false
            isLoading = false
            isSyncing = false
            print("🔄 [RecipesView] Refresh complete")
        }

        do {
            // Reset pagination and fetch initial page
            print("🔄 [RecipesView] Calling firebaseService.fetchInitialRecipes()...")
            let firebaseRecipes = try await firebaseService.fetchInitialRecipes()
            print("✅ [RecipesView] Fetched \(firebaseRecipes.count) recipes from Firebase")

            // Clear offline state on successful fetch
            withAnimation {
                isOffline = false
            }

            // Sync to local SwiftData with deduplication
            var newCount = 0
            var updatedCount = 0

            for fbRecipe in firebaseRecipes {
                let (_, isNew) = syncFirebaseRecipe(fbRecipe)
                if isNew {
                    newCount += 1
                } else {
                    updatedCount += 1
                }
            }

            print("💾 [RecipesView] Saving to SwiftData: \(newCount) new, \(updatedCount) updated")

            // Save changes
            try saveContext()

            // Update last sync date
            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: "lastRecipeSyncDate")

            // Success feedback
            if newCount > 0 {
                showSyncSuccess(count: newCount)
            }

            print("✅ [RecipesView] Sync complete! Total local recipes: \(allRecipes.count)")
        } catch {
            print("❌ [RecipesView] Firebase sync error: \(error)")
            print("❌ [RecipesView] Error details: \(error.localizedDescription)")

            // Check if it's a network error
            if isNetworkError(error) {
                withAnimation {
                    isOffline = true
                }
                errorMessage = "You're offline. Showing cached recipes."
            } else {
                errorMessage = error.localizedDescription
            }

            // Only show alert if we have no cached recipes to display
            if allRecipes.isEmpty {
                showErrorAlert = true
            }
        }
    }

    /// Check if an error is network-related
    private func isNetworkError(_ error: Error) -> Bool {
        let nsError = error as NSError

        // Check for common network error codes
        let networkErrorCodes = [
            NSURLErrorNotConnectedToInternet,
            NSURLErrorNetworkConnectionLost,
            NSURLErrorTimedOut,
            NSURLErrorCannotConnectToHost,
            NSURLErrorCannotFindHost,
            NSURLErrorDNSLookupFailed,
            NSURLErrorInternationalRoamingOff,
            NSURLErrorDataNotAllowed,
            NSURLErrorSecureConnectionFailed,
            NSURLErrorServerCertificateHasBadDate,
            NSURLErrorServerCertificateUntrusted
        ]

        if networkErrorCodes.contains(nsError.code) {
            return true
        }

        // Check for Firebase/Firestore offline errors
        let errorDescription = error.localizedDescription.lowercased()
        return errorDescription.contains("offline") ||
               errorDescription.contains("network") ||
               errorDescription.contains("internet") ||
               errorDescription.contains("connection") ||
               errorDescription.contains("unavailable")
    }
}


#Preview {
    RecipesView()
        .modelContainer(for: [Recipe.self, UserProfile.self, MealPlan.self], inMemory: true)
}
