import SwiftUI

/// A date range representing an existing meal plan
struct ExistingPlanRange: Equatable {
    let start: Date
    let end: Date
}

/// Custom calendar that highlights the 7-day meal plan range starting from the selected date
/// and shows existing meal plan ranges in a separate color
struct MealPlanCalendarView: View {
    @Binding var selectedDate: Date
    let minDate: Date
    let maxDate: Date
    var existingPlanRanges: [ExistingPlanRange] = []

    @State private var displayedMonth: Date = Date()

    private let calendar = Calendar.current
    private let daysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    private let rangeColor = Color(red: 0.2, green: 0.78, blue: 0.35) // Green for new selection
    private let existingColor = Color(red: 0.2, green: 0.78, blue: 0.35) // Green for existing plans

    // The 7-day range end date
    private var endDate: Date {
        calendar.date(byAdding: .day, value: 6, to: selectedDate) ?? selectedDate
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    private var canGoBack: Bool {
        let prevMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth)!
        let prevMonthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: calendar.startOfMonth(prevMonth))!
        return prevMonthEnd >= minDate
    }

    private var canGoForward: Bool {
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth)!
        let nextMonthStart = calendar.startOfMonth(nextMonth)
        return nextMonthStart <= maxDate
    }

    /// Check if a date falls within any existing meal plan range
    private func isInExistingPlan(_ date: Date) -> Bool {
        let day = calendar.startOfDay(for: date)
        return existingPlanRanges.contains { range in
            day >= calendar.startOfDay(for: range.start) && day <= calendar.startOfDay(for: range.end)
        }
    }

    /// Check if a date is the start of an existing meal plan range
    private func isExistingPlanStart(_ date: Date) -> Bool {
        existingPlanRanges.contains { calendar.isDate(date, inSameDayAs: $0.start) }
    }

    /// Check if a date is the end of an existing meal plan range
    private func isExistingPlanEnd(_ date: Date) -> Bool {
        existingPlanRanges.contains { calendar.isDate(date, inSameDayAs: $0.end) }
    }

    var body: some View {
        VStack(spacing: OnboardingDesign.Spacing.md) {
            // Month navigation
            HStack {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth)!
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(canGoBack ? OnboardingDesign.Colors.textPrimary : OnboardingDesign.Colors.textTertiary)
                }
                .disabled(!canGoBack)

                Spacer()

                Text(monthTitle)
                    .font(OnboardingDesign.Typography.headline)
                    .foregroundStyle(OnboardingDesign.Colors.textPrimary)

                Spacer()

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth)!
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(canGoForward ? OnboardingDesign.Colors.textPrimary : OnboardingDesign.Colors.textTertiary)
                }
                .disabled(!canGoForward)
            }
            .padding(.horizontal, 4)

            // Day of week headers
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(OnboardingDesign.Colors.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            let weeks = weeksInMonth()
            VStack(spacing: 4) {
                ForEach(weeks.indices, id: \.self) { weekIndex in
                    HStack(spacing: 0) {
                        ForEach(weeks[weekIndex].indices, id: \.self) { dayIndex in
                            let dayDate = weeks[weekIndex][dayIndex]
                            dayCell(for: dayDate)
                        }
                    }
                }
            }

            // Legend
            if !existingPlanRanges.isEmpty {
                HStack(spacing: OnboardingDesign.Spacing.lg) {
                    legendItem(color: rangeColor, label: "New plan")
                    legendItem(color: existingColor.opacity(0.5), label: "Current plan")
                }
                .padding(.top, 4)
            }
        }
        .padding(OnboardingDesign.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: OnboardingDesign.Radius.md)
                .fill(OnboardingDesign.Colors.cardBackground)
        )
        .onAppear {
            displayedMonth = selectedDate
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption2)
                .foregroundStyle(OnboardingDesign.Colors.textTertiary)
        }
    }

    // MARK: - Day Cell

    @ViewBuilder
    private func dayCell(for date: Date?) -> some View {
        if let date = date {
            let isCurrentMonth = calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month)
            let isStartDate = calendar.isDate(date, inSameDayAs: selectedDate)
            let isEndDate = calendar.isDate(date, inSameDayAs: endDate)
            let isInRange = date >= calendar.startOfDay(for: selectedDate) && date <= calendar.startOfDay(for: endDate)
            let isToday = calendar.isDateInToday(date)
            let isSelectable = date >= calendar.startOfDay(for: minDate) && date <= calendar.startOfDay(for: maxDate)
            let isExisting = isInExistingPlan(date) && !isInRange
            let isExistingStart = isExistingPlanStart(date) && !isInRange
            let isExistingEnd = isExistingPlanEnd(date) && !isInRange

            Button(action: {
                if isSelectable {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedDate = date
                    }
                }
            }) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(
                        !isCurrentMonth ? OnboardingDesign.Colors.textTertiary.opacity(0.4) :
                        !isSelectable ? OnboardingDesign.Colors.textTertiary.opacity(0.3) :
                        isStartDate || isEndDate ? .white :
                        isInRange ? rangeColor :
                        isExistingStart || isExistingEnd ? .white :
                        isExisting ? existingColor :
                        isToday ? OnboardingDesign.Colors.accent :
                        OnboardingDesign.Colors.textPrimary
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(
                        ZStack {
                            // Existing plan range background (behind new selection)
                            if isExisting && isCurrentMonth && !isExistingStart && !isExistingEnd {
                                Rectangle()
                                    .fill(existingColor.opacity(0.10))
                            }

                            if isExistingStart && isCurrentMonth {
                                HStack(spacing: 0) {
                                    Color.clear.frame(width: 19)
                                    Rectangle().fill(existingColor.opacity(0.10))
                                }
                                Circle()
                                    .fill(existingColor.opacity(0.5))
                                    .frame(width: 36, height: 36)
                            }

                            if isExistingEnd && !isExistingStart && isCurrentMonth {
                                HStack(spacing: 0) {
                                    Rectangle().fill(existingColor.opacity(0.10))
                                    Color.clear.frame(width: 19)
                                }
                                Circle()
                                    .fill(existingColor.opacity(0.5))
                                    .frame(width: 36, height: 36)
                            }

                            // New selection range background (middle days)
                            if isInRange && isCurrentMonth && !isStartDate && !isEndDate {
                                Rectangle()
                                    .fill(rangeColor.opacity(0.12))
                            }

                            // Start date: right half range + circle
                            if isStartDate && isCurrentMonth {
                                HStack(spacing: 0) {
                                    Color.clear.frame(width: 19)
                                    Rectangle().fill(rangeColor.opacity(0.12))
                                }
                                Circle()
                                    .fill(rangeColor)
                                    .frame(width: 36, height: 36)
                            }

                            // End date: left half range + circle
                            if isEndDate && !isStartDate && isCurrentMonth {
                                HStack(spacing: 0) {
                                    Rectangle().fill(rangeColor.opacity(0.12))
                                    Color.clear.frame(width: 19)
                                }
                                Circle()
                                    .fill(rangeColor)
                                    .frame(width: 36, height: 36)
                            }

                            // Today indicator (subtle ring when not in any range)
                            if isToday && !isStartDate && !isEndDate && !isExistingStart && !isExistingEnd {
                                Circle()
                                    .stroke(OnboardingDesign.Colors.textTertiary, lineWidth: 1)
                                    .frame(width: 36, height: 36)
                            }
                        }
                    )
            }
            .buttonStyle(.plain)
            .disabled(!isSelectable || !isCurrentMonth)
        } else {
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: 38)
        }
    }

    // MARK: - Calendar Helpers

    private func weeksInMonth() -> [[Date?]] {
        let monthStart = calendar.startOfMonth(displayedMonth)
        let monthRange = calendar.range(of: .day, in: .month, for: monthStart)!

        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let offset = (firstWeekday + 5) % 7

        var weeks: [[Date?]] = []
        var currentWeek: [Date?] = []

        for _ in 0..<offset {
            currentWeek.append(nil)
        }

        for day in 1...monthRange.count {
            let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart)!
            currentWeek.append(date)

            if currentWeek.count == 7 {
                weeks.append(currentWeek)
                currentWeek = []
            }
        }

        if !currentWeek.isEmpty {
            while currentWeek.count < 7 {
                currentWeek.append(nil)
            }
            weeks.append(currentWeek)
        }

        return weeks
    }
}

// MARK: - Calendar Extension
private extension Calendar {
    func startOfMonth(_ date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components)!
    }
}

#Preview {
    MealPlanCalendarView(
        selectedDate: .constant(Date()),
        minDate: Date(),
        maxDate: Calendar.current.date(byAdding: .weekOfYear, value: 8, to: Date())!,
        existingPlanRanges: [
            ExistingPlanRange(
                start: Date(),
                end: Calendar.current.date(byAdding: .day, value: 6, to: Date())!
            )
        ]
    )
    .padding()
}
