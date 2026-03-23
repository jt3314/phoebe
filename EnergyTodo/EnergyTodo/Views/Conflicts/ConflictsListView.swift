import SwiftUI

struct ConflictsListView: View {
    @Bindable var authVM: AuthViewModel
    @State private var vm = ConflictsViewModel()

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vm.conflicts.isEmpty {
                let empty = getEmptyStateCopy(section: .conflicts)
                EmptyStateView(
                    icon: "checkmark.shield",
                    title: empty.heading,
                    message: empty.cta
                )
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(sortedConflicts) { conflict in
                            ConflictCardView(
                                conflict: conflict,
                                projectName: conflict.projectId.flatMap { vm.projectNames[$0] },
                                onDismiss: {
                                    Task { await vm.resolveConflict(conflict) }
                                }
                            )
                        }
                    }
                    .padding(16)
                }
                .background(Theme.background)
            }
        }
        .navigationTitle("Conflicts")
        .task {
            if let userId = authVM.currentUserId {
                await vm.load(userId: userId)
            }
        }
    }

    /// Sorted: critical first, then by newest
    private var sortedConflicts: [SchedulingConflict] {
        vm.conflicts.sorted { a, b in
            if a.severity != b.severity {
                return a.severity == .critical
            }
            return a.createdAt > b.createdAt
        }
    }
}

// MARK: - Conflict Card

struct ConflictCardView: View {
    let conflict: SchedulingConflict
    let projectName: String?
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header badges
            HStack {
                // Type badge
                Text(typeLabel)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(typeColor.opacity(0.15))
                    .foregroundStyle(typeColor)
                    .clipShape(Capsule())

                // Severity badge
                Text(conflict.severity.rawValue.capitalized)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(severityColor.opacity(0.15))
                    .foregroundStyle(severityColor)
                    .clipShape(Capsule())

                Spacer()

                if let name = projectName {
                    Text(name)
                        .font(.caption)
                        .foregroundStyle(Theme.mutedForeground)
                }
            }

            // Description
            Text(conflict.description)
                .font(.subheadline)
                .foregroundStyle(Theme.foreground)

            // Affected dates pills
            if let datesStr = conflict.affectedDates,
               let data = datesStr.data(using: .utf8),
               let dates = try? JSONDecoder().decode([String].self, from: data),
               !dates.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(dates, id: \.self) { date in
                            Text(formatShortDate(date))
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Theme.secondary)
                                .foregroundStyle(Theme.secondaryForeground)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            // Suggestion
            if let suggestion = conflict.suggestion {
                Text(suggestion)
                    .font(.caption)
                    .foregroundStyle(.blue)
            }

            // Action buttons
            HStack(spacing: 12) {
                Button {
                    onDismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle")
                            .font(.caption)
                        Text("Dismiss")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(Theme.mutedForeground)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.secondary)
                    .clipShape(Capsule())
                }

                // Planner hint - user can switch via tab bar
                Label {
                    Text("Go to Planner")
                        .font(.caption)
                        .fontWeight(.medium)
                } icon: {
                    Image(systemName: "calendar.day.timeline.left")
                        .font(.caption)
                }
                .foregroundStyle(Theme.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Theme.primary.opacity(0.1))
                .clipShape(Capsule())
            }
        }
        .padding(14)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 1.5)
        )
    }

    private var borderColor: Color {
        switch conflict.severity {
        case .critical: return Theme.destructive.opacity(0.6)
        case .warning: return Theme.warning.opacity(0.6)
        }
    }

    private var typeLabel: String {
        switch conflict.type {
        case .impossibleDeadline: return "Deadline"
        case .overbookedDay: return "Overbooked"
        case .dependencyLoop: return "Dependency"
        }
    }

    private var typeColor: Color {
        switch conflict.type {
        case .impossibleDeadline: return .red
        case .overbookedDay: return .orange
        case .dependencyLoop: return .purple
        }
    }

    private var severityColor: Color {
        switch conflict.severity {
        case .critical: return .red
        case .warning: return .orange
        }
    }

    private func formatShortDate(_ isoDate: String) -> String {
        guard let date = CycleCalculator.parseISO(isoDate) else { return isoDate }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
