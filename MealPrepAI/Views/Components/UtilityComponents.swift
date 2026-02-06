import SwiftUI
import UIKit

// MARK: - Greeting Header
struct GreetingHeader: View {
    let userName: String
    var avatarEmoji: String? = nil
    var profileImageData: Data? = nil

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
    }

    var body: some View {
        HStack(spacing: Design.Spacing.md) {
            // Avatar - shows profile image, emoji, or initials
            ZStack {
                Circle()
                    .stroke(LinearGradient.purpleButtonGradient, lineWidth: 3)
                    .frame(width: 54, height: 54)

                if let imageData = profileImageData,
                   let uiImage = UIImage.downsample(data: imageData, maxDimension: 100) ?? UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 46, height: 46)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(LinearGradient.purpleButtonGradient)
                        .frame(width: 46, height: 46)

                    if let emoji = avatarEmoji {
                        Text(emoji)
                            .font(Design.Typography.title2)
                    } else {
                        Text(String(userName.prefix(2)).uppercased())
                            .font(.system(.body, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(userName)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(greeting), \(userName)")
    }
}

// MARK: - Rounded Search Bar
struct RoundedSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search recipes..."
    var onSubmit: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: Design.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(Design.Typography.callout.weight(.medium))
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $text)
                .font(.body)
                .submitLabel(.search)
                .onSubmit {
                    onSubmit?()
                }

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(Design.Typography.bodyLarge)
                        .foregroundStyle(.tertiary)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, Design.Spacing.md)
        .padding(.vertical, Design.Spacing.sm + 2)
        .background(
            Capsule()
                .fill(Color.backgroundSecondary)
        )
    }
}

// MARK: - Section Header (Updated)
struct NewSectionHeader: View {
    let title: String
    var emoji: String? = nil
    var icon: String? = nil
    var iconColor: Color = Color.accentPurple
    var showSeeAll: Bool = false
    var onSeeAll: (() -> Void)? = nil

    var body: some View {
        HStack {
            HStack(spacing: Design.Spacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(Design.Typography.bodyLarge.weight(.semibold))
                        .foregroundStyle(iconColor)
                } else if let emoji = emoji {
                    Text(emoji)
                }
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }

            Spacer()
                .accessibilityHidden(true)

            if showSeeAll, let onSeeAll = onSeeAll {
                Button(action: onSeeAll) {
                    Text("See all")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.accentPurple)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Personalization Banner
struct PersonalizationBanner: View {
    var title: String = "Personalise Meal Plan"
    var subtitle: String = "Update your weekly meal preferences"
    var buttonText: String = "Update Preferences"
    var onTap: () -> Void

    // Brown colors for text
    private let titleColor = Color(red: 0.30, green: 0.20, blue: 0.15)
    private let subtitleColor = Color(red: 0.45, green: 0.35, blue: 0.28)
    private let buttonTextColor = Color(hex: "59402E")
    private let buttonBackgroundColor = Color(hex: "FECA27")

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Background gradient: FEF1C6 to FDE6AF
            RoundedRectangle(cornerRadius: Design.Radius.card)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "FEF1C6"),
                            Color(hex: "FDE6AF")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Right side - Large Image (positioned to overflow bottom)
            Image("MealPlanBanner")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 170, height: 190)
                .offset(x: 5, y: 5)

            // Left side - Text and button
            VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                Text(title)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(titleColor)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(subtitleColor)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 180, alignment: .leading)

                Spacer()

                Button(action: onTap) {
                    Text(buttonText)
                        .font(.system(.body, design: .rounded, weight: .bold))
                        .foregroundStyle(buttonTextColor)
                        .padding(.horizontal, Design.Spacing.xl)
                        .padding(.vertical, Design.Spacing.md)
                        .background(
                            Capsule()
                                .fill(buttonBackgroundColor)
                                .shadow(
                                    color: buttonBackgroundColor.opacity(0.4),
                                    radius: 8,
                                    y: 4
                                )
                        )
                }
            }
            .padding(.leading, Design.Spacing.lg)
            .padding(.top, Design.Spacing.lg)
            .padding(.bottom, Design.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: Design.Radius.card))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
        .accessibilityHint("Double tap to \(buttonText.lowercased())")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Quick Action Button
struct QuickActionCard: View {
    let icon: String
    let title: String
    let color: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Design.Spacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: Design.Radius.md)
                        .fill(color.opacity(0.15))
                        .frame(width: 52, height: 52)

                    Image(systemName: icon)
                        .font(Design.Typography.title2)
                        .foregroundStyle(color)
                }

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Design.Spacing.md)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Design.Radius.card))
            .shadow(
                color: Design.Shadow.sm.color,
                radius: Design.Shadow.sm.radius,
                y: Design.Shadow.sm.y
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint("Double tap to activate")
    }
}

// MARK: - Empty State View (Updated)
struct NewEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var buttonTitle: String? = nil
    var buttonIcon: String? = nil
    var buttonStyle: EmptyStateButtonStyle = .purple
    var onButtonTap: (() -> Void)? = nil

    enum EmptyStateButtonStyle {
        case purple, yellow, green
    }

    var body: some View {
        VStack(spacing: Design.Spacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.mintLight)
                    .frame(width: 120, height: 120)

                Image(systemName: icon)
                    .font(Design.Typography.iconMedium)
                    .foregroundStyle(Color.mintVibrant)
            }

            VStack(spacing: Design.Spacing.sm) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Design.Spacing.xl)
            }

            if let buttonTitle = buttonTitle, let onButtonTap = onButtonTap {
                styledButton(title: buttonTitle, icon: buttonIcon, action: onButtonTap)
                    .padding(.top, Design.Spacing.md)
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }

    @ViewBuilder
    private func styledButton(title: String, icon: String?, action: @escaping () -> Void) -> some View {
        switch buttonStyle {
        case .purple:
            Button(action: action) {
                HStack(spacing: Design.Spacing.sm) {
                    if let icon = icon {
                        Image(systemName: icon)
                    }
                    Text(title)
                }
            }
            .purpleButton()
        case .yellow:
            Button(action: action) {
                HStack(spacing: Design.Spacing.sm) {
                    if let icon = icon {
                        Image(systemName: icon)
                    }
                    Text(title)
                }
            }
            .yellowButton()
        case .green:
            Button(action: action) {
                HStack(spacing: Design.Spacing.sm) {
                    if let icon = icon {
                        Image(systemName: icon)
                    }
                    Text(title)
                }
            }
            .floatingButton()
        }
    }
}
