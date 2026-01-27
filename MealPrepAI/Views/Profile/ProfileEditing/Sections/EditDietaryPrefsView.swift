import SwiftUI
import SwiftData

struct EditDietaryPrefsView: View {
    @Bindable var profile: UserProfile

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Design.Spacing.lg) {
                // Dietary Restrictions
                sectionCard(title: "Dietary Restrictions", icon: "leaf.fill", iconColor: Color.lunchGradientEnd) {
                    VStack(alignment: .leading, spacing: Design.Spacing.md) {
                        Text("Select all that apply")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)

                        FlowLayout(spacing: Design.Spacing.sm) {
                            ForEach(DietaryRestriction.allCases) { restriction in
                                OnboardingChip(
                                    restriction.rawValue,
                                    emoji: restriction.emoji,
                                    isSelected: profile.dietaryRestrictions.contains(restriction)
                                ) {
                                    toggleRestriction(restriction)
                                }
                            }
                        }

                        if !profile.dietaryRestrictions.isEmpty {
                            Button {
                                withAnimation {
                                    profile.dietaryRestrictions = []
                                }
                            } label: {
                                Text("Clear all")
                                    .font(.caption)
                                    .foregroundStyle(Color.textSecondary)
                            }
                        }
                    }
                }

                // Allergies
                sectionCard(title: "Allergies", icon: "exclamationmark.triangle.fill", iconColor: Color(hex: "FF6B6B")) {
                    VStack(alignment: .leading, spacing: Design.Spacing.md) {
                        Text("We'll exclude recipes with these ingredients")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)

                        FlowLayout(spacing: Design.Spacing.sm) {
                            ForEach(Allergy.allCases) { allergy in
                                OnboardingChip(
                                    allergy.rawValue,
                                    emoji: allergy.emoji,
                                    isSelected: profile.allergies.contains(allergy)
                                ) {
                                    toggleAllergy(allergy)
                                }
                            }
                        }

                        if !profile.allergies.isEmpty {
                            Button {
                                withAnimation {
                                    profile.allergies = []
                                }
                            } label: {
                                Text("Clear all")
                                    .font(.caption)
                                    .foregroundStyle(Color.textSecondary)
                            }
                        }
                    }
                }

                // Food Dislikes
                sectionCard(title: "Food Dislikes", icon: "hand.thumbsdown.fill", iconColor: Color.accentOrange) {
                    VStack(alignment: .leading, spacing: Design.Spacing.md) {
                        Text("Ingredients you'd prefer to avoid")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)

                        let columns = [GridItem(.adaptive(minimum: 75), spacing: Design.Spacing.sm)]

                        LazyVGrid(columns: columns, spacing: Design.Spacing.sm) {
                            ForEach(FoodDislike.allCases) { food in
                                FoodDislikeChip(
                                    food: food,
                                    isSelected: profile.foodDislikes.contains(food)
                                ) {
                                    toggleDislike(food)
                                }
                            }
                        }

                        if !profile.foodDislikes.isEmpty {
                            HStack {
                                Text("\(profile.foodDislikes.count) selected")
                                    .font(.caption)
                                    .foregroundStyle(Color.textSecondary)

                                Spacer()

                                Button {
                                    withAnimation {
                                        profile.foodDislikes = []
                                    }
                                } label: {
                                    Text("Clear all")
                                        .font(.caption)
                                        .foregroundStyle(Color.textSecondary)
                                }
                            }
                        }
                    }
                }

                // Summary Card
                if hasAnyRestrictions {
                    summaryCard
                }
            }
            .padding(.horizontal, Design.Spacing.md)
            .padding(.bottom, Design.Spacing.xxl)
        }
        .background(LinearGradient.mintBackgroundGradient.ignoresSafeArea())
        .navigationTitle("Dietary Preferences")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Summary Card

    private var hasAnyRestrictions: Bool {
        !profile.dietaryRestrictions.isEmpty ||
        !profile.allergies.isEmpty ||
        !profile.foodDislikes.isEmpty
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            HStack(spacing: Design.Spacing.sm) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.mintVibrant)
                Text("Your Preferences")
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
            }

            VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                if !profile.dietaryRestrictions.isEmpty {
                    summaryRow(
                        label: "Diet",
                        values: profile.dietaryRestrictions.map { $0.rawValue }
                    )
                }

                if !profile.allergies.isEmpty {
                    summaryRow(
                        label: "Allergies",
                        values: profile.allergies.map { $0.rawValue }
                    )
                }

                if !profile.foodDislikes.isEmpty {
                    summaryRow(
                        label: "Dislikes",
                        values: profile.foodDislikes.map { $0.rawValue }
                    )
                }
            }
        }
        .padding(Design.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Design.Radius.card)
                .fill(Color.mintVibrant.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: Design.Radius.card)
                        .strokeBorder(Color.mintVibrant.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func summaryRow(label: String, values: [String]) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
                .frame(width: 60, alignment: .leading)

            Text(values.joined(separator: ", "))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.textPrimary)
        }
    }

    // MARK: - Section Card Builder

    private func sectionCard<Content: View>(
        title: String,
        icon: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            HStack(spacing: Design.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
            }

            content()
        }
        .padding(Design.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Design.Radius.card)
                .fill(Color.cardBackground)
                .shadow(
                    color: Design.Shadow.card.color,
                    radius: Design.Shadow.card.radius,
                    y: Design.Shadow.card.y
                )
        )
    }

    // MARK: - Toggle Functions

    private func toggleRestriction(_ restriction: DietaryRestriction) {
        withAnimation(.spring(response: 0.3)) {
            if profile.dietaryRestrictions.contains(restriction) {
                profile.dietaryRestrictions.removeAll { $0 == restriction }
            } else {
                profile.dietaryRestrictions.append(restriction)
            }
        }
    }

    private func toggleAllergy(_ allergy: Allergy) {
        withAnimation(.spring(response: 0.3)) {
            if profile.allergies.contains(allergy) {
                profile.allergies.removeAll { $0 == allergy }
            } else {
                profile.allergies.append(allergy)
            }
        }
    }

    private func toggleDislike(_ food: FoodDislike) {
        withAnimation(.spring(response: 0.3)) {
            if profile.foodDislikes.contains(food) {
                profile.foodDislikes.removeAll { $0 == food }
            } else {
                profile.foodDislikes.append(food)
            }
        }
    }
}

// MARK: - Dietary Restriction Extension
private extension DietaryRestriction {
    var emoji: String {
        switch self {
        case .none: return "✅"
        case .vegetarian: return "🥬"
        case .vegan: return "🌱"
        case .pescatarian: return "🐟"
        case .keto: return "🥑"
        case .paleo: return "🦴"
        case .glutenFree: return "🌾"
        case .dairyFree: return "🥛"
        case .lactoseFree: return "🧈"
        case .halal: return "☪️"
        case .kosher: return "✡️"
        case .lowCarb: return "🍞"
        case .lowFat: return "🧀"
        }
    }
}

// MARK: - Allergy Extension
private extension Allergy {
    var emoji: String {
        switch self {
        case .none: return "✅"
        case .peanuts: return "🥜"
        case .treeNuts: return "🌰"
        case .milk: return "🥛"
        case .eggs: return "🥚"
        case .wheat: return "🌾"
        case .soy: return "🫘"
        case .fish: return "🐟"
        case .shellfish: return "🦐"
        case .sesame: return "🌱"
        }
    }
}

#Preview {
    NavigationStack {
        EditDietaryPrefsView(profile: UserProfile(name: "Test"))
    }
    .modelContainer(for: UserProfile.self, inMemory: true)
}
