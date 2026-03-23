import Foundation

/// Calls the Supabase Edge Function to schedule tasks across projects.
struct SchedulerService {

    struct ScheduleRequest: Encodable {
        let userId: String
    }

    struct ScheduleResponse: Decodable {
        let scheduledTasks: [ScheduledTaskResult]
        let conflicts: [ConflictResult]
    }

    struct ScheduledTaskResult: Decodable {
        let taskId: String
        let scheduledDate: String
    }

    struct ConflictResult: Decodable {
        let projectId: String
        let type: String
        let description: String
        let suggestedAction: String?
    }

    /// Schedule all unscheduled tasks for a user by calling the Edge Function.
    func scheduleAllTasks(userId: UUID) async throws -> ScheduleResponse {
        try await supabase.functions.invoke(
            "schedule-tasks",
            options: .init(body: ScheduleRequest(userId: userId.uuidString))
        )
    }
}
