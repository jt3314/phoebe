import Foundation

struct NotesService {
    // Daily Notes
    func fetchDailyNote(userId: UUID, date: String) async throws -> DailyNote? {
        let notes: [DailyNote] = try await supabase
            .from("daily_notes").select()
            .eq("user_id", value: userId.uuidString)
            .eq("date", value: date)
            .limit(1).execute().value
        return notes.first
    }

    func upsertDailyNote(userId: UUID, date: String, content: String) async throws -> DailyNote {
        struct NewNote: Encodable {
            let user_id: String; let date: String; let content: String
        }
        return try await supabase.from("daily_notes")
            .upsert(NewNote(user_id: userId.uuidString, date: date, content: content))
            .select().single().execute().value
    }

    func deleteDailyNote(id: UUID) async throws {
        try await supabase.from("daily_notes").delete().eq("id", value: id.uuidString).execute()
    }

    // Cycle Notes
    func fetchCycleNotes(userId: UUID, cycleDays: [Int]) async throws -> [CycleNote] {
        try await supabase.from("cycle_notes").select()
            .eq("user_id", value: userId.uuidString)
            .in("cycle_day", values: cycleDays.map(String.init))
            .execute().value
    }

    func upsertCycleNote(userId: UUID, cycleDay: Int, content: String) async throws -> CycleNote {
        struct NewNote: Encodable {
            let user_id: String; let cycle_day: Int; let content: String
        }
        return try await supabase.from("cycle_notes")
            .upsert(NewNote(user_id: userId.uuidString, cycle_day: cycleDay, content: content))
            .select().single().execute().value
    }

    func deleteCycleNote(id: UUID) async throws {
        try await supabase.from("cycle_notes").delete().eq("id", value: id.uuidString).execute()
    }
}
