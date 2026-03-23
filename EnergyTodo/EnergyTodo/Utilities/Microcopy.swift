import Foundation

// MARK: - Seeded Random

/// Returns a seed based on the current hour (changes every hour).
func getHourSeed() -> Int {
    let now = Date()
    let calendar = Calendar.current
    let components = calendar.dateComponents([.year, .month, .day, .hour], from: now)
    return (components.year ?? 0) * 1000000
        + (components.month ?? 0) * 10000
        + (components.day ?? 0) * 100
        + (components.hour ?? 0)
}

/// Simple seeded pseudo-random number generator returning 0..<1.
func seededRandom(seed: Int) -> Double {
    var s = seed
    s = ((s &* 1103515245) &+ 12345) & 0x7FFFFFFF
    return Double(s) / Double(0x7FFFFFFF)
}

// MARK: - Cycling Copy

func getCyclingCopy(options: [String], salt: Int = 0) -> String {
    guard !options.isEmpty else { return "" }
    let seed = getHourSeed() &+ salt
    let index = Int(seededRandom(seed: seed) * Double(options.count)) % options.count
    return options[index]
}

// MARK: - Empty State Copy

struct EmptyStateCopy {
    let heading: String
    let cta: String
}

private let emptyStateProjects: [(heading: String, cta: String)] = [
    ("No projects yet", "Create your first project to get started"),
    ("Your project list is empty", "Start by adding a project"),
    ("Nothing here yet", "Tap + to create a project"),
]

private let emptyStateStandaloneTasks: [(heading: String, cta: String)] = [
    ("No standalone tasks", "Add a quick task that doesn't belong to a project"),
    ("Your task list is clear", "Create a standalone task to track something"),
    ("Nothing to do?", "Add a task to get started"),
]

private let emptyStateRecurringTasks: [(heading: String, cta: String)] = [
    ("No recurring tasks", "Set up tasks that repeat on a schedule"),
    ("Nothing recurring yet", "Create a task that comes back automatically"),
    ("No repeating tasks", "Add a recurring task to stay on track"),
]

private let emptyStateTodayTasks: [(heading: String, cta: String)] = [
    ("Nothing scheduled today", "Enjoy your free day or schedule some tasks"),
    ("Today is clear", "You're all caught up!"),
    ("No tasks for today", "Schedule tasks to fill your day"),
]

private let emptyStateMilestones: [(heading: String, cta: String)] = [
    ("No milestones yet", "Break your project into milestones"),
    ("No milestones", "Add milestones to track progress"),
    ("Milestone-free", "Create milestones to organize your tasks"),
]

private let emptyStateProjectTasks: [(heading: String, cta: String)] = [
    ("No tasks in this project", "Add tasks to get things done"),
    ("This project is empty", "Create your first task"),
    ("Nothing here yet", "Start adding tasks to this project"),
]

private let emptyStateDailyNotes: [(heading: String, cta: String)] = [
    ("No notes for today", "Jot down how you're feeling"),
    ("Your journal is empty", "Write a note about your day"),
    ("Nothing written yet", "Capture your thoughts"),
]

private let emptyStateCycleNotes: [(heading: String, cta: String)] = [
    ("No cycle notes yet", "Track patterns across your cycle"),
    ("Nothing noted", "Add notes about this cycle day"),
    ("No notes here", "Record how you feel on this cycle day"),
]

private let emptyStateReminders: [(heading: String, cta: String)] = [
    ("No reminders", "Enable a reminder source to get tips"),
    ("Nothing to remind you", "Set up reminders for helpful nudges"),
    ("Reminders are quiet", "Turn on a source to start receiving reminders"),
]

private let emptyStateConflicts: [(heading: String, cta: String)] = [
    ("No conflicts", "Everything looks good!"),
    ("All clear", "No scheduling conflicts found"),
    ("No issues", "Your schedule is conflict-free"),
]

enum EmptyStateSection: String {
    case projects
    case standaloneTasks
    case recurringTasks
    case todayTasks
    case milestones
    case projectTasks
    case dailyNotes
    case cycleNotes
    case reminders
    case conflicts
}

func getEmptyStateCopy(section: EmptyStateSection, salt: Int = 0) -> (heading: String, cta: String) {
    let options: [(heading: String, cta: String)]
    switch section {
    case .projects: options = emptyStateProjects
    case .standaloneTasks: options = emptyStateStandaloneTasks
    case .recurringTasks: options = emptyStateRecurringTasks
    case .todayTasks: options = emptyStateTodayTasks
    case .milestones: options = emptyStateMilestones
    case .projectTasks: options = emptyStateProjectTasks
    case .dailyNotes: options = emptyStateDailyNotes
    case .cycleNotes: options = emptyStateCycleNotes
    case .reminders: options = emptyStateReminders
    case .conflicts: options = emptyStateConflicts
    }

    guard !options.isEmpty else { return ("", "") }
    let seed = getHourSeed() &+ salt
    let index = Int(seededRandom(seed: seed) * Double(options.count)) % options.count
    return options[index]
}

