import Foundation

/// Pure functions for effort point calculations.
/// Ported from src/lib/cycle/effort-calculator.ts and default-cycles.ts
enum EffortCalculator {

    // MARK: - Default Effort Pattern

    /// Get default effort points for a cycle day based on the standard 35-day pattern.
    /// Day 1 = 0 (rest), Day 2 = 2, Day 3-5 = 4, ... Day 13-15 = 15 (peak)
    static func getDefaultEffortForCycleDay(_ cycleDay: Int) -> Int {
        if cycleDay == 1 { return 0 }
        if cycleDay == 2 { return 2 }
        if cycleDay >= 3 && cycleDay <= 5 { return 4 }
        if cycleDay >= 6 && cycleDay <= 10 { return 8 }
        if cycleDay >= 11 && cycleDay <= 12 { return 12 }
        if cycleDay >= 13 && cycleDay <= 15 { return 15 }
        if cycleDay >= 16 && cycleDay <= 20 { return 12 }
        if cycleDay >= 21 && cycleDay <= 23 { return 10 }
        if cycleDay >= 24 && cycleDay <= 35 { return 5 }
        return 5 // Day 36-99 same as 35
    }

    /// Generate default effort points array for a given cycle length.
    static func generateDefaultEffortPointsArray(cycleLength: Int) -> [(dayNumber: Int, effortPoints: Int)] {
        (1...cycleLength).map { day in
            (dayNumber: day, effortPoints: getDefaultEffortForCycleDay(day))
        }
    }

    /// Get a descriptive label for a cycle day's energy level.
    static func getEffortDescription(cycleDay: Int) -> String {
        let effort = getDefaultEffortForCycleDay(cycleDay)
        if effort == 0 { return "Rest day" }
        if effort <= 2 { return "Low energy" }
        if effort <= 4 { return "Building energy" }
        if effort <= 8 { return "Good energy" }
        if effort <= 12 { return "High energy" }
        if effort >= 15 { return "Peak energy" }
        return "Moderate energy"
    }

    // MARK: - Base Effort Lookup

    /// Get base effort points for a specific cycle day from custom or default values.
    static func getBaseEffortForCycleDay(
        _ cycleDay: Int,
        effortPoints: [Int: Int],
        useDefaults: Bool = true
    ) -> Int {
        if let effort = effortPoints[cycleDay] {
            return effort
        }
        return useDefaults ? getDefaultEffortForCycleDay(cycleDay) : 0
    }

    static func getBaseEffortForCycleDay(
        _ cycleDay: Int,
        effortPointsList: [CycleEffortPoint],
        useDefaults: Bool = true
    ) -> Int {
        if let point = effortPointsList.first(where: { $0.dayNumber == cycleDay }) {
            return point.effortPoints
        }
        return useDefaults ? getDefaultEffortForCycleDay(cycleDay) : 0
    }

    // MARK: - Available Effort Calculation

    /// Calculate total available effort for a specific date.
    static func getAvailableEffortForDate(
        date: String,
        day1Date: String,
        cycleLength: Int,
        effortPoints: [Int: Int],
        weekendOverrides: [WeekendOverride] = [],
        fixedEvents: [FixedEvent] = [],
        sleepCheck: SleepCheck? = nil
    ) -> Int {
        let cycleDay = CycleCalculator.getCycleDay(date: date, day1Date: day1Date, cycleLength: cycleLength)
        var effort = getBaseEffortForCycleDay(cycleDay, effortPoints: effortPoints)

        // Weekend override
        if let override = weekendOverrides.first(where: { $0.date == date }) {
            effort = override.effortPoints
        }

        // Subtract fixed events
        let fixedCost = fixedEvents
            .filter { $0.date == date }
            .reduce(0) { $0 + $1.effortCost }
        effort -= fixedCost

        // Sleep reduction
        if let sleep = sleepCheck, sleep.sleptPoorly {
            effort -= sleep.effortReduction > 0 ? sleep.effortReduction : 1
        }

        return max(0, effort)
    }

    // MARK: - Effort Breakdown

    struct EffortBreakdown {
        let cycleDay: Int
        let baseEffort: Int
        let weekendOverride: Int?
        let fixedEventsEffort: Int
        let sleepReduction: Int
        let totalAvailable: Int
    }

    /// Get a detailed breakdown of effort allocation for a date.
    static func getEffortBreakdown(
        date: String,
        day1Date: String,
        cycleLength: Int,
        effortPoints: [Int: Int],
        weekendOverrides: [WeekendOverride] = [],
        fixedEvents: [FixedEvent] = [],
        sleepCheck: SleepCheck? = nil
    ) -> EffortBreakdown {
        let cycleDay = CycleCalculator.getCycleDay(date: date, day1Date: day1Date, cycleLength: cycleLength)
        let baseEffort = getBaseEffortForCycleDay(cycleDay, effortPoints: effortPoints)

        let override = weekendOverrides.first(where: { $0.date == date })
        let weekendOverrideValue = override?.effortPoints

        let fixedEventsEffort = fixedEvents
            .filter { $0.date == date }
            .reduce(0) { $0 + $1.effortCost }

        let sleepReduction: Int
        if let sleep = sleepCheck, sleep.sleptPoorly {
            sleepReduction = sleep.effortReduction > 0 ? sleep.effortReduction : 1
        } else {
            sleepReduction = 0
        }

        let effectiveBase = weekendOverrideValue ?? baseEffort
        let totalAvailable = max(0, effectiveBase - fixedEventsEffort - sleepReduction)

        return EffortBreakdown(
            cycleDay: cycleDay,
            baseEffort: baseEffort,
            weekendOverride: weekendOverrideValue,
            fixedEventsEffort: fixedEventsEffort,
            sleepReduction: sleepReduction,
            totalAvailable: totalAvailable
        )
    }

    // MARK: - Validation

    static func isValidCycleLength(_ length: Int) -> Bool {
        length >= 1 && length <= 99
    }

    static func isValidEffortPoints(_ effort: Int) -> Bool {
        effort >= 0 && effort <= 50
    }
}
