import SwiftUI
import SuperwallKit

struct PaywallStepView: View {
    let onSubscribe: (SubscriptionPlan) -> Void
    let onRestorePurchases: () -> Void

    @Environment(SubscriptionManager.self) var subscriptionManager
    @State private var appeared = false
    @State private var selectedPlan: SubscriptionPlan = .annual
    @State private var timelineAnimated = false

    // Fallback pricing (shown while products load)
    private var annualPrice: String {
        subscriptionManager.annualProduct?.displayPrice ?? "$59.99"
    }
    private var monthlyPrice: String {
        subscriptionManager.monthlyProduct?.displayPrice ?? "$9.99"
    }
    private var annualMonthlyPrice: String {
        if let product = subscriptionManager.annualProduct {
            let monthly = product.price / 12
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
            formatter.locale = Locale(identifier: "en_US")
            formatter.roundingMode = .down  
            formatter.maximumFractionDigits = 2
            return formatter.string(from: monthly as NSDecimalNumber) ?? "$4.99"
        }
        return "$4.99"
    }

    private var selectedPriceText: String {
        switch selectedPlan {
        case .annual: return annualPrice
        case .monthly: return monthlyPrice
        }
    }

    private var selectedPeriodText: String {
        switch selectedPlan {
        case .annual: return "/year"
        case .monthly: return "/month"
        }
    }

    private var billingDateText: String {
        let date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title section
            VStack(spacing: OnboardingDesign.Spacing.xxs) {
                Text("Start your 7-day FREE")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(OnboardingDesign.Colors.textPrimary)

                Text("trial to continue.")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(OnboardingDesign.Colors.textPrimary)
            }
            .padding(.top, OnboardingDesign.Spacing.xl)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.lg)

            // Timeline section
            TimelineView(
                billingDate: billingDateText,
                isAnimated: timelineAnimated
            )
            .padding(.horizontal, OnboardingDesign.Spacing.lg)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer()

            // Plan selector - Cal AI style
            VStack(spacing: OnboardingDesign.Spacing.sm) {
                // Two plans side by side: Monthly and Annual
                HStack(spacing: OnboardingDesign.Spacing.sm) {
                    CalAIPlanPill(
                        title: "Monthly",
                        price: monthlyPrice,
                        period: "/mo",
                        isSelected: selectedPlan == .monthly
                    ) {
                        selectedPlan = .monthly
                    }

                    CalAIPlanPill(
                        title: "Yearly",
                        price: annualMonthlyPrice,
                        period: "/mo",
                        badge: "Save 50%",
                        isSelected: selectedPlan == .annual
                    ) {
                        selectedPlan = .annual
                    }
                }
            }
            .padding(.horizontal, OnboardingDesign.Spacing.xl)
            .opacity(appeared ? 1 : 0)

            Spacer()
                .frame(height: OnboardingDesign.Spacing.lg)

            // Bottom CTA section
            VStack(spacing: OnboardingDesign.Spacing.sm) {
                // Checkmark with text
                HStack(spacing: OnboardingDesign.Spacing.xs) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                    Text("No Payment Due Now")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(OnboardingDesign.Colors.textPrimary)
                }

                // CTA Button
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onSubscribe(selectedPlan)
                } label: {
                    Group {
                        if subscriptionManager.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Start My 7-Day Free Trial")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color.black)
                    )
                }
                .disabled(subscriptionManager.isLoading)
                .buttonStyle(OnboardingScaleButtonStyle())

                // Price info
                Text("7 days free, then \(selectedPriceText) per year")
                    .font(OnboardingDesign.Typography.footnote)
                    .foregroundStyle(OnboardingDesign.Colors.textMuted)

                // Legal links
                HStack(spacing: OnboardingDesign.Spacing.md) {
                    Button("Restore") {
                        onRestorePurchases()
                    }
                    .font(OnboardingDesign.Typography.caption)
                    .foregroundStyle(OnboardingDesign.Colors.textTertiary)

                    Text("·")
                        .foregroundStyle(OnboardingDesign.Colors.textMuted)

                    Link("Terms", destination: URL(string: "https://example.com/terms")!)
                        .font(OnboardingDesign.Typography.caption)
                        .foregroundStyle(OnboardingDesign.Colors.textTertiary)

                    Text("·")
                        .foregroundStyle(OnboardingDesign.Colors.textMuted)

                    Link("Privacy", destination: URL(string: "https://example.com/privacy")!)
                        .font(OnboardingDesign.Typography.caption)
                        .foregroundStyle(OnboardingDesign.Colors.textTertiary)
                }
            }
            .padding(.horizontal, OnboardingDesign.Spacing.xl)
            .padding(.bottom, OnboardingDesign.Spacing.xl)
            .opacity(appeared ? 1 : 0)
        }
        .background(Color.white.ignoresSafeArea())
        .onAppear {
            SuperwallTracker.trackPaywallShown()
            withAnimation(OnboardingDesign.Animation.bouncy.delay(0.2)) {
                appeared = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
                timelineAnimated = true
            }
        }
    }
}

// MARK: - Timeline View with lines behind icons
private struct TimelineView: View {
    let billingDate: String
    let isAnimated: Bool

    private let iconSize: CGFloat = 36
    private let lineWidth: CGFloat = 10
    private let rowHeight: CGFloat = 80 // More spacing between rows

