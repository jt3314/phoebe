import SwiftUI

struct CalendarView: View {
    @Bindable var authVM: AuthViewModel
    @State private var vm = CalendarViewModel()
    @State private var selectedDate: Date?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // View mode picker
                    Picker("View", selection: $vm.viewMode) {
                        ForEach(CalendarViewModel.ViewMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    if vm.cycle == nil && !vm.isLoading {
                        Spacer()
                        EmptyStateView(
                            icon: "calendar.badge.exclamationmark",
                            title: "No cycle configured",
                            message: "Set up your energy cycle in the Setup tab to see your calendar."
                        )
                        Spacer()
                    } else {
                        switch vm.viewMode {
                        case .month:
                            monthView
                        case .cycle:
                            cycleView
                        }
                    }
                }
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if let userId = authVM.currentUserId {
                    await vm.load(userId: userId)
                }
            }
        }
    }

    // MARK: - Month View

    private var monthView: some View {
        VStack(spacing: 8) {
            HStack {
                Button { vm.previousMonth() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(Theme.foreground)
                }
                Spacer()
                Text(vm.monthTitle)
                    .font(.headline)
                    .foregroundStyle(Theme.foreground)
                Spacer()
                Button("Today") { vm.goToToday() }
                    .font(.caption)
                    .foregroundStyle(Theme.primary)
                Button { vm.nextMonth() } label: {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Theme.foreground)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Weekday headers
            let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(Theme.mutedForeground)
                }
            }
            .padding(.horizontal, 8)

            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                    ForEach(0..<vm.firstWeekdayOffset, id: \.self) { _ in
                        Color.clear.frame(height: 70)
                    }

                    ForEach(vm.daysInMonth, id: \.self) { date in
                        MonthDayCellView(
                            date: date,
                            isToday: Calendar.current.isDateInToday(date),
                            cycleDay: vm.cycleDayForDate(date),
                            effort: vm.effortForDate(date),
                            showCycleInfo: vm.showCycleInfo
                        )
                        .onTapGesture { selectedDate = date }
                    }
                }
                .padding(.horizontal, 8)
            }
        }
    }

    // MARK: - Cycle View

    private var cycleView: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(vm.cycleDays, id: \.day) { item in
                    CycleDayCellView(
                        day: item.day,
                        effort: item.effort,
                        intensity: vm.effortIntensity(effort: item.effort),
                        isCurrentDay: vm.cycleDayForDate(Date()) == item.day
                    )
                }
            }
            .padding()

            legendView
                .padding(.horizontal)
        }
    }

    // MARK: - Legend

    private var legendView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Legend")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.foreground)

            HStack(spacing: 4) {
                Text("Low")
                    .font(.caption2)
                    .foregroundStyle(Theme.mutedForeground)
                ForEach(Theme.lunarColors.indices, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.lunarColors[i])
                        .frame(width: 20, height: 12)
                }
                Text("High")
                    .font(.caption2)
                    .foregroundStyle(Theme.mutedForeground)
            }
        }
        .themedCard()
    }
}

// MARK: - Month Day Cell

struct MonthDayCellView: View {
    let date: Date
    let isToday: Bool
    let cycleDay: Int?
    let effort: (available: Int, scheduled: Int)?
    let showCycleInfo: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.caption)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(isToday ? Theme.primary : Theme.foreground)

            if showCycleInfo, let cd = cycleDay {
                Text("D\(cd)")
                    .font(.system(size: 8))
                    .foregroundStyle(Theme.mutedForeground)
            }

            if let effort {
                Text("\(effort.scheduled)/\(effort.available)")
                    .font(.system(size: 8))
                    .foregroundStyle(effortColor(scheduled: effort.scheduled, available: effort.available))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 70)
        .background(isToday ? Theme.primary.opacity(0.08) : Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isToday ? Theme.primary : Theme.cardBorder.opacity(0.5), lineWidth: isToday ? 1.5 : 0.5)
        )
    }

    private func effortColor(scheduled: Int, available: Int) -> Color {
        if scheduled > available { return Theme.destructive }
        if scheduled == available { return Theme.warning }
        return Theme.mutedForeground
    }
}

// MARK: - Cycle Day Cell

struct CycleDayCellView: View {
    let day: Int
    let effort: Int
    let intensity: Double
    let isCurrentDay: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text("D\(day)")
                .font(.caption2)
                .fontWeight(.medium)
            Text("\(effort)")
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundStyle(intensity > 0.85 ? .white : Theme.foreground)
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(lunarColor)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(isCurrentDay ? Theme.primary : Color.clear, lineWidth: 2.5)
        )
    }

    private var lunarColor: Color {
        if effort == 0 { return Theme.secondary.opacity(0.3) }
        let colors = Theme.lunarColors
        let index = min(Int(intensity * Double(colors.count - 1)), colors.count - 1)
        return colors[index]
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
