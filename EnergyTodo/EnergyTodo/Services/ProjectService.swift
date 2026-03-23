import Foundation

/// Handles CRUD operations for projects.
struct ProjectService {

    func fetchActive(userId: UUID) async throws -> [Project] {
        try await supabase
            .from("projects")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("status", value: "active")
            .order("priority", ascending: false)
            .execute()
            .value
    }

    func fetchAll(userId: UUID) async throws -> [Project] {
        try await supabase
            .from("projects")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("priority", ascending: false)
            .execute()
            .value
    }

    func fetchById(_ id: UUID) async throws -> Project {
        try await supabase
            .from("projects")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
    }

    struct NewProject: Encodable {
        let user_id: String
        let name: String
        let description: String?
        let deadline: String?
        let priority: Int
        let type: String
        let weekend_enabled: Bool
    }

    func create(_ project: NewProject) async throws -> Project {
        try await supabase
            .from("projects")
            .insert(project)
            .select()
            .single()
            .execute()
            .value
    }

    struct UpdateProject: Encodable {
        var name: String?
        var description: String?
        var deadline: String?
        var priority: Int?
        var type: String?
        var weekend_enabled: Bool?
        var status: String?
    }

    func update(id: UUID, data: UpdateProject) async throws {
        try await supabase
            .from("projects")
            .update(data)
            .eq("id", value: id.uuidString)
            .execute()
    }

    func delete(id: UUID) async throws {
        try await supabase
            .from("projects")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}
