import Foundation

struct Cycle: Codable, Identifiable, Sendable {
    let id: UUID
    let userId: UUID
    var length: Int
    var day1Date: String // ISO date "YYYY-MM-DD"
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, length
        case userId = "user_id"
        case day1Date = "day1_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct CycleEffortPoint: Codable, Identifiable, Sendable {
    let id: UUID
    let cycleId: UUID
    let dayNumber: Int
    var effortPoints: Int

    enum CodingKeys: String, CodingKey {
        case id
        case cycleId = "cycle_id"
        case dayNumber = "day_number"
        case effortPoints = "effort_points"
    }
}

struct WeekendOverride: Codable, Identifiable, Sendable {
    let id: UUID
    let cycleId: UUID
    let date: String
    var effortPoints: Int

    enum CodingKeys: String, CodingKey {
        case id, date
        case cycleId = "cycle_id"
        case effortPoints = "effort_points"
    }
}
