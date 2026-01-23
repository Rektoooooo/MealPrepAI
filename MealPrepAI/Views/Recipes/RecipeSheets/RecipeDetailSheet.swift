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
                    // Hero image - uses smart loader with high-res fallback
                    RecipeAsyncImage(
                        recipe: recipe,
                        height: 200,
                        cornerRadius: Design.Radius.featured
                    )
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
                                    .padding(.vertical, Design.Spacing.xs)
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
