import Foundation

struct ReminderSource: Codable, Identifiable, Sendable {
    let id: UUID
    let name: String
    let description: String?
    let url: String?
    let icon: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, description, url, icon
        case createdAt = "created_at"
    }
}
