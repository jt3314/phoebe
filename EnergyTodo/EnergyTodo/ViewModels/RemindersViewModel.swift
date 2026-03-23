import Foundation

@Observable
final class RemindersViewModel {
    var dailyNote: DailyNote?
    var cycleNotes: [CycleNote] = []
    var reminders: [Reminder] = []
    var sources: [ReminderSource] = []
    var userSources: [UserReminderSource] = []
    var isLoading = false
    var noteText = ""
    var cycleNoteTexts: [Int: String] = [:]

    private let notesService = NotesService()
    private let remindersService = RemindersService()

    func load(userId: UUID, date: String, cycleDay: Int) async {
        isLoading = true
        do {
            // Fetch daily note
            dailyNote = try await notesService.fetchDailyNote(userId: userId, date: date)
            noteText = dailyNote?.content ?? ""

            // Fetch cycle notes for current day +/- 1
            let days = [max(1, cycleDay - 1), cycleDay, cycleDay + 1]
            cycleNotes = try await notesService.fetchCycleNotes(userId: userId, cycleDays: days)
            for note in cycleNotes { cycleNoteTexts[note.cycleDay] = note.content }

            // Fetch reminders
            sources = try await remindersService.fetchSources()
            userSources = try await remindersService.fetchUserSources(userId: userId)
            let enabledSourceIds = userSources.filter(\.enabled).map(\.sourceId)
            if !enabledSourceIds.isEmpty {
                reminders = try await remindersService.fetchReminders(sourceIds: enabledSourceIds)
            }
        } catch {}
        isLoading = false
    }

    func saveDailyNote(userId: UUID, date: String) async {
        guard !noteText.isEmpty else { return }
        do { dailyNote = try await notesService.upsertDailyNote(userId: userId, date: date, content: noteText) } catch {}
    }

    func saveCycleNote(userId: UUID, cycleDay: Int) async {
        guard let text = cycleNoteTexts[cycleDay], !text.isEmpty else { return }
        do { _ = try await notesService.upsertCycleNote(userId: userId, cycleDay: cycleDay, content: text) } catch {}
    }

    /// Filter reminders for the current cycle day
    func remindersForDay(_ cycleDay: Int) -> [Reminder] {
        reminders.filter { r in
            if let min = r.cycleDayMin, cycleDay < min { return false }
            if let max = r.cycleDayMax, cycleDay > max { return false }
            return true
        }
    }
}
