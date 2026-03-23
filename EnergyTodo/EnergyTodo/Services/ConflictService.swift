import Foundation

/// Handles scheduling conflict operations.
struct ConflictService {

    func fetchAll(userId: UUID) async throws -> [SchedulingConflict] {
        try await supabase
            .from("scheduling_conflicts")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("resolved", value: false)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func resolve(id: UUID) async throws {
        try await supabase
            .from("scheduling_conflicts")
            .update(["resolved": true])
            .eq("id", value: id.uuidString)
            .execute()
    }
}
