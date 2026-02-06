import SwiftUI
import SwiftData

struct GroceryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<MealPlan> { $0.isActive }, sort: \MealPlan.createdAt, order: .reverse)
    private var mealPlans: [MealPlan]

    @State private var searchText = ""
    @State private var showingAddItem = false
    @State private var showingShareSheet = false
    @State private var showingHistory = false
    @State private var showingCompleteConfirmation = false
    @State private var animateContent = false

    private var currentMealPlan: MealPlan? {
        mealPlans.first
    }

    private var groceryList: GroceryList? {
        currentMealPlan?.groceryList
    }

    private var allItems: [GroceryItem] {
        groceryList?.sortedItems ?? []
    }

    private var filteredItems: [GroceryItem] {
        if searchText.isEmpty {
            return allItems
        }
        return allItems.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedItems: [(GroceryCategory, [GroceryItem])] {
        let grouped = Dictionary(grouping: filteredItems) { $0.ingredient?.category ?? .other }
        return grouped.sorted { $0.key.sortOrder < $1.key.sortOrder }
    }

    private var checkedCount: Int {
        allItems.filter { $0.isChecked }.count
    }

    private var progress: Double {
        guard !allItems.isEmpty else { return 0 }
        return Double(checkedCount) / Double(allItems.count)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if allItems.isEmpty {
                    emptyStateView
                } else {
                    // Progress Header
                    progressHeader
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : -20)

                    // Search
                    RoundedSearchBar(text: $searchText, placeholder: "Search items...")
                        .padding(.horizontal, Design.Spacing.md)
                        .padding(.vertical, Design.Spacing.sm)

                    // List
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: Design.Spacing.lg, pinnedViews: .sectionHeaders) {
                            ForEach(groupedItems, id: \.0) { category, items in
                                Section {
                                    VStack(spacing: Design.Spacing.xs) {
                                        ForEach(items) { item in
                                            GroceryItemRow(item: item)
                                        }
                                    }
                                } header: {
                                    categoryHeader(category: category, count: items.count)
                                }
                            }
                        }
                        .padding(.horizontal, Design.Spacing.md)
                        .padding(.bottom, 100)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .warmBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: Design.Spacing.xs) {
                        Text("Grocery List")
                            .font(Design.Typography.headline)
                        Image(systemName: "cart.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.mintVibrant)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddItem = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.accentPurple)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button(action: clearCheckedItems) {
                            Label("Clear Checked", systemImage: "checkmark.circle")
                        }
                        Button(action: uncheckAllItems) {
                            Label("Uncheck All", systemImage: "arrow.uturn.backward")
                        }
                        Divider()
                        Button(action: { showingShareSheet = true }) {
                            Label("Share List", systemImage: "square.and.arrow.up")
                        }
                        if currentMealPlan != nil {
                            Divider()
                            Button(action: generateGroceryList) {
                                Label("Regenerate from Meal Plan", systemImage: "arrow.clockwise")
                            }
                        }
                        Divider()
                        Button(action: { showingHistory = true }) {
                            Label("Shopping History", systemImage: "clock.arrow.circlepath")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddGroceryItemSheet()
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareGroceryListSheet(items: allItems)
            }
            .sheet(isPresented: $showingHistory) {
                GroceryHistoryView()
            }
            .alert("Complete Shopping?", isPresented: $showingCompleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Complete", role: .none) {
                    markShoppingComplete()
                }
            } message: {
                Text("This will mark all items as checked and archive this list. You can view it later in Shopping History.")
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) {
                    animateContent = true
                }
            }
        }
    }

    // MARK: - Empty State
    @ViewBuilder
    private var emptyStateView: some View {
        if currentMealPlan != nil {
            NewEmptyStateView(
                icon: "cart.fill",
                title: "No Grocery Items",
                message: "Add items manually or regenerate from your meal plan.",
                buttonTitle: "Generate from Meal Plan",
                buttonIcon: "arrow.clockwise",
                buttonStyle: .purple,
                onButtonTap: { generateGroceryList() }
            )
        } else {
            NewEmptyStateView(
                icon: "cart.fill",
                title: "No Grocery Items",
                message: "Generate a meal plan to automatically create your grocery list."
            )
        }
    }

    // MARK: - Progress Header
    private var progressHeader: some View {
        VStack(spacing: Design.Spacing.md) {
            HStack(spacing: Design.Spacing.md) {
                VStack(alignment: .leading, spacing: Design.Spacing.xxs) {
                    Text("Shopping Progress")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("\(checkedCount) of \(allItems.count) items")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Progress Ring
                ProgressRing(
                    progress: progress,
                    lineWidth: Design.Ring.medium,
                    gradient: LinearGradient(
                        colors: [Color(hex: "34C759"), Color(hex: "30D5C8")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    showLabel: true
                )
                .frame(width: 56, height: 56)
            }

            // Show "Mark Shopping Complete" button when progress >= 80%
            if progress >= 0.8 {
                Button(action: { showingCompleteConfirmation = true }) {
                    HStack(spacing: Design.Spacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                        Text("Mark Shopping Complete")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, Design.Spacing.md)
                    .padding(.vertical, Design.Spacing.sm)
                    .background(
                        Capsule()
                            .fill(Color(hex: "34C759"))
                    )
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .padding(Design.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Design.Radius.card)
                .fill(Color.cardBackground)
                .shadow(
                    color: Design.Shadow.card.color,
                    radius: Design.Shadow.card.radius,
                    y: Design.Shadow.card.y
                )
        )
        .padding(.horizontal, Design.Spacing.md)
        .padding(.top, Design.Spacing.sm)
        .animation(Design.Animation.smooth, value: progress >= 0.8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Shopping progress: \(checkedCount) of \(allItems.count) items, \(Int(progress * 100)) percent complete")
    }

    // MARK: - Category Header
    private func categoryHeader(category: GroceryCategory, count: Int) -> some View {
        HStack(spacing: Design.Spacing.xs) {
            Image(systemName: category.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.accentPurple)

            Text(category.rawValue)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.textPrimary)

            Text("(\(count))")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)

            Spacer()
        }
        .padding(.vertical, Design.Spacing.xs)
        .padding(.horizontal, Design.Spacing.xxs)
        .background(Color.backgroundMint.opacity(0.95))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category.rawValue), \(count) items")
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Actions
    private func clearCheckedItems() {
        guard let list = groceryList else { return }
        let checkedItems = (list.items ?? []).filter { $0.isChecked }
        for item in checkedItems {
            modelContext.delete(item)
        }
        try? modelContext.save()
    }

    private func uncheckAllItems() {
        guard let list = groceryList else { return }
        for item in list.items ?? [] {
            item.isChecked = false
        }
        try? modelContext.save()
    }

    private func markShoppingComplete() {
        guard let list = groceryList else { return }
        withAnimation {
            // Mark all items as checked
            for item in list.items ?? [] {
                item.isChecked = true
            }
            // Mark list as completed
            list.isCompleted = true
            list.completedAt = Date()
            list.lastModified = Date()

            // Deactivate the associated meal plan so a new one can be generated
            if let mealPlan = list.mealPlan {
                mealPlan.isActive = false
            }

            try? modelContext.save()
        }
    }

    private func generateGroceryList() {
        print("[DEBUG:Grocery] ========== GENERATE GROCERY LIST START ==========")
        guard let mealPlan = currentMealPlan else {
            print("[DEBUG:Grocery] ERROR: No current meal plan found")
            return
        }
        print("[DEBUG:Grocery] Meal plan ID: \(mealPlan.id)")
        print("[DEBUG:Grocery] Days in meal plan: \(mealPlan.sortedDays.count)")

        // Create or clear existing grocery list
        let list: GroceryList
        if let existingList = mealPlan.groceryList {
            // Clear existing items
            let existingCount = existingList.items?.count ?? 0
            print("[DEBUG:Grocery] Clearing existing list with \(existingCount) items")
            for item in existingList.items ?? [] {
                modelContext.delete(item)
            }
            list = existingList
        } else {
            print("[DEBUG:Grocery] Creating new grocery list")
            list = GroceryList()
            modelContext.insert(list)
            mealPlan.groceryList = list
        }

        // Collect all ingredients from the meal plan
        var ingredientQuantities: [String: (Ingredient, Double, MeasurementUnit)] = [:]
        var totalMeals = 0
        var totalRecipeIngredients = 0

        for day in mealPlan.sortedDays {
            for meal in day.sortedMeals {
                totalMeals += 1
                guard let recipe = meal.recipe else {
                    print("[DEBUG:Grocery] WARNING: Meal '\(meal.mealType.rawValue)' on day \(day.dayOfWeek) has no recipe")
                    continue
                }
                print("[DEBUG:Grocery] Processing recipe: \(recipe.name) (\(recipe.ingredients?.count ?? 0) ingredients)")
                for recipeIngredient in recipe.ingredients ?? [] {
                    guard let ingredient = recipeIngredient.ingredient else {
                        print("[DEBUG:Grocery] WARNING: RecipeIngredient has no ingredient")
                        continue
                    }
                    totalRecipeIngredients += 1

                    let key = ingredient.name.lowercased()
                    if let existing = ingredientQuantities[key] {
                        // Add to existing quantity (simple addition for same units)
                        ingredientQuantities[key] = (existing.0, existing.1 + recipeIngredient.quantity, existing.2)
                    } else {
                        ingredientQuantities[key] = (ingredient, recipeIngredient.quantity, recipeIngredient.unit)
                    }
                }
            }
        }

        print("[DEBUG:Grocery] Total meals processed: \(totalMeals)")
        print("[DEBUG:Grocery] Total recipe ingredients: \(totalRecipeIngredients)")
        print("[DEBUG:Grocery] Unique ingredients: \(ingredientQuantities.count)")

        // Create grocery items
        for (name, (ingredient, quantity, unit)) in ingredientQuantities {
            let groceryItem = GroceryItem(
                quantity: quantity,
                unit: unit,
                isChecked: false,
                isLocked: false,
                isManuallyAdded: false
            )
            groceryItem.ingredient = ingredient
            groceryItem.groceryList = list
            modelContext.insert(groceryItem)
            print("[DEBUG:Grocery] Added: \(name) - \(quantity) \(unit.rawValue)")
        }

        list.lastModified = Date()
        do {
            try modelContext.save()
            print("[DEBUG:Grocery] SUCCESS: Grocery list saved with \(ingredientQuantities.count) items")
        } catch {
            print("[DEBUG:Grocery] ERROR: Failed to save - \(error.localizedDescription)")
        }
        print("[DEBUG:Grocery] ========== GENERATE GROCERY LIST END ==========")
    }
}

// MARK: - Grocery Category Sort Order
extension GroceryCategory {
    var sortOrder: Int {
        switch self {
        case .produce: return 0
        case .meat: return 1
        case .dairy: return 2
        case .bakery: return 3
        case .frozen: return 4
        case .pantry: return 5
        case .canned: return 6
        case .condiments: return 7
        case .snacks: return 8
        case .beverages: return 9
        case .spices: return 10
        case .other: return 11
        }
    }
}

// MARK: - Grocery Item Row
struct GroceryItemRow: View {
    @Bindable var item: GroceryItem
    @AppStorage("measurementSystem") private var measurementSystem: MeasurementSystem = .metric

    /// Converts and formats the quantity based on user's measurement system preference
    private var convertedQuantity: String {
        let (convertedQty, convertedUnit) = item.unit.convert(item.quantity, to: measurementSystem)
        return MeasurementUnit.formatQuantity(convertedQty, unit: convertedUnit)
    }

    var body: some View {
        Button {
            withAnimation(Design.Animation.bouncy) {
                item.isChecked.toggle()
            }
        } label: {
            HStack(spacing: Design.Spacing.md) {
                // Animated Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(item.isChecked ? LinearGradient.purpleButtonGradient : LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom))
                        .frame(width: 26, height: 26)

                    RoundedRectangle(cornerRadius: 8)
                        .stroke(item.isChecked ? Color.clear : Color.textSecondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 26, height: 26)

                    if item.isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }

                // Item Details
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.displayName)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(item.isChecked ? Color.textSecondary : Color.textPrimary)
                        .strikethrough(item.isChecked)

                    Text(convertedQuantity)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                // Category Icon
                if let category = item.ingredient?.category {
                    Image(systemName: category.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.textSecondary.opacity(0.5))
                }
            }
            .padding(Design.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.md)
                    .fill(Color.cardBackground)
                    .opacity(item.isChecked ? 0.6 : 1)
            )
        }
        .buttonStyle(.plain)
        .animation(Design.Animation.smooth, value: item.isChecked)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.isChecked ? "Checked" : "Unchecked"), \(item.displayName), \(convertedQuantity)")
        .accessibilityHint("Double tap to toggle")
    }
}

