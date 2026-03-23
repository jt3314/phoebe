import Foundation

/// Handles CRUD operations for tasks (project tasks, standalone tasks, milestones).
struct TaskService {

    // MARK: - Project Tasks

    func fetchTasksForProject(_ projectId: UUID) async throws -> [Task_] {
        try await supabase
            .from("tasks")
            .select()
            .eq("project_id", value: projectId.uuidString)
            .order("sort_order")
            .execute()
            .value
    }

    func fetchTasksForDate(_ date: String, userId: UUID) async throws -> [Task_] {
        // Fetch project IDs for this user, then tasks for those projects on this date
        let projects: [Project] = try await supabase
            .from("projects")
            .select("id")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        let projectIds = projects.map(\.id.uuidString)
        guard !projectIds.isEmpty else { return [] }

        return try await supabase
            .from("tasks")
            .select()
            .in("project_id", values: projectIds)
            .eq("scheduled_date", value: date)
            .order("sort_order")
            .execute()
            .value
    }

    struct NewTask: Encodable {
        let project_id: String
        let milestone_id: String?
        let name: String
        let description: String?
        let effort_points: Int
        let sort_order: Int
    }

    func createTask(_ task: NewTask) async throws -> Task_ {
        try await supabase
            .from("tasks")
            .insert(task)
            .select()
            .single()
            .execute()
            .value
    }

    struct UpdateTask: Encodable {
        var name: String?
        var description: String?
        var effort_points: Int?
        var milestone_id: String?
        var status: String?
        var scheduled_date: String?
        var completed_date: String?
        var sort_order: Int?
    }

    func updateTask(id: UUID, data: UpdateTask) async throws {
        try await supabase
            .from("tasks")
            .update(data)
            .eq("id", value: id.uuidString)
            .execute()
    }

    func deleteTask(id: UUID) async throws {
        try await supabase
            .from("tasks")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    func completeTask(id: UUID) async throws {
        let today = CycleCalculator.formatISO(Date())
        try await updateTask(id: id, data: UpdateTask(
            status: "completed",
            completed_date: today
        ))
    }

    func uncompleteTask(id: UUID) async throws {
        try await updateTask(id: id, data: UpdateTask(
            status: "scheduled",
            completed_date: ""
        ))
    }

    // MARK: - Standalone Tasks

    func fetchStandaloneTasksForDate(_ date: String, userId: UUID) async throws -> [StandaloneTask] {
        try await supabase
            .from("standalone_tasks")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("scheduled_date", value: date)
            .execute()
            .value
    }

    func fetchAllStandaloneTasks(userId: UUID) async throws -> [StandaloneTask] {
        try await supabase
            .from("standalone_tasks")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
    }

    struct NewStandaloneTask: Encodable {
        let user_id: String
        let name: String
        let description: String?
        let effort_points: Int
        let scheduled_date: String?
    }

    func createStandaloneTask(_ task: NewStandaloneTask) async throws -> StandaloneTask {
        try await supabase
            .from("standalone_tasks")
            .insert(task)
            .select()
            .single()
            .execute()
            .value
    }

    func completeStandaloneTask(id: UUID) async throws {
        let today = CycleCalculator.formatISO(Date())
        try await supabase
            .from("standalone_tasks")
            .update(["status": "completed", "completed_date": today])
            .eq("id", value: id.uuidString)
            .execute()
    }

    func deleteStandaloneTask(id: UUID) async throws {
        try await supabase
            .from("standalone_tasks")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Milestones

    func fetchMilestones(projectId: UUID) async throws -> [Milestone] {
        try await supabase
            .from("milestones")
            .select()
            .eq("project_id", value: projectId.uuidString)
            .order("sort_order")
            .execute()
            .value
    }

    struct NewMilestone: Encodable {
        let project_id: String
        let name: String
        let description: String?
        let target_date: String?
        let sort_order: Int
    }

    func createMilestone(_ milestone: NewMilestone) async throws -> Milestone {
        try await supabase
            .from("milestones")
            .insert(milestone)
            .select()
            .single()
            .execute()
            .value
    }

    struct UpdateMilestone: Encodable {
        var name: String?
        var description: String?
        var target_date: String?
        var status: String?
    }

    func updateMilestone(id: UUID, data: UpdateMilestone) async throws {
        try await supabase
            .from("milestones")
            .update(data)
            .eq("id", value: id.uuidString)
            .execute()
    }

    func deleteMilestone(id: UUID) async throws {
        try await supabase
            .from("milestones")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Dependencies

    func fetchTaskDependencies(projectId: UUID) async throws -> [TaskDependency] {
        try await supabase
            .from("task_dependencies")
            .select()
            .eq("project_id", value: projectId.uuidString)
            .execute()
            .value
    }
}
