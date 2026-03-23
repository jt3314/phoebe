import Foundation

enum MilestoneStatus: String, Codable, Sendable, CaseIterable {
    case pending
    case inProgress = "in_progress"
    case completed
}

struct Milestone: Codable, Identifiable, Sendable {
    let id: UUID
    let projectId: UUID
    var name: String
    var description: String?
    var targetDate: String?
    var status: MilestoneStatus
    var sortOrder: Int
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, description, status
        case projectId = "project_id"
        case targetDate = "target_date"
        case sortOrder = "sort_order"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
