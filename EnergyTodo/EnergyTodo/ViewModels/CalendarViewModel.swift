import Foundation

@Observable
final class CalendarViewModel {

    enum ViewMode: String, CaseIterable {
        case month = "Month"
        case cycle = "Cycle"
    }

    var viewMode: ViewMode = .cycle
    var currentMonth: Date = Date()
    var showCycleInfo = true
    var cycle: Cycle?
    var effortPointsMap: [Int: Int] = [:]
    var tasksByDate: [String: [Task_]] = [:]
    var standaloneByDate: [String: [StandaloneTask]] = [:]
    var isLoading = false

    private let cycleService = CycleService()
    private let taskService = TaskService()

    // MARK: - Calendar Helpers

    private let calendar = Calendar.current

    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    var daysInMonth: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))
        else { return [] }

        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: firstDay)
        }
    }

    var firstWeekdayOffset: Int {
        guard let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))
        else { return 0 }
        return (calendar.component(.weekday, from: firstDay) - calendar.firstWeekday + 7) % 7
    }

    /// Cycle days array for cycle view.
    var cycleDays: [(day: Int, date: String, effort: Int)] {
        guard let cycle else { return [] }
        return (1...cycle.length).map { day in
            let effort = effortPointsMap[day] ?? EffortCalculator.getDefaultEffortForCycleDay(day)
            let date = CycleCalculator.getDateForCycleDay(day, day1Date: cycle.day1Date) ?? ""
            return (day: day, date: date, effort: effort)
        }
    }

    // MARK: - Effort for Date

    func effortForDate(_ date: Date) -> (available: Int, scheduled: Int)? {
        guard let cycle else { return nil }
        let dateStr = CycleCalculator.formatISO(date)
        let cycleDay = CycleCalculator.getCycleDay(date: dateStr, day1Date: cycle.day1Date, cycleLength: cycle.length)
        let available = effortPointsMap[cycleDay] ?? EffortCalculator.getDefaultEffortForCycleDay(cycleDay)

        let scheduledEffort = (tasksByDate[dateStr] ?? []).reduce(0) { $0 + $1.effortPoints } +
                              (standaloneByDate[dateStr] ?? []).reduce(0) { $0 + $1.effortPoints }

        return (available: available, scheduled: scheduledEffort)
    }

    func cycleDayForDate(_ date: Date) -> Int? {
        guard let cycle else { return nil }
        let dateStr = CycleCalculator.formatISO(date)
        return CycleCalculator.getCycleDay(date: dateStr, day1Date: cycle.day1Date, cycleLength: cycle.length)
    }

    /// Get lunar gradient color intensity for effort points (0.0 to 1.0).
    func effortIntensity(effort: Int) -> Double {
        guard let cycle else { return 0 }
        let maxEffort = effortPointsMap.values.max() ?? 15
        guard maxEffort > 0 else { return 0 }
        return min(1.0, Double(effort) / Double(maxEffort))
    }

    // MARK: - Navigation

    func previousMonth() {
        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }

    func nextMonth() {
        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
    }

    func goToToday() {
        currentMonth = Date()
    }

    // MARK: - Load

    func load(userId: UUID) async {
        isLoading = true
        do {
            cycle = try await cycleService.fetchCycle(userId: userId)
            if let cycle {
                let points = try await cycleService.fetchEffortPoints(cycleId: cycle.id)
                effortPointsMap = Dictionary(uniqueKeysWithValues: points.map { ($0.dayNumber, $0.effortPoints) })
            }

            // Load tasks for the visible month range
            let standalone = try await taskService.fetchAllStandaloneTasks(userId: userId)
            let projects = try await ProjectService().fetchActive(userId: userId)
            var allTasks: [Task_] = []
            for project in projects {
                let tasks = try await taskService.fetchTasksForProject(project.id)
                allTasks.append(contentsOf: tasks)
            }

            // Group by date
            tasksByDate = Dictionary(grouping: allTasks.filter { $0.scheduledDate != nil }) {
                $0.scheduledDate!
            }
            standaloneByDate = Dictionary(grouping: standalone.filter { $0.scheduledDate != nil }) {
                $0.scheduledDate!
            }
        } catch {
            // Silently handle - calendar still renders
        }
        isLoading = false
    }
}