// MARK: - Sleep Check Copy

private let sleepCheckGreetings = [
    "Good morning! How did you sleep?",
    "Rise and shine! How was your night?",
    "Morning! How are you feeling today?",
]

private let sleepCheckWellOptions = [
    "Slept great!",
    "Pretty well, thanks!",
    "Like a baby 😴",
]

private let sleepCheckPoorlyOptions = [
    "Not the best...",
    "Could have been better",
    "Rough night 😩",
]

func getSleepCheckCopy(salt: Int = 0) -> (greeting: String, wellOption: String, poorlyOption: String) {
    let seed = getHourSeed() &+ salt
    let greetingIndex = Int(seededRandom(seed: seed) * Double(sleepCheckGreetings.count)) % sleepCheckGreetings.count
    let wellIndex = Int(seededRandom(seed: seed &+ 1) * Double(sleepCheckWellOptions.count)) % sleepCheckWellOptions.count
    let poorlyIndex = Int(seededRandom(seed: seed &+ 2) * Double(sleepCheckPoorlyOptions.count)) % sleepCheckPoorlyOptions.count
    return (
        greeting: sleepCheckGreetings[greetingIndex],
        wellOption: sleepCheckWellOptions[wellIndex],
        poorlyOption: sleepCheckPoorlyOptions[poorlyIndex]
    )
}

// MARK: - Success Messages

struct SuccessMessages {
    static let taskCompleted = [
        "Nice work! Task complete ✓",
        "Done and dusted!",
        "Checked off! Keep going 💪",
    ]

    static let projectCreated = [
        "Project created! Time to add some tasks.",
        "New project ready to go!",
        "Your project is set up. Let's get to work!",
    ]

    static let taskAdded = [
        "Task added!",
        "Got it! Task is on the list.",
        "Added to your tasks.",
    ]

    static let allTasksComplete = [
        "All done for today! 🎉",
        "You crushed it! Everything's complete.",
        "Nothing left to do. Enjoy your free time!",
    ]
}

// MARK: - Day 1 Postcard Copy

struct Day1PostcardCopy {
    static let bannerHeading = [
        "It's Day 1!",
        "A new cycle begins",
        "Fresh start today",
    ]

    static let bannerCta = [
        "See what's ahead →",
        "Check your energy forecast →",
        "View your cycle plan →",
    ]

    static let postcardHeading = [
        "Welcome to a new cycle",
        "Day 1 is here",
        "A fresh cycle begins",
    ]

    static let postcardBody = [
        "Your energy will shift over the coming weeks. We've adjusted your schedule to match.",
        "A new cycle means a new rhythm. Your tasks are aligned with your energy forecast.",
        "Everything is recalibrated for this cycle. Take it easy today.",
    ]

    static let postcardFooter = [
        "Take care of yourself today ❤️",
        "Rest well — big energy is coming soon",
        "Ease into it. You've got this.",
    ]
}

// MARK: - Phase Transition Messages

/// Returns a message for transitioning into a new phase.
/// Supports template replacement: `{phaseName}`, `{seasonName}`, `{emoji}`.
func getPhaseTransitionMessage(phaseId: CyclePhaseId) -> String {
    let templates: [CyclePhaseId: [String]] = [
        .menstrual: [
            "Entering {phaseName} phase {emoji}. Time to slow down and prioritize rest.",
            "Welcome to {seasonName} {emoji}. Your body needs rest — we've lightened your load.",
        ],
        .follicular: [
            "You're moving into {phaseName} phase {emoji}. Energy is building!",
            "{seasonName} is here {emoji}. Great time to plan and start new things.",
        ],
        .ovulation: [
            "{phaseName} phase {emoji} — you're at your peak! Take on big challenges.",
            "It's {seasonName} {emoji}! Your energy is highest. Make the most of it.",
        ],
        .luteal: [
            "Entering {phaseName} phase {emoji}. Start winding down and wrapping up.",
            "{seasonName} is here {emoji}. Focus on finishing what you've started.",
        ],
    ]

    let options = templates[phaseId] ?? []
    guard !options.isEmpty else { return "" }
    let seed = getHourSeed()
    let index = Int(seededRandom(seed: seed) * Double(options.count)) % options.count
    var message = options[index]

    if let season = getSeasonForPhase(phaseId: phaseId) {
        message = message.replacingOccurrences(of: "{phaseName}", with: season.phaseLabel)
        message = message.replacingOccurrences(of: "{seasonName}", with: season.name)
        message = message.replacingOccurrences(of: "{emoji}", with: season.emoji)
    }

    return message
}
