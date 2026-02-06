import SwiftUI
import UIKit

// MARK: - Adaptive Color Palette (Light/Dark Mode)
extension Color {
    // MARK: - Primary Black/Gray (Adaptive) - Formerly Mint Green
    static let mintLight = Color(light: Color(hex: "F5F5F5"), dark: Color(hex: "1C1C1E"))
    static let mintMedium = Color(light: Color(hex: "E0E0E0"), dark: Color(hex: "2C2C2E"))
    static let mintDark = Color(light: Color(hex: "9E9E9E"), dark: Color(hex: "3A3A3C"))
    static let mintVibrant = Color(light: Color(hex: "212121"), dark: Color(hex: "FFFFFF"))

    // MARK: - Accent Black/Gray (Adaptive) - Named "Purple" for compatibility
    static let accentPurpleLight = Color(light: Color(hex: "757575"), dark: Color(hex: "B0B0B0"))
    static let accentPurple = Color(light: Color(hex: "424242"), dark: Color(hex: "9E9E9E"))
    static let accentPurpleDeep = Color(light: Color(hex: "212121"), dark: Color(hex: "757575"))

    // MARK: - Accent Yellow/Gold (Adaptive) - Vibrant for CTAs
    static let accentYellowLight = Color(light: Color(hex: "FFF176"), dark: Color(hex: "FFF59D"))
    static let accentYellow = Color(light: Color(hex: "FFEE58"), dark: Color(hex: "FFF176"))
    static let accentGold = Color(light: Color(hex: "FFD54F"), dark: Color(hex: "FFEE58"))

    // MARK: - Legacy Brand Colors (Keep for compatibility) - Now Black
    static let brandGreen = Color(light: Color(hex: "212121"), dark: Color(hex: "FFFFFF"))
    static let brandGreenDark = Color(light: Color(hex: "000000"), dark: Color(hex: "E0E0E0"))
    static let brandGreenLight = Color(light: Color(hex: "E0E0E0"), dark: Color(hex: "2C2C2E"))

    // MARK: - Additional Accents - Vibrant for Key UI
    static let accentOrange = Color(light: Color(hex: "FF9500"), dark: Color(hex: "FFB340"))
    static let accentBlue = Color(light: Color(hex: "007AFF"), dark: Color(hex: "409CFF"))
    static let accentPink = Color(light: Color(hex: "FF2D55"), dark: Color(hex: "FF6482"))
    static let accentTeal = Color(light: Color(hex: "30D5C8"), dark: Color(hex: "5CE1D6"))

    // MARK: - Meal Type Colors - Vibrant & Distinct
    static let breakfastGradientStart = Color(light: Color(hex: "FFB74D"), dark: Color(hex: "FFA726"))
    static let breakfastGradientEnd = Color(light: Color(hex: "FF9800"), dark: Color(hex: "F57C00"))

    static let lunchGradientStart = Color(light: Color(hex: "66BB6A"), dark: Color(hex: "81C784"))
    static let lunchGradientEnd = Color(light: Color(hex: "43A047"), dark: Color(hex: "66BB6A"))

    static let dinnerGradientStart = Color(light: Color(hex: "7E57C2"), dark: Color(hex: "9575CD"))
    static let dinnerGradientEnd = Color(light: Color(hex: "5E35B1"), dark: Color(hex: "7E57C2"))

    static let snackGradientStart = Color(light: Color(hex: "F06292"), dark: Color(hex: "F48FB1"))
    static let snackGradientEnd = Color(light: Color(hex: "E91E63"), dark: Color(hex: "F06292"))

    // MARK: - Macro Colors - Vibrant for Nutrition Tracking
    static let calorieColor = Color(light: Color(hex: "FF6B6B"), dark: Color(hex: "FF8A8A"))
    static let proteinColor = Color(light: Color(hex: "EF4444"), dark: Color(hex: "F87171"))  // Red
    static let carbColor = Color(light: Color(hex: "F97316"), dark: Color(hex: "FB923C"))    // Orange
    static let fatColor = Color(light: Color(hex: "3B82F6"), dark: Color(hex: "60A5FA"))     // Blue

