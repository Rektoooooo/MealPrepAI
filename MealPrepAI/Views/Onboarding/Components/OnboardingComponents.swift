import SwiftUI
import UIKit

// MARK: - Onboarding Progress Bar (Cal AI Style - thin black line)
struct OnboardingProgressBar: View {
    let currentStep: Int
    let totalSteps: Int

    private var progress: CGFloat {
        guard totalSteps > 0 else { return 0 }
        return CGFloat(currentStep) / CGFloat(totalSteps)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 2)
                    .fill(OnboardingDesign.Colors.progressBackground)
                    .frame(height: 3)

                // Progress fill
                RoundedRectangle(cornerRadius: 2)
                    .fill(OnboardingDesign.Colors.progressFill)
                    .frame(width: geometry.size.width * progress, height: 3)
                    .animation(OnboardingDesign.Animation.smooth, value: progress)
            }
        }
        .frame(height: 3)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Onboarding progress")
        .accessibilityValue("Step \(currentStep) of \(totalSteps)")
    }
}

// MARK: - Back Button (Cal AI Style - circular gray background)
struct OnboardingBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: {
            hapticFeedback(.light)
            action()
        }) {
            Image(systemName: "arrow.left")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(OnboardingDesign.Colors.cardBackground)
                )
        }
        .buttonStyle(OnboardingScaleButtonStyle())
        .accessibilityLabel("Go back")
    }

    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Primary CTA Button (Cal AI Style - black pill)
struct OnboardingCTAButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void

    init(_ title: String, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: {
            if isEnabled {
                hapticFeedback(.medium)
                action()
            }
        }) {
            Text(title)
                .font(OnboardingDesign.Typography.headline)
                .foregroundStyle(isEnabled ? OnboardingDesign.Colors.textOnDark : OnboardingDesign.Colors.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, OnboardingDesign.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: OnboardingDesign.Radius.xl)
                        .fill(isEnabled ? OnboardingDesign.Colors.accent : OnboardingDesign.Colors.cardBackground)
                )
        }
        .buttonStyle(OnboardingScaleButtonStyle())
        .accessibilityLabel(title)
        .accessibilityHint("Double tap to continue")
        .disabled(!isEnabled)
    }

    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Scale Button Style
struct OnboardingScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Selection Card (Cal AI Style - black when selected)
struct OnboardingSelectionCard: View {
    let title: String
    let description: String?
    let icon: String?
    let emoji: String?
    let isSelected: Bool
    let action: () -> Void

    init(
        title: String,
        description: String? = nil,
        icon: String? = nil,
        emoji: String? = nil,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.description = description
        self.icon = icon
        self.emoji = emoji
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: {
            hapticFeedback(.light)
            action()
        }) {
            HStack(spacing: OnboardingDesign.Spacing.md) {
                // Icon/Emoji in circle
                if let emoji = emoji {
                    Text(emoji)
                        .font(.system(size: 24))
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(isSelected ? OnboardingDesign.Colors.textOnDark.opacity(0.2) : OnboardingDesign.Colors.iconBackground)
                        )
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(isSelected ? OnboardingDesign.Colors.textOnDark : OnboardingDesign.Colors.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(isSelected ? OnboardingDesign.Colors.textOnDark.opacity(0.2) : OnboardingDesign.Colors.iconBackground)
                        )
                }

                VStack(alignment: .leading, spacing: OnboardingDesign.Spacing.xxs) {
                    Text(title)
                        .font(OnboardingDesign.Typography.bodyMedium)
                        .foregroundStyle(isSelected ? OnboardingDesign.Colors.textOnDark : OnboardingDesign.Colors.textPrimary)

                    if let description = description {
                        Text(description)
                            .font(OnboardingDesign.Typography.footnote)
                            .foregroundStyle(isSelected ? OnboardingDesign.Colors.textOnDark.opacity(0.7) : OnboardingDesign.Colors.textSecondary)
                    }
                }

                Spacer()
            }
            .padding(OnboardingDesign.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: OnboardingDesign.Radius.lg)
                    .fill(isSelected ? OnboardingDesign.Colors.selectedBackground : OnboardingDesign.Colors.unselectedBackground)
            )
        }
        .buttonStyle(OnboardingScaleButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title + (description.map { ", " + $0 } ?? ""))
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Double tap to \(isSelected ? "deselect" : "select")")
    }

    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Multi-Select Chip
