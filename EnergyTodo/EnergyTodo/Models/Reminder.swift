import Foundation

struct Reminder: Codable, Identifiable, Sendable {
    let id: UUID
    let sourceId: UUID
    let category: String // overview, energy, fitness, food
    let title: String
    let body: String?
    let cycleDayMin: Int?
    let cycleDayMax: Int?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, category, title, body
        case sourceId = "source_id"
        case cycleDayMin = "cycle_day_min"
        case cycleDayMax = "cycle_day_max"
        case createdAt = "created_at"
    }
}
