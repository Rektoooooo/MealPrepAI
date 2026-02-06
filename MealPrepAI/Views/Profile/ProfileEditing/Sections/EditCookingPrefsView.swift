import SwiftUI
import SwiftData

struct EditCookingPrefsView: View {
    @Bindable var profile: UserProfile

    // Group cuisines into rows for layout
    private let cuisineRows: [[CuisineType]] = [
        [.american, .italian, .mexican],
        [.french, .chinese, .japanese],
        [.indian, .thai, .mediterranean],
        [.greek, .korean, .vietnamese],
        [.middleEastern, .spanish]
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Design.Spacing.lg) {
                // Cuisine Preferences
                sectionCard(title: "Cuisine Preferences", icon: "globe", iconColor: Color.accentPurple) {
                    VStack(alignment: .leading, spacing: Design.Spacing.md) {
                        // Legend
                        HStack(spacing: Design.Spacing.lg) {
                            legendItem(color: OnboardingDesign.Colors.success, label: "Like")
                            legendItem(color: OnboardingDesign.Colors.textMuted, label: "Neutral")
                            legendItem(color: OnboardingDesign.Colors.highlight, label: "Dislike")
                        }

                        Text("Tap to cycle: neutral → like → dislike")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)

                        // Cuisine chips grid
                        VStack(spacing: Design.Spacing.sm) {
                            ForEach(cuisineRows.indices, id: \.self) { rowIndex in
                                HStack(spacing: Design.Spacing.sm) {
                                    ForEach(cuisineRows[rowIndex]) { cuisine in
                                        cuisineChip(cuisine: cuisine)
                                    }
                                    // Fill remaining space for last row
                                    if cuisineRows[rowIndex].count < 3 {
                                        ForEach(0..<(3 - cuisineRows[rowIndex].count), id: \.self) { _ in
                                            Color.clear
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 70)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Cooking Skill
                sectionCard(title: "Cooking Skill", icon: "flame.fill", iconColor: Color.accentOrange) {
                    VStack(spacing: Design.Spacing.sm) {
                        ForEach(CookingSkill.allCases) { skill in
                            OnboardingSelectionCard(
                                title: skill.rawValue,
                                description: skill.description,
                                icon: skill.icon,
                                isSelected: profile.cookingSkill == skill
                            ) {
                                profile.cookingSkill = skill
                            }
                        }
                    }
                }

                // Max Cooking Time
                sectionCard(title: "Max Cooking Time", icon: "clock.fill", iconColor: Color.accentBlue) {
                    VStack(spacing: Design.Spacing.sm) {
                        ForEach(CookingTime.allCases) { time in
                            OnboardingSelectionCard(
                                title: time.rawValue,
                                description: time.editDescription,
                                icon: time.editIcon,
                                isSelected: profile.maxCookingTime == time
                            ) {
                                profile.maxCookingTime = time
                            }
                        }
                    }
                }

                // Pantry Level
                sectionCard(title: "Pantry Level", icon: "cabinet.fill", iconColor: Color.mintVibrant) {
                    VStack(spacing: Design.Spacing.sm) {
                        ForEach(PantryLevel.allCases) { level in
                            OnboardingSelectionCard(
                                title: level.rawValue,
                                description: level.description,
                                icon: level.icon,
                                isSelected: profile.pantryLevel == level
                            ) {
                                profile.pantryLevel = level
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Design.Spacing.md)
            .padding(.bottom, Design.Spacing.xxl)
        }
        .background(LinearGradient.mintBackgroundGradient.ignoresSafeArea())
        .navigationTitle("Cooking Preferences")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Cuisine Chip

    private func cuisineChip(cuisine: CuisineType) -> some View {
        let preference = profile.cuisinePreferencesMap[cuisine.rawValue] ?? .neutral

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            // Cycle: neutral -> like -> dislike -> neutral
            var newMap = profile.cuisinePreferencesMap
            switch preference {
            case .neutral:
                newMap[cuisine.rawValue] = .like
            case .like:
                newMap[cuisine.rawValue] = .dislike
            case .dislike:
                newMap[cuisine.rawValue] = .neutral
            }
            profile.cuisinePreferencesMap = newMap
        } label: {
            VStack(spacing: Design.Spacing.xxs) {
                Text(cuisine.flag)
                    .font(Design.Typography.title2)

                Text(cuisine.rawValue)
                    .font(.system(.caption2))
                    .foregroundStyle(preference == .neutral ? Color.textSecondary : .white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.md)
                    .fill(backgroundColor(for: preference))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Design.Radius.md)
                    .strokeBorder(borderColor(for: preference), lineWidth: preference == .neutral ? 1 : 0)
            )
        }
        .buttonStyle(OnboardingScaleButtonStyle())
        .accessibilityLabel("\(cuisine.rawValue) cuisine")
        .accessibilityValue(preference.accessibilityDescription)
        .accessibilityHint("Tap to cycle preference")
    }

    private func backgroundColor(for preference: CuisinePreference) -> Color {
        switch preference {
        case .like:
            return OnboardingDesign.Colors.success
        case .dislike:
            return OnboardingDesign.Colors.highlight
        case .neutral:
            return OnboardingDesign.Colors.cardBackground
        }
    }

    private func borderColor(for preference: CuisinePreference) -> Color {
        switch preference {
        case .like, .dislike:
            return .clear
        case .neutral:
            return OnboardingDesign.Colors.cardBorder
        }
    }

    // MARK: - Legend Item

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: Design.Spacing.xxs) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .accessibilityHidden(true)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
        }
        .accessibilityElement(children: .combine)
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
                    .font(Design.Typography.footnote)
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
}

// MARK: - CuisinePreference Accessibility
private extension CuisinePreference {
    var accessibilityDescription: String {
        switch self {
        case .like: return "Liked"
        case .dislike: return "Disliked"
        case .neutral: return "Neutral"
        }
    }
}

// MARK: - Cooking Time Extension (for edit view only)
private extension CookingTime {
    var editIcon: String {
        switch self {
        case .quick: return "bolt.fill"
        case .moderate: return "clock"
        case .standard: return "clock.fill"
        case .leisurely: return "hourglass"
        }
    }

    var editDescription: String {
        switch self {
        case .quick: return "Fast meals when you're short on time"
        case .moderate: return "Quick but flexible"
        case .standard: return "Balanced prep and cooking time"
        case .leisurely: return "Weekend cooking projects"
        }
    }
}

#Preview {
    NavigationStack {
        EditCookingPrefsView(profile: UserProfile(name: "Test"))
    }
    .modelContainer(for: UserProfile.self, inMemory: true)
}
