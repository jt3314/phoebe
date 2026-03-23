import Foundation

enum ProjectType: String, Codable, Sendable, CaseIterable {
    case personal
    case professional
}

enum ProjectStatus: String, Codable, Sendable, CaseIterable {
    case active
    case completed
    case archived
}

struct Project: Codable, Identifiable, Sendable {
    let id: UUID
    let userId: UUID
    var name: String
    var description: String?
    var deadline: String? // ISO date
    var priority: Int
    var type: ProjectType
    var weekendEnabled: Bool
    var status: ProjectStatus
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, description, deadline, priority, type, status
        case userId = "user_id"
        case weekendEnabled = "weekend_enabled"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var priorityLabel: String {
        switch priority {
        case 1...3: return "Low"
        case 4...6: return "Medium"
        case 7...10: return "High"
        default: return "Medium"
        }
    }
}
