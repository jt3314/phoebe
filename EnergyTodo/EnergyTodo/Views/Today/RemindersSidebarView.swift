import SwiftUI

struct RemindersSidebarView: View {
    let cycleDay: Int
    let cycleLength: Int
    let viewingDate: String
    let userId: UUID
    let showSeasons: Bool
    let cycle: Cycle?

    @State private var vm = RemindersViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // A. Cycle Phase
                        cyclePhaseSection

                        // B. Cycle Season
                        if showSeasons {
                            cycleSeasonSection
                        }

                        // C. Tips
                        tipsSection

                        // D. Daily Notes
                        dailyNotesSection

                        // E. Cycle Notes
                        cycleNotesSection
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Cycle Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Theme.mutedForeground)
                    }
                }
            }
            .task {
                await vm.load(userId: userId, date: viewingDate, cycleDay: cycleDay)
            }
        }
    }

    // MARK: - A. Cycle Phase

    private var cyclePhaseSection: some View {
        Group {
            if let phaseInfo = getCurrentPhase(cycleDay: cycleDay, cycleLength: cycleLength) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(hex: phaseInfo.phase.color))
                            .frame(width: 12, height: 12)

                        Text(phaseInfo.phase.label)
                            .font(.headline)
                            .foregroundStyle(Theme.foreground)
                    }

                    Text("Day \(phaseInfo.dayWithinPhase) of \(phaseInfo.totalPhaseDays)")
                        .font(.subheadline)
                        .foregroundStyle(Theme.mutedForeground)

                    // Next phase transition
                    if let nextPhase = phaseInfo.nextPhase {
                        let daysRemaining = phaseInfo.totalPhaseDays - phaseInfo.dayWithinPhase
                        if daysRemaining <= 2 {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.forward.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(Theme.warning)
                                Text("\(nextPhase.label) phase starts in \(daysRemaining + 1) day\(daysRemaining == 0 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundStyle(Theme.warning)
                            }
                            .padding(8)
                            .background(Theme.warning.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .themedCard()
            }
        }
    }

    // MARK: - B. Cycle Season

    private var cycleSeasonSection: some View {
        Group {
            if let season = getCurrentSeason(cycleDay: cycleDay, cycleLength: cycleLength) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Text(season.emoji)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(season.name)
                                .font(.headline)
                                .foregroundStyle(Theme.foreground)
                            Text(season.phaseLabel)
                                .font(.caption)
                                .foregroundStyle(Theme.mutedForeground)
                        }
                    }

                    Text(season.description)
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryForeground)

                    // Artwork placeholder
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: season.color).opacity(0.15))
                        .frame(height: 80)
                        .overlay(
                            Text("Artwork coming soon")
                                .font(.caption)
                                .foregroundStyle(Theme.mutedForeground)
                        )
                }
                .themedCard()
            }
        }
    }

    // MARK: - C. Tips

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tips")
                .font(.headline)
                .foregroundStyle(Theme.foreground)

            let filteredReminders = vm.remindersForDay(cycleDay)

            if filteredReminders.isEmpty {
                VStack(spacing: 8) {
                    let empty = getEmptyStateCopy(section: .reminders)
                    Text(empty.heading)
                        .font(.subheadline)
                        .foregroundStyle(Theme.mutedForeground)
                    Text("Your tip feed is empty")
                        .font(.caption)
                        .foregroundStyle(Theme.mutedForeground)

                    NavigationLink(destination: EmptyView()) {
                        Text("Browse Tip Packs in Settings")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Theme.primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Theme.primary.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                // Group by category
                let grouped = Dictionary(grouping: filteredReminders, by: \.category)
                ForEach(grouped.keys.sorted(), id: \.self) { category in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(category.capitalized)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.primary)
                            .textCase(.uppercase)

                        ForEach(grouped[category] ?? []) { reminder in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(reminder.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(Theme.foreground)

                                if let body = reminder.body, !body.isEmpty {
                                    Text(body)
                                        .font(.caption)
                                        .foregroundStyle(Theme.mutedForeground)
                                }
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Theme.cardBorder, lineWidth: 0.5)
                            )
                        }
                    }
                }
            }
        }
        .themedCard()
    }

    // MARK: - D. Daily Notes

    private var dailyNotesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Daily Notes")
                    .font(.headline)
                    .foregroundStyle(Theme.foreground)
                Spacer()
                if vm.dailyNote != nil {
                    Button {
                        Task {
                            if let note = vm.dailyNote {
                                try? await NotesService().deleteDailyNote(id: note.id)
                                vm.dailyNote = nil
                                vm.noteText = ""
                            }
                        }
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(Theme.destructive)
                    }
                }
            }

            TextEditor(text: $vm.noteText)
                .font(.subheadline)
                .foregroundStyle(Theme.foreground)
                .frame(minHeight: 80)
                .padding(8)
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Theme.cardBorder, lineWidth: 0.5)
                )
                .overlay(alignment: .topLeading) {
                    if vm.noteText.isEmpty {
                        Text(getCyclingCopy(options: [
                            "How are you feeling today?",
                            "Jot down your thoughts...",
                            "Capture your day..."
                        ]))
                        .font(.subheadline)
                        .foregroundStyle(Theme.mutedForeground)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                    }
                }

            Button {
                Task { await vm.saveDailyNote(userId: userId, date: viewingDate) }
            } label: {
                Text("Save Note")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Theme.primaryForeground)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(vm.noteText.isEmpty ? Theme.muted : Theme.primary)
                    .clipShape(Capsule())
            }
            .disabled(vm.noteText.isEmpty)
        }
        .themedCard()
    }

    // MARK: - E. Cycle Notes

    private var cycleNotesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Cycle Notes")
                .font(.headline)
                .foregroundStyle(Theme.foreground)

            let nearbyDays = [max(1, cycleDay - 1), cycleDay, min(cycleLength, cycleDay + 1)]
            let uniqueDays = Array(Set(nearbyDays)).sorted()

            ForEach(uniqueDays, id: \.self) { day in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Day \(day)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(day == cycleDay ? Theme.primary : Theme.mutedForeground)

                        if day == cycleDay {
                            Text("(today)")
                                .font(.caption2)
                                .foregroundStyle(Theme.primary)
                        }

                        Spacer()

                        if let text = vm.cycleNoteTexts[day], !text.isEmpty {
                            Button {
                                Task { await vm.saveCycleNote(userId: userId, cycleDay: day) }
                            } label: {
                                Text("Save")
                                    .font(.caption2)
                                    .foregroundStyle(Theme.primary)
                            }
                        }
                    }

                    // Existing note or editable text
                    let binding = Binding<String>(
                        get: { vm.cycleNoteTexts[day] ?? "" },
                        set: { vm.cycleNoteTexts[day] = $0 }
                    )

                    TextField(getCyclingCopy(options: [
                        "Note for day \(day)...",
                        "How do you feel on day \(day)?",
                        "Track patterns..."
                    ]), text: binding, axis: .vertical)
                        .font(.caption)
                        .lineLimit(2...4)
                        .padding(8)
                        .background(Theme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(day == cycleDay ? Theme.primary.opacity(0.3) : Theme.cardBorder, lineWidth: 0.5)
                        )
                }
            }
        }
        .themedCard()
    }
}
