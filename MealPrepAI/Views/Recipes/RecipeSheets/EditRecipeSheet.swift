import SwiftUI
import SwiftData
import UIKit

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

        do {
            try modelContext.save()
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } catch {
            print("Failed to save: \(error)")
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
        dismiss()
    }
}
