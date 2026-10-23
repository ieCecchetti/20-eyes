import Foundation

public extension ActiveHours {
    func contains(_ date: Date, calendar: Calendar = .current) -> Bool {
        guard weekdays.contains(calendar.component(.weekday, from: date)) else { return false }
        let m = calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
        let s = start.minutesOfDay, e = end.minutesOfDay
        return s <= e ? (m >= s && m < e) : (m >= s || m < e) // s > e spans midnight
    }
}

public func nextClockFire(after date: Date, times: [ClockTime], calendar: Calendar = .current) -> Date? {
    times.compactMap {
        calendar.nextDate(after: date, matching: DateComponents(hour: $0.hour, minute: $0.minute, second: 0),
                          matchingPolicy: .nextTime)
    }.min()
}

public extension BreakTimer {
    /// Break length for the break firing now (pomodoro gets a long one every N rounds).
    var currentBreakDuration: TimeInterval {
        kind == .pomodoro && (round + 1) % max(1, roundsBeforeLongBreak) == 0 ? longBreakDuration : breakDuration
    }

    /// Fresh start: used when a timer is created, edited or reset.
    mutating func restart(now: Date, calendar: Calendar = .current) {
        round = 0
        pausedRemaining = nil
        if kind == .countdown {
            nextFire = now.addingTimeInterval(interval)
        } else {
            scheduleNext(from: now, calendar: calendar)
        }
    }

    /// After a break is taken or skipped. Countdowns are one-shot and switch off.
    mutating func completeBreak(at now: Date, calendar: Calendar = .current) {
        if kind == .pomodoro { round += 1 }
        if kind == .countdown {
            nextFire = nil
            enabled = false
        } else {
            scheduleNext(from: now, calendar: calendar)
        }
    }

    mutating func scheduleNext(from now: Date, calendar: Calendar = .current) {
        switch kind {
        case .repeating, .pomodoro, .countdown: nextFire = now.addingTimeInterval(interval)
        case .scheduled: nextFire = nextClockFire(after: now, times: clockTimes, calendar: calendar)
        }
    }

    mutating func snooze(now: Date, minutes: Double) {
        nextFire = now.addingTimeInterval(minutes * 60)
    }

    mutating func pause(now: Date) {
        guard let fire = nextFire, !isPaused else { return }
        pausedRemaining = max(0, fire.timeIntervalSince(now))
        nextFire = nil
    }

    mutating func resume(now: Date, calendar: Calendar = .current) {
        guard let remaining = pausedRemaining else { return }
        pausedRemaining = nil
        if kind == .scheduled {
            scheduleNext(from: now, calendar: calendar)
        } else {
            nextFire = now.addingTimeInterval(remaining)
        }
    }

    /// Applies a settings edit. Only changes to when it rings restart the countdown;
    /// the live state comes from `self`, since the form's copy may be stale.
    func applyingEdit(_ edited: BreakTimer, now: Date, calendar: Calendar = .current) -> BreakTimer {
        var t = edited
        t.enabled = enabled
        t.nextFire = nextFire
        t.pausedRemaining = pausedRemaining
        t.round = round
        guard enabled, edited.kind != kind || edited.interval != interval || edited.clockTimes != clockTimes
        else { return t }
        t.restart(now: now, calendar: calendar)
        if isPaused { t.pause(now: now) }
        return t
    }

    func isDue(at now: Date) -> Bool {
        enabled && !isPaused && (nextFire.map { $0 <= now } ?? false)
    }
}

public extension AppState {
    /// Running timers first (soonest first), then paused, then disabled.
    var sortedTimers: [BreakTimer] {
        timers.sorted { a, b in
            func rank(_ t: BreakTimer) -> Int { !t.enabled ? 2 : (t.nextFire == nil ? 1 : 0) }
            if rank(a) != rank(b) { return rank(a) < rank(b) }
            return (a.nextFire ?? .distantFuture) < (b.nextFire ?? .distantFuture)
        }
    }

    var isPausedAll: Bool { pausedAt != nil }

    mutating func pauseAll(until: Date?, now: Date) {
        if pausedAt == nil { pausedAt = now }
        pausedUntil = until
    }

    /// Shifts running timers by the pause length so they continue where they stopped.
    mutating func resumeAll(now: Date, calendar: Calendar = .current) {
        guard let start = pausedAt else { return }
        let paused = now.timeIntervalSince(start)
        for i in timers.indices where timers[i].enabled && !timers[i].isPaused {
            if timers[i].kind == .scheduled {
                timers[i].scheduleNext(from: now, calendar: calendar)
            } else {
                timers[i].nextFire = timers[i].nextFire?.addingTimeInterval(paused)
            }
        }
        pausedAt = nil
        pausedUntil = nil
    }

    /// Back from being away: repeating and pomodoro timers restart, since you already rested.
    /// Countdown and scheduled timers follow the real clock, so they keep running.
    mutating func resetAfterRest(now: Date) {
        for i in timers.indices where [.repeating, .pomodoro].contains(timers[i].kind)
            && timers[i].enabled && !timers[i].isPaused {
            timers[i].scheduleNext(from: now)
        }
    }
}

public func formatCountdown(_ seconds: TimeInterval) -> String {
    let s = max(0, Int(seconds.rounded(.up)))
    return s >= 3600
        ? String(format: "%d:%02d:%02d", s / 3600, s / 60 % 60, s % 60)
        : String(format: "%d:%02d", s / 60, s % 60)
}
