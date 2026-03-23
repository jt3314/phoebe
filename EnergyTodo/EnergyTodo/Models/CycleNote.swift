import Foundation

struct CycleNote: Codable, Identifiable, Sendable {
    let id: UUID
    let userId: UUID
    var cycleDay: Int
    var content: String
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, content
        case userId = "user_id"
        case cycleDay = "cycle_day"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
