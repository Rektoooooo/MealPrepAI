import SwiftUI
import SwiftData

struct GroceryHistoryDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("measurementSystem") private var measurementSystem: MeasurementSystem = .metric
    let groceryList: GroceryList

    private var sortedItems: [GroceryItem] {
        groceryList.sortedItems
    }

    private var groupedItems: [(GroceryCategory, [GroceryItem])] {
        let grouped = Dictionary(grouping: sortedItems) { $0.ingredient?.category ?? .other }
        return grouped.sorted { $0.key.sortOrder < $1.key.sortOrder }
    }

    private var completedDateString: String {
        guard let completedAt = groceryList.completedAt else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: completedAt)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: Design.Spacing.lg) {
                    // Header info
                    headerSection

                    // Items by category
                    LazyVStack(spacing: Design.Spacing.lg, pinnedViews: .sectionHeaders) {
                        ForEach(groupedItems, id: \.0) { category, items in
                            Section {
                                VStack(spacing: Design.Spacing.xs) {
                                    ForEach(items) { item in
                                        HistoryItemRow(item: item, measurementSystem: measurementSystem)
                                    }
                                }
                            } header: {
                                categoryHeader(category: category, count: items.count)
                            }
                        }
                    }
                }
                .padding(.horizontal, Design.Spacing.md)
                .padding(.bottom, Design.Spacing.xxl)
            }
            .background(LinearGradient.mintBackgroundGradient.ignoresSafeArea())
            .navigationTitle(groceryList.dateRangeDescription)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Color.accentPurple)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var headerSection: some View {
        VStack(spacing: Design.Spacing.sm) {
            HStack(spacing: Design.Spacing.md) {
                VStack(alignment: .leading, spacing: Design.Spacing.xxs) {
                    Text("Completed")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)

                    Text(completedDateString)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.textPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: Design.Spacing.xxs) {
                    Text("Total Items")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)

                    Text("\(groceryList.totalCount)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.accentPurple)
                }
            }
            .padding(Design.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.md)
                    .fill(Color.cardBackground)
                    .shadow(
                        color: Design.Shadow.sm.color,
                        radius: Design.Shadow.sm.radius,
                        y: Design.Shadow.sm.y
                    )
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Completed \(completedDateString), \(groceryList.totalCount) total items")
        }
        .padding(.top, Design.Spacing.sm)
    }

    private func categoryHeader(category: GroceryCategory, count: Int) -> some View {
        HStack(spacing: Design.Spacing.xs) {
            Image(systemName: category.icon)
                .font(Design.Typography.footnote).fontWeight(.semibold)
                .foregroundStyle(Color.accentPurple)

            Text(category.rawValue)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.textPrimary)

            Text("(\(count))")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)

            Spacer()
        }
        .padding(.vertical, Design.Spacing.xs)
        .padding(.horizontal, Design.Spacing.xxs)
        .background(Color.backgroundMint.opacity(0.95))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category.rawValue), \(count) items")
    }
}

// MARK: - History Item Row (Read-Only)
struct HistoryItemRow: View {
    let item: GroceryItem
    let measurementSystem: MeasurementSystem

    private var convertedQuantity: String {
        let (convertedQty, convertedUnit) = item.unit.convert(item.quantity, to: measurementSystem)
        return MeasurementUnit.formatQuantity(convertedQty, unit: convertedUnit)
    }

    var body: some View {
        HStack(spacing: Design.Spacing.md) {
            // Checkmark (always checked in history)
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient.purpleButtonGradient)
                    .frame(width: 26, height: 26)

                Image(systemName: "checkmark")
                    .font(Design.Typography.caption).fontWeight(.bold)
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)

            // Item Details
            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.textSecondary)
                    .strikethrough(true)

                Text(convertedQuantity)
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            // Category Icon
            if let category = item.ingredient?.category {
                Image(systemName: category.icon)
                    .font(Design.Typography.footnote)
                    .foregroundStyle(Color.textSecondary.opacity(0.5))
                    .accessibilityHidden(true)
            }
        }
        .padding(Design.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Design.Radius.md)
                .fill(Color.cardBackground)
                .opacity(0.6)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.displayName), \(convertedQuantity), purchased")
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: GroceryList.self, GroceryItem.self, Ingredient.self, MealPlan.self, configurations: config)

    let groceryList = GroceryList()
    groceryList.isCompleted = true
    groceryList.completedAt = Date()

    return GroceryHistoryDetailSheet(groceryList: groceryList)
        .modelContainer(container)
}
