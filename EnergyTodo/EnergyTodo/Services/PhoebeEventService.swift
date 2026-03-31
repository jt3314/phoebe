import Foundation

/// CRUD operations for Phoebe-only events (self-care blocks, energy check-ins, rest blocks).
struct PhoebeEventService {

    func fetchForDate(userId: UUID, date: String) async throws -> [PhoebeEvent] {
        try await supabase
            .from("phoebe_events")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("date", value: date)
            .order("start_time")
            .execute()
            .value
    }

    func fetchForDateRange(userId: UUID, startDate: String, endDate: String) async throws -> [PhoebeEvent] {
        try await supabase
            .from("phoebe_events")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("date", value: startDate)
            .lte("date", value: endDate)
            .order("date")
            .execute()
            .value
    }

    func create(
        userId: UUID,
        name: String,
        description: String?,
        eventType: PhoebeEvent.EventType,
        date: String,
        startTime: String?,
        endTime: String?,
        effortCost: Int
    ) async throws -> PhoebeEvent {
        let row = PhoebeEventInsert(
            userId: userId.uuidString,
            name: name,
            description: description,
            eventType: eventType.rawValue,
            date: date,
            startTime: startTime,
            endTime: endTime,
            effortCost: effortCost
        )

        return try await supabase
            .from("phoebe_events")
            .insert(row)
            .select()
            .single()
            .execute()
            .value
    }

    func delete(id: UUID) async throws {
        try await supabase
            .from("phoebe_events")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}

private struct PhoebeEventInsert: Encodable {
    let userId: String
    let name: String
    let description: String?
    let eventType: String
    let date: String
    let startTime: String?
    let endTime: String?
    let effortCost: Int

    enum CodingKeys: String, CodingKey {
        case name, description, date
        case userId = "user_id"
        case eventType = "event_type"
        case startTime = "start_time"
        case endTime = "end_time"
        case effortCost = "effort_cost"
    }
}
