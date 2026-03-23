import Foundation

struct CycleSeason: Sendable {
    let id: String
    let name: String
    let phaseId: CyclePhaseId
    let phaseLabel: String
    let description: String
    let color: String
    let emoji: String
}

let CYCLE_SEASONS: [CycleSeason] = [
    CycleSeason(
        id: "winter",
        name: "Winter",
        phaseId: .menstrual,
        phaseLabel: "Menstrual",
        description: "Time to slow down and rest. Honor your body's need for quiet and recovery.",
        color: "#94A3B8",
        emoji: "❄️"
    ),
    CycleSeason(
        id: "spring",
        name: "Spring",
        phaseId: .follicular,
        phaseLabel: "Follicular",
        description: "Fresh energy is building. A great time to start new projects and plan ahead.",
        color: "#86EFAC",
        emoji: "🌱"
    ),
    CycleSeason(
        id: "summer",
        name: "Summer",
        phaseId: .ovulation,
        phaseLabel: "Ovulation",
        description: "You're at your peak. Take on your biggest challenges and connect with others.",
        color: "#FDE68A",
        emoji: "☀️"
    ),
    CycleSeason(
        id: "autumn",
        name: "Autumn",
        phaseId: .luteal,
        phaseLabel: "Luteal",
        description: "Winding down. Focus on completing tasks and preparing for rest.",
        color: "#FDBA74",
        emoji: "🍂"
    ),
]

/// Returns the season associated with a given phase ID.
func getSeasonForPhase(phaseId: CyclePhaseId) -> CycleSeason? {
    return CYCLE_SEASONS.first { $0.phaseId == phaseId }
}

/// Returns the current season for a given cycle day and cycle length.
func getCurrentSeason(cycleDay: Int, cycleLength: Int) -> CycleSeason? {
    guard let phaseInfo = getCurrentPhase(cycleDay: cycleDay, cycleLength: cycleLength) else {
        return nil
    }
    return getSeasonForPhase(phaseId: phaseInfo.phase.id)
}
