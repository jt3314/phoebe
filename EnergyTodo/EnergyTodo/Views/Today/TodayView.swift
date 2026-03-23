import SwiftUI

struct TodayView: View {
    @Bindable var authVM: AuthViewModel
    @State private var vm = TodayViewModel()
    @State private var showAddTask = false
    @State private var showReminders = false
    @State private var showDay1Banner = false
    @State private var projects: [Project] = []

    private let projectService = ProjectService()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Colored header card
                    headerCard
                        .padding(.bottom, 8)

                    if vm.isLoading {
                        Spacer()
                        ProgressView()
                            .tint(Theme.primary)
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                // Sleep check banner
                                if vm.isToday && !vm.hasCheckedSleepToday {
                                    SleepCheckBanner(vm: vm, userId: authVM.currentUserId ?? UUID())
                                }

                                // Day 1 banner
                                if showDay1Banner && vm.isToday {
                                    Day1BannerView {
                                        withAnimation { showDay1Banner = false }
                                    }
                                }

                                // Effort display
                                if let breakdown = vm.effortBreakdown {
                                    effortCard(breakdown)
                                }

                                // Completion progress + Add Task button
                                if vm.totalTaskCount > 0 || true {
                                    HStack {
                                        if vm.totalTaskCount > 0 {
                                            Text("\(vm.completedTaskCount) of \(vm.totalTaskCount) completed")
                                                .font(.subheadline)
                                                .foregroundStyle(Theme.mutedForeground)
                                        }

                                        Spacer()

                                        Button {
                                            showAddTask = true
                                        } label: {
                                            HStack(spacing: 4) {
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.caption)
                                                Text("Add Task")
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                            }
                                            .foregroundStyle(Theme.primary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Theme.primary.opacity(0.1))
                                            .clipShape(Capsule())
                                        }
                                    }
                                }

                                // Task list
                                taskListSection
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        }
                    }
                }

                // Floating reminders button (bottom right)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showReminders = true
                        } label: {
                            Image(systemName: "leaf.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(Theme.primary)
                                .shadow(color: Theme.primary.opacity(0.3), radius: 6, x: 0, y: 3)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 16)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await authVM.signOut() }
                    } label: {
                        Image(systemName: "person.circle")
                            .foregroundStyle(Theme.primary)
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
            .sheet(isPresented: $showAddTask) {
                if let userId = authVM.currentUserId {
                    AddTaskSheet(
                        isPresented: $showAddTask,
                        userId: userId,
                        selectedDate: vm.selectedDateString,
                        projects: projects
                    ) {
                        Task { await vm.load(userId: userId) }
                    }
                }
            }
            .sheet(isPresented: $showReminders) {
                if let breakdown = vm.effortBreakdown, let cycle = vm.cycle {
                    RemindersSidebarView(
                        cycleDay: breakdown.cycleDay,
                        cycleLength: cycle.length,
                        viewingDate: vm.selectedDateString,
                        userId: authVM.currentUserId ?? UUID(),
                        showSeasons: cycle.showSeasons,
                        cycle: cycle
                    )
                }
            }
            .task {
                if let userId = authVM.currentUserId {
                    await vm.load(userId: userId)
                    await loadProjects(userId: userId)
                    updateDay1Banner()
                }
            }
            .onChange(of: vm.selectedDate) {
                Task {
                    if let userId = authVM.currentUserId {
                        await vm.load(userId: userId)
                        updateDay1Banner()
                    }
                }
            }
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        let effortIntensity = headerColorIntensity
        let headerBg = Theme.lunarColors[effortIntensity]

        return VStack(spacing: 8) {
            HStack {
                Button { vm.goToPreviousDay() } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundStyle(Theme.foreground)
                        .frame(width: 44, height: 44)
                }

                Spacer()

                VStack(spacing: 2) {
                    Text(vm.dateLabel)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.foreground)

                    if let breakdown = vm.effortBreakdown {
                        Text(fullDateLabel + " \u{2022} Day \(breakdown.cycleDay)")
                            .font(.subheadline)
                            .foregroundStyle(Theme.mutedForeground)
                    } else {
                        Text(fullDateLabel)
                            .font(.subheadline)
                            .foregroundStyle(Theme.mutedForeground)
                    }
                }

                Spacer()

                Button { vm.goToNextDay() } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundStyle(Theme.foreground)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, 8)

            // Points remaining badge
            if let breakdown = vm.effortBreakdown {
                let remaining = vm.remainingPoints
                HStack(spacing: 6) {
                    Text("\(abs(remaining)) pts \(remaining >= 0 ? "remaining" : "over")")
                        .font(.caption)
                        .fontWeight(.medium)

                    if breakdown.sleepReduction > 0 {
                        Text("(-\(breakdown.sleepReduction))")
                            .font(.caption)
                            .foregroundStyle(Theme.warning)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(remaining < 0 ? Theme.destructive.opacity(0.12) : Theme.success.opacity(0.12))
                .foregroundStyle(remaining < 0 ? Theme.destructive : Theme.success)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(remaining < 0 ? Theme.destructive.opacity(0.3) : Theme.success.opacity(0.3), lineWidth: 1)
                )
            }

            // Mark today as Day 1 link
            if vm.isToday {
                Button {
                    Task {
                        if let cycle = vm.cycle, let userId = authVM.currentUserId {
                            let today = CycleCalculator.formatISO(Date())
                            try? await CycleService().updateDay1Date(cycleId: cycle.id, day1Date: today)
                            vm.cycle?.day1Date = today
                            await vm.load(userId: userId)
                            updateDay1Banner()
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.caption2)
                        Text("Mark today as Day 1")
                            .font(.caption)
                    }
                    .foregroundStyle(Theme.primary)
                }
            }

            if !vm.isToday {
                Button("Back to Today") { vm.goToToday() }
                    .font(.caption)
                    .foregroundStyle(Theme.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Theme.primary.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(headerBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.cardBorder, lineWidth: 0.5)
        )
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }

    private var fullDateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: vm.selectedDate)
    }

    private var headerColorIntensity: Int {
        guard let breakdown = vm.effortBreakdown else { return 0 }
        let maxEffort = 15
        let ratio = Double(breakdown.totalAvailable) / Double(max(1, maxEffort))
        let index = min(Int(ratio * Double(Theme.lunarColors.count - 1)), Theme.lunarColors.count - 1)
        return max(0, index)
    }

    // MARK: - Effort Card

    private func effortCard(_ breakdown: EffortCalculator.EffortBreakdown) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Day \(breakdown.cycleDay)")
                    .font(.caption)
                    .foregroundStyle(Theme.mutedForeground)
                Text("\(breakdown.totalAvailable) pts available")
                    .font(.headline)
                    .foregroundStyle(Theme.foreground)
            }
            Spacer()
        }
        .themedCard()
    }

    // MARK: - Task List

    private var taskListSection: some View {
        VStack(spacing: 10) {
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
                let empty = getEmptyStateCopy(section: .todayTasks)
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.mutedForeground)
                    Text(empty.heading)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Theme.foreground)
                    Text(empty.cta)
                        .font(.caption)
                        .foregroundStyle(Theme.mutedForeground)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
    }

    // MARK: - Helpers

    private func loadProjects(userId: UUID) async {
        do {
            projects = try await projectService.fetchActive(userId: userId)
        } catch {
            projects = []
        }
    }

    private func updateDay1Banner() {
        if let breakdown = vm.effortBreakdown {
            showDay1Banner = breakdown.cycleDay == 1
        }
    }
}

