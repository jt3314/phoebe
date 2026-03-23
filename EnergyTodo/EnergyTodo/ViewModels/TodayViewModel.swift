import Foundation

@Observable
final class TodayViewModel {

    var selectedDate: Date = Date()
    var projectTasks: [Task_] = []
    var standaloneTasks: [StandaloneTask] = []
    var sleepCheck: SleepCheck?
    var effortBreakdown: EffortCalculator.EffortBreakdown?
    var cycle: Cycle?
    var effortPointsMap: [Int: Int] = [:]
    var isLoading = false
    var errorMessage: String?

    // Confetti state
    var showConfetti = false
    var completedTaskId: UUID?

    // Project name lookup for display
    var projectNames: [UUID: String] = [:]

    private let taskService = TaskService()
    private let sleepService = SleepCheckService()
    private let cycleService = CycleService()
    private let fixedEventService = FixedEventService()
    private let projectService = ProjectService()

    var selectedDateString: String {
        CycleCalculator.formatISO(selectedDate)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(selectedDate)
    }

    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(selectedDate)
    }

    var dateLabel: String {
        if isToday { return "Today" }
        if isYesterday { return "Yesterday" }
        if isTomorrow { return "Tomorrow" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: selectedDate)
    }

    var weekdayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: selectedDate)
    }

    var totalTaskCount: Int {
        projectTasks.count + standaloneTasks.count
    }

    var completedTaskCount: Int {
        projectTasks.filter { $0.status == .completed }.count +
        standaloneTasks.filter { $0.status == .completed }.count
    }

    var totalScheduledEffort: Int {
        projectTasks.reduce(0) { $0 + $1.effortPoints } +
        standaloneTasks.reduce(0) { $0 + $1.effortPoints }
    }

    var remainingPoints: Int {
        (effortBreakdown?.totalAvailable ?? 0) - totalScheduledEffort
    }

    var hasCheckedSleepToday: Bool {
        sleepCheck != nil
    }

    // MARK: - Actions

    func load(userId: UUID) async {
        isLoading = true
        errorMessage = nil
        let dateStr = selectedDateString

        do {
            // Fetch cycle info
            if cycle == nil {
                cycle = try await cycleService.fetchCycle(userId: userId)
                if let cycle {
                    let points = try await cycleService.fetchEffortPoints(cycleId: cycle.id)
                    effortPointsMap = Dictionary(uniqueKeysWithValues: points.map { ($0.dayNumber, $0.effortPoints) })
                }
            }

            // Fetch tasks, standalone tasks, and sleep check in parallel
            async let tasksResult = taskService.fetchTasksForDate(dateStr, userId: userId)
            async let standaloneResult = taskService.fetchStandaloneTasksForDate(dateStr, userId: userId)
            async let sleepResult = sleepService.fetch(userId: userId, date: dateStr)
            async let fixedEventsResult = fixedEventService.fetchForDate(userId: userId, date: dateStr)

            projectTasks = try await tasksResult
            standaloneTasks = try await standaloneResult
            sleepCheck = try await sleepResult
            let fixedEvents = try await fixedEventsResult

            // Load project names for display
            let projectIds = Set(projectTasks.map(\.projectId))
            for pid in projectIds where projectNames[pid] == nil {
                if let project = try? await projectService.fetchById(pid) {
                    projectNames[pid] = project.name
                }
            }

            // Calculate effort breakdown
            if let cycle {
                let overrides = try await cycleService.fetchWeekendOverrides(cycleId: cycle.id)
                effortBreakdown = EffortCalculator.getEffortBreakdown(
                    date: dateStr,
                    day1Date: cycle.day1Date,
                    cycleLength: cycle.length,
                    effortPoints: effortPointsMap,
                    weekendOverrides: overrides,
                    fixedEvents: fixedEvents,
                    sleepCheck: sleepCheck
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func goToNextDay() {
        selectedDate = CycleCalculator.addDays(selectedDate, 1)
    }

    func goToPreviousDay() {
        selectedDate = CycleCalculator.addDays(selectedDate, -1)
    }

    func goToToday() {
        selectedDate = Date()
    }

    func recordSleep(userId: UUID, sleptPoorly: Bool) async {
        do {
            sleepCheck = try await sleepService.record(
                userId: userId,
                date: selectedDateString,
                sleptPoorly: sleptPoorly
            )
            // Recalculate effort
            if let cycle {
                let overrides = try await cycleService.fetchWeekendOverrides(cycleId: cycle.id)
                let fixedEvents = try await fixedEventService.fetchForDate(userId: userId, date: selectedDateString)
                effortBreakdown = EffortCalculator.getEffortBreakdown(
                    date: selectedDateString,
                    day1Date: cycle.day1Date,
                    cycleLength: cycle.length,
                    effortPoints: effortPointsMap,
                    weekendOverrides: overrides,
                    fixedEvents: fixedEvents,
                    sleepCheck: sleepCheck
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func completeProjectTask(_ task: Task_) async {
        do {
            if task.status == .completed {
                try await taskService.uncompleteTask(id: task.id)
            } else {
                try await taskService.completeTask(id: task.id)
                completedTaskId = task.id
                showConfetti = true
            }
            // Refresh task list
            if let idx = projectTasks.firstIndex(where: { $0.id == task.id }) {
                projectTasks[idx].status = task.status == .completed ? .scheduled : .completed
                projectTasks[idx].completedDate = task.status == .completed ? nil : CycleCalculator.formatISO(Date())
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func completeStandaloneTask(_ task: StandaloneTask) async {
        do {
            try await taskService.completeStandaloneTask(id: task.id)
            completedTaskId = task.id
            showConfetti = true
            if let idx = standaloneTasks.firstIndex(where: { $0.id == task.id }) {
                standaloneTasks[idx].status = .completed
                standaloneTasks[idx].completedDate = CycleCalculator.formatISO(Date())
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func dismissConfetti() {
        showConfetti = false
        completedTaskId = nil
    }
}