    // MARK: - Background Colors (Adaptive)
    static let backgroundPrimary = Color(UIColor.systemBackground)
    static let backgroundSecondary = Color(UIColor.secondarySystemBackground)
    static let backgroundTertiary = Color(UIColor.tertiarySystemBackground)
    static let backgroundGrouped = Color(UIColor.systemGroupedBackground)

    // Custom backgrounds
    static let backgroundMint = Color(light: Color(hex: "FAFAFA"), dark: Color(hex: "1C1C1E"))
    static let backgroundCream = Color(light: Color(hex: "FFFDF7"), dark: Color(hex: "1C1C1E"))
    static let cardBackground = Color(light: .white, dark: Color(hex: "2C2C2E"))

    // MARK: - Text Colors
    static let textPrimary = Color(UIColor.label)
    static let textSecondary = Color(UIColor.secondaryLabel)
    static let textTertiary = Color(UIColor.tertiaryLabel)

    // MARK: - Surface Colors
    static let surfaceElevated = Color(light: .white, dark: Color(hex: "3A3A3C"))
    static let surfaceOverlay = Color(light: Color.black.opacity(0.04), dark: Color.white.opacity(0.06))
}

// MARK: - Color Initialization Helpers
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

// MARK: - Gradient Presets (Adaptive)
extension LinearGradient {
    // Main screen background (warm peach tint at top, fading to system background)
    static let mintBackgroundGradient = LinearGradient(
        colors: [
            Color(light: Color(hex: "FFF5F0"), dark: Color(hex: "1C1C1E")),
            Color(light: Color(hex: "FFFAF7"), dark: Color(hex: "1A1A1C")),
            Color.backgroundPrimary
        ],
        startPoint: .top,
        endPoint: .init(x: 0.5, y: 0.35)
    )

    // Light mint background (subtle)
    static let mintSubtleGradient = LinearGradient(
        colors: [Color.mintLight.opacity(0.6), Color.backgroundPrimary],
        startPoint: .top,
        endPoint: .center
    )

    // Teal card overlay for featured cards
    static let purpleOverlayGradient = LinearGradient(
        colors: [Color.clear, Color.accentPurpleDeep.opacity(0.9)],
        startPoint: .center,
        endPoint: .bottom
    )

