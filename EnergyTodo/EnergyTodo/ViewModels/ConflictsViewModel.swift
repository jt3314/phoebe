import Foundation

@Observable
final class ConflictsViewModel {

    var conflicts: [SchedulingConflict] = []
    var isLoading = false
    var errorMessage: String?

    // Project name lookup
    var projectNames: [UUID: String] = [:]

    private let conflictService = ConflictService()
    private let projectService = ProjectService()

    func load(userId: UUID) async {
        isLoading = true
        do {
            conflicts = try await conflictService.fetchAll(userId: userId)
            // Fetch project names
            let projectIds = Set(conflicts.compactMap(\.projectId))
            for pid in projectIds where projectNames[pid] == nil {
                if let project = try? await projectService.fetchById(pid) {
                    projectNames[pid] = project.name
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func resolveConflict(_ conflict: SchedulingConflict) async {
        do {
            try await conflictService.resolve(id: conflict.id)
            conflicts.removeAll { $0.id == conflict.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
