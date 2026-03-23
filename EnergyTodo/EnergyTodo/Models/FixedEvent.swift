import Foundation

struct FixedEvent: Codable, Identifiable, Sendable {
    let id: UUID
    let userId: UUID
    var name: String
    var effortCost: Int
    var date: String
    var recurringPattern: String? // JSON string
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, date
        case userId = "user_id"
        case effortCost = "effort_cost"
        case recurringPattern = "recurring_pattern"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
