import Foundation

/// Pure functions for cycle day calculations.
/// Ported from src/lib/cycle/cycle-calculator.ts
enum CycleCalculator {

    private static let calendar = Calendar.current
    private static let isoFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    // MARK: - Date Helpers

    static func parseISO(_ string: String) -> Date? {
        isoFormatter.date(from: string)
    }

    static func formatISO(_ date: Date) -> String {
        isoFormatter.string(from: date)
    }

    static func daysBetween(_ from: Date, _ to: Date) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: from), to: calendar.startOfDay(for: to)).day ?? 0
    }

    static func addDays(_ date: Date, _ days: Int) -> Date {
        calendar.date(byAdding: .day, value: days, to: date)!
    }

    // MARK: - Cycle Day Calculation

    /// Calculate which cycle day a given date falls on.
    /// - Parameters:
    ///   - date: The target date (ISO string or Date)
    ///   - day1Date: When Day 1 started (ISO string)
    ///   - cycleLength: Length of the cycle (1-99)
    /// - Returns: The cycle day number (1 to cycleLength)
    static func getCycleDay(date: String, day1Date: String, cycleLength: Int) -> Int {
        guard let targetDate = parseISO(date),
              let startDate = parseISO(day1Date),
              cycleLength > 0 else { return 1 }
        return getCycleDay(date: targetDate, day1Date: startDate, cycleLength: cycleLength)
    }

    static func getCycleDay(date: Date, day1Date: Date, cycleLength: Int) -> Int {
        guard cycleLength > 0 else { return 1 }
        let daysSinceStart = daysBetween(day1Date, date)

        if daysSinceStart < 0 {
            let cyclesBack = Int(ceil(Double(abs(daysSinceStart)) / Double(cycleLength)))
            let adjustedDays = daysSinceStart + cyclesBack * cycleLength
            let cycleDay = (adjustedDays % cycleLength) + 1
            return cycleDay == 0 ? cycleLength : cycleDay
        }

        return (daysSinceStart % cycleLength) + 1
    }

    /// Get the date for a specific cycle day relative to Day 1.
    static func getDateForCycleDay(_ cycleDay: Int, day1Date: String) -> String? {
        guard let startDate = parseISO(day1Date) else { return nil }
        let targetDate = addDays(startDate, cycleDay - 1)
        return formatISO(targetDate)
    }

    /// Check if a given date is a weekend (Saturday or Sunday).
    static func isWeekendDay(date: String) -> Bool {
        guard let d = parseISO(date) else { return false }
        return isWeekendDay(date: d)
    }

    static func isWeekendDay(date: Date) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        return weekday == 1 || weekday == 7 // 1=Sunday, 7=Saturday
    }

    /// Get all dates in a range (inclusive).
    static func getDateRange(start: String, end: String) -> [String] {
        guard let startDate = parseISO(start),
              let endDate = parseISO(end) else { return [] }

        var dates: [String] = []
        var current = startDate
        while current <= endDate {
            dates.append(formatISO(current))
            current = addDays(current, 1)
        }
        return dates
    }

    /// Calculate the start date of the current cycle.
    static func getCurrentCycleStartDate(currentDate: String, day1Date: String, cycleLength: Int) -> String? {
        guard let target = parseISO(currentDate),
              let startDate = parseISO(day1Date),
              cycleLength > 0 else { return nil }

        let daysSinceStart = daysBetween(startDate, target)
        let completeCycles = daysSinceStart / cycleLength
        let cycleStartDate = addDays(startDate, completeCycles * cycleLength)
        return formatISO(cycleStartDate)
    }

    /// Get the next occurrence of a specific cycle day.
    static func getNextCycleDayOccurrence(
        targetCycleDay: Int,
        fromDate: String,
        day1Date: String,
        cycleLength: Int
    ) -> String? {
        guard let from = parseISO(fromDate) else { return nil }
        let currentCycleDay = getCycleDay(date: fromDate, day1Date: day1Date, cycleLength: cycleLength)

        let daysToAdd: Int
        if targetCycleDay >= currentCycleDay {
            daysToAdd = targetCycleDay - currentCycleDay
        } else {
            daysToAdd = cycleLength - currentCycleDay + targetCycleDay
        }

        let targetDate = addDays(from, daysToAdd)
        return formatISO(targetDate)
    }
}
