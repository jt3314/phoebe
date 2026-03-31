import Foundation

struct Nudge: Identifiable {
    let id = UUID()
    let type: NudgeType
    let title: String
    let body: String
    let severity: NudgeSeverity

    enum NudgeType {
        case heavyCalendarLowEnergy
        case tomorrowLookahead
        case overbooked
        case backToBackMeetings
    }

    enum NudgeSeverity {
        case info
        case warning
        case critical
    }
}