struct OnboardingChip: View {
    let title: String
    let emoji: String?
    let isSelected: Bool
    let action: () -> Void

    init(_ title: String, emoji: String? = nil, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.emoji = emoji
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: {
            hapticFeedback(.light)
            action()
        }) {
            HStack(spacing: OnboardingDesign.Spacing.xs) {
                if let emoji = emoji {
                    Text(emoji)
                        .font(.system(size: 16))
                }
                Text(title)
                    .font(OnboardingDesign.Typography.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundStyle(isSelected ? OnboardingDesign.Colors.textOnDark : OnboardingDesign.Colors.textPrimary)
            .padding(.horizontal, OnboardingDesign.Spacing.md)
            .padding(.vertical, OnboardingDesign.Spacing.sm)
            .background(
                Capsule()
                    .fill(isSelected ? OnboardingDesign.Colors.selectedBackground : OnboardingDesign.Colors.unselectedBackground)
            )
        }
        .buttonStyle(OnboardingScaleButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(.isButton)
    }

    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Privacy Note
struct PrivacyNote: View {
    let text: String

    init(_ text: String = "Stored privately on your device") {
        self.text = text
    }

    var body: some View {
        HStack(spacing: OnboardingDesign.Spacing.xs) {
            Image(systemName: "lock.fill")
                .font(.system(size: 12))
            Text(text)
                .font(OnboardingDesign.Typography.caption)
        }
        .foregroundStyle(OnboardingDesign.Colors.textMuted)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Social Proof Card
struct SocialProofCard: View {
    let quote: String
    let author: String
    let stars: Int

    var body: some View {
        VStack(alignment: .leading, spacing: OnboardingDesign.Spacing.md) {
            // Stars
            HStack(spacing: 4) {
                ForEach(0..<stars, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.yellow)
                }
            }

            // Quote marks and text
            HStack(alignment: .top, spacing: OnboardingDesign.Spacing.xs) {
                Text("\"")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(OnboardingDesign.Colors.textTertiary)
                    .offset(y: -10)

                Text(quote)
                    .font(OnboardingDesign.Typography.body)
                    .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                    .italic()
            }

            // Author
            Text("- \(author)")
                .font(OnboardingDesign.Typography.footnote)
                .foregroundStyle(OnboardingDesign.Colors.textSecondary)
        }
        .padding(OnboardingDesign.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: OnboardingDesign.Radius.lg)
                .fill(OnboardingDesign.Colors.unselectedBackground)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(stars) star review by \(author): \(quote)")
    }
}

// MARK: - Thumbs Up/Down Row (for Cuisine Preferences)
struct ThumbsUpDownRow: View {
    let title: String
    let flag: String
    @Binding var preference: CuisinePreference

    var body: some View {
        HStack(spacing: OnboardingDesign.Spacing.md) {
            // Flag and title
            HStack(spacing: OnboardingDesign.Spacing.sm) {
                Text(flag)
                    .font(.system(size: 24))

                Text(title)
                    .font(OnboardingDesign.Typography.bodyMedium)
                    .foregroundStyle(OnboardingDesign.Colors.textPrimary)
            }

            Spacer()

            // Thumbs buttons
            HStack(spacing: OnboardingDesign.Spacing.sm) {
                // Thumbs down
                Button {
                    hapticFeedback(.light)
                    preference = preference == .dislike ? .neutral : .dislike
                } label: {
                    Image(systemName: preference == .dislike ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                        .font(.system(size: 20))
                        .foregroundStyle(preference == .dislike ? Color.red : OnboardingDesign.Colors.textTertiary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(preference == .dislike ? Color.red.opacity(0.15) : OnboardingDesign.Colors.unselectedBackground)
                        )
                }
                .buttonStyle(OnboardingScaleButtonStyle())
                .accessibilityLabel("Dislike \(title)")

                // Thumbs up
                Button {
                    hapticFeedback(.light)
                    preference = preference == .like ? .neutral : .like
                } label: {
                    Image(systemName: preference == .like ? "hand.thumbsup.fill" : "hand.thumbsup")
                        .font(.system(size: 20))
                        .foregroundStyle(preference == .like ? OnboardingDesign.Colors.success : OnboardingDesign.Colors.textTertiary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(preference == .like ? OnboardingDesign.Colors.success.opacity(0.15) : OnboardingDesign.Colors.unselectedBackground)
                        )
                }
                .buttonStyle(OnboardingScaleButtonStyle())
                .accessibilityLabel("Like \(title)")
            }
        }
        .padding(OnboardingDesign.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: OnboardingDesign.Radius.md)
                .fill(OnboardingDesign.Colors.unselectedBackground)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title) cuisine preference")
        .accessibilityValue(preference == .like ? "Liked" : preference == .dislike ? "Disliked" : "No preference")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                preference = preference == .dislike ? .neutral : .like
            case .decrement:
                preference = preference == .like ? .neutral : .dislike
            @unknown default:
                break
            }
        }
    }

    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Scroll Wheel Picker
struct OnboardingWheelPicker<T: Hashable>: View {
    let items: [T]
    @Binding var selection: T
    let itemLabel: (T) -> String

    var body: some View {
        Picker("", selection: $selection) {
            ForEach(items, id: \.self) { item in
                Text(itemLabel(item))
                    .font(OnboardingDesign.Typography.title)
                    .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                    .tag(item)
            }
        }
        .pickerStyle(.wheel)
        .frame(height: 150)
        .accessibilityLabel("Select value")
    }
}

// MARK: - Animated Progress Ring
struct AnimatedProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 8
    var size: CGFloat = 120

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(OnboardingDesign.Colors.progressBackground, lineWidth: lineWidth)
                .frame(width: size, height: size)

            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    OnboardingDesign.Colors.progressFill,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))

