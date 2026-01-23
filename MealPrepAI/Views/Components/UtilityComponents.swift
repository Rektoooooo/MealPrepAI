import SwiftUI

// MARK: - Greeting Header
struct GreetingHeader: View {
    let userName: String
    var avatarInitials: String? = nil

    private var initials: String {
        avatarInitials ?? String(userName.prefix(2)).uppercased()
    }

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
            // Avatar
            ZStack {
                Circle()
                    .fill(LinearGradient.purpleButtonGradient)
                    .frame(width: 50, height: 50)

                Text(initials)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
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
                .font(.system(size: 16, weight: .medium))
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
                        .font(.system(size: 18))
                        .foregroundStyle(.tertiary)
                }
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
                        .font(.system(size: 18, weight: .semibold))
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

            if showSeeAll, let onSeeAll = onSeeAll {
                Button(action: onSeeAll) {
                    Text("See all")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.accentPurple)
                }
            }
        }
    }
}

// MARK: - Personalization Banner
struct PersonalizationBanner: View {
    var title: String = "Personalise Meal Plan"
    var subtitle: String = "To personalize your menu, we still need information."
    var buttonText: String = "Fill in Data"
    var onTap: () -> Void

    // Brown colors for text
    private let titleColor = Color(red: 0.30, green: 0.20, blue: 0.15)
    private let subtitleColor = Color(red: 0.45, green: 0.35, blue: 0.28)
    private let buttonTextColor = Color(red: 0.35, green: 0.25, blue: 0.18)

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Background
            RoundedRectangle(cornerRadius: Design.Radius.card)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.95, blue: 0.78),
                            Color(red: 0.99, green: 0.90, blue: 0.68)
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
                    .font(.system(size: 22, weight: .bold, design: .rounded))
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
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(buttonTextColor)
                        .padding(.horizontal, Design.Spacing.xl)
                        .padding(.vertical, Design.Spacing.md)
                        .background(
                            Capsule()
                                .fill(Color.accentYellow)
                                .shadow(
                                    color: Color.accentYellow.opacity(0.4),
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
                        .font(.system(size: 22))
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
                    .font(.system(size: 50))
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
