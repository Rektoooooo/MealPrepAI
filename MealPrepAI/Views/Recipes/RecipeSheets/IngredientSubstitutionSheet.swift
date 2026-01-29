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
    @State private var swapCompleted = false

    // Loading animation state
    @State private var loadingProgress: Double = 0
    @State private var loadingMessage = "Analyzing ingredient..."
    @State private var loadingAppeared = false
    @State private var foodIndex = 0
    @State private var resultsAppeared = false

    private let loadingMessages = [
        "Analyzing ingredient...",
        "Checking dietary needs...",
        "Finding best substitutes...",
        "Calculating nutrition..."
    ]

    private let foods = ["🥦", "🍗", "🧀", "🥕", "🫘", "🥩", "🍳", "🥑", "🫑", "🍠"]

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
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()

                if isLoading {
                    loadingAnimationView
                } else if let error = errorMessage {
                    errorView(error)
                } else {
                    resultsView
                }
            }
            .navigationTitle(isLoading ? "" : "Swap Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.accentPurple)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .task {
            await loadSubstitutes()
        }
    }

    // MARK: - Loading Animation View

    private var loadingAnimationView: some View {
        VStack(spacing: 0) {
            Spacer()

            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.accentPurple.opacity(0.15), lineWidth: 10)
                    .frame(width: 130, height: 130)

                Circle()
                    .trim(from: 0, to: loadingProgress)
                    .stroke(
                        Color.accentPurple,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 130, height: 130)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(loadingProgress * 100))%")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.accentPurple)
            }
            .opacity(loadingAppeared ? 1 : 0)
            .scaleEffect(loadingAppeared ? 1 : 0.7)

            Spacer().frame(height: Design.Spacing.xxl)

            // Title
            VStack(spacing: Design.Spacing.sm) {
                Text("Finding Substitutes")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text("for \(ingredientName)")
                    .font(.headline)
                    .foregroundStyle(Color.accentPurple)
            }
            .opacity(loadingAppeared ? 1 : 0)

            Spacer().frame(height: Design.Spacing.lg)

            // Dynamic message
            Text(loadingMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .animation(.easeInOut, value: loadingMessage)
                .opacity(loadingAppeared ? 1 : 0)

            Spacer().frame(height: Design.Spacing.xxl)

            // Current ingredient card
            HStack(spacing: Design.Spacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(ingredientName)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                Spacer()
                Text(recipeIngredient.displayQuantity)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            .padding(Design.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.lg)
                    .fill(Color.backgroundSecondary)
            )
            .padding(.horizontal, Design.Spacing.xl)
            .opacity(loadingAppeared ? 1 : 0)

            Spacer().frame(height: Design.Spacing.xxl)

            // Food emoji carousel
            HStack(spacing: Design.Spacing.md) {
                ForEach(0..<5, id: \.self) { index in
                    let actualIndex = (foodIndex + index) % foods.count
                    Text(foods[actualIndex])
                        .font(.system(size: 36))
                        .frame(width: 52, height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: Design.Radius.md)
                                .fill(Color.backgroundSecondary)
                        )
                }
            }
            .opacity(loadingAppeared ? 1 : 0)

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                loadingAppeared = true
            }
            startLoadingAnimation()
        }
    }

    // MARK: - Results View

    private var resultsView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: Design.Spacing.lg) {
                    // Header
                    currentIngredientHeader
                        .opacity(resultsAppeared ? 1 : 0)
                        .offset(y: resultsAppeared ? 0 : 20)

                    // Substitutes
                    VStack(spacing: Design.Spacing.sm) {
                        ForEach(Array(substitutes.enumerated()), id: \.offset) { index, option in
                            substituteCard(option: option, index: index)
                                .opacity(resultsAppeared ? 1 : 0)
                                .offset(y: resultsAppeared ? 0 : 30)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.75)
                                        .delay(Double(index) * 0.1 + 0.15),
                                    value: resultsAppeared
                                )
                        }
                    }
                }
                .padding(.horizontal, Design.Spacing.lg)
                .padding(.bottom, 100)
            }

            // Confirm button pinned to bottom
            if !substitutes.isEmpty {
                confirmButton
                    .opacity(resultsAppeared ? 1 : 0)
                    .offset(y: resultsAppeared ? 0 : 40)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.75).delay(0.4),
                        value: resultsAppeared
                    )
            }
        }
        .overlay {
            if swapCompleted {
                swapSuccessOverlay
            }
        }
        .onAppear {
            resultsAppeared = true
        }
    }

    // MARK: - Swap Success Overlay

    private var swapSuccessOverlay: some View {
        ZStack {
            Color.backgroundPrimary.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: Design.Spacing.lg) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(Color.brandGreen)
                    .symbolEffect(.bounce, value: swapCompleted)

                Text("Ingredient Swapped!")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Recipe macros updated")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .scaleEffect(swapCompleted ? 1 : 0.5)
            .opacity(swapCompleted ? 1 : 0)
        }
        .transition(.opacity)
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

    // MARK: - Error View

    private func errorView(_ error: String) -> some View {
        VStack(spacing: Design.Spacing.md) {
            Spacer()

            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundStyle(.orange)

            Text(error)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Design.Spacing.xl)

            Button("Retry") {
                Task { await loadSubstitutes() }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.accentPurple)

            Spacer()
        }
    }

    // MARK: - Substitute Card

    private func substituteCard(option: SubstituteOption, index: Int) -> some View {
        let isSelected = selectedIndex == index
        let calDelta = Int(option.totalCalories) - Int(oldCalories)
        let proteinDelta = Int(option.totalProtein) - Int(oldProtein)

        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selectedIndex = index
            }
        } label: {
            HStack(spacing: Design.Spacing.md) {
                // Radio indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.accentPurple : Color.secondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 28, height: 28)

                    if isSelected {
                        Circle()
                            .fill(Color.accentPurple)
                            .frame(width: 18, height: 18)
                            .transition(.scale.combined(with: .opacity))
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(option.name)
                        .font(.body)
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
                RoundedRectangle(cornerRadius: Design.Radius.lg)
                    .fill(isSelected ? Color.accentPurple.opacity(0.08) : Color.backgroundSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Design.Radius.lg)
                    .stroke(isSelected ? Color.accentPurple : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Confirm Button

    private var confirmButton: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                performSwap()
            } label: {
                HStack(spacing: Design.Spacing.sm) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Swap Ingredient")
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Design.Spacing.md)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.accentPurple)
            .disabled(selectedIndex == nil)
            .padding(.horizontal, Design.Spacing.lg)
            .padding(.vertical, Design.Spacing.sm)
        }
        .background(Color.backgroundPrimary)
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

    // MARK: - Loading Animation

    private func startLoadingAnimation() {
        // Progress ring animation
        withAnimation(.linear(duration: 4.0)) {
            loadingProgress = 0.9
        }

        // Message cycling
        for (index, message) in loadingMessages.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.85) {
                withAnimation {
                    loadingMessage = message
                }
            }
        }

        // Food carousel rotation
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            if !isLoading {
                timer.invalidate()
                return
            }
            withAnimation(.easeInOut(duration: 0.3)) {
                foodIndex = (foodIndex + 1) % foods.count
            }
        }
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
                // Complete progress ring before showing results
                withAnimation(.easeOut(duration: 0.3)) {
                    loadingProgress = 1.0
                }
                try? await Task.sleep(nanoseconds: 400_000_000)

                substitutes = subs
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isLoading = false
                }
            } else {
                errorMessage = response.error ?? "Failed to load substitutes."
                isLoading = false
            }
        } catch let apiError as APIError {
            switch apiError {
            case .httpError(let code) where code == 401:
                errorMessage = "Unable to verify app. Please restart the app and try again."
            case .subscriptionRequired:
                errorMessage = "A subscription is required to swap ingredients."
            case .rateLimited:
                errorMessage = "Too many requests. Please try again later."
            default:
                errorMessage = apiError.localizedDescription
            }
            isLoading = false
        } catch {
            errorMessage = "Something went wrong. Please try again."
            isLoading = false
        }
    }

    // MARK: - SwiftData Update

    private func performSwap() {
        guard let index = selectedIndex, index < substitutes.count else { return }
        let option = substitutes[index]

        // Create new ingredient
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

        // Show success animation then dismiss
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            swapCompleted = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            dismiss()
        }
    }
}
