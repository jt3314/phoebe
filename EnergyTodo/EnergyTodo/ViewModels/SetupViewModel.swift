import Foundation

@Observable
final class SetupViewModel {

    var cycle: Cycle?
    var effortPoints: [CycleEffortPoint] = []
    var isLoading = false
    var errorMessage: String?
    var newLength: Int = 35
    var isUpdatingLength = false

    // Scheduling direction
    var schedulingDirection: String = "early"

    // Seasons toggle
    var showSeasons: Bool = true

    // Tip packs
    var reminderSources: [ReminderSource] = []
    var userReminderSources: [UserReminderSource] = []

    private let cycleService = CycleService()
    private let remindersService = RemindersService()

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
                schedulingDirection = cycle.schedulingDirection
                showSeasons = cycle.showSeasons
            }

            // Load tip packs
            async let sourcesResult = remindersService.fetchSources()
            async let userSourcesResult = remindersService.fetchUserSources(userId: userId)
            reminderSources = try await sourcesResult
            userReminderSources = try await userSourcesResult
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

    func saveSchedulingDirection() async {
        guard let cycle else { return }
        do {
            try await supabase
                .from("cycles")
                .update(["scheduling_direction": schedulingDirection])
                .eq("id", value: cycle.id.uuidString)
                .execute()
            self.cycle?.schedulingDirection = schedulingDirection
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveShowSeasons() async {
        guard let cycle else { return }
        do {
            try await supabase
                .from("cycles")
                .update(["show_seasons": showSeasons])
                .eq("id", value: cycle.id.uuidString)
                .execute()
            self.cycle?.showSeasons = showSeasons
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleTipPack(sourceId: UUID, enabled: Bool) async {
        guard let cycle else { return }
        do {
            try await remindersService.toggleSource(
                userId: cycle.userId,
                sourceId: sourceId,
                enabled: enabled
            )
            // Update local state
            if let idx = userReminderSources.firstIndex(where: { $0.sourceId == sourceId }) {
                userReminderSources[idx].enabled = enabled
            } else {
                // Refresh from server to get the new record
                userReminderSources = try await remindersService.fetchUserSources(userId: cycle.userId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
