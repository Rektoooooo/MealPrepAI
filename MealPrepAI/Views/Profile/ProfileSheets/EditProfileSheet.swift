import SwiftUI

// MARK: - Edit Profile Sheet
struct EditProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var profile: UserProfile

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Design.Spacing.lg) {
                    // Personal Info
                    VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                        Text("Personal")
                            .font(.headline)
                            .foregroundStyle(Color.textPrimary)

                        TextField("Name", text: $profile.name)
                            .font(.body)
                            .padding(Design.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: Design.Radius.md)
                                    .fill(Color.mintLight)
                            )
                    }

                    // Daily Targets
                    VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                        Text("Daily Targets")
                            .font(.headline)
                            .foregroundStyle(Color.textPrimary)

                        VStack(spacing: Design.Spacing.sm) {
                            macroStepper(label: "Calories", value: $profile.dailyCalorieTarget, range: 1000...5000, step: 50, unit: "cal", color: Color(hex: "FF6B6B"))
                            macroStepper(label: "Protein", value: $profile.proteinGrams, range: 50...400, step: 5, unit: "g", color: Color.accentPurple)
                            macroStepper(label: "Carbs", value: $profile.carbsGrams, range: 50...500, step: 5, unit: "g", color: Color.accentYellow)
                            macroStepper(label: "Fat", value: $profile.fatGrams, range: 20...200, step: 5, unit: "g", color: Color.mintVibrant)
                        }
                    }
                }
                .padding(Design.Spacing.lg)
            }
            .background(LinearGradient.mintBackgroundGradient.ignoresSafeArea())
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.accentPurple)
                }
            }
        }
    }

    private func macroStepper(label: String, value: Binding<Int>, range: ClosedRange<Int>, step: Int, unit: String, color: Color) -> some View {
        HStack {
            HStack(spacing: Design.Spacing.xs) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(Color.textPrimary)
            }

            Spacer()

            HStack(spacing: Design.Spacing.sm) {
                Button(action: {
                    if value.wrappedValue > range.lowerBound {
                        value.wrappedValue -= step
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(value.wrappedValue > range.lowerBound ? color : Color.textSecondary)
                }

                Text("\(value.wrappedValue) \(unit)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(width: 80)

                Button(action: {
                    if value.wrappedValue < range.upperBound {
                        value.wrappedValue += step
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(value.wrappedValue < range.upperBound ? color : Color.textSecondary)
                }
            }
        }
        .padding(Design.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Design.Radius.md)
                .fill(Color.mintLight)
        )
    }
}
