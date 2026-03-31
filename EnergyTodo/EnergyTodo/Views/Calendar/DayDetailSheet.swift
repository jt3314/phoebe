import SwiftUI

struct DayDetailSheet: View {
    let date: Date
    let dateString: String
    let cycleDay: Int?
    let googleEvents: [GoogleCalendarEvent]
    let phoebeEvents: [PhoebeEvent]
    let tasks: [Task_]
    let standaloneTasks: [StandaloneTask]
    let effort: (available: Int, scheduled: Int)?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Day summary
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(dateLabel)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Theme.foreground)

                                if let cd = cycleDay {
                                    Text("Cycle Day \(cd)")
                                        .font(.subheadline)
                                        .foregroundStyle(Theme.mutedForeground)
                                }
                            }
                            Spacer()
                            if let effort {
                                VStack(alignment: .trailing) {
                                    Text("\(effort.scheduled)/\(effort.available)")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Theme.primary)
                                    Text("effort pts")
                                        .font(.caption)
                                        .foregroundStyle(Theme.mutedForeground)
                                }
                            }
                        }
                        .themedCard()

                        // Google Calendar events
                        if !googleEvents.isEmpty {
                            sectionHeader(icon: "calendar", title: "Google Calendar", count: googleEvents.count)

                            ForEach(googleEvents) { event in
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(Theme.primary.opacity(0.3))
                                        .frame(width: 8, height: 8)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(event.summary)
                                            .font(.subheadline)
                                            .foregroundStyle(Theme.foreground)
                                        Text(event.isAllDay ? "All day" : formatTime(event.startTime, event.endTime))
                                            .font(.caption)
                                            .foregroundStyle(Theme.mutedForeground)
                                    }

                                    Spacer()

                                    EffortBadge(points: event.effortCost)
                                }
                                .themedCard()
                            }
                        }

                        // Phoebe events
                        if !phoebeEvents.isEmpty {
                            sectionHeader(icon: "heart.fill", title: "Phoebe Events", count: phoebeEvents.count)

                            ForEach(phoebeEvents) { event in
                                HStack(spacing: 10) {
                                    Image(systemName: event.eventType.icon)
                                        .font(.caption)
                                        .foregroundStyle(Theme.primary)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(event.name)
                                            .font(.subheadline)
                                            .foregroundStyle(Theme.foreground)
                                        Text(event.eventType.label)
                                            .font(.caption)
                                            .foregroundStyle(Theme.mutedForeground)
                                    }

                                    Spacer()

                                    if event.effortCost > 0 {
                                        EffortBadge(points: event.effortCost)
                                    }
                                }
                                .themedCard()
                            }
                        }

                        // Tasks
                        let allTasks = tasks.count + standaloneTasks.count
                        if allTasks > 0 {
                            sectionHeader(icon: "checkmark.circle", title: "Tasks", count: allTasks)

                            ForEach(tasks) { task in
                                HStack(spacing: 10) {
                                    Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(task.status == .completed ? Theme.success : Theme.cardBorder)

                                    Text(task.name)
                                        .font(.subheadline)
                                        .strikethrough(task.status == .completed)
                                        .foregroundStyle(task.status == .completed ? Theme.mutedForeground : Theme.foreground)

                                    Spacer()

                                    EffortBadge(points: task.effortPoints)
                                }
                                .themedCard()
                            }

                            ForEach(standaloneTasks) { task in
                                HStack(spacing: 10) {
                                    Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(task.status == .completed ? Theme.success : Theme.cardBorder)

                                    Text(task.name)
                                        .font(.subheadline)
                                        .strikethrough(task.status == .completed)
                                        .foregroundStyle(task.status == .completed ? Theme.mutedForeground : Theme.foreground)

                                    Spacer()

                                    EffortBadge(points: task.effortPoints)
                                }
                                .themedCard()
                            }
                        }

                        // Empty state
                        if googleEvents.isEmpty && phoebeEvents.isEmpty && allTasks == 0 {
                            VStack(spacing: 8) {
                                Image(systemName: "calendar.badge.checkmark")
                                    .font(.system(size: 30))
                                    .foregroundStyle(Theme.mutedForeground)
                                Text("Nothing scheduled")
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.mutedForeground)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Day Details")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }

    private func formatTime(_ start: Date, _ end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }

    private func sectionHeader(icon: String, title: String, count: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Theme.primary)
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.mutedForeground)
            Text("(\(count))")
                .font(.caption)
                .foregroundStyle(Theme.mutedForeground)
            Spacer()
        }
    }
}
