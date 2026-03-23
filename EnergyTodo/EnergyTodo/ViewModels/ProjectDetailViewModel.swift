import Foundation

@Observable
final class ProjectDetailViewModel {

    var project: Project?
    var milestones: [Milestone] = []
    var tasks: [Task_] = []
    var dependencies: [TaskDependency] = []
    var isLoading = false
    var errorMessage: String?

    // Edit mode
    var isEditing = false
    var editName = ""
    var editDescription = ""
    var editDeadline = Date()
    var editPriority = 5
    var editType: ProjectType = .personal

    // Task form
    var showNewTask = false
    var newTaskName = ""
    var newTaskDescription = ""
    var newTaskEffort = 3
    var newTaskMilestoneId: UUID?

    // Milestone form
    var showNewMilestone = false
    var newMilestoneName = ""
    var newMilestoneDescription = ""
    var newMilestoneDate = Date()

    // Delete confirmation
    var showDeleteConfirm = false
    var deleteTarget: DeleteTarget?

    enum DeleteTarget {
        case project
        case milestone(UUID)
        case task(UUID)
    }

    private let projectService = ProjectService()
    private let taskService = TaskService()

    var standaloneTasks: [Task_] {
        tasks.filter { $0.milestoneId == nil }
    }

    func tasksForMilestone(_ milestoneId: UUID) -> [Task_] {
        tasks.filter { $0.milestoneId == milestoneId }
    }

    var totalEffort: Int {
        tasks.reduce(0) { $0 + $1.effortPoints }
    }

    var completedCount: Int {
        tasks.filter { $0.status == .completed }.count
    }

    // MARK: - Load

    func load(projectId: UUID) async {
        isLoading = true
        do {
            project = try await projectService.fetchById(projectId)
            milestones = try await taskService.fetchMilestones(projectId: projectId)
            tasks = try await taskService.fetchTasksForProject(projectId)
            dependencies = try await taskService.fetchTaskDependencies(projectId: projectId)

            if let p = project {
                editName = p.name
                editDescription = p.description ?? ""
                if let deadline = p.deadline, let d = CycleCalculator.parseISO(deadline) {
                    editDeadline = d
                }
                editPriority = p.priority
                editType = p.type
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Project Actions

    func saveProjectEdits() async {
        guard let project else { return }
        do {
            try await projectService.update(id: project.id, data: .init(
                name: editName,
                description: editDescription.isEmpty ? nil : editDescription,
                deadline: CycleCalculator.formatISO(editDeadline),
                priority: editPriority,
                type: editType.rawValue
            ))
            self.project?.name = editName
            self.project?.description = editDescription.isEmpty ? nil : editDescription
            self.project?.deadline = CycleCalculator.formatISO(editDeadline)
            self.project?.priority = editPriority
            self.project?.type = editType
            isEditing = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteProject() async {
        guard let project else { return }
        do {
            try await projectService.delete(id: project.id)
            self.project = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Task Actions

    func addTask() async {
        guard let project else { return }
        do {
            let newTask = TaskService.NewTask(
                project_id: project.id.uuidString,
                milestone_id: newTaskMilestoneId?.uuidString,
                name: newTaskName,
                description: newTaskDescription.isEmpty ? nil : newTaskDescription,
                effort_points: newTaskEffort,
                sort_order: tasks.count
            )
            let task = try await taskService.createTask(newTask)
            tasks.append(task)
            resetTaskForm()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleTaskCompletion(_ task: Task_) async {
        do {
            if task.status == .completed {
                try await taskService.uncompleteTask(id: task.id)
                if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
                    tasks[idx].status = .scheduled
                    tasks[idx].completedDate = nil
                }
            } else {
                try await taskService.completeTask(id: task.id)
                if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
                    tasks[idx].status = .completed
                    tasks[idx].completedDate = CycleCalculator.formatISO(Date())
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteTask(_ taskId: UUID) async {
        do {
            try await taskService.deleteTask(id: taskId)
            tasks.removeAll { $0.id == taskId }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func moveTasks(from source: IndexSet, to destination: Int) {
        tasks.move(fromOffsets: source, toOffset: destination)
        // Update sort orders
        for (index, _) in tasks.enumerated() {
            tasks[index].sortOrder = index
        }
    }

    // MARK: - Milestone Actions

    func addMilestone() async {
        guard let project else { return }
        do {
            let milestone = try await taskService.createMilestone(.init(
                project_id: project.id.uuidString,
                name: newMilestoneName,
                description: newMilestoneDescription.isEmpty ? nil : newMilestoneDescription,
                target_date: CycleCalculator.formatISO(newMilestoneDate),
                sort_order: milestones.count
            ))
            milestones.append(milestone)
            resetMilestoneForm()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteMilestone(_ milestoneId: UUID) async {
        do {
            try await taskService.deleteMilestone(id: milestoneId)
            milestones.removeAll { $0.id == milestoneId }
            // Tasks with this milestone get unassigned (DB handles SET NULL)
            for i in tasks.indices where tasks[i].milestoneId == milestoneId {
                tasks[i].milestoneId = nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Form Helpers

    private func resetTaskForm() {
        showNewTask = false
        newTaskName = ""
        newTaskDescription = ""
        newTaskEffort = 3
        newTaskMilestoneId = nil
    }

    private func resetMilestoneForm() {
        showNewMilestone = false
        newMilestoneName = ""
        newMilestoneDescription = ""
        newMilestoneDate = Date()
    }
}
