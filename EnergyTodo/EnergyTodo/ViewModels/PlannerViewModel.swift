import Foundation

@Observable
final class PlannerViewModel {
    var days: [(date: Date, dateString: String, cycleDay: Int?, tasks: [Task_], standaloneTasks: [StandaloneTask], available: Int)] = []
    var isLoading = false
    var cycle: Cycle?
    var effortPointsMap: [Int: Int] = [:]

    private let taskService = TaskService()
    private let cycleService = CycleService()
    private let schedulerService = SchedulerService()

    func load(userId: UUID) async {
        isLoading = true
        // Fetch cycle, effort points, and tasks for next 14 days
        // Build days array with tasks grouped by date
        do {
            cycle = try await cycleService.fetchCycle(userId: userId)
            if let cycle {
                let points = try await cycleService.fetchEffortPoints(cycleId: cycle.id)
                effortPointsMap = Dictionary(uniqueKeysWithValues: points.map { ($0.dayNumber, $0.effortPoints) })
            }

            // Build 14 days
            var result: [(date: Date, dateString: String, cycleDay: Int?, tasks: [Task_], standaloneTasks: [StandaloneTask], available: Int)] = []
            for i in 0..<14 {
                let date = CycleCalculator.addDays(Date(), i)
                let dateStr = CycleCalculator.formatISO(date)
                let cd = cycle.map { CycleCalculator.getCycleDay(date: dateStr, day1Date: $0.day1Date, cycleLength: $0.length) }
                let available = cd.flatMap { effortPointsMap[$0] } ?? EffortCalculator.getDefaultEffortForCycleDay(cd ?? 1)
                let tasks = try await taskService.fetchTasksForDate(dateStr, userId: userId)
                let standalone = try await taskService.fetchStandaloneTasksForDate(dateStr, userId: userId)
                result.append((date: date, dateString: dateStr, cycleDay: cd, tasks: tasks, standaloneTasks: standalone, available: available))
            }
            days = result
        } catch {}
        isLoading = false
    }

    func scheduleAll(userId: UUID) async {
        do { _ = try await schedulerService.scheduleAllTasks(userId: userId) } catch {}
    }
}
