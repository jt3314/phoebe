import SwiftUI

struct ProjectDetailView: View {
    let projectId: UUID
    @Bindable var authVM: AuthViewModel
    @State private var vm = ProjectDetailViewModel()

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vm.project == nil {
                Text("Project not found or deleted.")
                    .foregroundStyle(.secondary)
            } else {
                projectContent
            }
        }
        .navigationTitle(vm.project?.name ?? "Project")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if vm.project != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button { vm.isEditing.toggle() } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            vm.deleteTarget = .project
                            vm.showDeleteConfirm = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $vm.showNewTask) {
            newTaskSheet
        }
        .sheet(isPresented: $vm.showNewMilestone) {
            newMilestoneSheet
        }
        .alert("Delete", isPresented: $vm.showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    switch vm.deleteTarget {
                    case .project: await vm.deleteProject()
                    case .milestone(let id): await vm.deleteMilestone(id)
                    case .task(let id): await vm.deleteTask(id)
                    case .none: break
                    }
                }
            }
        } message: {
            switch vm.deleteTarget {
            case .project: Text("This will delete the project and all its milestones and tasks.")
            case .milestone: Text("Tasks in this milestone will be unassigned.")
            case .task: Text("This task will be permanently deleted.")
            case .none: Text("")
            }
        }
        .task {
            await vm.load(projectId: projectId)
        }
    }

    // MARK: - Project Content

    private var projectContent: some View {
        List {
            // Project info section
            Section("Info") {
                if vm.isEditing {
                    editForm
                } else {
                    projectInfoView
                }
            }

            // Milestones section
            Section {
                ForEach(vm.milestones) { milestone in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(milestone.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            if let date = milestone.targetDate {
                                Text(date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        let milestoneTasks = vm.tasksForMilestone(milestone.id)
                        ForEach(milestoneTasks) { task in
                            taskRow(task)
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            vm.deleteTarget = .milestone(milestone.id)
                            vm.showDeleteConfirm = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Milestones")
                    Spacer()
                    Button { vm.showNewMilestone = true } label: {
                        Image(systemName: "plus.circle")
                    }
                }
            }

            // Standalone tasks section
            Section {
                ForEach(vm.standaloneTasks) { task in
                    taskRow(task)
                }
                .onMove { from, to in
                    vm.moveTasks(from: from, to: to)
                }
            } header: {
                HStack {
                    Text("Tasks")
                    Spacer()
                    Button { vm.showNewTask = true } label: {
                        Image(systemName: "plus.circle")
                    }
                }
            } footer: {
                Text("\(vm.completedCount)/\(vm.tasks.count) tasks  \(vm.totalEffort) pts total")
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Task Row

    private func taskRow(_ task: Task_) -> some View {
        HStack(spacing: 10) {
            Button {
                Task { await vm.toggleTaskCompletion(task) }
            } label: {
                Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.status == .completed ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading) {
                Text(task.name)
                    .strikethrough(task.status == .completed)
                if let date = task.scheduledDate {
                    Text(date)
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
            }

            Spacer()

            EffortBadge(points: task.effortPoints)
        }
        .swipeActions {
            Button(role: .destructive) {
                vm.deleteTarget = .task(task.id)
                vm.showDeleteConfirm = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Project Info

    private var projectInfoView: some View {
        Group {
            if let desc = vm.project?.description, !desc.isEmpty {
                Text(desc).font(.subheadline).foregroundStyle(.secondary)
            }
            LabeledContent("Deadline", value: vm.project?.deadline ?? "None")
            LabeledContent("Priority", value: "\(vm.project?.priority ?? 0) - \(vm.project?.priorityLabel ?? "")")
            LabeledContent("Type", value: vm.project?.type.rawValue.capitalized ?? "")
            LabeledContent("Status", value: vm.project?.status.rawValue.capitalized ?? "")
        }
    }

    // MARK: - Edit Form

    private var editForm: some View {
        Group {
            TextField("Name", text: $vm.editName)
            TextField("Description", text: $vm.editDescription, axis: .vertical)
            DatePicker("Deadline", selection: $vm.editDeadline, displayedComponents: .date)
            Picker("Priority", selection: $vm.editPriority) {
                ForEach(1...10, id: \.self) { Text("\($0)").tag($0) }
            }
            Picker("Type", selection: $vm.editType) {
                Text("Personal").tag(ProjectType.personal)
                Text("Professional").tag(ProjectType.professional)
            }
            HStack {
                Button("Cancel") { vm.isEditing = false }
                Spacer()
                Button("Save") { Task { await vm.saveProjectEdits() } }
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - New Task Sheet

    private var newTaskSheet: some View {
        NavigationStack {
            Form {
                TextField("Task Name", text: $vm.newTaskName)
                TextField("Description (optional)", text: $vm.newTaskDescription, axis: .vertical)
                Picker("Effort Points", selection: $vm.newTaskEffort) {
                    ForEach(1...15, id: \.self) { Text("\($0)").tag($0) }
                }
                Picker("Milestone", selection: $vm.newTaskMilestoneId) {
                    Text("No milestone").tag(nil as UUID?)
                    ForEach(vm.milestones) { ms in
                        Text(ms.name).tag(ms.id as UUID?)
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { vm.showNewTask = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { Task { await vm.addTask() } }
                        .disabled(vm.newTaskName.isEmpty)
                }
            }
        }
    }

    // MARK: - New Milestone Sheet

    private var newMilestoneSheet: some View {
        NavigationStack {
            Form {
                TextField("Milestone Name", text: $vm.newMilestoneName)
                TextField("Description (optional)", text: $vm.newMilestoneDescription, axis: .vertical)
                DatePicker("Target Date", selection: $vm.newMilestoneDate, displayedComponents: .date)
            }
            .navigationTitle("New Milestone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { vm.showNewMilestone = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { Task { await vm.addMilestone() } }
                        .disabled(vm.newMilestoneName.isEmpty)
                }
            }
        }
    }
}
