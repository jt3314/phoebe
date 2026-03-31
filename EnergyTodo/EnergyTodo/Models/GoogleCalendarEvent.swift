import Foundation

struct GoogleCalendarEvent: Codable, Identifiable, Sendable {
    let id: UUID
    let userId: UUID
    let googleEventId: String
    var summary: String
    var startTime: Date
    var endTime: Date
    var date: String // ISO date (YYYY-MM-DD) for the day it falls on
    var effortCost: Int // derived from duration
    var isAllDay: Bool
    let syncedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, summary, date
        case userId = "user_id"
        case googleEventId = "google_event_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case effortCost = "effort_cost"
        case isAllDay = "is_all_day"
        case syncedAt = "synced_at"
    }

    /// Calculate effort cost from event duration.
    /// 1 point per 30 minutes, capped at 8. All-day events = 3 points.
    static func effortCost(startTime: Date, endTime: Date, isAllDay: Bool) -> Int {
        if isAllDay { return 3 }
        let minutes = endTime.timeIntervalSince(startTime) / 60.0
        return min(8, max(1, Int(ceil(minutes / 30.0))))
    }
}
