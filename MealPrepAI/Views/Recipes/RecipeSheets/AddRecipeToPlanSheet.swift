import SwiftUI
import SwiftData
import UIKit

// MARK: - Add Recipe To Plan Sheet
struct AddRecipeToPlanSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let recipe: Recipe
    let mealPlan: MealPlan?

    @State private var selectedMealType: MealType = .lunch
    @State private var selectedDayIndex: Int = 0

    private var availableDays: [Day] {
        mealPlan?.sortedDays ?? []
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Design.Spacing.xl) {
                if mealPlan == nil || availableDays.isEmpty {
                    Spacer()
                    VStack(spacing: Design.Spacing.md) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(Design.Typography.iconMedium)
                            .foregroundStyle(Color.textSecondary)

                        Text("No Meal Plan")
                            .font(.headline)

                        Text("Generate a meal plan first to add recipes")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                } else {
                    // Recipe info
                    HStack(spacing: Design.Spacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: Design.Radius.md)
                                .fill(Color.mintMedium)
                                .frame(width: 60, height: 60)

                            Image(systemName: "fork.knife")
                                .font(Design.Typography.title2)
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(recipe.name)
                                .font(.headline)
                                .lineLimit(1)

                            Text("\(recipe.caloriesPerServing) kcal/serving")
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: Design.Radius.card)
                            .fill(Color.cardBackground)
                    )
                    .padding(.horizontal)

                    // Day selector
                    VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                        Text("Select Day")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.textSecondary)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Design.Spacing.sm) {
                                ForEach(Array(availableDays.enumerated()), id: \.element.id) { index, day in
                                    DayPickerButton(
                                        day: day,
                                        isSelected: selectedDayIndex == index,
                                        onSelect: { selectedDayIndex = index }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Meal type selector
                    VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                        Text("Meal Type")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.textSecondary)

                        HStack(spacing: Design.Spacing.sm) {
                            ForEach(MealType.allCases) { type in
                                MealTypePicker(
                                    type: type,
                                    isSelected: selectedMealType == type,
                                    onSelect: { selectedMealType = type }
                                )
                            }
                        }
                    }
                    .padding(.horizontal)

                    Spacer()

                    Button(action: addToPlan) {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                            Text("Add to Plan")
                        }
                    }
                    .purpleButton()
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("Add to Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.accentPurple)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func addToPlan() {
        guard selectedDayIndex < availableDays.count else { return }
        let day = availableDays[selectedDayIndex]

        let meal = Meal(mealType: selectedMealType)
        meal.recipe = recipe
        meal.day = day
        day.meals.append(meal)

        modelContext.insert(meal)
        do {
            try modelContext.save()
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } catch {
            #if DEBUG
            print("Failed to save: \(error)")
            #endif
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }

        dismiss()
    }
}

// MARK: - Day Picker Button
struct DayPickerButton: View {
    let day: Day
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 2) {
                Text(day.shortDayName)
                    .font(.caption)
                    .fontWeight(.medium)

                Text("\(Calendar.current.component(.day, from: day.date))")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .frame(width: 50, height: 55)
            .foregroundStyle(isSelected ? .white : Color.textPrimary)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.md)
                    .fill(isSelected ? Color.accentPurple : Color.cardBackground)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Meal Type Picker
struct MealTypePicker: View {
    let type: MealType
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 4) {
                Image(systemName: type.icon)
                    .font(Design.Typography.bodyLarge)

                Text(type.rawValue)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Design.Spacing.sm)
            .foregroundStyle(isSelected ? .white : Color.textPrimary)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.md)
                    .fill(isSelected ? Color.accentPurple : Color.cardBackground)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Recipe Action Button
struct RecipeActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(Design.Typography.bodyLarge)

                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Design.Spacing.sm)
            .foregroundStyle(color)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.md)
                    .fill(color.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }
}