    // Teal button gradient
    static let purpleButtonGradient = LinearGradient(
        colors: [Color.accentPurpleLight, Color.accentPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Yellow CTA gradient
    static let yellowCTAGradient = LinearGradient(
        colors: [Color.accentYellowLight, Color.accentYellow],
        startPoint: .leading,
        endPoint: .trailing
    )

    // Gold accent gradient
    static let goldGradient = LinearGradient(
        colors: [Color.accentYellowLight, Color.accentGold],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Legacy brand gradient (updated)
    static let brandGradient = LinearGradient(
        colors: [Color.mintVibrant, Color.brandGreen],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Meal type gradients
    static let sunriseGradient = LinearGradient(
        colors: [Color.breakfastGradientStart, Color.breakfastGradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let freshGradient = LinearGradient(
        colors: [Color.lunchGradientStart, Color.lunchGradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let eveningGradient = LinearGradient(
        colors: [Color.dinnerGradientStart, Color.dinnerGradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let skyGradient = LinearGradient(
        colors: [Color.snackGradientStart, Color.snackGradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Hero card gradient
    static let heroGradient = LinearGradient(
        colors: [Color.mintVibrant, Color.brandGreen, Color.mintDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Subtle card gradient
    static let cardGradient = LinearGradient(
        colors: [Color.cardBackground, Color.cardBackground.opacity(0.95)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Cal AI-style warm background: subtle peach/blush tint at top ~20%, fading to white
    static let warmTopGradient = LinearGradient(
        colors: [
            Color(light: Color(hex: "FFF5F0"), dark: Color(hex: "1C1C1E")),
            Color(light: Color(hex: "FFFAF7"), dark: Color(hex: "1A1A1C")),
            Color.backgroundPrimary
        ],
        startPoint: .top,
        endPoint: .init(x: 0.5, y: 0.35)
    )
}

// MARK: - Design Tokens (Updated for new design)
struct Design {
    // Spacing (generous layout)
    struct Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 40
        static let section: CGFloat = 28  // Between major sections
    }

    // Corner Radius (larger for softer appearance)
    struct Radius {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 14
        static let lg: CGFloat = 18
        static let xl: CGFloat = 22
        static let xxl: CGFloat = 26
        static let card: CGFloat = 24     // Standard cards
        static let featured: CGFloat = 28  // Featured/hero cards
        static let full: CGFloat = 100     // Capsule
    }

    // Shadows (flat, subtle - Cal AI style)
    struct Shadow {
        static let sm = (color: Color.black.opacity(0.03), radius: 4.0, y: 2.0)
        static let md = (color: Color.black.opacity(0.05), radius: 8.0, y: 3.0)
        static let lg = (color: Color.black.opacity(0.08), radius: 16.0, y: 6.0)
        static let card = (color: Color.black.opacity(0.04), radius: 10.0, y: 4.0)
        static let elevated = (color: Color.black.opacity(0.07), radius: 18.0, y: 8.0)
        static let purple = (color: Color.accentPurple.opacity(0.15), radius: 12.0, y: 4.0)
        static let glow = (color: Color.mintVibrant.opacity(0.2), radius: 16.0, y: 0.0)
        static let tabBar = (color: Color.black.opacity(0.15), radius: 20.0, y: -4.0)
    }

    // Animation
    struct Animation {
        static let quick = SwiftUI.Animation.easeOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let smooth = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
        static let bouncy = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.65)
        static let gentle = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.85)
    }

    // Typography — scales with Dynamic Type
    struct Typography {
        static let largeTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
        static let title = Font.system(.title, design: .rounded).weight(.bold)
        static let title2 = Font.system(.title2, design: .rounded).weight(.bold)
        static let title3 = Font.system(.title3, design: .rounded).weight(.semibold)
        static let headline = Font.system(.headline, design: .rounded)
        static let body = Font.system(.body)
        static let bodyLarge = Font.system(.body).weight(.medium)
        static let callout = Font.system(.callout)
        static let subheadline = Font.system(.subheadline)
        static let footnote = Font.system(.footnote)
        static let caption = Font.system(.caption).weight(.medium)
        static let captionSmall = Font.system(.caption2).weight(.medium)

        // Hero numbers — fixed sizes (intentionally large display numbers in constrained layouts)
        static let heroNumber = Font.system(size: 52, weight: .bold, design: .rounded)
        static let heroNumberMedium = Font.system(size: 44, weight: .bold, design: .rounded)
        static let heroNumberSmall = Font.system(size: 40, weight: .bold, design: .rounded)
        static let heroSubtitle = Font.system(size: 14, weight: .medium, design: .rounded)

        // Icon/emoji sizing — fixed (SF Symbols inside fixed containers)
        static let iconLarge = Font.system(size: 60)
        static let iconMedium = Font.system(size: 50)
        static let iconSmall = Font.system(size: 40)
        static let iconXSmall = Font.system(size: 26)
    }

    // Progress Ring Line Widths
    struct Ring {
        static let thin: CGFloat = 4
        static let medium: CGFloat = 6
        static let thick: CGFloat = 10
        static let hero: CGFloat = 12
    }
}

// MARK: - Reduce Motion Support

extension View {
    /// Conditionally applies animation based on the user's reduce motion preference.
    /// Use this for key animations that would be disruptive for motion-sensitive users.
    func animateIfAllowed(_ animation: Animation?, value: some Equatable) -> some View {
        transaction { transaction in
            if UIAccessibility.isReduceMotionEnabled {
                transaction.animation = nil
            }
        }
        .animation(UIAccessibility.isReduceMotionEnabled ? nil : animation, value: value)
    }
}

// MARK: - Custom View Modifiers

// Premium Card Style (Updated)
struct PremiumCardModifier: ViewModifier {
    var cornerRadius: CGFloat = Design.Radius.card
    var padding: CGFloat = Design.Spacing.md

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.cardBackground)
                    .shadow(
                        color: Design.Shadow.card.color,
                        radius: Design.Shadow.card.radius,
                        y: Design.Shadow.card.y
                    )
            )
    }
}

// Featured Card Style (New)
struct FeaturedCardModifier: ViewModifier {
    var cornerRadius: CGFloat = Design.Radius.featured

    func body(content: Content) -> some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(
                color: Design.Shadow.elevated.color,
                radius: Design.Shadow.elevated.radius,
                y: Design.Shadow.elevated.y
            )
    }
}

// Glass Card Style
struct GlassCardModifier: ViewModifier {
    var padding: CGFloat = Design.Spacing.md
    var cornerRadius: CGFloat = Design.Radius.card

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .shadow(
                        color: Design.Shadow.md.color,
                        radius: Design.Shadow.md.radius,
                        y: Design.Shadow.md.y
                    )
            )
    }
}

// Gradient Card Style
struct GradientCardModifier: ViewModifier {
    let gradient: LinearGradient
    var cornerRadius: CGFloat = Design.Radius.card

    func body(content: Content) -> some View {
        content
            .padding(Design.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(gradient)
                    .shadow(
                        color: Design.Shadow.md.color,
                        radius: Design.Shadow.md.radius,
                        y: Design.Shadow.md.y
                    )
            )
    }
}

// Macro Pill Card Style (Cal AI-style horizontal macro cards)
struct MacroPillCardModifier: ViewModifier {
    let accentColor: Color

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, Design.Spacing.md)
            .padding(.vertical, Design.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.lg)
                    .fill(Color.cardBackground)
                    .shadow(
                        color: Design.Shadow.sm.color,
                        radius: Design.Shadow.sm.radius,
                        y: Design.Shadow.sm.y
                    )
            )
    }
}

// Teal Button Style (named Purple for compatibility)
struct PurpleButtonModifier: ViewModifier {
    var isSmall: Bool = false

    func body(content: Content) -> some View {
        content
            .font(isSmall ? .subheadline.weight(.semibold) : .headline)
            .foregroundStyle(.white)
            .padding(.horizontal, isSmall ? Design.Spacing.md : Design.Spacing.xl)
            .padding(.vertical, isSmall ? Design.Spacing.sm : Design.Spacing.md)
            .background(
                Capsule()
                    .fill(LinearGradient.purpleButtonGradient)
                    .shadow(
                        color: Design.Shadow.purple.color,
                        radius: Design.Shadow.purple.radius,
                        y: Design.Shadow.purple.y
                    )
            )
    }
}

// Yellow CTA Button Style
struct YellowButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundStyle(Color(hex: "5D4037")) // Brown text
            .padding(.horizontal, Design.Spacing.xl)
            .padding(.vertical, Design.Spacing.md)
            .background(
                Capsule()
                    .fill(LinearGradient.yellowCTAGradient)
                    .shadow(
                        color: Color.accentYellow.opacity(0.3),
                        radius: 12,
                        y: 4
                    )
            )
    }
}

// Floating Action Button Style
struct FloatingButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, Design.Spacing.xl)
            .padding(.vertical, Design.Spacing.md)
            .background(
                Capsule()
                    .fill(LinearGradient.brandGradient)
                    .shadow(
                        color: Color.mintVibrant.opacity(0.4),
                        radius: 12,
                        y: 6
                    )
            )
    }
}

