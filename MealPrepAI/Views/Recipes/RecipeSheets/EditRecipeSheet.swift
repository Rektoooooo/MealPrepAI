import SwiftUI
import SwiftData
import PhotosUI
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
    @State private var cuisineType: CuisineType?
    @State private var instructionSteps: [InstructionStep]
    @State private var ingredientEntries: [IngredientEntry]
    @State private var calories: String
    @State private var protein: String
    @State private var carbs: String
    @State private var fat: String
    @State private var fiber: String
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var recipeImageData: Data?
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    init(recipe: Recipe) {
        self.recipe = recipe
        _recipeName = State(initialValue: recipe.name)
        _recipeDescription = State(initialValue: recipe.recipeDescription)
        _servings = State(initialValue: recipe.servings)
        _prepTime = State(initialValue: recipe.prepTimeMinutes)
        _cookTime = State(initialValue: recipe.cookTimeMinutes)
        _complexity = State(initialValue: recipe.complexity)
        _cuisineType = State(initialValue: recipe.cuisineType)
        _recipeImageData = State(initialValue: recipe.localImageData)

        let steps: [InstructionStep] = recipe.instructions.isEmpty
            ? [InstructionStep()]
            : recipe.instructions.map { InstructionStep(text: $0) }
        _instructionSteps = State(initialValue: steps)

        let entries: [IngredientEntry]
        if !recipe.ingredients.isEmpty {
            entries = recipe.ingredients.map { ri in
                var entry = IngredientEntry()
                entry.name = ri.ingredient?.name ?? ""
                entry.quantity = String(format: "%g", ri.quantity)
                entry.unit = ri.unit
                entry.category = ri.ingredient?.category ?? .other
                return entry
            }
        } else {
            entries = [IngredientEntry()]
        }
        _ingredientEntries = State(initialValue: entries)

        _calories = State(initialValue: recipe.calories > 0 ? "\(recipe.calories)" : "")
        _protein = State(initialValue: recipe.proteinGrams > 0 ? "\(recipe.proteinGrams)" : "")
        _carbs = State(initialValue: recipe.carbsGrams > 0 ? "\(recipe.carbsGrams)" : "")
        _fat = State(initialValue: recipe.fatGrams > 0 ? "\(recipe.fatGrams)" : "")
        _fiber = State(initialValue: recipe.fiberGrams > 0 ? "\(recipe.fiberGrams)" : "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Design.Spacing.xl) {
                    recipePhotoSection

                    sectionField("Recipe Name") {
                        TextField("Recipe name", text: $recipeName)
                            .font(.body)
                            .padding(Design.Spacing.md)
                            .background(RoundedRectangle(cornerRadius: Design.Radius.md).fill(Color.backgroundSecondary))
                    }

                    sectionField("Description") {
                        TextField("Description", text: $recipeDescription, axis: .vertical)
                            .font(.body)
                            .lineLimit(3...6)
                            .padding(Design.Spacing.md)
                            .background(RoundedRectangle(cornerRadius: Design.Radius.md).fill(Color.backgroundSecondary))
                    }

                    sectionField("Difficulty") {
                        HStack(spacing: Design.Spacing.sm) {
                            ForEach(RecipeComplexity.allCases) { level in
                                Button(action: { complexity = level }) {
                                    Text(level.label)
                                        .font(.subheadline).fontWeight(.medium)
                                        .foregroundStyle(complexity == level ? .white : .primary)
                                        .padding(.horizontal, Design.Spacing.md)
                                        .padding(.vertical, Design.Spacing.sm)
                                        .background(Capsule().fill(complexity == level ? Color.accentPurple : Color.backgroundSecondary))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    sectionField("Cuisine Type") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Design.Spacing.sm) {
                                ForEach(CuisineType.allCases) { cuisine in
                                    Button(action: { cuisineType = cuisineType == cuisine ? nil : cuisine }) {
                                        Text(cuisine.rawValue)
                                            .font(.subheadline).fontWeight(.medium)
                                            .foregroundStyle(cuisineType == cuisine ? .white : .primary)
                                            .padding(.horizontal, Design.Spacing.md)
                                            .padding(.vertical, Design.Spacing.sm)
                                            .background(Capsule().fill(cuisineType == cuisine ? Color.accentPurple : Color.backgroundSecondary))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    HStack(spacing: Design.Spacing.lg) {
                        sectionField("Prep Time") {
                            Stepper("\(prepTime) min", value: $prepTime, in: 5...180, step: 5)
                                .padding(Design.Spacing.sm)
                                .background(RoundedRectangle(cornerRadius: Design.Radius.md).fill(Color.backgroundSecondary))
                        }
                        sectionField("Cook Time") {
                            Stepper("\(cookTime) min", value: $cookTime, in: 0...180, step: 5)
                                .padding(Design.Spacing.sm)
                                .background(RoundedRectangle(cornerRadius: Design.Radius.md).fill(Color.backgroundSecondary))
                        }
                    }

                    sectionField("Servings") {
                        Stepper("\(servings) servings", value: $servings, in: 1...12)
                            .padding(Design.Spacing.sm)
                            .background(RoundedRectangle(cornerRadius: Design.Radius.md).fill(Color.backgroundSecondary))
                    }

                    instructionsSection
                    ingredientsSection
                    nutritionSection
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
            .alert("Something Went Wrong", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Photo Section

    private var recipePhotoSection: some View {
        VStack(spacing: Design.Spacing.md) {
            if let imageData = recipeImageData,
               let uiImage = UIImage.downsample(data: imageData, maxDimension: 400) ?? UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: Design.Radius.card))

                HStack(spacing: Design.Spacing.md) {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack(spacing: Design.Spacing.xs) {
                            Image(systemName: "photo")
                            Text("Change Photo")
                        }
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundStyle(Color.accentPurple)
                    }

                    Button(action: {
                        recipeImageData = nil
                        selectedPhotoItem = nil
                    }) {
                        HStack(spacing: Design.Spacing.xs) {
                            Image(systemName: "trash")
                            Text("Remove")
                        }
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundStyle(.red)
                    }
                }
            } else {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    VStack(spacing: Design.Spacing.sm) {
                        Image(systemName: "camera.fill")
                            .font(Design.Typography.title)
                            .foregroundStyle(Color.accentPurple)
                        Text("Add Photo")
                            .font(.subheadline).fontWeight(.medium)
                            .foregroundStyle(Color.accentPurple)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background(
                        RoundedRectangle(cornerRadius: Design.Radius.card)
                            .fill(Color.backgroundSecondary)
                            .overlay(
                                RoundedRectangle(cornerRadius: Design.Radius.card)
                                    .strokeBorder(Color.accentPurple.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
                            )
                    )
                }
            }
        }
        .onChange(of: selectedPhotoItem) { _, newValue in
            Task {
                if let newValue,
                   let data = try? await newValue.loadTransferable(type: Data.self) {
                    await MainActor.run { recipeImageData = data }
                }
            }
        }
    }

    // MARK: - Instructions Section

    private var instructionsSection: some View {
        sectionField("Instructions") {
            VStack(spacing: Design.Spacing.sm) {
                ForEach(Array(instructionSteps.enumerated()), id: \.element.id) { index, step in
                    HStack(alignment: .top, spacing: Design.Spacing.sm) {
                        Text("\(index + 1).")
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundStyle(Color.accentPurple)
                            .frame(width: 24, alignment: .trailing)
                            .padding(.top, Design.Spacing.md)

                        TextField("Step \(index + 1)...", text: instructionBinding(for: step.id), axis: .vertical)
                            .font(.body)
                            .lineLimit(2...4)
                            .padding(Design.Spacing.md)
                            .background(RoundedRectangle(cornerRadius: Design.Radius.md).fill(Color.backgroundSecondary))

                        if instructionSteps.count > 1 {
                            Button(action: {
                                withAnimation { instructionSteps.removeAll { $0.id == step.id } }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            .padding(.top, Design.Spacing.md)
                        }
                    }
                }

                Button(action: {
                    withAnimation { instructionSteps.append(InstructionStep()) }
                }) {
                    HStack(spacing: Design.Spacing.xs) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Step")
                    }
                    .font(.subheadline).fontWeight(.medium)
                    .foregroundStyle(Color.accentPurple)
                }
            }
        }
    }

    // MARK: - Ingredients Section

    private var ingredientsSection: some View {
        sectionField("Ingredients") {
            VStack(spacing: Design.Spacing.sm) {
                ForEach(Array(ingredientEntries.enumerated()), id: \.element.id) { _, entry in
                    HStack(alignment: .center, spacing: Design.Spacing.sm) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(Color.accentPurple)

                        TextField("e.g., 200g chicken breast", text: ingredientBinding(for: entry.id))
                            .font(.body)
                            .padding(Design.Spacing.md)
                            .background(RoundedRectangle(cornerRadius: Design.Radius.md).fill(Color.backgroundSecondary))

                        if ingredientEntries.count > 1 {
                            Button(action: {
                                withAnimation { ingredientEntries.removeAll { $0.id == entry.id } }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }

                Button(action: {
                    withAnimation { ingredientEntries.append(IngredientEntry()) }
                }) {
                    HStack(spacing: Design.Spacing.xs) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Ingredient")
                    }
                    .font(.subheadline).fontWeight(.medium)
                    .foregroundStyle(Color.accentPurple)
                }
            }
        }
    }

    // MARK: - Nutrition Section

    private var nutritionSection: some View {
        sectionField("Nutrition per serving (optional)") {
            VStack(spacing: Design.Spacing.sm) {
                HStack(spacing: Design.Spacing.sm) {
                    nutritionField("Calories", text: $calories)
                    nutritionField("Protein (g)", text: $protein)
                }
                HStack(spacing: Design.Spacing.sm) {
                    nutritionField("Carbs (g)", text: $carbs)
                    nutritionField("Fat (g)", text: $fat)
                }
                HStack(spacing: Design.Spacing.sm) {
                    nutritionField("Fiber (g)", text: $fiber)
                    Spacer()
                }
            }
        }
    }

    // MARK: - Helpers

    private func sectionField<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Design.Spacing.sm) {
            Text(title)
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(.secondary)
            content()
        }
    }

    private func nutritionField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("0", text: text)
                .font(.body)
                .keyboardType(.numberPad)
                .padding(Design.Spacing.sm)
                .background(RoundedRectangle(cornerRadius: Design.Radius.md).fill(Color.backgroundSecondary))
        }
    }

    private func instructionBinding(for id: UUID) -> Binding<String> {
        Binding(
            get: { instructionSteps.first(where: { $0.id == id })?.text ?? "" },
            set: { newValue in
                if let index = instructionSteps.firstIndex(where: { $0.id == id }) {
                    instructionSteps[index].text = newValue
                }
            }
        )
    }

    private func ingredientBinding(for id: UUID) -> Binding<String> {
        Binding(
            get: { ingredientEntries.first(where: { $0.id == id })?.name ?? "" },
            set: { newValue in
                if let index = ingredientEntries.firstIndex(where: { $0.id == id }) {
                    ingredientEntries[index].name = newValue
                }
            }
        )
    }

    // MARK: - Save

    private func saveChanges() {
        recipe.name = recipeName
        recipe.recipeDescription = recipeDescription
        recipe.servings = servings
        recipe.prepTimeMinutes = prepTime
        recipe.cookTimeMinutes = cookTime
        recipe.complexity = complexity
        recipe.cuisineType = cuisineType
        recipe.instructions = instructionSteps.map(\.text).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        recipe.calories = Int(calories) ?? 0
        recipe.proteinGrams = Int(protein) ?? 0
        recipe.carbsGrams = Int(carbs) ?? 0
        recipe.fatGrams = Int(fat) ?? 0
        recipe.fiberGrams = Int(fiber) ?? 0
        recipe.localImageData = recipeImageData

        // Remove old recipe ingredients
        for ri in recipe.ingredients {
            if let ingredient = ri.ingredient {
                modelContext.delete(ingredient)
            }
            modelContext.delete(ri)
        }

        // Create new ingredients
        for entry in ingredientEntries where !entry.name.trimmingCharacters(in: .whitespaces).isEmpty {
            let ingredient = Ingredient(
                name: entry.name.trimmingCharacters(in: .whitespaces).capitalized,
                category: entry.category,
                defaultUnit: entry.unit
            )
            modelContext.insert(ingredient)

            let qty = Double(entry.quantity) ?? 1
            let recipeIngredient = RecipeIngredient(quantity: qty, unit: entry.unit)
            recipeIngredient.ingredient = ingredient
            recipeIngredient.recipe = recipe
            modelContext.insert(recipeIngredient)
        }

        do {
            try modelContext.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            #if DEBUG
            print("Failed to save: \(error)")
            #endif
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            errorMessage = "We couldn't save your changes. Please try again.\n\nDetails: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
}
