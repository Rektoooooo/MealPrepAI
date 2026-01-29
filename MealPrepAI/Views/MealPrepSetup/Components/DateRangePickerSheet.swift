import SwiftUI

// MARK: - Date Range Picker Sheet
/// A sheet for selecting the start and end dates of a meal plan via calendar taps
struct DateRangePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date
    @Binding var planDuration: Int
    var existingPlanRanges: [ExistingPlanRange] = []
    var maxDuration: Int = 14

    // Local state for editing before confirmation
    @State private var tempStartDate: Date
    @State private var tempEndDate: Date
    @State private var isSelectingEnd: Bool = false

    init(selectedDate: Binding<Date>, planDuration: Binding<Int>, existingPlanRanges: [ExistingPlanRange] = [], maxDuration: Int = 14) {
        self._selectedDate = selectedDate
        self._planDuration = planDuration
        self.existingPlanRanges = existingPlanRanges
        self.maxDuration = maxDuration
        let start = selectedDate.wrappedValue
        let end = Calendar.current.date(byAdding: .day, value: planDuration.wrappedValue - 1, to: start) ?? start
        self._tempStartDate = State(initialValue: start)
        self._tempEndDate = State(initialValue: end)
    }

    // MARK: - Computed Properties

    private var computedDuration: Int {
        let cal = Calendar.current
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: tempStartDate), to: cal.startOfDay(for: tempEndDate)).day ?? 0
        return days + 1
    }

    private var dateRangePreview: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        let startString = formatter.string(from: tempStartDate)
        let endString = formatter.string(from: tempEndDate)
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
        let daysUntilMonday = weekday == 1 ? 1 : (9 - weekday)
        return calendar.date(byAdding: .day, value: daysUntilMonday, to: today) ?? today
    }

    private var maxDate: Date {
        Calendar.current.date(byAdding: .weekOfYear, value: 8, to: today) ?? today
    }

    /// Whether a valid range has been fully selected (not mid-selection)
    private var hasValidRange: Bool {
        !isSelectingEnd && computedDuration >= 1
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
            .navigationTitle("Select Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(OnboardingDesign.Colors.textTertiary)
                            .font(.title2)
                    }
                    .accessibilityLabel("Close date picker")
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Quick Options Section

    private var quickOptionsSection: some View {
        VStack(alignment: .leading, spacing: OnboardingDesign.Spacing.md) {
            Text("Quick Select Start")
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
        let isSelected = Calendar.current.isDate(tempStartDate, inSameDayAs: date) && !isSelectingEnd

        return Button(action: {
            withAnimation(OnboardingDesign.Animation.quick) {
                tempStartDate = date
                tempEndDate = date
                isSelectingEnd = true
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
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint("Sets start date to \(title.lowercased())")
        .buttonStyle(.plain)
    }

    // MARK: - Calendar Section

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: OnboardingDesign.Spacing.md) {
            Text("Pick your date range")
                .font(OnboardingDesign.Typography.headline)
                .foregroundStyle(OnboardingDesign.Colors.textPrimary)

            MealPlanCalendarView(
                selectedStartDate: $tempStartDate,
                selectedEndDate: $tempEndDate,
                minDate: today,
                maxDate: maxDate,
                existingPlanRanges: existingPlanRanges,
                maxDuration: maxDuration,
                isSelectingEnd: $isSelectingEnd
            )
        }
    }

    // MARK: - Confirm Section

    private var confirmSection: some View {
        VStack(spacing: OnboardingDesign.Spacing.md) {
            // Preview
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(OnboardingDesign.Colors.textSecondary)
                    .accessibilityHidden(true)

                Text("Your plan: ")
                    .font(OnboardingDesign.Typography.subheadline)
                    .foregroundStyle(OnboardingDesign.Colors.textSecondary)

                if isSelectingEnd {
                    Text("Select end date...")
                        .font(OnboardingDesign.Typography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(OnboardingDesign.Colors.accent)
                } else {
                    Text(dateRangePreview)
                        .font(OnboardingDesign.Typography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(OnboardingDesign.Colors.textPrimary)

                    Text("(\(computedDuration) \(computedDuration == 1 ? "day" : "days"))")
                        .font(OnboardingDesign.Typography.caption)
                        .foregroundStyle(OnboardingDesign.Colors.textTertiary)
                }
            }
            .padding(OnboardingDesign.Spacing.md)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: OnboardingDesign.Radius.md)
                    .fill(OnboardingDesign.Colors.unselectedBackground)
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel(isSelectingEnd ? "Select end date to complete range" : "Plan: \(dateRangePreview), \(computedDuration) \(computedDuration == 1 ? "day" : "days")")

            // Confirm Button
            Button(action: {
                selectedDate = tempStartDate
                planDuration = computedDuration
                dismiss()
            }) {
                Text("Confirm Date Range")
                    .font(OnboardingDesign.Typography.headline)
                    .foregroundStyle(OnboardingDesign.Colors.textOnDark)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, OnboardingDesign.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: OnboardingDesign.Radius.xl)
                            .fill(hasValidRange ? OnboardingDesign.Colors.accent : OnboardingDesign.Colors.textTertiary)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!hasValidRange)
        }
    }
}

// MARK: - Preview
#Preview {
    DateRangePickerSheet(selectedDate: .constant(Date()), planDuration: .constant(7))
}
