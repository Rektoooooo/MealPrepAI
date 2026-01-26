import SwiftUI

struct CuisinePreferencesStepView: View {
    @Binding var cuisinePreferences: [String: CuisinePreference]
    let onContinue: () -> Void

    @State private var appeared = false

    // Group cuisines into rows for better layout (using actual CuisineType cases)
    private let cuisineRows: [[CuisineType]] = [
        [.american, .italian, .mexican],
        [.french, .chinese, .japanese],
        [.indian, .thai, .mediterranean],
        [.greek, .korean, .vietnamese],
        [.middleEastern, .spanish]
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            OnboardingStepHeader(
                "Cuisine preferences",
                subtitle: "Tap to like, double tap to dislike"
            )
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .padding(.top, OnboardingDesign.Spacing.xl)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.lg)

            // Legend
            HStack(spacing: OnboardingDesign.Spacing.lg) {
                CuisineLegendItem(color: OnboardingDesign.Colors.success, label: "Like")
                CuisineLegendItem(color: OnboardingDesign.Colors.textMuted, label: "Neutral")
                CuisineLegendItem(color: OnboardingDesign.Colors.highlight, label: "Dislike")
            }
            .opacity(appeared ? 1 : 0)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.xl)

            // Cuisine chips grid
            VStack(spacing: OnboardingDesign.Spacing.sm) {
                ForEach(cuisineRows.indices, id: \.self) { rowIndex in
                    HStack(spacing: OnboardingDesign.Spacing.sm) {
                        ForEach(cuisineRows[rowIndex]) { cuisine in
                            CuisinePreferenceChip(
                                cuisine: cuisine,
                                preference: binding(for: cuisine)
                            )
                        }
                        // Fill remaining space for last row with single item
                        if cuisineRows[rowIndex].count < 3 {
                            ForEach(0..<(3 - cuisineRows[rowIndex].count), id: \.self) { _ in
                                Color.clear
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 80)
                            }
                        }
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(
                        OnboardingDesign.Animation.bouncy.delay(0.2 + Double(rowIndex) * 0.05),
                        value: appeared
                    )
                }
            }

            Spacer()

            // Skip hint
            Text("You can skip this step if you have no preferences")
                .font(OnboardingDesign.Typography.caption)
                .foregroundStyle(OnboardingDesign.Colors.textMuted)
                .multilineTextAlignment(.center)
                .opacity(appeared ? 1 : 0)
                .padding(.bottom, OnboardingDesign.Spacing.md)

            // CTA
            OnboardingCTAButton("Continue") {
                onContinue()
            }
            .opacity(appeared ? 1 : 0)
        }
        .padding(.horizontal, OnboardingDesign.Spacing.xl)
        .padding(.bottom, OnboardingDesign.Spacing.xl)
        .onboardingBackground()
        .onAppear {
            withAnimation(OnboardingDesign.Animation.bouncy.delay(0.2)) {
                appeared = true
            }
        }
    }

    private func binding(for cuisine: CuisineType) -> Binding<CuisinePreference> {
        Binding(
            get: { cuisinePreferences[cuisine.rawValue] ?? .neutral },
            set: { cuisinePreferences[cuisine.rawValue] = $0 }
        )
    }
}

// MARK: - Cuisine Preference Chip
private struct CuisinePreferenceChip: View {
    let cuisine: CuisineType
    @Binding var preference: CuisinePreference

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            // Cycle through: neutral -> like -> dislike -> neutral
            switch preference {
            case .neutral:
                preference = .like
            case .like:
                preference = .dislike
            case .dislike:
                preference = .neutral
            }
        } label: {
            VStack(spacing: OnboardingDesign.Spacing.xxs) {
                Text(cuisine.flag)
                    .font(.system(size: 28))

                Text(cuisine.rawValue)
                    .font(OnboardingDesign.Typography.caption)
                    .foregroundStyle(preference == .neutral ? OnboardingDesign.Colors.textSecondary : .white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(
                RoundedRectangle(cornerRadius: OnboardingDesign.Radius.md)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: OnboardingDesign.Radius.md)
                    .strokeBorder(borderColor, lineWidth: preference == .neutral ? 1 : 0)
            )
        }
        .buttonStyle(OnboardingScaleButtonStyle())
    }

    private var backgroundColor: Color {
        switch preference {
        case .like:
            return OnboardingDesign.Colors.success
        case .dislike:
            return OnboardingDesign.Colors.highlight
        case .neutral:
            return OnboardingDesign.Colors.cardBackground
        }
    }

    private var borderColor: Color {
        switch preference {
        case .like, .dislike:
            return .clear
        case .neutral:
            return OnboardingDesign.Colors.cardBorder
        }
    }
}

// MARK: - Cuisine Legend Item
private struct CuisineLegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: OnboardingDesign.Spacing.xxs) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(OnboardingDesign.Typography.caption)
                .foregroundStyle(OnboardingDesign.Colors.textSecondary)
        }
    }
}

#Preview {
    CuisinePreferencesStepView(
        cuisinePreferences: .constant([:]),
        onContinue: {}
    )
}
