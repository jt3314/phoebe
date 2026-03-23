import Foundation

struct StandaloneTask: Codable, Identifiable, Sendable {
    let id: UUID
    let userId: UUID
    var name: String
    var description: String?
    var effortPoints: Int
    var scheduledDate: String?
    var completedDate: String?
    var status: TaskStatus
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, description, status
        case userId = "user_id"
        case effortPoints = "effort_points"
        case scheduledDate = "scheduled_date"
        case completedDate = "completed_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