            // Percentage text
            Text("\(Int(animatedProgress * 100))%")
                .font(OnboardingDesign.Typography.title2)
                .fontWeight(.bold)
                .foregroundStyle(OnboardingDesign.Colors.textPrimary)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 2.0)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = newValue
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(animatedProgress * 100)) percent")
    }
}

// MARK: - Avatar Grid
struct AvatarGrid: View {
    @Binding var selectedEmoji: String
    let columns = [GridItem(.adaptive(minimum: 60), spacing: OnboardingDesign.Spacing.md)]

    let avatars = [
        "🍳", "🥗", "🍕", "🌮",
        "🍜", "🍣", "🥑", "🍱",
        "🧑‍🍳", "👨‍🍳", "👩‍🍳", "🦊",
        "🐻", "🐼", "🦁", "🐸"
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: OnboardingDesign.Spacing.md) {
            ForEach(avatars, id: \.self) { emoji in
                Button {
                    hapticFeedback(.light)
                    selectedEmoji = emoji
                } label: {
                    Text(emoji)
                        .font(.system(size: 36))
                        .frame(width: 60, height: 60)
                        .background(
                            Circle()
                                .fill(selectedEmoji == emoji ? OnboardingDesign.Colors.selectedBackground : OnboardingDesign.Colors.unselectedBackground)
                        )
                        .scaleEffect(selectedEmoji == emoji ? 1.1 : 1.0)
                        .animation(OnboardingDesign.Animation.bouncy, value: selectedEmoji)
                }
                .buttonStyle(OnboardingScaleButtonStyle())
                .accessibilityLabel(emoji)
                .accessibilityValue(selectedEmoji == emoji ? "Selected" : "")
                .accessibilityHint("Double tap to select this avatar")
            }
        }
    }

    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Pricing Card
