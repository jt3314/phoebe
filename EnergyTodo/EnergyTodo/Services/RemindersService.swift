import Foundation

struct RemindersService {
    func fetchSources() async throws -> [ReminderSource] {
        try await supabase.from("reminder_sources").select().execute().value
    }

    func fetchReminders(sourceIds: [UUID]) async throws -> [Reminder] {
        guard !sourceIds.isEmpty else { return [] }
        return try await supabase.from("reminders").select()
            .in("source_id", values: sourceIds.map(\.uuidString))
            .execute().value
    }

    func fetchUserSources(userId: UUID) async throws -> [UserReminderSource] {
        try await supabase.from("user_reminder_sources").select()
            .eq("user_id", value: userId.uuidString).execute().value
    }

    func toggleSource(userId: UUID, sourceId: UUID, enabled: Bool) async throws {
        struct URS: Encodable {
            let user_id: String; let source_id: String; let enabled: Bool
        }
        try await supabase.from("user_reminder_sources")
            .upsert(URS(user_id: userId.uuidString, source_id: sourceId.uuidString, enabled: enabled))
            .execute()
    }

    func saveFeatureInterest(userId: UUID, featureType: String, responses: String, notify: Bool) async throws {
        struct FI: Encodable {
            let user_id: String; let feature_type: String; let responses: String; let notify_on_launch: Bool
        }
        try await supabase.from("feature_interests")
            .insert(FI(user_id: userId.uuidString, feature_type: featureType, responses: responses, notify_on_launch: notify))
            .execute()
    }
}
