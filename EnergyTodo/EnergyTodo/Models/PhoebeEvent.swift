import Foundation

struct PhoebeEvent: Codable, Identifiable, Sendable {
    let id: UUID
    let userId: UUID
    var name: String
    var description: String?
    var eventType: EventType
    var date: String // ISO date (YYYY-MM-DD)
    var startTime: String? // HH:mm format
    var endTime: String? // HH:mm format
    var effortCost: Int
    let createdAt: Date
    var updatedAt: Date

    enum EventType: String, Codable, CaseIterable, Sendable {
        case selfCare = "self_care"
        case energyCheckin = "energy_checkin"
        case restBlock = "rest_block"

        var label: String {
            switch self {
            case .selfCare: return "Self Care"
            case .energyCheckin: return "Energy Check-in"
            case .restBlock: return "Rest Block"
            }
        }

        var icon: String {
            switch self {
            case .selfCare: return "heart.fill"
            case .energyCheckin: return "bolt.fill"
            case .restBlock: return "moon.fill"
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, name, description, date
        case userId = "user_id"
        case eventType = "event_type"
        case startTime = "start_time"
        case endTime = "end_time"
        case effortCost = "effort_cost"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
