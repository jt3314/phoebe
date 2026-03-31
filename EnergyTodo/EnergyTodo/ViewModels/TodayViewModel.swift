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

    // Google Calendar events for the selected date
    var googleEvents: [GoogleCalendarEvent] = []

    // Phoebe-only events for the selected date
    var phoebeEvents: [PhoebeEvent] = []

    // Energy-aware nudges
    var nudges: [Nudge] = []
    var dismissedNudgeIds: Set<UUID> = []

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
    private let phoebeEventService = PhoebeEventService()

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

            // Fetch tasks, standalone tasks, sleep check, and Google events in parallel
            async let tasksResult = taskService.fetchTasksForDate(dateStr, userId: userId)
            async let standaloneResult = taskService.fetchStandaloneTasksForDate(dateStr, userId: userId)
            async let sleepResult = sleepService.fetch(userId: userId, date: dateStr)
            async let fixedEventsResult = fixedEventService.fetchForDate(userId: userId, date: dateStr)
            async let googleEventsResult = GoogleCalendarService.fetchCachedEvents(userId: userId, date: dateStr)
            async let phoebeEventsResult = phoebeEventService.fetchForDate(userId: userId, date: dateStr)

            projectTasks = try await tasksResult
            standaloneTasks = try await standaloneResult
            sleepCheck = try await sleepResult
            let fixedEvents = try await fixedEventsResult
            googleEvents = (try? await googleEventsResult) ?? []
            phoebeEvents = (try? await phoebeEventsResult) ?? []

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
                    googleEvents: googleEvents,
                    phoebeEvents: phoebeEvents,
                    sleepCheck: sleepCheck
                )

                // Generate nudges
                let tomorrowStr = CycleCalculator.formatISO(CycleCalculator.addDays(selectedDate, 1))
                let tomorrowEvents = (try? await GoogleCalendarService.fetchCachedEvents(userId: userId, date: tomorrowStr)) ?? []
                let tomorrowCycleDay = CycleCalculator.getCycleDay(date: tomorrowStr, day1Date: cycle.day1Date, cycleLength: cycle.length)
                let tomorrowBase = EffortCalculator.getBaseEffortForCycleDay(tomorrowCycleDay, effortPoints: effortPointsMap)

                let nudgeInput = NudgeEngine.NudgeInput(
                    cycleDay: effortBreakdown!.cycleDay,
                    baseEffort: effortBreakdown!.baseEffort,
                    googleEvents: googleEvents,
                    tomorrowGoogleEvents: tomorrowEvents,
                    tomorrowBaseEffort: tomorrowBase,
                    sleepCheck: sleepCheck,
                    totalScheduledTaskEffort: totalScheduledEffort,
                    totalAvailableEffort: effortBreakdown!.totalAvailable
                )
                nudges = NudgeEngine.generateNudges(input: nudgeInput)
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
                    googleEvents: googleEvents,
                    phoebeEvents: phoebeEvents,
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

    func dismissNudge(_ nudge: Nudge) {
        dismissedNudgeIds.insert(nudge.id)
    }

    var visibleNudges: [Nudge] {
        nudges.filter { !dismissedNudgeIds.contains($0.id) }
    }

    func dismissConfetti() {
        showConfetti = false
        completedTaskId = nil
    }

    /// Sync Google Calendar events for the current week, then reload.
    @MainActor
    func syncGoogleCalendar(userId: UUID) async {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(byAdding: .day, value: -7, to: selectedDate) ?? selectedDate
        let endOfWeek = calendar.date(byAdding: .day, value: 14, to: selectedDate) ?? selectedDate
        let startStr = CycleCalculator.formatISO(startOfWeek)
        let endStr = CycleCalculator.formatISO(endOfWeek)

        do {
            try await GoogleCalendarService.syncEvents(userId: userId, dateRange: startStr...endStr)
            await load(userId: userId)
        } catch {
            // Sync failure is non-fatal — we still show cached data
        }
    }
}