// MARK: - View Extensions
extension View {
    func premiumCard(cornerRadius: CGFloat = Design.Radius.card, padding: CGFloat = Design.Spacing.md) -> some View {
        modifier(PremiumCardModifier(cornerRadius: cornerRadius, padding: padding))
    }

    func featuredCard(cornerRadius: CGFloat = Design.Radius.featured) -> some View {
        modifier(FeaturedCardModifier(cornerRadius: cornerRadius))
    }

    func glassCard(padding: CGFloat = Design.Spacing.md, cornerRadius: CGFloat = Design.Radius.card) -> some View {
        modifier(GlassCardModifier(padding: padding, cornerRadius: cornerRadius))
    }

    func gradientCard(_ gradient: LinearGradient, cornerRadius: CGFloat = Design.Radius.card) -> some View {
        modifier(GradientCardModifier(gradient: gradient, cornerRadius: cornerRadius))
    }

    func purpleButton(small: Bool = false) -> some View {
        modifier(PurpleButtonModifier(isSmall: small))
    }

    func yellowButton() -> some View {
        modifier(YellowButtonModifier())
    }

    func floatingButton() -> some View {
        modifier(FloatingButtonModifier())
    }

    func macroPillCard(accent: Color = .clear) -> some View {
        modifier(MacroPillCardModifier(accentColor: accent))
    }