// MARK: - Add Item Sheet
struct AddGroceryItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<MealPlan> { $0.isActive }, sort: \MealPlan.createdAt, order: .reverse)
    private var mealPlans: [MealPlan]

    @State private var itemName = ""
    @State private var quantity: Double = 1
    @State private var selectedUnit = MeasurementUnit.piece
    @State private var selectedCategory = GroceryCategory.produce

    private var currentMealPlan: MealPlan? {
        mealPlans.first
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Design.Spacing.lg) {
                // Item Name
                VStack(alignment: .leading, spacing: Design.Spacing.xs) {
                    Text("Item Name")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.textSecondary)

                    TextField("e.g., Chicken Breast", text: $itemName)
                        .font(.body)
                        .padding(Design.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: Design.Radius.md)
                                .fill(Color.mintLight)
                        )
                }

                // Quantity
                VStack(alignment: .leading, spacing: Design.Spacing.xs) {
                    Text("Quantity")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.textSecondary)

                    HStack(spacing: Design.Spacing.md) {
                        HStack {
                            Button(action: { if quantity > 0.5 { quantity -= 0.5 } }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(quantity > 0.5 ? Color.accentPurple : Color.textSecondary)
                            }
                            Text(String(format: quantity.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", quantity))
                                .font(.headline)
                                .frame(width: 40)
                            Button(action: { quantity += 0.5 }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.accentPurple)
                            }
                        }
                        .padding(Design.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: Design.Radius.md)
                                .fill(Color.mintLight)
                        )

                        Picker("Unit", selection: $selectedUnit) {
                            ForEach(MeasurementUnit.allCases) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Color.accentPurple)
                    }
                }

                // Category
                VStack(alignment: .leading, spacing: Design.Spacing.xs) {
                    Text("Category")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.textSecondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Design.Spacing.xs) {
                            ForEach(GroceryCategory.allCases) { cat in
                                CategoryChip(
                                    category: cat,
                                    isSelected: selectedCategory == cat
                                ) {
                                    selectedCategory = cat
                                }
                            }
                        }
                    }
                }

                Spacer()

                // Add Button
                Button(action: addItem) {
                    Text("Add Item")
                }
                .purpleButton()
                .disabled(itemName.isEmpty)
                .opacity(itemName.isEmpty ? 0.5 : 1)
            }
            .padding(Design.Spacing.lg)
            .background(LinearGradient.mintBackgroundGradient.ignoresSafeArea())
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func addItem() {
        // Create or get grocery list
        let groceryList: GroceryList
        if let existingList = currentMealPlan?.groceryList {
            groceryList = existingList
        } else {
            groceryList = GroceryList()
            modelContext.insert(groceryList)
            currentMealPlan?.groceryList = groceryList
        }

        // Create ingredient
        let ingredient = Ingredient(
            name: itemName,
            category: selectedCategory,
            defaultUnit: selectedUnit
        )
        modelContext.insert(ingredient)

        // Create grocery item
        let groceryItem = GroceryItem(
            quantity: quantity,
            unit: selectedUnit,
            isChecked: false,
            isLocked: false,
            isManuallyAdded: true
        )
        groceryItem.ingredient = ingredient
        groceryItem.groceryList = groceryList
        modelContext.insert(groceryItem)

        groceryList.lastModified = Date()
        try? modelContext.save()
        dismiss()
    }
}

