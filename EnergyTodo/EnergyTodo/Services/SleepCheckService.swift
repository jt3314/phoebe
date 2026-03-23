import Foundation

/// Handles sleep check operations.
struct SleepCheckService {

    /// Fetch sleep check for a specific date.
    func fetch(userId: UUID, date: String) async throws -> SleepCheck? {
        let checks: [SleepCheck] = try await supabase
            .from("sleep_checks")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("date", value: date)
            .limit(1)
            .execute()
            .value
        return checks.first
    }

    /// Record a sleep check for today.
    func record(userId: UUID, date: String, sleptPoorly: Bool) async throws -> SleepCheck {
        struct NewSleepCheck: Encodable {
            let user_id: String
            let date: String
            let slept_poorly: Bool
            let effort_reduction: Int
        }

        return try await supabase
            .from("sleep_checks")
            .upsert(NewSleepCheck(
                user_id: userId.uuidString,
                date: date,
                slept_poorly: sleptPoorly,
                effort_reduction: sleptPoorly ? 1 : 0
            ))
            .select()
            .single()
            .execute()
            .value
    }
}
