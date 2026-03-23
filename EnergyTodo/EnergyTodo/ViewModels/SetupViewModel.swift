import Foundation

@Observable
final class SetupViewModel {

    var cycle: Cycle?
    var effortPoints: [CycleEffortPoint] = []
    var isLoading = false
    var errorMessage: String?
    var newLength: Int = 35
    var isUpdatingLength = false

    private let cycleService = CycleService()

    var currentCycleDay: Int? {
        guard let cycle else { return nil }
        let today = CycleCalculator.formatISO(Date())
        return CycleCalculator.getCycleDay(date: today, day1Date: cycle.day1Date, cycleLength: cycle.length)
    }

    var day1DateFormatted: String {
        guard let cycle, let date = CycleCalculator.parseISO(cycle.day1Date) else { return "—" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    func load(userId: UUID) async {
        isLoading = true
        do {
            cycle = try await cycleService.fetchCycle(userId: userId)
            if let cycle {
                effortPoints = try await cycleService.fetchEffortPoints(cycleId: cycle.id)
                newLength = cycle.length
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func restartCycle() async {
        guard let cycle else { return }
        let today = CycleCalculator.formatISO(Date())
        do {
            try await cycleService.updateDay1Date(cycleId: cycle.id, day1Date: today)
            self.cycle?.day1Date = today
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateLength() async {
        guard let cycle, EffortCalculator.isValidCycleLength(newLength) else { return }
        isUpdatingLength = true
        do {
            try await cycleService.updateLength(cycleId: cycle.id, newLength: newLength, oldLength: cycle.length)
            self.cycle?.length = newLength
            // Refresh effort points
            effortPoints = try await cycleService.fetchEffortPoints(cycleId: cycle.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isUpdatingLength = false
    }
}
