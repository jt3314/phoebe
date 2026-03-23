import Foundation

struct UserReminderSource: Codable, Identifiable, Sendable {
    let id: UUID
    let userId: UUID
    let sourceId: UUID
    var enabled: Bool

    enum CodingKeys: String, CodingKey {
        case id, enabled
        case userId = "user_id"
        case sourceId = "source_id"
    }
}
