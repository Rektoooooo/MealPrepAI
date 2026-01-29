import SwiftUI
import SwiftData

struct IngredientSubstitutionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let recipe: Recipe
    let recipeIngredient: RecipeIngredient
    let userProfile: UserProfile

    @State private var substitutes: [SubstituteOption] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedIndex: Int?

    private var ingredientName: String {
        recipeIngredient.ingredient?.name ?? "Unknown"
    }

    private var oldCalories: Double {
        guard let ing = recipeIngredient.ingredient else { return 0 }
        return Double(ing.caloriesPer100g) * (recipeIngredient.quantityGrams ?? 0) / 100
    }

    private var oldProtein: Double {
        guard let ing = recipeIngredient.ingredient else { return 0 }
        return ing.proteinPer100g * (recipeIngredient.quantityGrams ?? 0) / 100
    }

    private var oldCarbs: Double {
        guard let ing = recipeIngredient.ingredient else { return 0 }
        return ing.carbsPer100g * (recipeIngredient.quantityGrams ?? 0) / 100
    }

    private var oldFat: Double {
        guard let ing = recipeIngredient.ingredient else { return 0 }
        return ing.fatPer100g * (recipeIngredient.quantityGrams ?? 0) / 100
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Design.Spacing.lg) {
                    // Header: current ingredient
                    currentIngredientHeader

                    if isLoading {
                        loadingView
                    } else if let error = errorMessage {
                        errorView(error)
                    } else {
                        substitutesList
                    }
                }
                .padding(.horizontal, Design.Spacing.lg)
                .padding(.bottom, Design.Spacing.xxl)
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("Swap Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.accentPurple)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !substitutes.isEmpty {
                    confirmButton
                }
            }
        }
        .presentationDetents([.medium, .large])
        .task {
            await loadSubstitutes()
        }
    }

    // MARK: - Current Ingredient Header

    private var currentIngredientHeader: some View {
        VStack(spacing: Design.Spacing.sm) {
            HStack {
                Text("Swapping:")
                    .foregroundStyle(.secondary)
                Text(ingredientName)
                    .fontWeight(.semibold)
                Spacer()
                Text(recipeIngredient.displayQuantity)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)

            HStack(spacing: Design.Spacing.md) {
                miniMacro(label: "Cal", value: "\(Int(oldCalories))", color: .orange)
                miniMacro(label: "P", value: "\(Int(oldProtein))g", color: .proteinColor)
                miniMacro(label: "C", value: "\(Int(oldCarbs))g", color: .carbColor)
                miniMacro(label: "F", value: "\(Int(oldFat))g", color: .fatColor)
            }
        }
        .padding(Design.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Design.Radius.md)
                .fill(Color.backgroundSecondary)
        )
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Design.Spacing.md) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: Design.Radius.md)
                    .fill(Color.backgroundSecondary)
                    .frame(height: 90)
                    .shimmer()
            }
        }
        .padding(.top, Design.Spacing.md)
    }

    // MARK: - Error View

    private func errorView(_ error: String) -> some View {
        VStack(spacing: Design.Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)

            Text(error)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Retry") {
                Task { await loadSubstitutes() }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.accentPurple)
        }
        .padding(.top, Design.Spacing.xl)
    }

    // MARK: - Substitutes List

    private var substitutesList: some View {
        VStack(spacing: Design.Spacing.sm) {
            ForEach(Array(substitutes.enumerated()), id: \.offset) { index, option in
                substituteCard(option: option, index: index)
            }
        }
    }

    private func substituteCard(option: SubstituteOption, index: Int) -> some View {
        let isSelected = selectedIndex == index
        let calDelta = Int(option.totalCalories) - Int(oldCalories)
        let proteinDelta = Int(option.totalProtein) - Int(oldProtein)

        return Button {
            withAnimation(Design.Animation.quick) {
                selectedIndex = index
            }
        } label: {
            HStack(spacing: Design.Spacing.md) {
                // Radio indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.accentPurple : .secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(option.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text(option.reason)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: Design.Spacing.sm) {
                        deltaLabel(value: calDelta, suffix: " cal")
                        deltaLabel(value: proteinDelta, suffix: "g P")
                    }
                    .font(.caption2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(formatQuantity(option.quantity)) \(option.unit)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(Design.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.md)
                    .fill(isSelected ? Color.accentPurple.opacity(0.08) : Color.backgroundSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Design.Radius.md)
                    .stroke(isSelected ? Color.accentPurple : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Confirm Button

    private var confirmButton: some View {
        Button {
            performSwap()
        } label: {
            Text("Swap Ingredient")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Design.Spacing.md)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.accentPurple)
        .disabled(selectedIndex == nil)
        .padding(.horizontal, Design.Spacing.lg)
        .padding(.bottom, Design.Spacing.sm)
        .background(.ultraThinMaterial)
    }

    // MARK: - Helpers

    private func miniMacro(label: String, value: String, color: Color) -> some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
    }

    private func deltaLabel(value: Int, suffix: String) -> some View {
        let sign = value >= 0 ? "+" : ""
        let color: Color = value > 0 ? .orange : value < 0 ? .green : .secondary
        return Text("\(sign)\(value)\(suffix)")
            .foregroundStyle(color)
    }

    private func formatQuantity(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }

    // MARK: - Network

    private func loadSubstitutes() async {
        isLoading = true
        errorMessage = nil

        let otherIngredients = (recipe.ingredients ?? [])
            .filter { $0.id != recipeIngredient.id }
            .compactMap { $0.ingredient?.name }

        let context = SubstituteRecipeContext(
            recipeName: recipe.name,
            totalCalories: recipe.calories,
            totalProtein: recipe.proteinGrams,
            totalCarbs: recipe.carbsGrams,
            totalFat: recipe.fatGrams,
            otherIngredients: otherIngredients
        )

        let restrictions = userProfile.dietaryRestrictions.map(\.rawValue)
        let allergies = userProfile.allergies.map(\.rawValue)

        do {
            let response = try await APIService.shared.substituteIngredient(
                ingredientName: ingredientName,
                ingredientQuantity: recipeIngredient.quantity,
                ingredientUnit: recipeIngredient.unitRaw,
                recipeContext: context,
                dietaryRestrictions: restrictions,
                allergies: allergies
            )

            if response.success, let subs = response.substitutes {
                substitutes = subs
            } else {
                errorMessage = response.error ?? "Failed to load substitutes."
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - SwiftData Update

    private func performSwap() {
        guard let index = selectedIndex, index < substitutes.count else { return }
        let option = substitutes[index]

        // Create or find new ingredient
        let newIngredient = Ingredient(
            name: option.name,
            category: GroceryCategory(rawValue: option.category) ?? .other,
            defaultUnit: MeasurementUnit(rawValue: option.unit) ?? .gram,
            caloriesPer100g: Int(option.caloriesPer100g),
            proteinPer100g: option.proteinPer100g,
            carbsPer100g: option.carbsPer100g,
            fatPer100g: option.fatPer100g
        )
        modelContext.insert(newIngredient)

        // Subtract old contribution, add new
        recipe.calories = recipe.calories - Int(oldCalories) + Int(option.totalCalories)
        recipe.proteinGrams = recipe.proteinGrams - Int(oldProtein) + Int(option.totalProtein)
        recipe.carbsGrams = recipe.carbsGrams - Int(oldCarbs) + Int(option.totalCarbs)
        recipe.fatGrams = recipe.fatGrams - Int(oldFat) + Int(option.totalFat)

        // Update the recipe ingredient
        recipeIngredient.ingredient = newIngredient
        recipeIngredient.quantity = option.quantity
        recipeIngredient.unitRaw = option.unit
        recipeIngredient.quantityGrams = option.quantityGrams

        dismiss()
    }
}
