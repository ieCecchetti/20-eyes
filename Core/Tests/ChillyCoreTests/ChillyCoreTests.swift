import XCTest
@testable import ChillyCore

final class ChillyCoreTests: XCTestCase {
    var cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    func date(_ y: Int, _ mo: Int, _ d: Int, _ h: Int = 0, _ mi: Int = 0) -> Date {
        cal.date(from: DateComponents(year: y, month: mo, day: d, hour: h, minute: mi))!
    }

    func category(_ kind: TimerKind) -> TimerCategory {
        TimerCategory.builtIns.first { $0.kind == kind }!
    }

    func testRepeatingSchedulesAfterInterval() {
        let now = date(2026, 10, 22, 10)
        var t = BreakTimer(category: category(.repeating))
        t.restart(now: now, calendar: cal)
        XCTAssertEqual(t.nextFire, now.addingTimeInterval(20 * 60))
        XCTAssertFalse(t.isDue(at: now))
        XCTAssertTrue(t.isDue(at: now.addingTimeInterval(20 * 60)))
    }

    func testCountdownIsOneShot() {
        let now = date(2026, 10, 22, 10)
        var t = BreakTimer(category: category(.countdown))
        t.restart(now: now)
        XCTAssertEqual(t.nextFire, now.addingTimeInterval(15 * 60))
        t.completeBreak(at: now)
        XCTAssertNil(t.nextFire)
        XCTAssertFalse(t.enabled)
    }

    func testPomodoroLongBreakEveryNRounds() {
        var t = BreakTimer(category: category(.pomodoro))
        t.roundsBeforeLongBreak = 4
        let durations = (0..<8).map { _ -> TimeInterval in
            defer { t.completeBreak(at: .now) }
            return t.currentBreakDuration
        }
        XCTAssertEqual(durations, [300, 300, 300, 900, 300, 300, 300, 900])
    }

    func testScheduledPicksNextClockTimeAndWrapsToTomorrow() {
        var t = BreakTimer(category: category(.scheduled)) // 11:00 and 15:30
        t.restart(now: date(2026, 10, 22, 12), calendar: cal)
        XCTAssertEqual(t.nextFire, date(2026, 10, 22, 15, 30))
        t.completeBreak(at: date(2026, 10, 22, 15, 30), calendar: cal)
        XCTAssertEqual(t.nextFire, date(2026, 10, 23, 11))
    }

    func testPauseAndResumeKeepsRemaining() {
        let now = date(2026, 10, 22, 10)
        var t = BreakTimer(category: category(.repeating))
        t.restart(now: now)
        t.pause(now: now.addingTimeInterval(5 * 60))
        XCTAssertEqual(t.pausedRemaining, 15 * 60)
        XCTAssertFalse(t.isDue(at: now.addingTimeInterval(3600)))
        t.resume(now: now.addingTimeInterval(3600))
        XCTAssertEqual(t.nextFire, now.addingTimeInterval(3600 + 15 * 60))
    }

    func testResumeAllShiftsRunningTimersOnly() {
        let now = date(2026, 10, 22, 10)
        var state = AppState.makeDefault(now: now)
        var paused = BreakTimer(category: category(.repeating))
        paused.restart(now: now)
        paused.pause(now: now)
        state.timers.append(paused)
        state.pauseAll(until: nil, now: now)
        state.resumeAll(now: now.addingTimeInterval(600))
        XCTAssertEqual(state.timers[0].nextFire, now.addingTimeInterval(20 * 60 + 600))
        XCTAssertEqual(state.timers[1].pausedRemaining, 20 * 60)
        XCTAssertFalse(state.isPausedAll)
    }

    func testResetAfterRestOnlyTouchesRepeating() {
        let now = date(2026, 10, 22, 10)
        var state = AppState.makeDefault(now: now)
        var countdown = BreakTimer(category: category(.countdown))
        countdown.restart(now: now)
        state.timers.append(countdown)
        let later = now.addingTimeInterval(600)
        state.resetAfterRest(now: later)
        XCTAssertEqual(state.timers[0].nextFire, later.addingTimeInterval(20 * 60))
        XCTAssertEqual(state.timers[1].nextFire, now.addingTimeInterval(15 * 60))
    }

    func testSortedTimersRunningThenPausedThenDisabled() {
        let now = date(2026, 10, 22, 10)
        var a = BreakTimer(category: category(.repeating)); a.name = "late"; a.nextFire = now.addingTimeInterval(500)
        var b = BreakTimer(category: category(.repeating)); b.name = "soon"; b.nextFire = now.addingTimeInterval(100)
        var c = BreakTimer(category: category(.repeating)); c.name = "paused"; c.pausedRemaining = 5
        var d = BreakTimer(category: category(.repeating)); d.name = "off"; d.enabled = false; d.nextFire = now
        let state = AppState(categories: [], timers: [d, c, a, b])
        XCTAssertEqual(state.sortedTimers.map(\.name), ["soon", "late", "paused", "off"])
    }

    func testActiveHours() {
        let weekdays = ActiveHours() // Mon–Fri 9–18
        XCTAssertTrue(weekdays.contains(date(2026, 10, 22, 10), calendar: cal)) // Thursday
        XCTAssertFalse(weekdays.contains(date(2026, 10, 22, 18), calendar: cal))
        XCTAssertFalse(weekdays.contains(date(2026, 10, 24, 10), calendar: cal)) // Saturday
        let night = ActiveHours(weekdays: Set(1...7), start: .init(hour: 22, minute: 0), end: .init(hour: 2, minute: 0))
        XCTAssertTrue(night.contains(date(2026, 10, 22, 23), calendar: cal))
        XCTAssertTrue(night.contains(date(2026, 10, 22, 1), calendar: cal))
        XCTAssertFalse(night.contains(date(2026, 10, 22, 12), calendar: cal))
    }

    func testStreak() {
        let now = date(2026, 10, 22, 8)
        let id = UUID()
        func e(_ day: Int, _ o: BreakOutcome) -> BreakEvent {
            BreakEvent(date: date(2026, 10, day, 12), timerName: "Eyes", categoryID: id, outcome: o)
        }
        // Today empty, 21 & 20 clean, 19 has a skip.
        let events = [e(21, .taken), e(20, .taken), e(20, .snoozed), e(19, .taken), e(19, .skipped)]
        XCTAssertEqual(streak(events, now: now, calendar: cal), 2)
        XCTAssertEqual(streak(events + [BreakEvent(date: now, timerName: "", categoryID: id, outcome: .skipped)],
                              now: now, calendar: cal), 0)
        let today = dailyStats(events, days: 7, now: now, calendar: cal)
        XCTAssertEqual(today.count, 7)
        XCTAssertEqual(today[5].taken, 1)
    }

    func testFormatCountdown() {
        XCTAssertEqual(formatCountdown(59.2), "1:00")
        XCTAssertEqual(formatCountdown(20 * 60), "20:00")
        XCTAssertEqual(formatCountdown(3725), "1:02:05")
        XCTAssertEqual(formatCountdown(-3), "0:00")
    }

    func testStoreRoundTrip() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let state = AppState.makeDefault()
        try Store.save(state, to: "state.json", in: dir)
        let loaded = try XCTUnwrap(Store.load(AppState.self, from: "state.json", in: dir))
        XCTAssertEqual(loaded.timers, state.timers)
        XCTAssertEqual(loaded.categories.count, 8)
    }
}
