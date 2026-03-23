import SwiftUI

struct AddTaskSheet: View {
    @Binding var isPresented: Bool
    let userId: UUID
    let selectedDate: String
    let projects: [Project]
    var onTaskCreated: () -> Void

    @State private var taskName = ""
    @State private var taskDescription = ""
    @State private var effortPoints = 3
    @State private var scheduledDate: String
    @State private var selectedProjectId: UUID?
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let taskService = TaskService()

    init(isPresented: Binding<Bool>, userId: UUID, selectedDate: String, projects: [Project], onTaskCreated: @escaping () -> Void) {
        self._isPresented = isPresented
        self.userId = userId
        self.selectedDate = selectedDate
        self.projects = projects
        self.onTaskCreated = onTaskCreated
        self._scheduledDate = State(initialValue: selectedDate)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Task Name
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Task Name")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(Theme.foreground)

                            TextField(getCyclingCopy(options: [
                                "What do you need to do?",
                                "Name your task...",
                                "What's on your plate?"
                            ]), text: $taskName)
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(Theme.card)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Theme.cardBorder, lineWidth: 0.5)
                                )
                        }

                        // Description
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Description")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(Theme.foreground)

                            TextField(getCyclingCopy(options: [
                                "Add some details (optional)",
                                "Any extra notes?",
                                "Describe it briefly..."
                            ]), text: $taskDescription, axis: .vertical)
                                .textFieldStyle(.plain)
                                .lineLimit(3...6)
                                .padding(12)
                                .background(Theme.card)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Theme.cardBorder, lineWidth: 0.5)
                                )
                        }

                        // Effort Points
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Effort Points")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(Theme.foreground)

                            HStack(spacing: 8) {
                                ForEach(1...10, id: \.self) { point in
                                    Button {
                                        effortPoints = point
                                    } label: {
                                        Text("\(point)")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .frame(width: 30, height: 30)
                                            .background(effortPoints == point ? Theme.primary : Theme.card)
                                            .foregroundStyle(effortPoints == point ? Theme.primaryForeground : Theme.foreground)
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(effortPoints == point ? Theme.primary : Theme.cardBorder, lineWidth: 0.5)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Project Picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Project")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(Theme.foreground)

                            Menu {
                                Button("No project (standalone)") {
                                    selectedProjectId = nil
                                }
                                ForEach(projects) { project in
                                    Button(project.name) {
                                        selectedProjectId = project.id
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(selectedProjectName)
                                        .foregroundStyle(selectedProjectId == nil ? Theme.mutedForeground : Theme.foreground)
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.caption)
                                        .foregroundStyle(Theme.mutedForeground)
                                }
                                .padding(12)
                                .background(Theme.card)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Theme.cardBorder, lineWidth: 0.5)
                                )
                            }
                        }

                        // Error message
                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(Theme.destructive)
                        }

                        // Save button
                        Button {
                            Task { await saveTask() }
                        } label: {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .tint(Theme.primaryForeground)
                                        .scaleEffect(0.8)
                                }
                                Text(isSaving ? "Saving..." : getCyclingCopy(options: [
                                    "Add Task",
                                    "Create Task",
                                    "Save Task"
                                ]))
                            }
                            .font(.headline)
                            .foregroundStyle(Theme.primaryForeground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(taskName.isEmpty ? Theme.muted : Theme.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(taskName.isEmpty || isSaving)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundStyle(Theme.primary)
                }
            }
        }
    }

    private var selectedProjectName: String {
        if let id = selectedProjectId,
           let project = projects.first(where: { $0.id == id }) {
            return project.name
        }
        return "No project (standalone)"
    }

    private func saveTask() async {
        guard !taskName.isEmpty else { return }
        isSaving = true
        errorMessage = nil

        do {
            if let projectId = selectedProjectId {
                // Create project task
                let newTask = TaskService.NewTask(
                    project_id: projectId.uuidString,
                    milestone_id: nil,
                    name: taskName,
                    description: taskDescription.isEmpty ? nil : taskDescription,
                    effort_points: effortPoints,
                    sort_order: 0
                )
                var created = try await taskService.createTask(newTask)
                // Schedule it for the selected date
                try await taskService.updateTask(
                    id: created.id,
                    data: TaskService.UpdateTask(
                        status: "scheduled",
                        scheduled_date: scheduledDate
                    )
                )
            } else {
                // Create standalone task
                let newTask = TaskService.NewStandaloneTask(
                    user_id: userId.uuidString,
                    name: taskName,
                    description: taskDescription.isEmpty ? nil : taskDescription,
                    effort_points: effortPoints,
                    scheduled_date: scheduledDate
                )
                _ = try await taskService.createStandaloneTask(newTask)
            }

            onTaskCreated()
            isPresented = false
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }
}
