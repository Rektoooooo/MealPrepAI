import SwiftUI
import UIKit

// MARK: - Adaptive Color Palette (Light/Dark Mode)
extension Color {
    // MARK: - Primary Mint Green (Adaptive)
    static let mintLight = Color(light: Color(hex: "E8F5E9"), dark: Color(hex: "1B3D20"))
    static let mintMedium = Color(light: Color(hex: "C8E6C9"), dark: Color(hex: "2E5233"))
    static let mintDark = Color(light: Color(hex: "A5D6A7"), dark: Color(hex: "4A7C50"))
    static let mintVibrant = Color(light: Color(hex: "66BB6A"), dark: Color(hex: "81C784"))

    // MARK: - Accent Green (Adaptive) - Named "Purple" for compatibility
    static let accentPurpleLight = Color(light: Color(hex: "81C784"), dark: Color(hex: "A5D6A7"))
    static let accentPurple = Color(light: Color(hex: "43A047"), dark: Color(hex: "66BB6A"))
    static let accentPurpleDeep = Color(light: Color(hex: "2E7D32"), dark: Color(hex: "43A047"))

    // MARK: - Accent Yellow/Gold (Adaptive)
    static let accentYellowLight = Color(light: Color(hex: "FFD54F"), dark: Color(hex: "FFE082"))
    static let accentYellow = Color(light: Color(hex: "FFCA28"), dark: Color(hex: "FFD54F"))
    static let accentGold = Color(light: Color(hex: "FFC107"), dark: Color(hex: "FFCA28"))

    // MARK: - Legacy Brand Colors (Keep for compatibility)
    static let brandGreen = Color(light: Color(hex: "4CAF50"), dark: Color(hex: "66BB6A"))
    static let brandGreenDark = Color(light: Color(hex: "388E3C"), dark: Color(hex: "4CAF50"))
    static let brandGreenLight = Color(light: Color(hex: "C8E6C9"), dark: Color(hex: "2E5233"))

    // MARK: - Additional Accents
    static let accentOrange = Color(light: Color(hex: "FF9800"), dark: Color(hex: "FFB74D"))
    static let accentBlue = Color(light: Color(hex: "2196F3"), dark: Color(hex: "64B5F6"))
    static let accentPink = Color(light: Color(hex: "E91E63"), dark: Color(hex: "F06292"))
    static let accentTeal = Color(light: Color(hex: "009688"), dark: Color(hex: "4DB6AC"))

    // MARK: - Meal Type Colors
    static let breakfastGradientStart = Color(light: Color(hex: "FFB74D"), dark: Color(hex: "FFA726"))
    static let breakfastGradientEnd = Color(light: Color(hex: "FF8A65"), dark: Color(hex: "FF7043"))

    static let lunchGradientStart = Color(light: Color(hex: "66BB6A"), dark: Color(hex: "81C784"))
    static let lunchGradientEnd = Color(light: Color(hex: "4CAF50"), dark: Color(hex: "66BB6A"))

    static let dinnerGradientStart = Color(light: Color(hex: "5C6BC0"), dark: Color(hex: "7986CB"))
    static let dinnerGradientEnd = Color(light: Color(hex: "3F51B5"), dark: Color(hex: "5C6BC0"))

    static let snackGradientStart = Color(light: Color(hex: "FF8A80"), dark: Color(hex: "FF8A80"))
    static let snackGradientEnd = Color(light: Color(hex: "FF5252"), dark: Color(hex: "FF5252"))

    // MARK: - Macro Colors
    static let calorieColor = Color(light: Color(hex: "FF9800"), dark: Color(hex: "FFB74D"))
    static let proteinColor = Color(light: Color(hex: "5C6BC0"), dark: Color(hex: "7986CB")) // Indigo for protein
    static let carbColor = Color(light: Color(hex: "FFCA28"), dark: Color(hex: "FFD54F"))
    static let fatColor = Color(light: Color(hex: "EC407A"), dark: Color(hex: "F06292"))

    // MARK: - Background Colors (Adaptive)
    static let backgroundPrimary = Color(UIColor.systemBackground)
    static let backgroundSecondary = Color(UIColor.secondarySystemBackground)
    static let backgroundTertiary = Color(UIColor.tertiarySystemBackground)
    static let backgroundGrouped = Color(UIColor.systemGroupedBackground)

    // Custom backgrounds
    static let backgroundMint = Color(light: Color(hex: "F1F8E9"), dark: Color(hex: "1A2E1C"))
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
    // Main screen mint background
    static let mintBackgroundGradient = LinearGradient(
        colors: [Color.mintLight, Color.mintMedium.opacity(0.5), Color.backgroundCream],
        startPoint: .top,
        endPoint: .bottom
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

    // Shadows (softer, more subtle)
    struct Shadow {
        static let sm = (color: Color.black.opacity(0.04), radius: 6.0, y: 2.0)
        static let md = (color: Color.black.opacity(0.08), radius: 12.0, y: 4.0)
        static let lg = (color: Color.black.opacity(0.12), radius: 20.0, y: 8.0)
        static let card = (color: Color.black.opacity(0.06), radius: 16.0, y: 6.0)
        static let elevated = (color: Color.black.opacity(0.10), radius: 24.0, y: 10.0)
        static let purple = (color: Color.accentPurple.opacity(0.25), radius: 16.0, y: 6.0) // Now teal
        static let glow = (color: Color.mintVibrant.opacity(0.3), radius: 20.0, y: 0.0)
    }

    // Animation
    struct Animation {
        static let quick = SwiftUI.Animation.easeOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let smooth = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
        static let bouncy = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.65)
        static let gentle = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.85)
    }

    // Typography
    struct Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .bold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 17, weight: .regular)
        static let callout = Font.system(size: 16, weight: .regular)
        static let subheadline = Font.system(size: 15, weight: .regular)
        static let footnote = Font.system(size: 13, weight: .regular)
        static let caption = Font.system(size: 12, weight: .medium)
        static let captionSmall = Font.system(size: 11, weight: .medium)
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

    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
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
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedProgress = min(progress, 1.0)
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = min(newValue, 1.0)
            }
        }
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
        case .produce: return .mintVibrant
        case .meat: return .accentPink
        case .dairy: return .accentBlue
        case .bakery: return .accentOrange
        case .frozen: return .accentTeal
        case .pantry: return .accentYellow
        case .canned: return .accentGold
        case .condiments: return .accentOrange
        case .snacks: return .accentOrange
        case .beverages: return .accentBlue
        case .spices: return .accentPink
        case .other: return .textSecondary
        }
    }
}
