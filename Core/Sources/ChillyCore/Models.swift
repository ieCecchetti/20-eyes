import Foundation

public enum TimerKind: String, Codable, CaseIterable, Sendable {
    case repeating, pomodoro, countdown, scheduled

    public var label: String {
        switch self {
        case .repeating: "Repeating"
        case .pomodoro: "Pomodoro"
        case .countdown: "Countdown"
        case .scheduled: "Scheduled"
        }
    }
}

public enum BreakStyle: String, Codable, CaseIterable, Sendable {
    case overlay, popup

    public var label: String { self == .overlay ? "Full-screen overlay" : "Popup" }
}

public struct ClockTime: Codable, Hashable, Sendable {
    public var hour: Int
    public var minute: Int

    public init(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
    }

    public var minutesOfDay: Int { hour * 60 + minute }
}

public struct ActiveHours: Codable, Hashable, Sendable {
    /// Calendar weekdays: 1 = Sunday … 7 = Saturday.
    public var weekdays: Set<Int>
    public var start: ClockTime
    public var end: ClockTime

    public init(weekdays: Set<Int> = [2, 3, 4, 5, 6],
                start: ClockTime = .init(hour: 9, minute: 0),
                end: ClockTime = .init(hour: 18, minute: 0)) {
        self.weekdays = weekdays
        self.start = start
        self.end = end
    }
}

/// A category groups timers and pre-fills the "New timer" form.
public struct TimerCategory: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var symbol: String
    public var colorHex: String
    public var kind: TimerKind
    public var interval: TimeInterval
    public var breakDuration: TimeInterval
    public var message: String
    public var builtIn: Bool

    public init(id: UUID = UUID(), name: String, symbol: String, colorHex: String, kind: TimerKind,
                interval: TimeInterval, breakDuration: TimeInterval, message: String, builtIn: Bool = false) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.colorHex = colorHex
        self.kind = kind
        self.interval = interval
        self.breakDuration = breakDuration
        self.message = message
        self.builtIn = builtIn
    }
}

public struct BreakTimer: Codable, Identifiable, Hashable, Sendable {
    public var id = UUID()
    public var name: String
    public var categoryID: UUID
    public var kind: TimerKind
    /// Repeating/countdown period, or pomodoro work length.
    public var interval: TimeInterval
    /// 0 means a plain alert with no break countdown.
    public var breakDuration: TimeInterval
    public var longBreakDuration: TimeInterval = 15 * 60
    public var roundsBeforeLongBreak = 4
    public var clockTimes: [ClockTime] = []
    public var message: String
    public var style: BreakStyle = .overlay
    public var playSound = true
    public var showInMenuBar = true
    public var enabled = true
    public var activeHours: ActiveHours?

    // Runtime state, persisted so the widget can read it.
    public var nextFire: Date?
    public var pausedRemaining: TimeInterval?
    public var round = 0

    public init(category: TimerCategory) {
        name = category.name
        categoryID = category.id
        kind = category.kind
        interval = category.interval
        breakDuration = category.breakDuration
        message = category.message
        if kind == .scheduled { clockTimes = [.init(hour: 11, minute: 0), .init(hour: 15, minute: 30)] }
    }

    public var isPaused: Bool { pausedRemaining != nil }
}

public struct AppSettings: Codable, Hashable, Sendable {
    public var pauseWhenIdle = true
    public var idleMinutes: Double = 5
    public var postponeDuringCalls = true
    public var postponeDuringFullscreen = true
    public var snoozeMinutes: Double = 5

    public init() {}
}

public struct AppState: Codable, Sendable {
    public var categories: [TimerCategory]
    public var timers: [BreakTimer]
    public var settings = AppSettings()
    /// Start of a global pause; nil when running.
    public var pausedAt: Date?
    /// End of a global pause; nil with `pausedAt` set means "until resumed".
    public var pausedUntil: Date?

    public init(categories: [TimerCategory], timers: [BreakTimer]) {
        self.categories = categories
        self.timers = timers
    }

    public func category(for timer: BreakTimer) -> TimerCategory? {
        categories.first { $0.id == timer.categoryID }
    }

    public static func makeDefault(now: Date = .now) -> AppState {
        let categories = TimerCategory.builtIns
        var eyes = BreakTimer(category: categories[0])
        eyes.restart(now: now)
        return AppState(categories: categories, timers: [eyes])
    }
}

public extension TimerCategory {
    static var builtIns: [TimerCategory] {
        [
            .init(name: "Eyes", symbol: "eye", colorHex: "#34C759", kind: .repeating, interval: 20 * 60,
                  breakDuration: 20, message: "Look at something 20 feet (6 m) away for 20 seconds.", builtIn: true),
            .init(name: "Posture", symbol: "figure.stand", colorHex: "#007AFF", kind: .repeating, interval: 30 * 60,
                  breakDuration: 10, message: "Sit up straight and relax your shoulders.", builtIn: true),
            .init(name: "Water", symbol: "drop.fill", colorHex: "#5AC8FA", kind: .repeating, interval: 60 * 60,
                  breakDuration: 0, message: "Drink a glass of water.", builtIn: true),
            .init(name: "Stretch", symbol: "figure.flexibility", colorHex: "#FF9500", kind: .repeating, interval: 90 * 60,
                  breakDuration: 120, message: "Stand up and stretch your legs and back.", builtIn: true),
            .init(name: "Pomodoro", symbol: "timer", colorHex: "#FF3B30", kind: .pomodoro, interval: 25 * 60,
                  breakDuration: 5 * 60, message: "Focus session done. Take a break.", builtIn: true),
            .init(name: "Countdown", symbol: "hourglass", colorHex: "#AF52DE", kind: .countdown, interval: 15 * 60,
                  breakDuration: 0, message: "Time's up!", builtIn: true),
            .init(name: "Scheduled", symbol: "alarm", colorHex: "#FFCC00", kind: .scheduled, interval: 0,
                  breakDuration: 60, message: "Scheduled break.", builtIn: true),
            .init(name: "Custom", symbol: "star", colorHex: "#8E8E93", kind: .repeating, interval: 45 * 60,
                  breakDuration: 30, message: "Time for a break.", builtIn: true),
        ]
    }
}
