import SwiftUI

struct StreakBadge: View {
    let streak: Int

    var body: some View {
        HStack(spacing: Design.Spacing.xxs) {
            Image(systemName: "flame.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.accentOrange)

            Text("\(streak)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.textPrimary)
        }
        .fixedSize()
        .padding(.horizontal, Design.Spacing.sm)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.cardBackground)
                .shadow(
                    color: Design.Shadow.sm.color,
                    radius: Design.Shadow.sm.radius,
                    y: Design.Shadow.sm.y
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(streak) day streak")
    }
}
