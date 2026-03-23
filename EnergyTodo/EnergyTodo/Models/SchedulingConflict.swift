import Foundation

enum ConflictType: String, Codable, Sendable {
    case impossibleDeadline = "impossible_deadline"
    case overbookedDay = "overbooked_day"
    case dependencyLoop = "dependency_loop"
}

enum ConflictSeverity: String, Codable, Sendable {
    case critical
    case warning
}

struct SchedulingConflict: Codable, Identifiable, Sendable {
    let id: UUID
    let userId: UUID
    let projectId: UUID?
    let type: ConflictType
    let description: String
    let affectedDates: String? // JSON array
    let severity: ConflictSeverity
    let suggestion: String?
    var resolved: Bool
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, type, description, severity, suggestion, resolved
        case userId = "user_id"
        case projectId = "project_id"
        case affectedDates = "affected_dates"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