    var body: some View {
        HStack(alignment: .top, spacing: OnboardingDesign.Spacing.md) {
            // Left column: Icons with connector lines behind them
            VStack(spacing: 0) {
                // Icon 1 with line extending down behind it
                ZStack(alignment: .top) {
                    // Line starts from center of icon and goes down
                    VStack(spacing: 0) {
                        Color.clear.frame(height: iconSize / 2)
                        Rectangle()
                            .fill(Color.green.opacity(0.7))
                            .frame(width: lineWidth)
                    }
                    .frame(height: rowHeight)

                    // Icon on top
                    TimelineIcon(icon: "lock.open.fill", color: Color.green, isAnimated: isAnimated, delay: 0.1)
                }
                .frame(height: rowHeight)

                // Icon 2 with lines above and below
                ZStack(alignment: .center) {
                    // Continuous line
                    Rectangle()
                        .fill(Color.green.opacity(0.7))
                        .frame(width: lineWidth, height: rowHeight)

                    // Icon on top
                    TimelineIcon(icon: "bell.fill", color: Color.green, isAnimated: isAnimated, delay: 0.25)
                }
                .frame(height: rowHeight)

                // Icon 3 with line above and below (gray)
                ZStack(alignment: .center) {
                    // Line from green to gray transition
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.green.opacity(0.7))
                            .frame(width: lineWidth, height: rowHeight / 2)
                        Rectangle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: lineWidth, height: rowHeight / 2)
                    }

                    // Icon on top
                    TimelineIcon(icon: "crown.fill", color: Color.gray, isAnimated: isAnimated, delay: 0.4)
                }
                .frame(height: rowHeight)

                // Final line segment with rounded bottom end
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: lineWidth / 2,
                    bottomTrailingRadius: lineWidth / 2,
                    topTrailingRadius: 0
                )
                .fill(Color.gray.opacity(0.5))
                .frame(width: lineWidth, height: 30)
            }
            .frame(width: iconSize)

            // Right column: Text content
            VStack(alignment: .leading, spacing: 0) {
                // Row 1
                TimelineText(
                    title: "Today",
                    subtitle: "Unlock all the app's features like AI meal planning and more.",
                    isAnimated: isAnimated,
                    delay: 0.1
                )
                .frame(height: rowHeight, alignment: .top)
                .padding(.top, 6)

                // Row 2
                TimelineText(
                    title: "In 6 Days - Reminder",
                    subtitle: "We'll send you a reminder that your trial is ending soon.",
                    isAnimated: isAnimated,
                    delay: 0.25
                )
                .frame(height: rowHeight, alignment: .top)
                .padding(.top, 24)

                // Row 3
                TimelineText(
                    title: "In 7 Days - Billing Starts",
                    subtitle: "You'll be charged on \(billingDate) unless you cancel anytime before.",
                    isAnimated: isAnimated,
                    delay: 0.4
                )
                .frame(height: rowHeight, alignment: .top)
                .padding(.top, 12)

                // Spacer for the final line
                Spacer()
                    .frame(height: 30)
            }
        }
        .padding(OnboardingDesign.Spacing.md)
    }
}

// MARK: - Timeline Icon
private struct TimelineIcon: View {
    let icon: String
    let color: Color
    let isAnimated: Bool
    let delay: Double

    private let iconSize: CGFloat = 36

    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: iconSize, height: iconSize)

            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.white)
        }
        .scaleEffect(isAnimated ? 1 : 0)
        .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(delay), value: isAnimated)
    }
}

// MARK: - Timeline Text
private struct TimelineText: View {
    let title: String
    let subtitle: String
    let isAnimated: Bool
    let delay: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(OnboardingDesign.Colors.textPrimary)

            Text(subtitle)
                .font(.system(size: 15))
                .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .opacity(isAnimated ? 1 : 0)
        .offset(x: isAnimated ? 0 : 20)
        .animation(.easeOut(duration: 0.3).delay(delay), value: isAnimated)
    }
}

// MARK: - Cal AI Style Plan Pill
private struct CalAIPlanPill: View {
    let title: String
    let price: String
    let period: String
    var badge: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            ZStack(alignment: .topTrailing) {
                HStack {
                    // Left: Text content
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(isSelected ? .white : OnboardingDesign.Colors.textSecondary)

                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(price)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(isSelected ? .white : OnboardingDesign.Colors.textPrimary)
                            Text(period)
                                .font(.system(size: 14))
                                .foregroundStyle(isSelected ? .white.opacity(0.8) : OnboardingDesign.Colors.textSecondary)
                        }
                    }

                    Spacer()

                    // Right: Checkmark circle
                    ZStack {
                        Circle()
                            .strokeBorder(isSelected ? Color.white : OnboardingDesign.Colors.cardBorder, lineWidth: 2)
                            .frame(width: 28, height: 28)

                        if isSelected {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 28, height: 28)

                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color.black)
                        }
                    }
                }
                .padding(.horizontal, OnboardingDesign.Spacing.md)
                .padding(.vertical, OnboardingDesign.Spacing.md)
                .frame(minHeight: 70)
                .background(
                    RoundedRectangle(cornerRadius: OnboardingDesign.Radius.lg)
                        .fill(isSelected ? Color.black : Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: OnboardingDesign.Radius.lg)
                        .strokeBorder(isSelected ? Color.clear : OnboardingDesign.Colors.cardBorder, lineWidth: 1)
                )

                // Badge (if present)
                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.green)
                        )
                        .offset(x: -12, y: -10)
                }
            }
        }
        .buttonStyle(OnboardingScaleButtonStyle())
    }
}

// MARK: - Subscription Plan
enum SubscriptionPlan: String, CaseIterable {
    case monthly = "Monthly"
    case annual = "Annual"
}

#Preview {
    PaywallStepView(
        onSubscribe: { _ in },
        onRestorePurchases: {}
    )
    .environment(SubscriptionManager())
}
