import SwiftUI
import SwiftData

struct GroceryHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<GroceryList> { $0.isCompleted }, sort: \GroceryList.completedAt, order: .reverse)
    private var completedLists: [GroceryList]

    @State private var selectedList: GroceryList?

    var body: some View {
        NavigationStack {
            Group {
                if completedLists.isEmpty {
                    emptyStateView
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: Design.Spacing.md) {
                            ForEach(completedLists) { list in
                                GroceryHistoryCard(groceryList: list)
                                    .onTapGesture {
                                        selectedList = list
                                    }
                                    .accessibilityHint("Shows shopping list details")
                            }
                        }
                        .padding(.horizontal, Design.Spacing.md)
                        .padding(.vertical, Design.Spacing.sm)
                    }
                }
            }
            .background(LinearGradient.mintBackgroundGradient.ignoresSafeArea())
            .navigationTitle("Shopping History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Color.accentPurple)
                }
            }
            .sheet(item: $selectedList) { list in
                GroceryHistoryDetailSheet(groceryList: list)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: Design.Spacing.lg) {
            Image(systemName: "clock.arrow.circlepath")
                .font(Design.Typography.iconLarge)
                .foregroundStyle(Color.textSecondary.opacity(0.5))

            Text("No Shopping History")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.textPrimary)

            Text("Completed shopping lists will appear here.")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Design.Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No shopping history. Completed shopping lists will appear here.")
    }
}

// MARK: - History Card
struct GroceryHistoryCard: View {
    let groceryList: GroceryList

    private var relativeTimeString: String {
        guard let completedAt = groceryList.completedAt else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: completedAt, relativeTo: Date())
    }

    var body: some View {
        HStack(spacing: Design.Spacing.md) {
            // Checkmark icon
            ZStack {
                Circle()
                    .fill(LinearGradient.purpleButtonGradient)
                    .frame(width: 44, height: 44)

                Image(systemName: "checkmark")
                    .font(Design.Typography.bodyLarge).fontWeight(.bold)
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Design.Spacing.xxs) {
                Text(groceryList.dateRangeDescription)
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)

                HStack(spacing: Design.Spacing.sm) {
                    Label("\(groceryList.totalCount) items", systemImage: "cart.fill")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)

                    if !relativeTimeString.isEmpty {
                        Text("•")
                            .foregroundStyle(Color.textSecondary.opacity(0.5))

                        Label(relativeTimeString, systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(Design.Typography.footnote).fontWeight(.semibold)
                .foregroundStyle(Color.textSecondary.opacity(0.5))
                .accessibilityHidden(true)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(groceryList.dateRangeDescription), \(groceryList.totalCount) items, completed \(relativeTimeString)")
    }
}

#Preview {
    GroceryHistoryView()
        .modelContainer(for: [GroceryList.self, GroceryItem.self, Ingredient.self, MealPlan.self], inMemory: true)
}
