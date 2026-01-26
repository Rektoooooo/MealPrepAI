import SwiftUI

// MARK: - Onboarding Design System
// Light theme inspired by Cal AI - clean white background with black accents

struct OnboardingDesign {
    // MARK: - Colors
    struct Colors {
        // Background - Pure white like Cal AI
        static let background = Color.white
        static let backgroundSecondary = Color(hex: "FAFAFA")

        // Card backgrounds - Light gray for unselected
        static let cardBackground = Color(hex: "F5F5F5")
        static let cardBackgroundSelected = Color.black
        static let cardBorder = Color(hex: "E5E5E5")

        // Primary accent - Black (Cal AI style)
        static let accent = Color.black
        static let accentSecondary = Color(hex: "1A1A1A")

        // Success/highlight colors
        static let success = Color(hex: "4ADE80")
        static let highlight = Color(hex: "FF6B6B") // For charts/special elements

        // Text colors
        static let textPrimary = Color.black
        static let textSecondary = Color(hex: "6B6B6B")
        static let textTertiary = Color(hex: "9CA3AF")
        static let textMuted = Color(hex: "B0B0B0")
        static let textOnDark = Color.white

        // Selection states
        static let selectedBorder = Color.black
        static let selectedBackground = Color.black
        static let unselectedBackground = Color(hex: "F5F5F5")

        // Icon backgrounds
        static let iconBackground = Color(hex: "F0F0F0")
        static let iconBackgroundSelected = Color.black

        // Progress bar
        static let progressBackground = Color(hex: "E5E5E5")
        static let progressFill = Color.black

        // Overlay
        static let overlay = Color.black.opacity(0.4)
    }

    // MARK: - Gradients
    struct Gradients {
        // Cal AI uses solid colors, but keeping gradient option
        static let ctaButton = LinearGradient(
            colors: [Colors.accent, Colors.accentSecondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let progressBar = LinearGradient(
            colors: [Colors.progressFill, Colors.progressFill],
            startPoint: .leading,
            endPoint: .trailing
        )

        // Subtle gradient for special cards
        static let cardHighlight = LinearGradient(
            colors: [Color.white, Color(hex: "FAFAFA")],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Spacing
    struct Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
        static let section: CGFloat = 40
    }

    // MARK: - Corner Radius
    struct Radius {
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 28
        static let full: CGFloat = 100
    }

    // MARK: - Typography
    struct Typography {
        // Cal AI uses bold, clean sans-serif
        static let largeTitle = Font.system(size: 32, weight: .bold, design: .default)
        static let title = Font.system(size: 28, weight: .bold, design: .default)
        static let title2 = Font.system(size: 24, weight: .bold, design: .default)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .default)
        static let headline = Font.system(size: 17, weight: .semibold, design: .default)
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        static let bodyMedium = Font.system(size: 17, weight: .medium, design: .default)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
        static let footnote = Font.system(size: 13, weight: .regular, design: .default)
        static let caption = Font.system(size: 12, weight: .medium, design: .default)
        static let captionSmall = Font.system(size: 11, weight: .medium, design: .default)
    }

    // MARK: - Animation
    struct Animation {
        static let quick = SwiftUI.Animation.easeOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let smooth = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
        static let bouncy = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.65)
        static let gentle = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.85)
    }

    // MARK: - Shadows
    struct Shadow {
        // Cal AI uses subtle or no shadows
        static let card = (color: Color.black.opacity(0.05), radius: 8.0, y: 2.0)
        static let elevated = (color: Color.black.opacity(0.08), radius: 16.0, y: 4.0)
        static let button = (color: Color.black.opacity(0.15), radius: 8.0, y: 4.0)
    }
}

// MARK: - Onboarding View Modifiers

struct OnboardingBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(OnboardingDesign.Colors.background.ignoresSafeArea())
    }
}

struct OnboardingCardModifier: ViewModifier {
    var isSelected: Bool = false
    var padding: CGFloat = OnboardingDesign.Spacing.md

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: OnboardingDesign.Radius.lg)
                    .fill(isSelected ? OnboardingDesign.Colors.selectedBackground : OnboardingDesign.Colors.unselectedBackground)
            )
    }
}

struct OnboardingButtonModifier: ViewModifier {
    var isEnabled: Bool = true

    func body(content: Content) -> some View {
        content
            .font(OnboardingDesign.Typography.headline)
            .foregroundStyle(isEnabled ? OnboardingDesign.Colors.textOnDark : OnboardingDesign.Colors.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, OnboardingDesign.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: OnboardingDesign.Radius.xl)
                    .fill(isEnabled ? OnboardingDesign.Colors.accent : OnboardingDesign.Colors.cardBackground)
            )
    }
}

// MARK: - View Extensions for Onboarding

extension View {
    func onboardingBackground() -> some View {
        modifier(OnboardingBackgroundModifier())
    }

    func onboardingCard(isSelected: Bool = false, padding: CGFloat = OnboardingDesign.Spacing.md) -> some View {
        modifier(OnboardingCardModifier(isSelected: isSelected, padding: padding))
    }

    func onboardingButton(isEnabled: Bool = true) -> some View {
        modifier(OnboardingButtonModifier(isEnabled: isEnabled))
    }
}
