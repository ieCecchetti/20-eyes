import AppKit
import ChillyCore
import Observation
import WidgetKit

@MainActor @Observable
final class TimerEngine {
    var state: AppState {
        didSet {
            try? Store.save(state, to: Store.stateFile)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    private(set) var events: [BreakEvent]
    private(set) var now = Date.now
    /// Why a due break is being held back, shown in the menu.
    private(set) var postponeReason: String?
    private(set) var awaySince: Date?

    @ObservationIgnored private let presenter = BreakPresenter()
    @ObservationIgnored private var ticker: Timer?
    @ObservationIgnored private var hotKey: HotKey?
    @ObservationIgnored private var screenLocked = false

    init() {
        state = Store.load(AppState.self, from: Store.stateFile) ?? .makeDefault()
        events = Store.load([BreakEvent].self, from: Store.statsFile) ?? []
        ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        ticker?.tolerance = 0.2
        hotKey = HotKey { [weak self] in self?.togglePauseAll() }
        observeLockAndSleep()
    }

    // MARK: Derived

    var sortedTimers: [BreakTimer] { state.sortedTimers }

    /// Soonest running timer pinned to the menu bar.
    var menuBarTimer: BreakTimer? {
        state.sortedTimers.first { $0.showInMenuBar && $0.enabled && $0.nextFire != nil }
    }

    func category(for timer: BreakTimer) -> TimerCategory? { state.category(for: timer) }

    func remaining(_ timer: BreakTimer) -> TimeInterval? {
        guard let fire = timer.nextFire else { return timer.pausedRemaining }
        // While paused globally the countdown freezes at the pause moment.
        return fire.timeIntervalSince(state.pausedAt ?? now)
    }

    // MARK: Loop

    private func tick() {
        now = .now
        if let until = state.pausedUntil, now >= until { state.resumeAll(now: now) }
        guard !state.isPausedAll else { return }
        updateAway()
        guard awaySince == nil, !presenter.isShowing else { return }
        guard let i = state.timers.indices.filter({ state.timers[$0].isDue(at: now) })
            .min(by: { state.timers[$0].nextFire! < state.timers[$1].nextFire! })
        else { postponeReason = nil; return }

        if let hours = state.timers[i].activeHours, !hours.contains(now) {
            state.timers[i].scheduleNext(from: now) // outside active hours: roll over silently
            return
        }
        postponeReason = Presence.postponeReason(state.settings)
        guard postponeReason == nil else { return }
        fire(state.timers[i])
    }

    private func updateAway() {
        guard state.settings.pauseWhenIdle else { awaySince = nil; return }
        let threshold = state.settings.idleMinutes * 60
        let idle = Presence.idleSeconds
        if screenLocked || idle >= threshold {
            if awaySince == nil { awaySince = screenLocked ? now : now.addingTimeInterval(-idle) }
        } else if let since = awaySince {
            awaySince = nil
            if now.timeIntervalSince(since) >= threshold { state.resetAfterRest(now: now) }
        }
    }

    private func observeLockAndSleep() {
        let dnc = DistributedNotificationCenter.default()
        dnc.addObserver(forName: .init("com.apple.screenIsLocked"), object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.screenLocked = true }
        }
        dnc.addObserver(forName: .init("com.apple.screenIsUnlocked"), object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.screenLocked = false }
        }
        let wnc = NSWorkspace.shared.notificationCenter
        wnc.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.state.settings.pauseWhenIdle, self.awaySince == nil else { return }
                self.awaySince = .now
            }
        }
    }

    private func fire(_ timer: BreakTimer) {
        presenter.show(timer: timer, category: category(for: timer),
                       duration: timer.currentBreakDuration,
                       snoozeMinutes: state.settings.snoozeMinutes) { [weak self] outcome in
            self?.finish(timer.id, outcome)
        }
    }

    private func finish(_ id: UUID, _ outcome: BreakOutcome) {
        guard let i = state.timers.firstIndex(where: { $0.id == id }) else { return }
        let t = state.timers[i]
        let end = Date.now
        if outcome == .snoozed {
            state.timers[i].snooze(now: end, minutes: state.settings.snoozeMinutes)
        } else {
            state.timers[i].completeBreak(at: end)
        }
        events.append(BreakEvent(date: end, timerName: t.name, categoryID: t.categoryID, outcome: outcome))
        events.removeAll { $0.date < end.addingTimeInterval(-366 * 86400) }
        try? Store.save(events, to: Store.statsFile)
    }

    // MARK: Actions

    func save(_ timer: BreakTimer) {
        var t = timer
        if !t.isPaused { t.restart(now: .now) }
        if let i = state.timers.firstIndex(where: { $0.id == t.id }) {
            state.timers[i] = t
        } else {
            state.timers.append(t)
        }
    }

    func delete(_ id: UUID) { state.timers.removeAll { $0.id == id } }

    func setEnabled(_ id: UUID, _ enabled: Bool) {
        guard let i = state.timers.firstIndex(where: { $0.id == id }) else { return }
        state.timers[i].enabled = enabled
        if enabled { state.timers[i].restart(now: .now) } else { state.timers[i].nextFire = nil }
    }

    func togglePause(_ id: UUID) {
        guard let i = state.timers.firstIndex(where: { $0.id == id }) else { return }
        if state.timers[i].isPaused { state.timers[i].resume(now: .now) } else { state.timers[i].pause(now: .now) }
    }

    func restart(_ id: UUID) {
        guard let i = state.timers.firstIndex(where: { $0.id == id }) else { return }
        state.timers[i].enabled = true
        state.timers[i].restart(now: .now)
    }

    func breakNow(_ id: UUID) {
        guard !presenter.isShowing, let t = state.timers.first(where: { $0.id == id }) else { return }
        fire(t)
    }

    func pauseAll(for minutes: Double?) {
        state.pauseAll(until: minutes.map { Date.now.addingTimeInterval($0 * 60) }, now: .now)
    }

    func pauseUntilTomorrow() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: .now))!
        state.pauseAll(until: tomorrow, now: .now)
    }

    func resumeAll() { state.resumeAll(now: .now) }

    func togglePauseAll() { state.isPausedAll ? resumeAll() : pauseAll(for: nil) }

    func saveCategory(_ category: TimerCategory) {
        if let i = state.categories.firstIndex(where: { $0.id == category.id }) {
            state.categories[i] = category
        } else {
            state.categories.append(category)
        }
    }

    /// Only custom categories with no timers can be deleted.
    func canDelete(_ category: TimerCategory) -> Bool {
        !category.builtIn && !state.timers.contains { $0.categoryID == category.id }
    }

    func deleteCategory(_ id: UUID) {
        guard let c = state.categories.first(where: { $0.id == id }), canDelete(c) else { return }
        state.categories.removeAll { $0.id == id }
    }
}
