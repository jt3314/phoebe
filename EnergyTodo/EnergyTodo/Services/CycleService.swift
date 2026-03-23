import Foundation

/// Handles CRUD operations for cycles and cycle effort points.
struct CycleService {

    /// Fetch the user's cycle (there should be at most one).
    func fetchCycle(userId: UUID) async throws -> Cycle? {
        let cycles: [Cycle] = try await supabase
            .from("cycles")
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value
        return cycles.first
    }

    /// Create a new cycle with default effort points.
    func createCycle(userId: UUID, length: Int, day1Date: String) async throws -> Cycle {
        struct NewCycle: Encodable {
            let user_id: String
            let length: Int
            let day1_date: String
        }

        let cycle: Cycle = try await supabase
            .from("cycles")
            .insert(NewCycle(user_id: userId.uuidString, length: length, day1_date: day1Date))
            .select()
            .single()
            .execute()
            .value

        // Create default effort points
        let effortArray = EffortCalculator.generateDefaultEffortPointsArray(cycleLength: length)

        struct NewEffortPoint: Encodable {
            let cycle_id: String
            let day_number: Int
            let effort_points: Int
        }

        let effortRows = effortArray.map {
            NewEffortPoint(
                cycle_id: cycle.id.uuidString,
                day_number: $0.dayNumber,
                effort_points: $0.effortPoints
            )
        }

        try await supabase
            .from("cycle_effort_points")
            .insert(effortRows)
            .execute()

        return cycle
    }

    /// Update cycle day1 date (restart cycle).
    func updateDay1Date(cycleId: UUID, day1Date: String) async throws {
        try await supabase
            .from("cycles")
            .update(["day1_date": day1Date])
            .eq("id", value: cycleId.uuidString)
            .execute()
    }

    /// Update cycle length.
    func updateLength(cycleId: UUID, newLength: Int, oldLength: Int) async throws {
        try await supabase
            .from("cycles")
            .update(["length": newLength])
            .eq("id", value: cycleId.uuidString)
            .execute()

        // If expanding, add new effort point rows
        if newLength > oldLength {
            struct NewEffortPoint: Encodable {
                let cycle_id: String
                let day_number: Int
                let effort_points: Int
            }

            let newRows = ((oldLength + 1)...newLength).map { day in
                NewEffortPoint(
                    cycle_id: cycleId.uuidString,
                    day_number: day,
                    effort_points: EffortCalculator.getDefaultEffortForCycleDay(day)
                )
            }

            try await supabase
                .from("cycle_effort_points")
                .insert(newRows)
                .execute()
        }
    }

    /// Fetch effort points for a cycle.
    func fetchEffortPoints(cycleId: UUID) async throws -> [CycleEffortPoint] {
        try await supabase
            .from("cycle_effort_points")
            .select()
            .eq("cycle_id", value: cycleId.uuidString)
            .order("day_number")
            .execute()
            .value
    }

    /// Fetch weekend overrides for a cycle.
    func fetchWeekendOverrides(cycleId: UUID) async throws -> [WeekendOverride] {
        try await supabase
            .from("weekend_overrides")
            .select()
            .eq("cycle_id", value: cycleId.uuidString)
            .execute()
            .value
    }
}