// MARK: - Task Row Views

struct StandaloneTaskRowView: View {
    let task: StandaloneTask
    let onToggle: () -> Void
    @State private var celebrating = false

    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                if task.status != .completed {
                    celebrating = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { celebrating = false }
                }
                onToggle()
            }) {
                ZStack {
                    Circle()
                        .stroke(task.status == .completed ? Theme.success : Theme.cardBorder, lineWidth: 2)
                        .frame(width: 22, height: 22)

                    if task.status == .completed {
                        Circle()
                            .fill(Theme.success)
                            .frame(width: 22, height: 22)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .scaleEffect(celebrating ? 1.3 : 1.0)
                .animation(.spring(response: 0.3), value: celebrating)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(task.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .strikethrough(task.status == .completed)
                        .foregroundStyle(task.status == .completed ? Theme.mutedForeground : Theme.foreground)

                    EffortBadge(points: task.effortPoints)

                    Text("Standalone")
                        .font(.system(size: 10))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.secondary)
                        .foregroundStyle(Theme.secondaryForeground)
                        .clipShape(Capsule())
                }

                if let desc = task.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(Theme.mutedForeground)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(celebrating ? Theme.success.opacity(0.08) : Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(celebrating ? Theme.success.opacity(0.4) : Theme.cardBorder, lineWidth: 0.5)
        )
        .scaleEffect(celebrating ? 1.02 : 1.0)
        .animation(.easeOut(duration: 0.3), value: celebrating)
    }
}

struct ProjectTaskRowView: View {
    let task: Task_
    let projectName: String?
    let onToggle: () -> Void
    @State private var celebrating = false

    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                if task.status != .completed {
                    celebrating = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { celebrating = false }
                }
                onToggle()
            }) {
                ZStack {
                    Circle()
                        .stroke(task.status == .completed ? Theme.success : Theme.cardBorder, lineWidth: 2)
                        .frame(width: 22, height: 22)

                    if task.status == .completed {
                        Circle()
                            .fill(Theme.success)
                            .frame(width: 22, height: 22)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .scaleEffect(celebrating ? 1.3 : 1.0)
                .animation(.spring(response: 0.3), value: celebrating)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(task.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .strikethrough(task.status == .completed)
                        .foregroundStyle(task.status == .completed ? Theme.mutedForeground : Theme.foreground)

                    EffortBadge(points: task.effortPoints)
                }

                HStack(spacing: 4) {
                    if let name = projectName {
                        Text(name)
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Theme.primary)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }

                if let desc = task.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(Theme.mutedForeground)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(celebrating ? Theme.success.opacity(0.08) : Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(celebrating ? Theme.success.opacity(0.4) : Theme.cardBorder, lineWidth: 0.5)
        )
        .scaleEffect(celebrating ? 1.02 : 1.0)
        .animation(.easeOut(duration: 0.3), value: celebrating)
    }
}
