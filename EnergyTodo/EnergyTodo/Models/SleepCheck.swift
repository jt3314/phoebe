import Foundation

struct SleepCheck: Codable, Identifiable, Sendable {
    let id: UUID
    let userId: UUID
    let date: String
    var sleptPoorly: Bool
    var effortReduction: Int
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, date
        case userId = "user_id"
        case sleptPoorly = "slept_poorly"
        case effortReduction = "effort_reduction"
        case createdAt = "created_at"
    }
}
