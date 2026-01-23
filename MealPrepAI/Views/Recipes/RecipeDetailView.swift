import SwiftUI

struct RecipeDetailView: View {
    let recipeName: String

    @State private var isFavorite = false
    @State private var servings = 2
    @State private var showingSwapSheet = false

    // Sample data
    private let sampleIngredients = [
        ("Chicken Breast", "2 pieces", "400g"),
        ("Olive Oil", "2 tbsp", "30ml"),
        ("Garlic", "4 cloves", "12g"),
        ("Fresh Rosemary", "2 sprigs", "5g"),
        ("Lemon", "1 whole", "80g"),
        ("Salt", "1 tsp", "6g"),
        ("Black Pepper", "1/2 tsp", "2g")
    ]

    private let sampleInstructions = [
        "Preheat oven to 400F (200C).",
        "Pat chicken breasts dry and season generously with salt and pepper.",
        "Heat olive oil in an oven-safe skillet over medium-high heat.",
        "Sear chicken for 3-4 minutes per side until golden brown.",
        "Add garlic and rosemary to the pan.",
        "Squeeze lemon juice over chicken and add lemon halves to pan.",
        "Transfer skillet to oven and bake for 15-20 minutes until internal temperature reaches 165F (74C).",
        "Let rest for 5 minutes before serving."
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero Image
                heroImage

                // Content
                VStack(spacing: 24) {
                    // Title & Quick Info
                    titleSection

                    // Nutrition Card
                    nutritionCard

                    // Ingredients
                    ingredientsSection

                    // Instructions
                    instructionsSection
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button(action: { isFavorite.toggle() }) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundStyle(isFavorite ? .red : .primary)
                    }

                    Menu {
                        Button(action: {}) {
                            Label("Add to Plan", systemImage: "calendar.badge.plus")
                        }
                        Button(action: {}) {
                            Label("Add to Grocery List", systemImage: "cart.badge.plus")
                        }
                        Divider()
                        Button(action: {}) {
                            Label("Share Recipe", systemImage: "square.and.arrow.up")
                        }
                        Button(action: {}) {
                            Label("Edit Recipe", systemImage: "pencil")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingSwapSheet) {
            IngredientSwapSheet()
        }
    }

    // MARK: - Hero Image
    private var heroImage: some View {
        ZStack(alignment: .bottomLeading) {
            // Gradient placeholder
            LinearGradient(
                colors: [.green.opacity(0.6), .green.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 250)
            .overlay(
                Image(systemName: "fork.knife")
                    .font(.system(size: 60))
                    .foregroundStyle(.white.opacity(0.3))
            )

            // Complexity badge
            HStack {
                Text("Medium")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .clipShape(Capsule())

                Spacer()
            }
            .padding()
        }
    }

    // MARK: - Title Section
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(recipeName)
                .font(.title)
                .fontWeight(.bold)

            HStack(spacing: 16) {
                Label("35 min", systemImage: "clock")
                Label("Medium", systemImage: "chart.bar")
                Label("Italian", systemImage: "globe")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            // Servings Adjuster
            HStack {
                Text("Servings")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                HStack(spacing: 16) {
                    Button(action: { if servings > 1 { servings -= 1 } }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(servings > 1 ? .green : .gray)
                    }
                    .disabled(servings <= 1)

                    Text("\(servings)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .frame(width: 30)

                    Button(action: { servings += 1 }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.green)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Nutrition Card
    private var nutritionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutrition per serving")
                .font(.headline)

            HStack(spacing: 0) {
                nutritionItem(value: "480", unit: "cal", label: "Calories", color: .orange)
                Divider().frame(height: 50)
                nutritionItem(value: "42", unit: "g", label: "Protein", color: .blue)
                Divider().frame(height: 50)
                nutritionItem(value: "8", unit: "g", label: "Carbs", color: .purple)
                Divider().frame(height: 50)
                nutritionItem(value: "32", unit: "g", label: "Fat", color: .yellow)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func nutritionItem(value: String, unit: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Ingredients Section
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Ingredients")
                    .font(.headline)
                Spacer()
                Button("Swap") {
                    showingSwapSheet = true
                }
                .font(.subheadline)
            }

            VStack(spacing: 8) {
                ForEach(sampleIngredients, id: \.0) { name, amount, grams in
                    IngredientRow(name: name, amount: amount, grams: grams, servings: servings)
                }
            }
        }
    }

    // MARK: - Instructions Section
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Instructions")
                .font(.headline)

            VStack(spacing: 16) {
                ForEach(Array(sampleInstructions.enumerated()), id: \.offset) { index, instruction in
                    InstructionRow(stepNumber: index + 1, instruction: instruction)
                }
            }
        }
    }
}

// MARK: - Ingredient Row
struct IngredientRow: View {
    let name: String
    let amount: String
    let grams: String
    let servings: Int

    var body: some View {
        HStack {
            Image(systemName: "circle")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(name)
                .font(.subheadline)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(amount)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("(\(grams))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Instruction Row
struct InstructionRow: View {
    let stepNumber: Int
    let instruction: String
    @State private var isCompleted = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: { isCompleted.toggle() }) {
                ZStack {
                    Circle()
                        .fill(isCompleted ? Color.green : Color(.secondarySystemGroupedBackground))
                        .frame(width: 32, height: 32)

                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    } else {
                        Text("\(stepNumber)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Text(instruction)
                .font(.subheadline)
                .foregroundStyle(isCompleted ? .secondary : .primary)
                .strikethrough(isCompleted)
        }
    }
}

// MARK: - Ingredient Swap Sheet
struct IngredientSwapSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedIngredient = "Chicken Breast"
    @State private var searchText = ""

    private let alternatives = [
        ("Turkey Breast", "Similar protein, leaner", 450, 45),
        ("Tofu", "Plant-based option", 350, 25),
        ("Salmon", "More omega-3s", 520, 38),
        ("Tempeh", "Fermented, high protein", 400, 30)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Current ingredient
                HStack {
                    Text("Swapping:")
                        .foregroundStyle(.secondary)
                    Text(selectedIngredient)
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)

                // Alternatives
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(alternatives, id: \.0) { name, reason, calories, protein in
                            SwapOptionRow(
                                name: name,
                                reason: reason,
                                calories: calories,
                                protein: protein
                            ) {
                                dismiss()
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Swap Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct SwapOptionRow: View {
    let name: String
    let reason: String
    let calories: Int
    let protein: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text(reason)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        Label("\(calories) cal", systemImage: "flame")
                        Label("\(protein)g protein", systemImage: "p.circle")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        RecipeDetailView(recipeName: "Herb Crusted Chicken")
    }
}
