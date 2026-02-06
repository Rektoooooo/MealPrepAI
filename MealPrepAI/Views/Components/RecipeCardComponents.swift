import SwiftUI
import UIKit

// MARK: - Featured Recipe Card
struct FeaturedRecipeCard: View {
    let recipe: Recipe
    var onTap: () -> Void
    var onFavorite: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                // Background Image
                ZStack(alignment: .bottom) {
                    // Real image or colorful food-themed gradient placeholder
                    if let imageData = recipe.localImageData,
                       let uiImage = UIImage.downsample(data: imageData, maxDimension: 400) ?? UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: Design.Radius.featured))
                    } else {
                        FoodImagePlaceholder(
                            style: recipe.cuisineType?.foodStyle ?? .random,
                            height: 220,
                            cornerRadius: Design.Radius.featured,
                            showIcon: recipe.imageURL == nil,
                            iconSize: 60,
                            imageName: recipe.highResImageURL ?? recipe.imageURL
                        )
                    }

                    // Purple overlay gradient for text readability
                    LinearGradient(
                        colors: [.clear, Color.accentPurpleDeep.opacity(0.85)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Design.Radius.featured))

                    // Content
                    VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                        // Cuisine badge
                        Text(recipe.cuisineType?.rawValue ?? "Recipe")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, Design.Spacing.sm)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(.white.opacity(0.2))
                            )

                        Text(recipe.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .lineLimit(2)

                        HStack(spacing: Design.Spacing.lg) {
                            // Time
                            HStack(spacing: Design.Spacing.xs) {
                                Image(systemName: "clock.fill")
                                    .font(.caption)
                                Text("\(recipe.totalTimeMinutes) min")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(.white.opacity(0.9))

                            // Calories per serving
                            HStack(spacing: Design.Spacing.xs) {
                                Image(systemName: "flame.fill")
                                    .font(.caption)
                                Text("\(recipe.caloriesPerServing) cal/serving")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(.white.opacity(0.9))

                            Spacer()

                            // See Recipe button
                            Text("See Recipe")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, Design.Spacing.md)
                                .padding(.vertical, Design.Spacing.xs)
                                .background(
                                    Capsule()
                                        .fill(.white.opacity(0.25))
                                )
                        }
                    }
                    .padding(Design.Spacing.lg)
                }

                // Favorite button
                Button(action: onFavorite) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 40, height: 40)

                        Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                            .font(Design.Typography.bodyLarge)
                            .foregroundStyle(recipe.isFavorite ? .red : .white)
                    }
                }
                .accessibilityLabel(recipe.isFavorite ? "Remove from favorites" : "Add to favorites")
                .padding(Design.Spacing.md)
            }
        }
        .buttonStyle(.plain)
        .featuredCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(recipe.name), \(recipe.cuisineType?.rawValue ?? "Recipe"), \(recipe.totalTimeMinutes) minutes, \(recipe.caloriesPerServing) calories per serving")
        .accessibilityHint("Double tap to view recipe")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Stacked Recipe Card (for grids)
struct StackedRecipeCard: View {
    let recipe: Recipe
    var onTap: () -> Void
    var onAdd: (() -> Void)? = nil

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Image area with badges overlay
                ZStack {
                    if let imageData = recipe.localImageData,
                       let uiImage = UIImage.downsample(data: imageData, maxDimension: 400) ?? UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 140)
                            .clipShape(
                                UnevenRoundedRectangle(
                                    topLeadingRadius: Design.Radius.card,
                                    bottomLeadingRadius: 0,
                                    bottomTrailingRadius: 0,
                                    topTrailingRadius: Design.Radius.card
                                )
                            )
                    } else {
                        FoodImagePlaceholder(
                            style: recipe.cuisineType?.foodStyle ?? .random,
                            height: 140,
                            cornerRadius: 0,
                            showIcon: recipe.imageURL == nil,
                            iconSize: 36,
                            imageName: recipe.highResImageURL ?? recipe.imageURL
                        )
                        .clipShape(
                            UnevenRoundedRectangle(
                                topLeadingRadius: Design.Radius.card,
                                bottomLeadingRadius: 0,
                                bottomTrailingRadius: 0,
                                topTrailingRadius: Design.Radius.card
                            )
                        )
                    }

                    // Gradient overlay for badges
                    VStack {
                        Spacer()
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 50)
                    }
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: Design.Radius.card,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: Design.Radius.card
                        )
                    )

                    // Badges layer
                    VStack {
                        // Top row: Add button
                        HStack {
                            Spacer()
                            if let onAdd = onAdd {
                                Button(action: onAdd) {
                                    ZStack {
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                            .frame(width: 34, height: 34)

                                        Image(systemName: "plus")
                                            .font(Design.Typography.footnote.weight(.bold))
                                            .foregroundStyle(Color.accentPurple)
                                    }
                                    .frame(minWidth: 44, minHeight: 44)
                                    .contentShape(Rectangle())
                                }
                                .accessibilityLabel("Add to meal plan")
                            }
                        }
                        .padding(Design.Spacing.sm)

                        Spacer()

                        // Bottom row: Time & Cuisine badges
                        HStack {
                            // Time badge
                            HStack(spacing: 3) {
                                Image(systemName: "clock.fill")
                                    .font(Design.Typography.captionSmall)
                                Text("\(recipe.totalTimeMinutes)m")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(.black.opacity(0.5))
                            )

                            Spacer()

                            // Cuisine badge (if available)
                            if let cuisine = recipe.cuisineType {
                                Text(cuisine.rawValue)
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule()
                                            .fill(Color.accentPurple.opacity(0.8))
                                    )
                            }
                        }
                        .padding(.horizontal, Design.Spacing.sm)
                        .padding(.bottom, Design.Spacing.sm)
                    }
                }
                .frame(height: 140)

                // Info section
                VStack(alignment: .leading, spacing: 6) {
                    Text(recipe.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(height: 38, alignment: .top)

                    // Stats row
                    HStack(spacing: 0) {
                        // Calories
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(Design.Typography.captionSmall)
                                .foregroundStyle(Color.accentOrange)
                            Text("\(recipe.caloriesPerServing)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                        }

                        Text(" kcal")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)

                        Spacer()

                        // Servings
                        HStack(spacing: 3) {
                            Image(systemName: "person.fill")
                                .font(Design.Typography.captionSmall)
                                .foregroundStyle(Color.mintVibrant)
                            Text("\(recipe.servings)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        // Favorite
                        Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                            .font(Design.Typography.caption)
                            .foregroundStyle(recipe.isFavorite ? .red : .secondary.opacity(0.5))
                    }
                }
                .padding(.horizontal, Design.Spacing.sm)
                .padding(.vertical, Design.Spacing.sm)
                .frame(height: 75)
            }
            .frame(height: 215)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Design.Radius.card))
            .shadow(color: Color.black.opacity(0.08), radius: 8, y: 4)
            .shadow(color: Color.black.opacity(0.04), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(recipe.name), \(recipe.caloriesPerServing) calories, \(recipe.totalTimeMinutes) minutes, \(recipe.servings) servings")
        .accessibilityHint("Double tap to view recipe")
        .accessibilityAddTraits(.isButton)
    }
}
