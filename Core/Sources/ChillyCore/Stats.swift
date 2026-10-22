import Foundation

public enum BreakOutcome: String, Codable, Sendable {
    case taken, skipped, snoozed
}

public struct BreakEvent: Codable, Hashable, Sendable {
    public var date: Date
    public var timerName: String
    public var categoryID: UUID
    public var outcome: BreakOutcome

    public init(date: Date, timerName: String, categoryID: UUID, outcome: BreakOutcome) {
        self.date = date
        self.timerName = timerName
        self.categoryID = categoryID
        self.outcome = outcome
    }
}

public struct DayStats: Hashable, Sendable {
    public var day: Date
    public var taken = 0
    public var skipped = 0
    public var snoozed = 0
}

/// The last `days` days, oldest first, ending today.
public func dailyStats(_ events: [BreakEvent], days: Int, now: Date = .now, calendar: Calendar = .current) -> [DayStats] {
    let today = calendar.startOfDay(for: now)
    var result = (0..<days).reversed().map {
        DayStats(day: calendar.date(byAdding: .day, value: -$0, to: today)!)
    }
    for e in events {
        let day = calendar.startOfDay(for: e.date)
        guard let i = result.firstIndex(where: { $0.day == day }) else { continue }
        switch e.outcome {
        case .taken: result[i].taken += 1
        case .skipped: result[i].skipped += 1
        case .snoozed: result[i].snoozed += 1
        }
    }
    return result
}

/// Consecutive days with at least one break taken and none skipped.
/// Today only counts once it has breaks, so an empty morning doesn't end the streak.
public func streak(_ events: [BreakEvent], now: Date = .now, calendar: Calendar = .current) -> Int {
    let days = dailyStats(events, days: 366, now: now, calendar: calendar).reversed()
    var count = 0
    for (offset, d) in days.enumerated() {
        if offset == 0 && d.taken == 0 && d.skipped == 0 { continue }
        guard d.taken > 0 && d.skipped == 0 else { break }
        count += 1
    }
    return count
}
