import Foundation

@Observable
final class ProjectsViewModel {

    var projects: [Project] = []
    var isLoading = false
    var errorMessage: String?

    // New project form
    var showNewProject = false
    var newName = ""
    var newDescription = ""
    var newDeadline = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    var newPriority = 5
    var newType: ProjectType = .personal

    // Scheduling
    var isScheduling = false
    var scheduleResult: SchedulerService.ScheduleResponse?
    var showScheduleResult = false

    private let projectService = ProjectService()
    private let taskService = TaskService()
    private let schedulerService = SchedulerService()

    // Task counts per project for display
    var taskCounts: [UUID: (total: Int, completed: Int, effort: Int)] = [:]

    func load(userId: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            projects = try await projectService.fetchActive(userId: userId)

            // Fetch task counts for each project
            for project in projects {
                let tasks = try await taskService.fetchTasksForProject(project.id)
                let completed = tasks.filter { $0.status == .completed }.count
                let effort = tasks.reduce(0) { $0 + $1.effortPoints }
                taskCounts[project.id] = (total: tasks.count, completed: completed, effort: effort)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    var unscheduledTaskCount: Int {
        taskCounts.values.reduce(0) { sum, counts in
            sum + counts.total - counts.completed
        }
    }

    func createProject(userId: UUID) async {
        errorMessage = nil
        do {
            let newProject = ProjectService.NewProject(
                user_id: userId.uuidString,
                name: newName,
                description: newDescription.isEmpty ? nil : newDescription,
                deadline: CycleCalculator.formatISO(newDeadline),
                priority: newPriority,
                type: newType.rawValue,
                weekend_enabled: newType == .personal
            )
            let project = try await projectService.create(newProject)
            projects.insert(project, at: 0)
            taskCounts[project.id] = (total: 0, completed: 0, effort: 0)
            resetNewProjectForm()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteProject(_ project: Project) async {
        do {
            try await projectService.delete(id: project.id)
            projects.removeAll { $0.id == project.id }
            taskCounts.removeValue(forKey: project.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func archiveProject(_ project: Project) async {
        do {
            try await projectService.update(id: project.id, data: .init(status: "archived"))
            projects.removeAll { $0.id == project.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func scheduleAllTasks(userId: UUID) async {
        isScheduling = true
        do {
            scheduleResult = try await schedulerService.scheduleAllTasks(userId: userId)
            showScheduleResult = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isScheduling = false
    }

    private func resetNewProjectForm() {
        showNewProject = false
        newName = ""
        newDescription = ""
        newDeadline = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        newPriority = 5
        newType = .personal
    }
}
