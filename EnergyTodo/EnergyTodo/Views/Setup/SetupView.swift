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
        .navigationTitle("Cycle Setup")
        .task {
            if let userId = authVM.currentUserId {
                await vm.load(userId: userId)
            }
        }
    }

    private var setupContent: some View {
        List {
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

            // Effort points grid
            Section("Effort Points") {
                EffortPointsGridView(
                    effortPoints: vm.effortPoints,
                    cycleLength: vm.cycle?.length ?? 0
                )
            }

            if let error = vm.errorMessage {
                Section {
                    Text(error).foregroundStyle(.red).font(.caption)
                }
            }
        }
        .listStyle(.insetGrouped)
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