struct CategoryChip: View {
    let category: GroceryCategory
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Design.Spacing.xxs) {
                Image(systemName: category.icon)
                    .font(.caption)
                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(isSelected ? .white : Color.textPrimary)
            .padding(.horizontal, Design.Spacing.sm)
            .padding(.vertical, Design.Spacing.xs)
            .background(
                Capsule()
                    .fill(isSelected ? LinearGradient.purpleButtonGradient : LinearGradient(colors: [Color.mintLight], startPoint: .top, endPoint: .bottom))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Share Grocery List Sheet
struct ShareGroceryListSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("measurementSystem") private var measurementSystem: MeasurementSystem = .metric
    let items: [GroceryItem]

    /// Converts and formats quantity for a grocery item
    private func formattedQuantity(for item: GroceryItem) -> String {
        let (convertedQty, convertedUnit) = item.unit.convert(item.quantity, to: measurementSystem)
        return MeasurementUnit.formatQuantity(convertedQty, unit: convertedUnit)
    }

    private var shareText: String {
        var text = "🛒 My Grocery List\n\n"

        // Group by category
        let grouped = Dictionary(grouping: items) { $0.ingredient?.category ?? .other }
        let sortedCategories = grouped.keys.sorted { $0.sortOrder < $1.sortOrder }

        for category in sortedCategories {
            if let categoryItems = grouped[category], !categoryItems.isEmpty {
                text += "\(category.rawValue):\n"
                for item in categoryItems {
                    let checkbox = item.isChecked ? "✅" : "⬜️"
                    text += "\(checkbox) \(item.displayName) - \(formattedQuantity(for: item))\n"
                }
                text += "\n"
            }
        }

        let checkedCount = items.filter { $0.isChecked }.count
        text += "Progress: \(checkedCount)/\(items.count) items checked\n"
        text += "\nCreated with MealPrepAI"

        return text
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Design.Spacing.xl) {
                Spacer()

                // Preview
                VStack(spacing: Design.Spacing.md) {
                    Image(systemName: "cart.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.mintVibrant)

                    Text("Share Grocery List")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("\(items.count) items ready to share")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }

                // Preview Card
                VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                    Text("Preview:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textSecondary)

                    ScrollView {
                        Text(shareText)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(Color.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 150)
                    .padding(Design.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: Design.Radius.md)
                            .fill(Color.mintLight)
                    )
                }
                .padding(.horizontal)

                Spacer()

                // Action buttons
                VStack(spacing: Design.Spacing.sm) {
                    ShareLink(item: shareText) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share List")
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

                    Button(action: exportAsChecklist) {
                        HStack {
                            Image(systemName: "checklist")
                            Text("Export Unchecked Only")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundStyle(Color.mintVibrant)
                        .background(
                            RoundedRectangle(cornerRadius: Design.Radius.xl)
                                .fill(Color.mintVibrant.opacity(0.1))
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
        .presentationDetents([.large])
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = shareText
        dismiss()
    }

    private func exportAsChecklist() {
        let uncheckedItems = items.filter { !$0.isChecked }
        var text = "🛒 Shopping List (Still Needed)\n\n"

        let grouped = Dictionary(grouping: uncheckedItems) { $0.ingredient?.category ?? .other }
        let sortedCategories = grouped.keys.sorted { $0.sortOrder < $1.sortOrder }

        for category in sortedCategories {
            if let categoryItems = grouped[category], !categoryItems.isEmpty {
                text += "\(category.rawValue):\n"
                for item in categoryItems {
                    text += "• \(item.displayName) - \(formattedQuantity(for: item))\n"
                }
                text += "\n"
            }
        }

        text += "\(uncheckedItems.count) items remaining\n"
        text += "\nCreated with MealPrepAI"

        UIPasteboard.general.string = text
        dismiss()
    }
}

#Preview {
    GroceryListView()
        .modelContainer(for: [MealPlan.self, GroceryList.self, GroceryItem.self, Ingredient.self], inMemory: true)
}
