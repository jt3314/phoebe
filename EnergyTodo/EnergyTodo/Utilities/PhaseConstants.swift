import Foundation

enum CyclePhaseId: String, CaseIterable, Codable, Sendable {
    case menstrual
    case follicular
    case ovulation
    case luteal
}

struct PhaseConfig: Sendable {
    let id: CyclePhaseId
    let label: String
    var length: Int
    var effortPoints: Int
    let color: String // hex
    let minLength: Int
}

let CYCLE_PHASES: [PhaseConfig] = [
    PhaseConfig(id: .menstrual, label: "Menstrual", length: 5, effortPoints: 3, color: "#B85C4A", minLength: 1),
    PhaseConfig(id: .follicular, label: "Follicular", length: 6, effortPoints: 10, color: "#D4906F", minLength: 1),
    PhaseConfig(id: .ovulation, label: "Ovulation", length: 3, effortPoints: 15, color: "#C97D5C", minLength: 1),
    PhaseConfig(id: .luteal, label: "Luteal", length: 14, effortPoints: 7, color: "#A65D3F", minLength: 1),
]

/// Returns default phase config scaled so total days match `totalDays`.
/// Luteal absorbs the difference.
func getDefaultPhaseConfig(totalDays: Int) -> [PhaseConfig] {
    var phases = CYCLE_PHASES
    let nonLutealTotal = phases.filter { $0.id != .luteal }.reduce(0) { $0 + $1.length }
    if let lutealIndex = phases.firstIndex(where: { $0.id == .luteal }) {
        let newLutealLength = max(phases[lutealIndex].minLength, totalDays - nonLutealTotal)
        phases[lutealIndex].length = newLutealLength
    }
    return phases
}

/// Rebalances phases after one phase's length changed.
/// Luteal absorbs the difference to keep the total equal to `totalDays`.
func rebalancePhases(phases: [PhaseConfig], changedId: CyclePhaseId, newLength: Int, totalDays: Int) -> [PhaseConfig] {
    var result = phases
    if let changedIndex = result.firstIndex(where: { $0.id == changedId }) {
        result[changedIndex].length = max(result[changedIndex].minLength, newLength)
    }

    let nonLutealTotal = result.filter { $0.id != .luteal }.reduce(0) { $0 + $1.length }
    if let lutealIndex = result.firstIndex(where: { $0.id == .luteal }) {
        let newLutealLength = max(result[lutealIndex].minLength, totalDays - nonLutealTotal)
        result[lutealIndex].length = newLutealLength
    }

    return result
}

/// Converts phase configs to a per-day array of effort points.
func phasesToDayEffort(phases: [PhaseConfig]) -> [(dayNumber: Int, effortPoints: Int)] {
    var result: [(dayNumber: Int, effortPoints: Int)] = []
    var dayNumber = 1
    for phase in phases {
        for _ in 0..<phase.length {
            result.append((dayNumber: dayNumber, effortPoints: phase.effortPoints))
            dayNumber += 1
        }
    }
    return result
}

struct CurrentPhaseInfo {
    let phase: PhaseConfig
    let dayWithinPhase: Int
    let totalPhaseDays: Int
    let nextPhase: PhaseConfig?
}

/// Returns info about which phase a given cycle day falls in.
func getCurrentPhase(cycleDay: Int, cycleLength: Int) -> CurrentPhaseInfo? {
    let phases = getDefaultPhaseConfig(totalDays: cycleLength)
    var dayCounter = 0
    for (index, phase) in phases.enumerated() {
        if cycleDay <= dayCounter + phase.length {
            let dayWithinPhase = cycleDay - dayCounter
            let nextPhase = index + 1 < phases.count ? phases[index + 1] : phases.first
            return CurrentPhaseInfo(
                phase: phase,
                dayWithinPhase: dayWithinPhase,
                totalPhaseDays: phase.length,
                nextPhase: nextPhase
            )
        }
        dayCounter += phase.length
    }
    return nil
}

struct PhaseDayRange {
    let phase: PhaseConfig
    let startDay: Int
    let endDay: Int
}

/// Returns the start and end day for each phase.
func getPhaseDayRanges(phases: [PhaseConfig]) -> [PhaseDayRange] {
    var ranges: [PhaseDayRange] = []
    var currentDay = 1
    for phase in phases {
        let startDay = currentDay
        let endDay = currentDay + phase.length - 1
        ranges.append(PhaseDayRange(phase: phase, startDay: startDay, endDay: endDay))
        currentDay = endDay + 1
    }
    return ranges
}