    // Cal AI-style warm background (subtle peach tint at top only)
    func warmBackground() -> some View {
        self.background(
            LinearGradient.warmTopGradient
                .ignoresSafeArea()
        )
    }

    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }

    // Premium glass card with subtle color tint for Insights
    func insightsGlassCard(tint: Color = .clear) -> some View {
        self
            .padding(Design.Spacing.md)
            .background(
                ZStack {
                    // Glass material base
                    RoundedRectangle(cornerRadius: Design.Radius.card)
                        .fill(.ultraThinMaterial)

                    // Subtle color tint overlay
                    RoundedRectangle(cornerRadius: Design.Radius.card)
                        .fill(tint.opacity(0.05))

                    // Top-left highlight for glass depth
                    RoundedRectangle(cornerRadius: Design.Radius.card)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.12), .clear, .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Inner border for glass edge
                    RoundedRectangle(cornerRadius: Design.Radius.card)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.25), tint.opacity(0.1), Color.white.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                }
                .shadow(
                    color: Design.Shadow.card.color,
                    radius: Design.Shadow.card.radius,
                    y: Design.Shadow.card.y
                )
            )
    }

    // Convenience for mint background
    func mintBackground() -> some View {
        self.background(
            LinearGradient.mintBackgroundGradient
                .ignoresSafeArea()
        )
    }
}

// MARK: - Shimmer Effect
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.4),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 2)
                    .offset(x: -geo.size.width + (phase * geo.size.width * 2))
                }
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

// MARK: - Animated Counter
struct AnimatedNumber: View {
    let value: Int
    let font: Font
    let color: Color

    @State private var displayValue: Int = 0

    var body: some View {
        Text("\(displayValue)")
            .font(font)
            .foregroundStyle(color)
            .contentTransition(.numericText(value: Double(displayValue)))
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    displayValue = value
                }
            }
            .onChange(of: value) { _, newValue in
                withAnimation(.easeOut(duration: 0.5)) {
                    displayValue = newValue
                }
            }
    }
}

// MARK: - Progress Ring
struct ProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let gradient: LinearGradient
    var showLabel: Bool = true

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.surfaceOverlay, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    gradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            if showLabel {
                Text("\(Int(animatedProgress * 100))%")
                    .font(.system(.callout, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = min(newValue, 1.0)
            }
        }
        .onAppear {
            animatedProgress = min(progress, 1.0)
        }
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(animatedProgress * 100)) percent")
    }
}

// MARK: - Macro Progress Bar
struct MacroProgressBar: View {
    let label: String
    let current: Int
    let target: Int
    let color: Color
    let icon: String

    private var progress: Double {
        guard target > 0 else { return 0 }
        return Double(current) / Double(target)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.xs) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(current)g / \(target)g")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.15))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * min(progress, 1.0))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 6)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) progress")
        .accessibilityValue("\(current) of \(target) grams, \(target > 0 ? Int(Double(current) / Double(target) * 100) : 0) percent")
    }
}

// MARK: - Meal Type Helpers
extension MealType {
    var gradient: LinearGradient {
        switch self {
        case .breakfast: return .sunriseGradient
        case .lunch: return .freshGradient
        case .dinner: return .eveningGradient
        case .snack: return .skyGradient
        }
    }

    var primaryColor: Color {
        switch self {
        case .breakfast: return .breakfastGradientEnd
        case .lunch: return .lunchGradientEnd
        case .dinner: return .dinnerGradientEnd
        case .snack: return .snackGradientEnd
        }
    }
}

// MARK: - Category Icon Helper
extension GroceryCategory {
    var themeColor: Color {
        switch self {
        case .produce: return .lunchGradientEnd      // Green for fresh produce
        case .meat: return .accentPink               // Pink/red for meat
        case .dairy: return .accentBlue              // Blue for dairy
        case .bakery: return .accentOrange           // Orange for bakery
        case .frozen: return .accentTeal             // Teal for frozen
        case .pantry: return .carbColor              // Yellow for pantry
        case .canned: return .accentOrange           // Orange for canned
        case .condiments: return .fatColor           // Purple for condiments
        case .snacks: return .snackGradientEnd       // Pink for snacks
        case .beverages: return .accentBlue          // Blue for beverages
        case .spices: return .dinnerGradientEnd      // Purple for spices
        case .other: return .textSecondary
        }
    }
}
