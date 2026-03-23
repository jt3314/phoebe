import Foundation

struct DailyNote: Codable, Identifiable, Sendable {
    let id: UUID
    let userId: UUID
    var date: String
    var content: String
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, date, content
        case userId = "user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
