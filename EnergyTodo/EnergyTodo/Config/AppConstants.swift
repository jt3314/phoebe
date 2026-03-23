import Foundation

enum AppConstants {
    static let maxCycleLength = 99
    static let minCycleLength = 1
    static let maxPriority = 10
    static let minPriority = 1
    static let defaultCycleLength = 35
    static let maxEffortPoints = 50
    static let schedulingHorizonDays = 365

    static let commonCycleLengths: [(value: Int, label: String)] = [
        (7, "7 days (Weekly)"),
        (14, "14 days (Bi-weekly)"),
        (21, "21 days"),
        (28, "28 days (Lunar)"),
        (30, "30 days (Monthly)"),
        (35, "35 days (Recommended)"),
    ]

    /// Lunar-inspired effort color palette (low to high intensity)
    static let effortColors: [String] = [
        "#FCF5F2", "#F9EBE4", "#F5DED2", "#F0CFBD",
        "#E8B89D", "#DFA07D", "#D4845A",
    ]
}
