import SwiftUI

// MARK: - Share Recipe Sheet
struct ShareRecipeSheet: View {
    @Environment(\.dismiss) private var dismiss
    let recipe: Recipe

    private var shareText: String {
        var text = "\(recipe.name)\n\n"
        text += "\(recipe.recipeDescription)\n\n"
        text += "Nutrition (per serving):\n"
        text += "- \(recipe.caloriesPerServing) calories\n"
        text += "- \(recipe.proteinGrams)g protein\n"
        text += "- \(recipe.carbsGrams)g carbs\n"
        text += "- \(recipe.fatGrams)g fat\n\n"
        text += "Total time: \(recipe.totalTimeMinutes) minutes\n"
        text += "Difficulty: \(recipe.complexity.label)\n\n"

        if !recipe.instructions.isEmpty {
            text += "Instructions:\n"
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
