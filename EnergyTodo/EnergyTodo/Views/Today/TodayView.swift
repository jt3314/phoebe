import SwiftUI

struct TodayView: View {
    @Bindable var authVM: AuthViewModel
    @State private var vm = TodayViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Date navigation header
                dateNavigationHeader

                if vm.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Sleep check banner
                            if vm.isToday && !vm.hasCheckedSleepToday {
                                SleepCheckBanner(vm: vm, userId: authVM.currentUserId ?? UUID())
                            }

                            // Effort display
                            if let breakdown = vm.effortBreakdown {
                                effortCard(breakdown)
                            }

                            // Task list
                            taskListSection
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await authVM.signOut() }
                    } label: {
                        Image(systemName: "person.circle")
                    }
                }
            }
            .overlay {
                if vm.showConfetti {
                    ConfettiView()
                        .allowsHitTesting(false)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                vm.dismissConfetti()
                            }
                        }
                }
            }
            .task {
                if let userId = authVM.currentUserId {
                    await vm.load(userId: userId)
                }
            }
            .onChange(of: vm.selectedDate) {
                Task {
                    if let userId = authVM.currentUserId {
                        await vm.load(userId: userId)
                    }
                }
            }
        }
    }

    // MARK: - Date Navigation

    private var dateNavigationHeader: some View {
        VStack(spacing: 4) {
            HStack {
                Button { vm.goToPreviousDay() } label: {
                    Image(systemName: "chevron.left")
                }

                Spacer()

                VStack(spacing: 2) {
                    Text(vm.dateLabel)
                        .font(.headline)
                    Text(vm.weekdayLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button { vm.goToNextDay() } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)

            if !vm.isToday {
                Button("Back to Today") { vm.goToToday() }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Effort Card

    private func effortCard(_ breakdown: EffortCalculator.EffortBreakdown) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Day \(breakdown.cycleDay)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(breakdown.totalAvailable) pts available")
                    .font(.headline)
            }

            Spacer()

            let remaining = vm.remainingPoints
            Text("\(abs(remaining)) pts \(remaining >= 0 ? "remaining" : "over")")
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(remaining >= 0 ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                .foregroundStyle(remaining >= 0 ? .green : .red)
                .clipShape(Capsule())

            if breakdown.sleepReduction > 0 {
                Text("-\(breakdown.sleepReduction)")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Task List

    private var taskListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if vm.totalTaskCount > 0 {
                Text("\(vm.completedTaskCount) of \(vm.totalTaskCount) completed")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Standalone tasks
            ForEach(vm.standaloneTasks) { task in
                StandaloneTaskRowView(task: task) {
                    Task { await vm.completeStandaloneTask(task) }
                }
            }

            // Project tasks
            ForEach(vm.projectTasks) { task in
                ProjectTaskRowView(
                    task: task,
                    projectName: vm.projectNames[task.projectId]
                ) {
                    Task { await vm.completeProjectTask(task) }
                }
            }

            if vm.totalTaskCount == 0 {
                EmptyStateView(
                    icon: "checkmark.circle",
                    title: "No tasks scheduled",
                    message: "No tasks scheduled for \(vm.dateLabel). Create a project to get started."
                )
            }
        }
    }
}

// MARK: - Task Row Views

struct StandaloneTaskRowView: View {
    let task: StandaloneTask
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.status == .completed ? .green : .secondary)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(task.name)
                    .strikethrough(task.status == .completed)
                    .foregroundStyle(task.status == .completed ? .secondary : .primary)
                if let desc = task.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            EffortBadge(points: task.effortPoints)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct ProjectTaskRowView: View {
    let task: Task_
    let projectName: String?
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.status == .completed ? .green : .secondary)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(task.name)
                    .strikethrough(task.status == .completed)
                    .foregroundStyle(task.status == .completed ? .secondary : .primary)
                if let name = projectName {
                    Text(name)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.15))
                        .clipShape(Capsule())
                }
                if let desc = task.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            EffortBadge(points: task.effortPoints)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