struct PricingCard: View {
    let title: String
    let price: String
    let period: String
    let badge: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            hapticFeedback(.medium)
            action()
        }) {
            VStack(alignment: .leading, spacing: OnboardingDesign.Spacing.sm) {
                // Badge
                if let badge = badge {
                    Text(badge)
                        .font(OnboardingDesign.Typography.captionSmall)
                        .fontWeight(.bold)
                        .foregroundStyle(OnboardingDesign.Colors.textOnDark)
                        .padding(.horizontal, OnboardingDesign.Spacing.sm)
                        .padding(.vertical, OnboardingDesign.Spacing.xxs)
                        .background(
                            Capsule()
                                .fill(OnboardingDesign.Colors.success)
                        )
                }

                HStack {
                    VStack(alignment: .leading, spacing: OnboardingDesign.Spacing.xxs) {
                        Text(title)
                            .font(OnboardingDesign.Typography.headline)
                            .foregroundStyle(isSelected ? OnboardingDesign.Colors.textOnDark : OnboardingDesign.Colors.textPrimary)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(price)
                                .font(OnboardingDesign.Typography.title)
                                .foregroundStyle(isSelected ? OnboardingDesign.Colors.textOnDark : OnboardingDesign.Colors.textPrimary)
                            Text(period)
                                .font(OnboardingDesign.Typography.footnote)
                                .foregroundStyle(isSelected ? OnboardingDesign.Colors.textOnDark.opacity(0.7) : OnboardingDesign.Colors.textSecondary)
                        }
                    }

                    Spacer()

                    // Selection indicator
                    Circle()
                        .fill(isSelected ? OnboardingDesign.Colors.textOnDark : OnboardingDesign.Colors.unselectedBackground)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .fill(OnboardingDesign.Colors.accent)
                                .frame(width: 10, height: 10)
                                .opacity(isSelected ? 1 : 0)
                        )
                }
            }
            .padding(OnboardingDesign.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: OnboardingDesign.Radius.lg)
                    .fill(isSelected ? OnboardingDesign.Colors.selectedBackground : OnboardingDesign.Colors.unselectedBackground)
            )
        }
        .buttonStyle(OnboardingScaleButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(price) \(period)" + (badge.map { ", \($0)" } ?? ""))
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(.isButton)
    }

    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Food Dislike Chip (Visual grid with icons)
struct FoodDislikeChip: View {
    let food: FoodDislike
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            hapticFeedback(.light)
            action()
        }) {
            VStack(spacing: OnboardingDesign.Spacing.xs) {
                Text(food.emoji)
                    .font(.system(size: 32))

                Text(food.rawValue)
                    .font(OnboardingDesign.Typography.captionSmall)
                    .foregroundStyle(isSelected ? OnboardingDesign.Colors.textOnDark : OnboardingDesign.Colors.textSecondary)
                    .lineLimit(1)
            }
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: OnboardingDesign.Radius.md)
                    .fill(isSelected ? OnboardingDesign.Colors.selectedBackground : OnboardingDesign.Colors.unselectedBackground)
            )
        }
        .buttonStyle(OnboardingScaleButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(food.rawValue)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(.isButton)
    }

    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Unit Segmented Control
struct OnboardingSegmentedControl: View {
    let options: [String]
    @Binding var selection: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                Button {
                    hapticFeedback(.light)
                    withAnimation(OnboardingDesign.Animation.quick) {
                        selection = index
                    }
                } label: {
                    Text(option)
                        .font(OnboardingDesign.Typography.subheadline)
                        .fontWeight(selection == index ? .semibold : .regular)
                        .foregroundStyle(selection == index ? OnboardingDesign.Colors.textOnDark : OnboardingDesign.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, OnboardingDesign.Spacing.sm)
                        .background(
                            Capsule()
                                .fill(selection == index ? OnboardingDesign.Colors.selectedBackground : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option)
                .accessibilityValue(selection == index ? "Selected" : "Not selected")
                .accessibilityAddTraits(selection == index ? .isSelected : [])
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(OnboardingDesign.Colors.unselectedBackground)
        )
        .accessibilityElement(children: .contain)
    }

    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Step Header
struct OnboardingStepHeader: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: OnboardingDesign.Spacing.xs) {
            Text(title)
                .font(OnboardingDesign.Typography.title)
                .foregroundStyle(OnboardingDesign.Colors.textPrimary)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(OnboardingDesign.Typography.subheadline)
                    .foregroundStyle(OnboardingDesign.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
