import SwiftUI

struct ConflictsListView: View {
    @Bindable var authVM: AuthViewModel
    @State private var vm = ConflictsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.conflicts.isEmpty {
                    EmptyStateView(
                        icon: "checkmark.shield",
                        title: "No conflicts",
                        message: "All your projects are on track. Scheduling conflicts will appear here when detected."
                    )
                } else {
                    List {
                        ForEach(vm.conflicts) { conflict in
                            ConflictRowView(
                                conflict: conflict,
                                projectName: conflict.projectId.flatMap { vm.projectNames[$0] }
                            )
                            .swipeActions {
                                Button("Resolve") {
                                    Task { await vm.resolveConflict(conflict) }
                                }
                                .tint(.green)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Conflicts")
            .task {
                if let userId = authVM.currentUserId {
                    await vm.load(userId: userId)
                }
            }
        }
    }
}

struct ConflictRowView: View {
    let conflict: SchedulingConflict
    let projectName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
                        .foregroundStyle(.secondary)
                }
            }

            Text(conflict.description)
                .font(.subheadline)

            if let suggestion = conflict.suggestion {
                Text(suggestion)
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 4)
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
}
