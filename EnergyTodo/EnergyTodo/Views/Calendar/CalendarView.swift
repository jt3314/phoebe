import SwiftUI

struct CalendarView: View {
    @Bindable var authVM: AuthViewModel
    @State private var vm = CalendarViewModel()
    @State private var selectedDayDate: Date?
    @State private var showDayDetail = false

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
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                    if vm.cycle == nil && !vm.isLoading {
                        Spacer()
                        EmptyStateView(
                            icon: "calendar.badge.exclamationmark",
                            title: "No cycle configured",
                            message: "Set up your energy cycle in Settings to see your calendar."
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
            .sheet(isPresented: $showDayDetail) {
                if let date = selectedDayDate {
                    let dateStr = CycleCalculator.formatISO(date)
                    DayDetailSheet(
                        date: date,
                        dateString: dateStr,
                        cycleDay: vm.cycleDayForDate(date),
                        googleEvents: vm.googleEventsByDate[dateStr] ?? [],
                        phoebeEvents: [],
                        tasks: vm.tasksByDate[dateStr] ?? [],
                        standaloneTasks: vm.standaloneByDate[dateStr] ?? [],
                        effort: vm.effortForDate(date)
                    )
                }
            }
        }
    }

    // MARK: - Month View

    private var monthView: some View {
        VStack(spacing: 12) {
            // Month navigation
            HStack {
                Button { vm.previousMonth() } label: {
                    Image(systemName: "chevron.left")
                        .font(.body)
                        .foregroundStyle(Theme.foreground)
                        .frame(width: 36, height: 36)
                }
                Spacer()
                Text(vm.monthTitle)
                    .font(.headline)
                    .foregroundStyle(Theme.foreground)
                Spacer()
                Button("Today") { vm.goToToday() }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Theme.primary)
                Button { vm.nextMonth() } label: {
                    Image(systemName: "chevron.right")
                        .font(.body)
                        .foregroundStyle(Theme.foreground)
                        .frame(width: 36, height: 36)
                }
            }
            .padding(.horizontal, 16)

            // Weekday headers
            let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.mutedForeground)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 12)

            // Day grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                // Offset for first day
                ForEach(0..<vm.firstWeekdayOffset, id: \.self) { _ in
                    Color.clear.frame(height: 56)
                }

                ForEach(vm.daysInMonth, id: \.self) { date in
                    let dateStr = CycleCalculator.formatISO(date)
                    let hasGoogleEvents = !(vm.googleEventsByDate[dateStr] ?? []).isEmpty
                    MonthDayCellView(
                        date: date,
                        isToday: Calendar.current.isDateInToday(date),
                        cycleDay: vm.cycleDayForDate(date),
                        effort: vm.effortForDate(date),
                        showCycleInfo: vm.showCycleInfo,
                        hasGoogleEvents: hasGoogleEvents
                    )
                    .onTapGesture {
                        selectedDayDate = date
                        showDayDetail = true
                    }
                }
            }
            .padding(.horizontal, 12)

            Spacer()
        }
    }

    // MARK: - Cycle View

    private var cycleView: some View {
        ScrollView {
            VStack(spacing: 16) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                    ForEach(vm.cycleDays, id: \.day) { item in
                        CycleDayCellView(
                            day: item.day,
                            date: item.date,
                            effort: item.effort,
                            intensity: vm.effortIntensity(effort: item.effort),
                            isCurrentDay: vm.cycleDayForDate(Date()) == item.day
                        )
                    }
                }
                .padding(.horizontal, 12)

                legendView
                    .padding(.horizontal, 16)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Legend

    private var legendView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Legend")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.foreground)

            HStack(spacing: 3) {
                Text("Low")
                    .font(.caption2)
                    .foregroundStyle(Theme.mutedForeground)
                ForEach(Theme.lunarColors.indices, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Theme.lunarColors[i])
                        .frame(width: 24, height: 14)
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
    var hasGoogleEvents: Bool = false

    private let isWeekend: Bool

    init(date: Date, isToday: Bool, cycleDay: Int?, effort: (available: Int, scheduled: Int)?, showCycleInfo: Bool, hasGoogleEvents: Bool = false) {
        self.date = date
        self.isToday = isToday
        self.cycleDay = cycleDay
        self.effort = effort
        self.showCycleInfo = showCycleInfo
        self.hasGoogleEvents = hasGoogleEvents
        let wd = Calendar.current.component(.weekday, from: date)
        self.isWeekend = wd == 1 || wd == 7
    }

    var body: some View {
        VStack(spacing: 1) {
            HStack(spacing: 2) {
                Spacer()
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 14, weight: isToday ? .bold : .medium))
                    .foregroundStyle(isToday ? Theme.primary : Theme.foreground)
                Spacer()
            }

            if showCycleInfo, let cd = cycleDay {
                Text("D\(cd)")
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.mutedForeground)
            }

            if let effort {
                Text("\(effort.scheduled)/\(effort.available)")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(effortColor(scheduled: effort.scheduled, available: effort.available))
            }

            // Event indicator dots
            if hasGoogleEvents {
                Circle()
                    .fill(Theme.primary.opacity(0.6))
                    .frame(width: 4, height: 4)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(cellBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isToday ? Theme.primary : Color.clear, lineWidth: isToday ? 2 : 0)
        )
    }

    private var cellBackground: Color {
        if isToday { return Theme.primary.opacity(0.12) }
        if isWeekend { return Theme.muted.opacity(0.5) }
        return Theme.card
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
    let date: String
    let effort: Int
    let intensity: Double
    let isCurrentDay: Bool

    var body: some View {
        VStack(spacing: 1) {
            Text("D\(day)")
                .font(.system(size: 10, weight: .semibold))
            Text("\(effort)")
                .font(.system(size: 13, weight: .bold))

            // Show short date
            if let d = CycleCalculator.parseISO(date) {
                Text(shortDate(d))
                    .font(.system(size: 8))
                    .opacity(0.7)
            }
        }
        .foregroundStyle(intensity > 0.8 ? .white : Theme.foreground)
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(lunarColor)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(isCurrentDay ? Theme.primary : Color.clear, lineWidth: 2.5)
        )
        .scaleEffect(isWeekend ? 0.9 : 1.0)
    }

    private var isWeekend: Bool {
        CycleCalculator.isWeekendDay(date: date)
    }

    private var lunarColor: Color {
        if effort == 0 { return Theme.secondary.opacity(0.2) }
        let colors = Theme.lunarColors
        let index = min(Int(intensity * Double(colors.count - 1)), colors.count - 1)
        return colors[index]
    }

    private func shortDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "M/d"
        return f.string(from: d)
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
