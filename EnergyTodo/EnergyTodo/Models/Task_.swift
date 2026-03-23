import Foundation

enum TaskStatus: String, Codable, Sendable, CaseIterable {
    case pending
    case scheduled
    case completed
}

/// Named Task_ to avoid collision with Swift.Task
struct Task_: Codable, Identifiable, Sendable {
    let id: UUID
    let projectId: UUID
    var milestoneId: UUID?
    var name: String
    var description: String?
    var effortPoints: Int
    var timeEstimate: Int? // minutes
    var scheduledDate: String?
    var completedDate: String?
    var status: TaskStatus
    var sortOrder: Int
    var recurringPattern: String?
    var recurringOverrideDate: String?
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, description, status
        case projectId = "project_id"
        case milestoneId = "milestone_id"
        case effortPoints = "effort_points"
        case timeEstimate = "time_estimate"
        case scheduledDate = "scheduled_date"
        case completedDate = "completed_date"
        case sortOrder = "sort_order"
        case recurringPattern = "recurring_pattern"
        case recurringOverrideDate = "recurring_override_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
