import SwiftUI

/// A date range representing an existing meal plan
struct ExistingPlanRange: Equatable {
    let start: Date
    let end: Date
}

/// Custom calendar where user taps to select a start date, then taps again to select an end date.
/// The range is validated to be within maxDuration days.
struct MealPlanCalendarView: View {
    @Binding var selectedStartDate: Date
    @Binding var selectedEndDate: Date
    let minDate: Date
    let maxDate: Date
    var existingPlanRanges: [ExistingPlanRange] = []
    var maxDuration: Int = 14

    /// Tracks whether the next tap should set the start or end date
    @Binding var isSelectingEnd: Bool

    @State private var displayedMonth: Date = Date()

    private let calendar = Calendar.current
    private let daysOfWeek = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    private let rangeColor = Color(red: 0.2, green: 0.78, blue: 0.35)
    private let existingColor = Color(red: 0.2, green: 0.78, blue: 0.35)

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

    /// The latest valid end date based on start + maxDuration
    private var maxEndDate: Date {
        calendar.date(byAdding: .day, value: maxDuration - 1, to: selectedStartDate) ?? selectedStartDate
    }

    /// Check if a date falls within any existing meal plan range
    private func isInExistingPlan(_ date: Date) -> Bool {
        let day = calendar.startOfDay(for: date)
        return existingPlanRanges.contains { range in
            day >= calendar.startOfDay(for: range.start) && day <= calendar.startOfDay(for: range.end)
        }
    }

    private func isExistingPlanStart(_ date: Date) -> Bool {
        existingPlanRanges.contains { calendar.isDate(date, inSameDayAs: $0.start) }
    }

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
                        .font(OnboardingDesign.Typography.body).fontWeight(.semibold)
                        .foregroundStyle(canGoBack ? OnboardingDesign.Colors.textPrimary : OnboardingDesign.Colors.textTertiary)
                }
                .accessibilityLabel("Previous month")
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
                        .font(OnboardingDesign.Typography.body).fontWeight(.semibold)
                        .foregroundStyle(canGoForward ? OnboardingDesign.Colors.textPrimary : OnboardingDesign.Colors.textTertiary)
                }
                .accessibilityLabel("Next month")
                .disabled(!canGoForward)
            }
            .padding(.horizontal, 4)

            // Instruction hint
            Text(isSelectingEnd ? "Now tap the end date (max \(maxDuration) days)" : "Tap to select start date")
                .font(.caption)
                .foregroundStyle(isSelectingEnd ? rangeColor : OnboardingDesign.Colors.textTertiary)
                .animation(.easeInOut(duration: 0.2), value: isSelectingEnd)

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
            displayedMonth = selectedStartDate
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)
            Text(label)
                .font(.caption2)
                .foregroundStyle(OnboardingDesign.Colors.textTertiary)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Day Cell

    @ViewBuilder
    private func dayCell(for date: Date?) -> some View {
        if let date = date {
            let isCurrentMonth = calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month)
            let startDay = calendar.startOfDay(for: selectedStartDate)
            let endDay = calendar.startOfDay(for: selectedEndDate)
            let thisDay = calendar.startOfDay(for: date)

            let isStartDate = calendar.isDate(date, inSameDayAs: selectedStartDate)
            let isEndDate = calendar.isDate(date, inSameDayAs: selectedEndDate)
            let isInRange = thisDay >= startDay && thisDay <= endDay
            let isToday = calendar.isDateInToday(date)
            let isSelectable = thisDay >= calendar.startOfDay(for: minDate) && thisDay <= calendar.startOfDay(for: maxDate)

            // When selecting end, dates beyond maxDuration from start are dimmed
            let isWithinMaxRange = !isSelectingEnd || thisDay <= calendar.startOfDay(for: maxEndDate)
            let isValidEndTarget = !isSelectingEnd || thisDay >= startDay

            let isExisting = isInExistingPlan(date) && !isInRange
            let isExistingStart = isExistingPlanStart(date) && !isInRange
            let isExistingEnd = isExistingPlanEnd(date) && !isInRange

            let canTap = isSelectable && isCurrentMonth && isWithinMaxRange && isValidEndTarget

            Button(action: {
                if canTap {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if isSelectingEnd {
                            // Second tap: set end date
                            selectedEndDate = date
                            isSelectingEnd = false
                        } else {
                            // First tap: set start date, reset end to same day, enter end-selection mode
                            selectedStartDate = date
                            selectedEndDate = date
                            isSelectingEnd = true
                        }
                    }
                }
            }) {
                Text("\(calendar.component(.day, from: date))")
                    .font(OnboardingDesign.Typography.subheadline).fontWeight(.bold)
                    .foregroundStyle(
                        !isCurrentMonth ? OnboardingDesign.Colors.textTertiary.opacity(0.4) :
                        !isSelectable || (isSelectingEnd && (!isWithinMaxRange || !isValidEndTarget)) ? OnboardingDesign.Colors.textTertiary.opacity(0.3) :
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
                            // Existing plan range background
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
                                if !isEndDate {
                                    // Only show right-side fill if there's a range
                                    HStack(spacing: 0) {
                                        Color.clear.frame(width: 19)
                                        Rectangle().fill(rangeColor.opacity(0.12))
                                    }
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

                            // Today indicator
                            if isToday && !isStartDate && !isEndDate && !isExistingStart && !isExistingEnd {
                                Circle()
                                    .stroke(OnboardingDesign.Colors.textTertiary, lineWidth: 1)
                                    .frame(width: 36, height: 36)
                            }
                        }
                    )
            }
            .buttonStyle(.plain)
            .disabled(!canTap)
            .accessibilityLabel({
                let formatter = DateFormatter()
                formatter.dateStyle = .long
                var label = formatter.string(from: date)
                if isStartDate { label += ", start date" }
                if isEndDate && !isStartDate { label += ", end date" }
                if isInRange && !isStartDate && !isEndDate { label += ", in selected range" }
                if isExisting { label += ", has existing plan" }
                if isToday { label += ", today" }
                return label
            }())
            .accessibilityHint(canTap ? (isSelectingEnd ? "Double tap to set as end date" : "Double tap to set as start date") : "")
            .accessibilityAddTraits(isStartDate || isEndDate ? [.isSelected] : [])
        } else {
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .accessibilityHidden(true)
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
        selectedStartDate: .constant(Date()),
        selectedEndDate: .constant(Calendar.current.date(byAdding: .day, value: 6, to: Date())!),
        minDate: Date(),
        maxDate: Calendar.current.date(byAdding: .weekOfYear, value: 8, to: Date())!,
        existingPlanRanges: [
            ExistingPlanRange(
                start: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
                end: Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            )
        ],
        isSelectingEnd: .constant(false)
    )
    .padding()
}
