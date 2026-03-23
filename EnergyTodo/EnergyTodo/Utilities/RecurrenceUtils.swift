import Foundation

enum RecurrenceType: String, Codable, Sendable, CaseIterable {
    case none
    case daily
    case weekly
    case monthly
    case cycleDay = "cycle_day"
}

struct RecurringPattern: Codable, Sendable {
    let type: RecurrenceType
    var interval: Int
    var weekdays: [Int]?       // 1=Sunday, 2=Monday, ..., 7=Saturday
    var monthDay: Int?
    var cycleDay: Int?
    var endDate: String?       // ISO date "YYYY-MM-DD"

    enum CodingKeys: String, CodingKey {
        case type, interval, weekdays
        case monthDay = "month_day"
        case cycleDay = "cycle_day"
        case endDate = "end_date"
    }
}

/// Returns a human-readable description of a recurrence pattern.
func formatRecurrenceDescription(pattern: RecurringPattern) -> String {
    switch pattern.type {
    case .none:
        return "Does not repeat"
    case .daily:
        if pattern.interval == 1 {
            return "Every day"
        }
        return "Every \(pattern.interval) days"
    case .weekly:
        if let weekdays = pattern.weekdays, !weekdays.isEmpty {
            let dayNames = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
            let names = weekdays.compactMap { $0 >= 1 && $0 <= 7 ? dayNames[$0] : nil }
            if names.count == 1 {
                return pattern.interval == 1
                    ? "Every \(names[0])"
                    : "Every \(pattern.interval) weeks on \(names[0])"
            }
            let joined = names.joined(separator: ", ")
            return pattern.interval == 1
                ? "Weekly on \(joined)"
                : "Every \(pattern.interval) weeks on \(joined)"
        }
        return pattern.interval == 1 ? "Every week" : "Every \(pattern.interval) weeks"
    case .monthly:
        if let day = pattern.monthDay {
            return pattern.interval == 1
                ? "Monthly on day \(day)"
                : "Every \(pattern.interval) months on day \(day)"
        }
        return pattern.interval == 1 ? "Every month" : "Every \(pattern.interval) months"
    case .cycleDay:
        if let day = pattern.cycleDay {
            return "Every Day \(day)"
        }
        return "Every cycle"
    }
}

struct CycleInfo {
    let day1Date: String      // ISO date "YYYY-MM-DD"
    let cycleLength: Int
}

/// Generates occurrence dates (as ISO date strings) for a recurring pattern within a date range.
func generateOccurrences(
    pattern: RecurringPattern,
    startDate: String,
    rangeStart: String,
    rangeEnd: String,
    maxInstances: Int = 365,
    cycleInfo: CycleInfo? = nil
) -> [String] {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone(identifier: "UTC")

    guard let start = formatter.date(from: startDate),
          let rStart = formatter.date(from: rangeStart),
          let rEnd = formatter.date(from: rangeEnd) else {
        return []
    }

    let endLimit: Date
    if let endDateStr = pattern.endDate, let ed = formatter.date(from: endDateStr) {
        endLimit = min(ed, rEnd)
    } else {
        endLimit = rEnd
    }

    let calendar = Calendar(identifier: .gregorian)
    var results: [String] = []

    switch pattern.type {
    case .none:
        return []

    case .daily:
        var current = start
        while current <= endLimit && results.count < maxInstances {
            if current >= rStart {
                results.append(formatter.string(from: current))
            }
            guard let next = calendar.date(byAdding: .day, value: pattern.interval, to: current) else { break }
            current = next
        }

    case .weekly:
        let targetWeekdays = pattern.weekdays ?? []
        var current = start
        while current <= endLimit && results.count < maxInstances {
            let weekday = calendar.component(.weekday, from: current) // 1=Sunday
            if targetWeekdays.isEmpty || targetWeekdays.contains(weekday) {
                if current >= rStart {
                    results.append(formatter.string(from: current))
                }
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }

    case .monthly:
        guard let targetDay = pattern.monthDay else { return [] }
        var components = calendar.dateComponents([.year, .month], from: start)
        while results.count < maxInstances {
            components.day = targetDay
            guard let candidate = calendar.date(from: components) else { break }
            if candidate > endLimit { break }
            if candidate >= rStart && candidate >= start {
                results.append(formatter.string(from: candidate))
            }
            if let nextMonth = calendar.date(byAdding: .month, value: pattern.interval, to: candidate) {
                components = calendar.dateComponents([.year, .month], from: nextMonth)
            } else {
                break
            }
        }

    case .cycleDay:
        guard let info = cycleInfo,
              let targetDay = pattern.cycleDay,
              let cycleStart = formatter.date(from: info.day1Date) else {
            return []
        }
        // Generate occurrences for each cycle that falls in range
        var currentCycleStart = cycleStart
        while currentCycleStart <= endLimit && results.count < maxInstances {
            guard let occurrenceDate = calendar.date(byAdding: .day, value: targetDay - 1, to: currentCycleStart) else { break }
            if occurrenceDate >= rStart && occurrenceDate <= endLimit {
                results.append(formatter.string(from: occurrenceDate))
            }
            guard let nextCycle = calendar.date(byAdding: .day, value: info.cycleLength, to: currentCycleStart) else { break }
            currentCycleStart = nextCycle
        }
    }

    return results
}
