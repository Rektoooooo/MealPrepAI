import SwiftUI

// MARK: - Date Range Picker Sheet
/// A sheet for selecting the start date of a meal plan with quick options and calendar
struct DateRangePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date

    // Local state for editing before confirmation
    @State private var tempDate: Date

    init(selectedDate: Binding<Date>) {
        self._selectedDate = selectedDate
        self._tempDate = State(initialValue: selectedDate.wrappedValue)
    }

    // MARK: - Computed Properties

    private var endDate: Date {
        Calendar.current.date(byAdding: .day, value: 6, to: tempDate) ?? tempDate
    }

    private var dateRangePreview: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        let startString = formatter.string(from: tempDate)
        let endString = formatter.string(from: endDate)
        return "\(startString) → \(endString)"
    }

    private var today: Date {
        Calendar.current.startOfDay(for: Date())
    }

    private var tomorrow: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
    }

    private var nextMonday: Date {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: today)
        // Sunday = 1, Monday = 2, etc.
        let daysUntilMonday = weekday == 1 ? 1 : (9 - weekday)
        return calendar.date(byAdding: .day, value: daysUntilMonday, to: today) ?? today
    }

    private var maxDate: Date {
        Calendar.current.date(byAdding: .weekOfYear, value: 8, to: today) ?? today
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Quick Options Section
                quickOptionsSection
                    .padding(.horizontal, OnboardingDesign.Spacing.lg)
                    .padding(.top, OnboardingDesign.Spacing.lg)

                Divider()
                    .padding(.vertical, OnboardingDesign.Spacing.lg)

                // Calendar Section
                calendarSection
                    .padding(.horizontal, OnboardingDesign.Spacing.lg)

                Spacer()

                // Preview and Confirm Section
                confirmSection
                    .padding(.horizontal, OnboardingDesign.Spacing.lg)
                    .padding(.bottom, OnboardingDesign.Spacing.xxl)
            }
            .navigationTitle("Select Start Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(OnboardingDesign.Colors.textTertiary)
                            .font(.title2)
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Quick Options Section

    private var quickOptionsSection: some View {
        VStack(alignment: .leading, spacing: OnboardingDesign.Spacing.md) {
            Text("Quick Select")
                .font(OnboardingDesign.Typography.headline)
                .foregroundStyle(OnboardingDesign.Colors.textPrimary)

            HStack(spacing: OnboardingDesign.Spacing.sm) {
                quickOptionButton("Today", date: today)
                quickOptionButton("Tomorrow", date: tomorrow)
                quickOptionButton("Next Monday", date: nextMonday)
            }
        }
    }

    private func quickOptionButton(_ title: String, date: Date) -> some View {
        let isSelected = Calendar.current.isDate(tempDate, inSameDayAs: date)

        return Button(action: {
            withAnimation(OnboardingDesign.Animation.quick) {
                tempDate = date
            }
        }) {
            Text(title)
                .font(OnboardingDesign.Typography.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? OnboardingDesign.Colors.textOnDark : OnboardingDesign.Colors.textPrimary)
                .padding(.horizontal, OnboardingDesign.Spacing.md)
                .padding(.vertical, OnboardingDesign.Spacing.sm)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: OnboardingDesign.Radius.sm)
                        .fill(isSelected ? OnboardingDesign.Colors.selectedBackground : OnboardingDesign.Colors.unselectedBackground)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Calendar Section

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: OnboardingDesign.Spacing.md) {
            Text("Or pick a date")
                .font(OnboardingDesign.Typography.headline)
                .foregroundStyle(OnboardingDesign.Colors.textPrimary)

            DatePicker(
                "Start Date",
                selection: $tempDate,
                in: today...maxDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(OnboardingDesign.Colors.accent)
        }
    }

    // MARK: - Confirm Section

    private var confirmSection: some View {
        VStack(spacing: OnboardingDesign.Spacing.md) {
            // Preview
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(OnboardingDesign.Colors.textSecondary)

                Text("Your plan: ")
                    .font(OnboardingDesign.Typography.subheadline)
                    .foregroundStyle(OnboardingDesign.Colors.textSecondary)

                Text(dateRangePreview)
                    .font(OnboardingDesign.Typography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(OnboardingDesign.Colors.textPrimary)

                Text("(7 days)")
                    .font(OnboardingDesign.Typography.caption)
                    .foregroundStyle(OnboardingDesign.Colors.textTertiary)
            }
            .padding(OnboardingDesign.Spacing.md)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: OnboardingDesign.Radius.md)
                    .fill(OnboardingDesign.Colors.unselectedBackground)
            )

            // Confirm Button
            Button(action: {
                selectedDate = tempDate
                dismiss()
            }) {
                Text("Confirm Date")
                    .font(OnboardingDesign.Typography.headline)
                    .foregroundStyle(OnboardingDesign.Colors.textOnDark)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, OnboardingDesign.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: OnboardingDesign.Radius.xl)
                            .fill(OnboardingDesign.Colors.accent)
                    )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Preview
#Preview {
    DateRangePickerSheet(selectedDate: .constant(Date()))
}
