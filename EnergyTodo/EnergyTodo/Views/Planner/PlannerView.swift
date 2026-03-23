import SwiftUI

struct PlannerView: View {
    @Bindable var authVM: AuthViewModel
    @State private var vm = PlannerViewModel()
    @State private var showAddTask = false
    @State private var selectedDayIndex = 0

    private let projectService = ProjectService()
    @State private var projects: [Project] = []

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    if vm.isLoading {
                        Spacer()
                        ProgressView()
                            .tint(Theme.primary)
                        Spacer()
                    } else if vm.days.isEmpty {
                        emptyState
                    } else {
                        // Horizontal scroll of day columns
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .top, spacing: 12) {
                                ForEach(Array(vm.days.enumerated()), id: \.offset) { index, day in
                                    dayColumn(day: day, index: index)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                    }
                }
            }
            .navigationTitle("Planner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        // Rejig button
                        Button {
                            Task {
                                if let userId = authVM.currentUserId {
                                    await vm.scheduleAll(userId: userId)
                                    await vm.load(userId: userId)
                                }
                            }
                        } label: {
                            Label("Rejig", systemImage: "arrow.triangle.2.circlepath")
                                .font(.subheadline)
                                .foregroundStyle(Theme.primary)
                        }

                        // Add task button
                        Button {
                            showAddTask = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Theme.primary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddTask) {
                if let userId = authVM.currentUserId {
                    let dateStr = vm.days.indices.contains(selectedDayIndex) ? vm.days[selectedDayIndex].dateString : CycleCalculator.formatISO(Date())
                    AddTaskSheet(
                        isPresented: $showAddTask,
                        userId: userId,
                        selectedDate: dateStr,
                        projects: projects
                    ) {
                        Task {
                            await vm.load(userId: userId)
                        }
                    }
                }
            }
            .task {
                if let userId = authVM.currentUserId {
                    projects = (try? await projectService.fetchActive(userId: userId)) ?? []
                    await vm.load(userId: userId)
                }
            }
        }
    }

    // MARK: - Day Column

    private func dayColumn(day: (date: Date, dateString: String, cycleDay: Int?, tasks: [Task_], standaloneTasks: [StandaloneTask], available: Int), index: Int) -> some View {
        let isToday = Calendar.current.isDateInToday(day.date)
        let weekdayFormatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "EEE"
            return f
        }()
        let dayFormatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "d"
            return f
        }()
        let monthFormatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "MMM"
            return f
        }()

        let totalEffort = day.tasks.reduce(0) { $0 + $1.effortPoints } + day.standaloneTasks.reduce(0) { $0 + $1.effortPoints }
        let remaining = day.available - totalEffort

        return VStack(spacing: 8) {
            // Date header
            VStack(spacing: 2) {
                Text(weekdayFormatter.string(from: day.date))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(isToday ? Theme.primaryForeground : Theme.mutedForeground)

                Text(dayFormatter.string(from: day.date))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(isToday ? Theme.primaryForeground : Theme.foreground)

                Text(monthFormatter.string(from: day.date))
                    .font(.caption2)
                    .foregroundStyle(isToday ? Theme.primaryForeground.opacity(0.8) : Theme.mutedForeground)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isToday ? Theme.primary : Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Cycle day badge
            if let cd = day.cycleDay {
                Text("Day \(cd)")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Theme.primary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.primary.opacity(0.1))
                    .clipShape(Capsule())
            }

            // Effort capacity
            HStack(spacing: 3) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 8))
                Text("\(remaining)/\(day.available)")
                    .font(.system(size: 9, weight: .medium))
            }
            .foregroundStyle(remaining < 0 ? Theme.destructive : remaining == 0 ? Theme.warning : Theme.success)

            // Task cards
            VStack(spacing: 4) {
                ForEach(day.standaloneTasks) { task in
                    taskCard(name: task.name, effort: task.effortPoints, isCompleted: task.status == .completed, isStandalone: true)
                }
                ForEach(day.tasks) { task in
                    taskCard(name: task.name, effort: task.effortPoints, isCompleted: task.status == .completed, isStandalone: false)
                }
            }

            // Empty day message
            if day.tasks.isEmpty && day.standaloneTasks.isEmpty {
                let empty = getEmptyStateCopy(section: .todayTasks, salt: index)
                Text(empty.cta)
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.mutedForeground)
                    .multilineTextAlignment(.center)
                    .frame(width: 100)
                    .padding(.vertical, 8)
            }

            // Add button for this day
            Button {
                selectedDayIndex = index
                showAddTask = true
            } label: {
                Image(systemName: "plus")
                    .font(.caption2)
                    .foregroundStyle(Theme.primary)
                    .frame(width: 24, height: 24)
                    .background(Theme.primary.opacity(0.1))
                    .clipShape(Circle())
            }

            Spacer(minLength: 0)
        }
        .frame(width: 120)
    }

    // MARK: - Task Card

    private func taskCard(name: String, effort: Int, isCompleted: Bool, isStandalone: Bool) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(name)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(isCompleted ? Theme.mutedForeground : Theme.foreground)
                .strikethrough(isCompleted)
                .lineLimit(2)

            HStack(spacing: 3) {
                Text("\(effort) pts")
                    .font(.system(size: 8))
                    .foregroundStyle(Theme.mutedForeground)

                if isStandalone {
                    Text("S")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(Theme.secondaryForeground)
                        .padding(.horizontal, 3)
                        .padding(.vertical, 1)
                        .background(Theme.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                }
            }
        }
        .padding(6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: CGFloat(max(28, effort * 6)))
        .background(isCompleted ? Theme.success.opacity(0.08) : Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isCompleted ? Theme.success.opacity(0.3) : Theme.cardBorder, lineWidth: 0.5)
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            icon: "calendar.badge.clock",
            title: "No days to plan",
            message: "Set up your cycle to start planning your tasks around your energy."
        )
    }
}
