import Foundation

/// Handles fixed event operations.
struct FixedEventService {

    func fetchForDate(userId: UUID, date: String) async throws -> [FixedEvent] {
        try await supabase
            .from("fixed_events")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("date", value: date)
            .execute()
            .value
    }

    func fetchAll(userId: UUID) async throws -> [FixedEvent] {
        try await supabase
            .from("fixed_events")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("date")
            .execute()
            .value
    }
}
