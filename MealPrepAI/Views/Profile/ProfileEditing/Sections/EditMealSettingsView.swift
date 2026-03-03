import SwiftUI
import SwiftData

struct EditMealSettingsView: View {
    @Bindable var profile: UserProfile

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Design.Spacing.lg) {
                sectionCard(title: "Meals Per Day", icon: "fork.knife", iconColor: Color.accentOrange) {
                    VStack(spacing: Design.Spacing.md) {
                        mealCountRow(
                            icon: "sunrise.fill",
                            iconColor: .orange,
                            title: "Breakfast",
                            count: $profile.breakfastCount,
                            range: 0...2
                        )

                        mealCountRow(
                            icon: "sun.max.fill",
                            iconColor: .yellow,
                            title: "Lunch",
                            count: $profile.lunchCount,
                            range: 0...2
                        )

                        mealCountRow(
                            icon: "moon.fill",
                            iconColor: .indigo,
                            title: "Dinner",
                            count: $profile.dinnerCount,
                            range: 0...2
                        )

                        mealCountRow(
                            icon: "carrot.fill",
                            iconColor: .green,
                            title: "Snacks",
                            count: $profile.snackCount,
                            range: 0...4
                        )

                        Divider()

                        HStack {
                            Text("Total")
                                .font(.headline)
                                .foregroundStyle(Color.textPrimary)
                            Spacer()
                            Text("\(profile.mealsPerDay) meals/day")
                                .font(.headline)
                                .foregroundStyle(Color.accentPurple)
                        }
                    }
                }
            }
            .padding(.horizontal, Design.Spacing.md)
            .padding(.bottom, Design.Spacing.xxl)
        }
        .background(LinearGradient.mintBackgroundGradient.ignoresSafeArea())
        .navigationTitle("Meal Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Meal Count Row

    private func mealCountRow(
        icon: String,
        iconColor: Color,
        title: String,
        count: Binding<Int>,
        range: ClosedRange<Int>
    ) -> some View {
        HStack(spacing: Design.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(Design.Typography.bodyLarge)
                    .foregroundStyle(iconColor)
            }

            Text(title)
                .font(.body)
                .foregroundStyle(Color.textPrimary)

            Spacer()

            HStack(spacing: Design.Spacing.sm) {
                Button {
                    if count.wrappedValue > range.lowerBound {
                        count.wrappedValue -= 1
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(count.wrappedValue > range.lowerBound ? Color.textPrimary.opacity(0.6) : Color.textSecondary.opacity(0.3))
                }
                .disabled(count.wrappedValue <= range.lowerBound)

                Text("\(count.wrappedValue)")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                    .frame(width: 28, alignment: .center)
                    .monospacedDigit()

                Button {
                    if count.wrappedValue < range.upperBound {
                        count.wrappedValue += 1
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(count.wrappedValue < range.upperBound ? Color.accentPurple : Color.textSecondary.opacity(0.3))
                }
                .disabled(count.wrappedValue >= range.upperBound)
            }
        }
    }

    // MARK: - Section Card Builder

    private func sectionCard<Content: View>(
        title: String,
        icon: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            HStack(spacing: Design.Spacing.sm) {
                Image(systemName: icon)
                    .font(Design.Typography.footnote)
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
            }

            content()
        }
        .padding(Design.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Design.Radius.card)
                .fill(Color.cardBackground)
                .shadow(
                    color: Design.Shadow.card.color,
                    radius: Design.Shadow.card.radius,
                    y: Design.Shadow.card.y
                )
        )
    }
}

#Preview {
    NavigationStack {
        EditMealSettingsView(profile: UserProfile(name: "Test"))
    }
    .modelContainer(for: UserProfile.self, inMemory: true)
}
