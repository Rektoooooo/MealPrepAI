import SwiftUI
import SwiftData
import UIKit

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
        do {
            try modelContext.save()
            // Haptic feedback on success
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } catch {
            print("Failed to save recipe: \(error)")
            // Haptic feedback on error
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
        dismiss()
    }
}
