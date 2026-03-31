import SwiftUI

struct SetupView: View {
    @Bindable var authVM: AuthViewModel
    @State private var vm = SetupViewModel()

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vm.cycle == nil {
                EmptyStateView(
                    icon: "arrow.triangle.2.circlepath",
                    title: "No cycle configured",
                    message: "Set up your energy cycle to start tracking your energy patterns."
                )
            } else {
                setupContent
            }
        }
        .navigationTitle("Settings")
        .task {
            if let userId = authVM.currentUserId {
                await vm.load(userId: userId)
            }
        }
    }

    private var setupContent: some View {
        List {
            // Privacy Notice
            Section {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Data is Private")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.foreground)

                        Text("Your cycle data, tasks, and notes are encrypted and only visible to you. We never share your health information with third parties.")
                            .font(.caption)
                            .foregroundStyle(Theme.mutedForeground)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(12)
                .background(Color.blue.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }

            // Current cycle info
            Section("Current Cycle") {
                if let day = vm.currentCycleDay {
                    LabeledContent("Current Day", value: "Day \(day)")
                }
                LabeledContent("Cycle Length", value: "\(vm.cycle?.length ?? 0) days")
                LabeledContent("Day 1 Started", value: vm.day1DateFormatted)
            }

            // Restart cycle
            Section {
                Button("Mark Today as Day 1") {
                    Task { await vm.restartCycle() }
                }
            } header: {
                Text("Restart Cycle")
            } footer: {
                Text("This resets your cycle start date to today.")
            }

            // Change length
            Section {
                HStack {
                    TextField("Length", value: $vm.newLength, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 100)

                    Text("days")
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button {
                        Task { await vm.updateLength() }
                    } label: {
                        if vm.isUpdatingLength {
                            ProgressView()
                        } else {
                            Text("Update")
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(!EffortCalculator.isValidCycleLength(vm.newLength) || vm.newLength == vm.cycle?.length)
                }
            } header: {
                Text("Cycle Length")
            } footer: {
                Text("Changing cycle length will add or remove days with default effort values.")
            }

            // Scheduling Direction
            Section {
                SchedulingDirectionView(selectedDirection: $vm.schedulingDirection)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .onChange(of: vm.schedulingDirection) {
                        Task { await vm.saveSchedulingDirection() }
                    }
            } header: {
                Text("Scheduling Direction")
            } footer: {
                Text("Choose how tasks are distributed across your available days.")
            }

            // Tip Packs
            Section {
                TipPacksView(
                    sources: vm.reminderSources,
                    userSources: vm.userReminderSources,
                    userId: authVM.currentUserId ?? UUID()
                ) { sourceId, enabled in
                    Task { await vm.toggleTipPack(sourceId: sourceId, enabled: enabled) }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            } header: {
                Text("Tip Packs")
            } footer: {
                Text("Enable tip packs to receive cycle-aware reminders and wellness suggestions.")
            }

            // Cycle Seasons toggle
            Section {
                Toggle(isOn: $vm.showSeasons) {
                    HStack(spacing: 10) {
                        Image(systemName: "leaf")
                            .foregroundStyle(Theme.primary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Show Cycle Seasons")
                                .font(.subheadline)
                                .foregroundStyle(Theme.foreground)
                            Text("Display seasonal metaphors in the reminders sidebar")
                                .font(.caption)
                                .foregroundStyle(Theme.mutedForeground)
                        }
                    }
                }
                .tint(Theme.primary)
                .onChange(of: vm.showSeasons) {
                    Task { await vm.saveShowSeasons() }
                }
            }

            // Effort points grid
            Section("Effort Points") {
                EffortPointsGridView(
                    effortPoints: vm.effortPoints,
                    cycleLength: vm.cycle?.length ?? 0
                )
            }

            // Upcoming Features
            Section("Upcoming Features") {
                UpcomingFeaturesView(userId: authVM.currentUserId ?? UUID())
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

            // Conflicts link
            Section {
                NavigationLink {
                    ConflictsListView(authVM: authVM)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(Theme.warning)
                        Text("Scheduling Conflicts")
                            .foregroundStyle(Theme.foreground)
                    }
                }
            }

            if let error = vm.errorMessage {
                Section {
                    Text(error).foregroundStyle(.red).font(.caption)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
    }
}

// MARK: - Effort Points Grid

struct EffortPointsGridView: View {
    let effortPoints: [CycleEffortPoint]
    let cycleLength: Int

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    private let maxDisplay = 35

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(effortPoints.prefix(maxDisplay)) { point in
                    VStack(spacing: 2) {
                        Text("D\(point.dayNumber)")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                        Text("\(point.effortPoints)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(effortColor(point.effortPoints))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }

            if cycleLength > maxDisplay {
                Text("Showing first \(maxDisplay) of \(cycleLength) days")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func effortColor(_ effort: Int) -> Color {
        if effort == 0 { return Color.secondary.opacity(0.1) }
        let maxEffort = effortPoints.map(\.effortPoints).max() ?? 15
        let intensity = Double(effort) / Double(max(1, maxEffort))
        let colors = AppConstants.effortColors
        let index = min(Int(intensity * Double(colors.count - 1)), colors.count - 1)
        return Color(hex: colors[index])
    }
}
