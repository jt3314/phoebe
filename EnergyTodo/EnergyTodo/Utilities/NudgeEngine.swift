import Foundation

/// Pure functions for generating energy-aware nudges based on calendar + cycle state.
enum NudgeEngine {

    struct NudgeInput {
        let cycleDay: Int
        let baseEffort: Int
        let googleEvents: [GoogleCalendarEvent]
        let tomorrowGoogleEvents: [GoogleCalendarEvent]
        let tomorrowBaseEffort: Int
        let sleepCheck: SleepCheck?
        let totalScheduledTaskEffort: Int
        let totalAvailableEffort: Int
    }

    static func generateNudges(input: NudgeInput) -> [Nudge] {
        var nudges: [Nudge] = []

        let googleEffort = input.googleEvents.reduce(0) { $0 + $1.effortCost }

        // Rule 1: Heavy meeting load on low-energy cycle day
        if input.baseEffort <= 5 && googleEffort > 0 && Double(googleEffort) > Double(input.baseEffort) * 0.5 {
            nudges.append(Nudge(
                type: .heavyCalendarLowEnergy,
                title: "Heavy calendar on a low-energy day",
                body: "You have \(input.googleEvents.count) event\(input.googleEvents.count == 1 ? "" : "s") using \(googleEffort) effort points on a day with only \(input.baseEffort) base energy. Consider lighter tasks today.",
                severity: .warning
            ))
        }

        // Rule 2: Tomorrow lookahead
        let tomorrowGoogleEffort = input.tomorrowGoogleEvents.reduce(0) { $0 + $1.effortCost }
        if input.tomorrowBaseEffort <= 5 && tomorrowGoogleEffort > 0 && Double(tomorrowGoogleEffort) > Double(input.tomorrowBaseEffort) * 0.5 {
            nudges.append(Nudge(
                type: .tomorrowLookahead,
                title: "Busy day ahead tomorrow",
                body: "Tomorrow is a lower-energy day with \(input.tomorrowGoogleEvents.count) event\(input.tomorrowGoogleEvents.count == 1 ? "" : "s"). Consider getting ahead on tasks today.",
                severity: .info
            ))
        }

        // Rule 3: Overbooked
        let totalCommitted = input.totalScheduledTaskEffort + googleEffort
        if totalCommitted > input.totalAvailableEffort && input.totalAvailableEffort > 0 {
            let overBy = totalCommitted - input.totalAvailableEffort
            nudges.append(Nudge(
                type: .overbooked,
                title: "You're overbooked today",
                body: "You're \(overBy) points over your available effort. Consider moving some tasks to another day.",
                severity: .critical
            ))
        }

        // Rule 4: Back-to-back meetings (3+ events with <15 min gaps)
        let timedEvents = input.googleEvents.filter { !$0.isAllDay }.sorted { $0.startTime < $1.startTime }
        if timedEvents.count >= 3 {
            var consecutiveCount = 1
            for i in 1..<timedEvents.count {
                let gap = timedEvents[i].startTime.timeIntervalSince(timedEvents[i-1].endTime)
                if gap < 15 * 60 { // less than 15 minutes
                    consecutiveCount += 1
                } else {
                    consecutiveCount = 1
                }
                if consecutiveCount >= 3 {
                    nudges.append(Nudge(
                        type: .backToBackMeetings,
                        title: "No breaks between meetings",
                        body: "You have \(consecutiveCount)+ meetings back-to-back. Try to find a moment to rest.",
                        severity: .warning
                    ))
                    break
                }
            }
        }

        return nudges
    }
}
