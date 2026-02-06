import SwiftUI
import SwiftData

// MARK: - Recipe Detail Sheet
struct RecipeDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<MealPlan> { $0.isActive }, sort: \MealPlan.createdAt, order: .reverse)
    private var mealPlans: [MealPlan]
    @AppStorage("measurementSystem") private var measurementSystem: MeasurementSystem = .metric

    let recipe: Recipe

    @Environment(\.userProfile) private var userProfile
    @State private var showingAddToPlan = false
    @State private var showingEditSheet = false
    @State private var showingShareSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var ingredientToSwap: RecipeIngredient?

    private var currentMealPlan: MealPlan? {
        mealPlans.first
    }

    /// Converts and formats quantity for a recipe ingredient
    private func formattedQuantity(for ingredient: RecipeIngredient) -> String {
        let (convertedQty, convertedUnit) = ingredient.unit.convert(ingredient.quantity, to: measurementSystem)
        return MeasurementUnit.formatQuantity(convertedQty, unit: convertedUnit)
    }

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(alignment: .leading, spacing: Design.Spacing.lg) {
                    // Hero image - full width, extends to top of sheet
                    ZStack(alignment: .bottom) {
                        RecipeAsyncImage(
                            recipe: recipe,
                            height: 260,
                            cornerRadius: 0
                        )

                        // Gradient fade to background
                        LinearGradient(
                            colors: [
                                Color.cardBackground.opacity(0),
                                Color.cardBackground.opacity(0.6),
                                Color.cardBackground
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 80)
                    }

                    // Info
                    VStack(alignment: .leading, spacing: Design.Spacing.md) {
                        Text(recipe.name)
                            .font(.title)
                            .fontWeight(.bold)

                        Text(recipe.recipeDescription)
                            .font(.body)
                            .foregroundStyle(.secondary)

                        // Diet badges
                        if !recipe.displayDiets.isEmpty {
                            HStack(spacing: Design.Spacing.sm) {
                                ForEach(recipe.displayDiets) { badge in
                                    HStack(spacing: 4) {
                                        Image(systemName: badge.icon)
                                            .font(.system(size: 12))
                                        Text(badge.name)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundStyle(badge.color)
                                    .padding(.horizontal, Design.Spacing.sm)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(badge.color.opacity(0.12))
                                    )
                                }
                            }
                        }

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

                            // Source link button for non-video sources
                            if let sourceURL = recipe.sourceURL,
                               let url = URL(string: sourceURL),
                               !recipe.hasVideo {
                                Link(destination: url) {
                                    VStack(spacing: 4) {
                                        Image(systemName: "link")
                                            .font(.system(size: 18))
                                        Text("Source")
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Design.Spacing.sm)
                                    .foregroundStyle(Color.accentBlue)
                                    .background(
                                        RoundedRectangle(cornerRadius: Design.Radius.md)
                                            .fill(Color.accentBlue.opacity(0.1))
                                    )
                                }
                            }
                        }
                        .padding(.vertical, Design.Spacing.sm)

                        // Stats row
                        HStack(spacing: Design.Spacing.xl) {
                            statItem(icon: "clock", value: "\(recipe.totalTimeMinutes)m", label: "Time")
                            statItem(icon: "flame", value: "\(recipe.caloriesPerServing)", label: "Cal/Serving")
                            statItem(icon: "person.2", value: "\(recipe.servings)", label: "Servings")
                            statItem(icon: "chart.bar", value: recipe.complexity.label, label: "Level")
                        }
                        .padding(.vertical, Design.Spacing.md)

                        // Total calories note
                        HStack(spacing: Design.Spacing.xs) {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                            Text("Total calories for entire recipe: \(recipe.totalCalories) kcal")
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                        }

                        // Watch Video Button (if available)
                        if recipe.hasVideo, let sourceURL = recipe.sourceURL, let url = URL(string: sourceURL) {
                            Link(destination: url) {
                                HStack(spacing: Design.Spacing.sm) {
                                    Image(systemName: "play.circle.fill")
                                        .font(.title2)
                                    Text("Watch Video")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Design.Spacing.md)
                                .foregroundStyle(.white)
                                .background(
                                    RoundedRectangle(cornerRadius: Design.Radius.lg)
                                        .fill(Color.red)
                                )
                            }
                            .padding(.top, Design.Spacing.sm)
                        }

                        // Macros
                        NewSectionHeader(title: "Nutrition")
                        HStack(spacing: Design.Spacing.lg) {
                            macroChip(label: "Protein", value: "\(recipe.proteinGrams)g", color: .proteinColor)
                            macroChip(label: "Carbs", value: "\(recipe.carbsGrams)g", color: .carbColor)
                            macroChip(label: "Fat", value: "\(recipe.fatGrams)g", color: .fatColor)
                        }

                        // Ingredients
                        if !recipe.ingredients.isEmpty {
                            NewSectionHeader(title: "Ingredients")
                            VStack(spacing: Design.Spacing.sm) {
                                ForEach(recipe.ingredients, id: \.id) { recipeIngredient in
                                    Button {
                                        ingredientToSwap = recipeIngredient
                                    } label: {
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

                                            Image(systemName: "arrow.triangle.2.circlepath")
                                                .font(.caption)
                                                .foregroundStyle(Color.accentPurple.opacity(0.6))
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityElement(children: .combine)
                                    .accessibilityLabel("\(formattedQuantity(for: recipeIngredient)) \(recipeIngredient.ingredient?.name ?? "Unknown")")
                                    .accessibilityHint("Double tap to swap this ingredient")
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
                        if !recipe.parsedInstructions.isEmpty {
                            HStack {
                                NewSectionHeader(title: "Instructions")
                                Spacer()
                                Text("\(recipe.parsedInstructions.count) steps")
                                    .font(.caption)
                                    .foregroundStyle(Color.textSecondary)
                            }

                            VStack(alignment: .leading, spacing: Design.Spacing.md) {
                                ForEach(Array(recipe.parsedInstructions.enumerated()), id: \.offset) { index, instruction in
                                    HStack(alignment: .top, spacing: Design.Spacing.md) {
                                        Text("\(index + 1)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white)
                                            .frame(width: 28, height: 28)
                                            .background(Circle().fill(Color.accentPurple))

                                        Text(instruction)
                                            .font(.body)
                                            .foregroundStyle(.primary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .accessibilityElement(children: .combine)
                                    .accessibilityLabel("Step \(index + 1): \(instruction)")
                                    .padding(.vertical, Design.Spacing.xs)
                                }
                            }
                        } else if !recipe.instructions.isEmpty {
                            // Fallback for recipes with unparseable instructions
                            NewSectionHeader(title: "Instructions")
                            VStack(alignment: .leading, spacing: Design.Spacing.md) {
                                ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, instruction in
                                    HStack(alignment: .top, spacing: Design.Spacing.md) {
                                        Text("\(index + 1)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white)
                                            .frame(width: 28, height: 28)
                                            .background(Circle().fill(Color.accentPurple))

                                        Text(instruction)
                                            .font(.body)
                                            .foregroundStyle(.primary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .accessibilityElement(children: .combine)
                                    .accessibilityLabel("Step \(index + 1): \(instruction)")
                                    .padding(.vertical, Design.Spacing.xs)
                                }
                            }
                        }
                        // Delete button for custom recipes
                        if recipe.isCustom {
                            Button(role: .destructive, action: {
                                showingDeleteConfirmation = true
                            }) {
                                HStack(spacing: Design.Spacing.sm) {
                                    Image(systemName: "trash")
                                    Text("Delete Recipe")
                                }
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Design.Spacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: Design.Radius.lg)
                                        .fill(Color.red.opacity(0.1))
                                )
                            }
                            .padding(.top, Design.Spacing.lg)
                        }
                    }
                    .padding(.horizontal, Design.Spacing.lg)
                }
                .padding(.bottom, Design.Spacing.xxl)
            }
            .background(Color.backgroundPrimary)
            .ignoresSafeArea(edges: .top)

            // Floating top bar overlay
            HStack {
                Button("Close") { dismiss() }
                    .accessibilityIdentifier("recipe_detail_dismiss")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, Design.Spacing.md)
                    .padding(.vertical, Design.Spacing.sm)
                    .background(.ultraThinMaterial, in: Capsule())

                Spacer()

                Text("Recipe")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, Design.Spacing.lg)
                    .padding(.vertical, Design.Spacing.sm)
                    .background(.ultraThinMaterial, in: Capsule())

                Spacer()

                Button(action: { toggleFavorite() }) {
                    Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(recipe.isFavorite ? .red : .primary)
                }
                .accessibilityIdentifier("recipe_detail_favorite")
                .accessibilityLabel(recipe.isFavorite ? "Remove from favorites" : "Add to favorites")
                .accessibilityHint("Double tap to toggle favorite")
                .padding(Design.Spacing.sm)
                .background(.ultraThinMaterial, in: Circle())
            }
            .padding(.horizontal, Design.Spacing.lg)
            .padding(.top, Design.Spacing.md)
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
        .sheet(item: $ingredientToSwap) { ingredient in
            if let profile = userProfile {
                IngredientSubstitutionSheet(
                    recipe: recipe,
                    recipeIngredient: ingredient,
                    userProfile: profile
                )
            } else {
                VStack(spacing: Design.Spacing.lg) {
                    Spacer()
                    Image(systemName: "person.crop.circle.badge.exclamationmark")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.accentPurple)
                    Text("Profile Required")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Complete your profile to get personalized ingredient substitutions based on your dietary needs and allergies.")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Design.Spacing.xl)
                    Spacer()
                }
                .presentationDetents([.medium])
            }
        }
        .alert("Delete Recipe", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(recipe)
                try? modelContext.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \"\(recipe.name)\"? This cannot be undone.")
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
