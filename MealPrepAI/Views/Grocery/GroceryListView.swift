import SwiftUI
import SwiftData

struct GroceryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<MealPlan> { $0.isActive }, sort: \MealPlan.createdAt, order: .reverse)
    private var mealPlans: [MealPlan]

    @State private var searchText = ""
    @State private var showingAddItem = false
    @State private var showingShareSheet = false
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
                        .padding(.bottom, Design.Spacing.xxl)
                    }
                }
            }
            .background(LinearGradient.mintBackgroundGradient.ignoresSafeArea())
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
        HStack(spacing: Design.Spacing.md) {
            VStack(alignment: .leading, spacing: Design.Spacing.xxs) {
                Text("Shopping Progress")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text("\(checkedCount) of \(allItems.count) items")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            }

            Spacer()

            // Progress Ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 5)
                    .frame(width: 56, height: 56)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)

                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
        }
        .padding(Design.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Design.Radius.featured)
                .fill(LinearGradient.purpleButtonGradient)
                .shadow(color: Color.accentPurple.opacity(0.4), radius: 20, y: 10)
        )
        .padding(.horizontal, Design.Spacing.md)
        .padding(.top, Design.Spacing.sm)
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

    private func generateGroceryList() {
        guard let mealPlan = currentMealPlan else { return }

        // Create or clear existing grocery list
        let list: GroceryList
        if let existingList = mealPlan.groceryList {
            // Clear existing items
            for item in existingList.items ?? [] {
                modelContext.delete(item)
            }
            list = existingList
        } else {
            list = GroceryList()
            modelContext.insert(list)
            mealPlan.groceryList = list
        }

        // Collect all ingredients from the meal plan
        var ingredientQuantities: [String: (Ingredient, Double, MeasurementUnit)] = [:]

        for day in mealPlan.sortedDays {
            for meal in day.sortedMeals {
                guard let recipe = meal.recipe else { continue }
                for recipeIngredient in recipe.ingredients ?? [] {
                    guard let ingredient = recipeIngredient.ingredient else { continue }

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

        // Create grocery items
        for (_, (ingredient, quantity, unit)) in ingredientQuantities {
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
        }

        list.lastModified = Date()
        try? modelContext.save()
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
        HStack(spacing: Design.Spacing.md) {
            // Animated Checkbox
            Button(action: {
                withAnimation(Design.Animation.bouncy) {
                    item.isChecked.toggle()
                }
            }) {
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
            }
            .buttonStyle(.plain)

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
        .animation(Design.Animation.smooth, value: item.isChecked)
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
                            .font(.system(size: 12, design: .monospaced))
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
