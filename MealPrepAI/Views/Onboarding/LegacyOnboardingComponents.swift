import SwiftUI

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Onboarding Header Component
struct OnboardingHeader: View {
    let icon: String
    let title: String
    let subtitle: String

    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.sm) {
            HStack(spacing: Design.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.purpleButtonGradient)
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .scaleEffect(appeared ? 1 : 0.5)
                .opacity(appeared ? 1 : 0)

                Text(title)
                    .font(Design.Typography.title)
                    .foregroundStyle(Color.textPrimary)
                    .offset(x: appeared ? 0 : -10)
                    .opacity(appeared ? 1 : 0)
            }

            Text(subtitle)
                .font(Design.Typography.subheadline)
                .foregroundStyle(Color.textSecondary)
                .offset(y: appeared ? 0 : 10)
                .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(Design.Animation.bouncy.delay(0.1)) {
                appeared = true
            }
        }
        .onDisappear {
            appeared = false
        }
    }
}

// MARK: - Premium Reusable Components

struct PremiumTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(Design.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.md)
                    .fill(Color.mintLight)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Design.Radius.md)
                    .strokeBorder(Color.mintMedium.opacity(0.5), lineWidth: 1)
            )
    }
}

struct PremiumSelectionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Design.Typography.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : Color.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Design.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: Design.Radius.md)
                        .fill(isSelected ? AnyShapeStyle(LinearGradient.purpleButtonGradient) : AnyShapeStyle(Color.mintLight))
                        .shadow(
                            color: isSelected ? Design.Shadow.purple.color : .clear,
                            radius: isSelected ? 8 : 0,
                            y: isSelected ? 4 : 0
                        )
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct PremiumGoalRow: View {
    let icon: String
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Design.Spacing.md) {
                // Icon Circle
                ZStack {
                    Circle()
                        .fill(isSelected ? LinearGradient.purpleButtonGradient : LinearGradient(colors: [Color.mintLight, Color.mintLight], startPoint: .top, endPoint: .bottom))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : Color.accentPurple)
                }

                VStack(alignment: .leading, spacing: Design.Spacing.xxs) {
                    Text(title)
                        .font(Design.Typography.headline)
                        .foregroundStyle(Color.textPrimary)
                    Text(description)
                        .font(Design.Typography.caption)
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                // Checkmark
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.accentPurple : Color.mintMedium, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Color.accentPurple)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(Design.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.lg)
                    .fill(Color.cardBackground)
                    .shadow(
                        color: isSelected ? Design.Shadow.purple.color : Design.Shadow.sm.color,
                        radius: isSelected ? Design.Shadow.purple.radius : Design.Shadow.sm.radius,
                        y: isSelected ? Design.Shadow.purple.y : Design.Shadow.sm.y
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: Design.Radius.lg)
                    .strokeBorder(isSelected ? Color.accentPurple.opacity(0.5) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct PremiumMultiSelectChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Design.Spacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                }
                Text(title)
                    .font(Design.Typography.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundStyle(isSelected ? .white : Color.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Design.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.md)
                    .fill(isSelected ? AnyShapeStyle(LinearGradient.purpleButtonGradient) : AnyShapeStyle(Color.cardBackground))
                    .shadow(
                        color: isSelected ? Design.Shadow.purple.color : Design.Shadow.sm.color,
                        radius: isSelected ? 8 : Design.Shadow.sm.radius,
                        y: isSelected ? 4 : Design.Shadow.sm.y
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct PremiumCuisineChip: View {
    let flag: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Design.Spacing.xs) {
                Text(flag)
                    .font(.system(size: 28))
                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)

                Text(title)
                    .font(Design.Typography.captionSmall)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? .white : Color.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Design.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.md)
                    .fill(isSelected ? AnyShapeStyle(LinearGradient.purpleButtonGradient) : AnyShapeStyle(Color.cardBackground))
                    .shadow(
                        color: isSelected ? Design.Shadow.purple.color : Design.Shadow.sm.color,
                        radius: isSelected ? 8 : Design.Shadow.sm.radius,
                        y: isSelected ? 4 : Design.Shadow.sm.y
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: Design.Radius.md)
                    .strokeBorder(isSelected ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct PremiumTimeChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Design.Typography.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : Color.textPrimary)
                .padding(.horizontal, Design.Spacing.lg)
                .padding(.vertical, Design.Spacing.sm)
                .background(
                    Capsule()
                        .fill(isSelected ? AnyShapeStyle(LinearGradient.purpleButtonGradient) : AnyShapeStyle(Color.cardBackground))
                        .shadow(
                            color: isSelected ? Design.Shadow.purple.color : Design.Shadow.sm.color,
                            radius: isSelected ? 8 : Design.Shadow.sm.radius,
                            y: isSelected ? 4 : Design.Shadow.sm.y
                        )
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Legacy Components (kept for compatibility)

struct OnboardingTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(Design.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.md)
                    .fill(Color.mintLight)
            )
    }
}

struct SelectionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        PremiumSelectionButton(title: title, isSelected: isSelected, action: action)
    }
}

struct GoalOptionRow: View {
    let icon: String
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        PremiumGoalRow(icon: icon, title: title, description: description, isSelected: isSelected, action: action)
    }
}

struct MultiSelectChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        PremiumMultiSelectChip(title: title, icon: icon, isSelected: isSelected, action: action)
    }
}

struct CuisineChip: View {
    let flag: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        PremiumCuisineChip(flag: flag, title: title, isSelected: isSelected, action: action)
    }
}
