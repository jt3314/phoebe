import Foundation

struct TaskDependency: Codable, Identifiable, Sendable {
    let id: UUID
    let taskId: UUID
    let dependsOnTaskId: UUID
    let projectId: UUID

    enum CodingKeys: String, CodingKey {
        case id
        case taskId = "task_id"
        case dependsOnTaskId = "depends_on_task_id"
        case projectId = "project_id"
    }
}

struct MilestoneDependency: Codable, Identifiable, Sendable {
    let id: UUID
    let milestoneId: UUID
    let dependsOnMilestoneId: UUID
    let projectId: UUID

    enum CodingKeys: String, CodingKey {
        case id
        case milestoneId = "milestone_id"
        case dependsOnMilestoneId = "depends_on_milestone_id"
        case projectId = "project_id"
    }
}
