import SwiftUI

struct ProjectsListView: View {
    @Bindable var authVM: AuthViewModel
    @State private var vm = ProjectsViewModel()

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            Group {
                if vm.isLoading {
                    ProgressView()
                        .tint(Theme.primary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.projects.isEmpty {
                    EmptyStateView(
                        icon: "folder.badge.plus",
                        title: "No projects yet",
                        message: "Create your first project to start scheduling tasks around your energy."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(vm.projects) { project in
                                NavigationLink(value: project.id) {
                                    ProjectCardView(project: project, counts: vm.taskCounts[project.id])
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        Task { await vm.deleteProject(project) }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    Button {
                                        Task { await vm.archiveProject(project) }
                                    } label: {
                                        Label("Archive", systemImage: "archivebox")
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
        }
        .navigationTitle("Tasks")
        .navigationDestination(for: UUID.self) { projectId in
            ProjectDetailView(projectId: projectId, authVM: authVM)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    if vm.unscheduledTaskCount > 0 {
                        Button {
                            Task {
                                if let userId = authVM.currentUserId {
                                    await vm.scheduleAllTasks(userId: userId)
                                }
                            }
                        } label: {
                            if vm.isScheduling {
                                ProgressView()
                            } else {
                                Label("Schedule", systemImage: "calendar.badge.clock")
                                    .foregroundStyle(Theme.primary)
                            }
                        }
                    }

                    Button {
                        vm.showNewProject = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Theme.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $vm.showNewProject) {
            NewProjectSheet(vm: vm, userId: authVM.currentUserId ?? UUID())
        }
        .alert("Schedule Result", isPresented: $vm.showScheduleResult) {
            Button("OK") { vm.showScheduleResult = false }
        } message: {
            if let result = vm.scheduleResult {
                Text("\(result.scheduledTasks.count) tasks scheduled. \(result.conflicts.count) conflicts found.")
            }
        }
        .task {
            if let userId = authVM.currentUserId {
                await vm.load(userId: userId)
            }
        }
    }
}

// MARK: - Project Card

struct ProjectCardView: View {
    let project: Project
    let counts: (total: Int, completed: Int, effort: Int)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(project.name)
                    .font(.headline)
                    .foregroundStyle(Theme.foreground)
                Spacer()
                PriorityBadge(priority: project.priority)
            }

            HStack(spacing: 8) {
                if let deadline = project.deadline {
                    Label(deadline, systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(Theme.mutedForeground)
                }

                Text(project.type.rawValue.capitalized)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(project.type == .professional ? Color.blue.opacity(0.12) : Theme.success.opacity(0.12))
                    .foregroundStyle(project.type == .professional ? .blue : Theme.success)
                    .clipShape(Capsule())

                if let counts {
                    Text("\(counts.completed)/\(counts.total) tasks")
                        .font(.caption)
                        .foregroundStyle(Theme.mutedForeground)
                    Text("\(counts.effort) pts")
                        .font(.caption)
                        .foregroundStyle(Theme.mutedForeground)
                }
            }

            if let desc = project.description, !desc.isEmpty {
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(Theme.mutedForeground)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.cardBorder, lineWidth: 0.5)
        )
    }
}

// MARK: - New Project Sheet

struct NewProjectSheet: View {
    @Bindable var vm: ProjectsViewModel
    let userId: UUID

    var body: some View {
        NavigationStack {
            Form {
                Section("Project Info") {
                    TextField("Project Name", text: $vm.newName)
                    TextField("Description (optional)", text: $vm.newDescription, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Details") {
                    DatePicker("Deadline", selection: $vm.newDeadline, displayedComponents: .date)

                    Picker("Priority", selection: $vm.newPriority) {
                        ForEach(1...10, id: \.self) { p in
                            Text("\(p) - \(priorityLabel(p))").tag(p)
                        }
                    }

                    Picker("Type", selection: $vm.newType) {
                        Text("Personal").tag(ProjectType.personal)
                        Text("Professional").tag(ProjectType.professional)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { vm.showNewProject = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task { await vm.createProject(userId: userId) }
                    }
                    .disabled(vm.newName.isEmpty)
                }
            }
        }
    }

    private func priorityLabel(_ p: Int) -> String {
        switch p {
        case 1...3: return "Low"
        case 4...6: return "Medium"
        case 7...10: return "High"
        default: return ""
        }
    }
}
