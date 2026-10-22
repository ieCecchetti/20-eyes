import ChillyCore
import SwiftUI

struct MenuView: View {
    @Environment(TimerEngine.self) private var engine

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Chilly Eye").font(.headline)
                Spacer()
                Text(status).font(.caption).foregroundStyle(.secondary)
            }
            if engine.state.timers.isEmpty {
                Text("No timers yet. Add one in Settings.").foregroundStyle(.secondary)
            }
            ForEach(engine.sortedTimers) { TimerRow(timer: $0) }
            Divider()
            HStack {
                if engine.state.isPausedAll {
                    Button("Resume all") { engine.resumeAll() }
                } else {
                    Menu("Pause all") {
                        Button("30 minutes") { engine.pauseAll(for: 30) }
                        Button("1 hour") { engine.pauseAll(for: 60) }
                        Button("Until tomorrow") { engine.pauseUntilTomorrow() }
                        Button("Until I resume  \(HotKey.display)") { engine.pauseAll(for: nil) }
                    }
                    .fixedSize()
                }
                Spacer()
                SettingsLink { Text("Settings…") }
                    .simultaneousGesture(TapGesture().onEnded { NSApp.activate(ignoringOtherApps: true) })
                Button("Quit") { NSApp.terminate(nil) }
            }
        }
        .padding(12)
        .frame(width: 340)
    }

    private var status: String {
        if engine.state.isPausedAll {
            guard let until = engine.state.pausedUntil else { return "Paused" }
            return "Paused until \(until.formatted(date: .omitted, time: .shortened))"
        }
        if engine.awaySince != nil { return "Away. Timers on hold" }
        if let reason = engine.postponeReason { return "Break postponed: \(reason)" }
        return ""
    }
}

private struct TimerRow: View {
    @Environment(TimerEngine.self) private var engine
    let timer: BreakTimer

    var body: some View {
        let category = engine.category(for: timer)
        HStack {
            Image(systemName: category?.symbol ?? "bell")
                .foregroundStyle(Color(hex: category?.colorHex ?? "#8E8E93"))
                .frame(width: 20)
            VStack(alignment: .leading) {
                Text(timer.name)
                Text(timer.kind.label).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(detail).monospacedDigit().foregroundStyle(timer.nextFire == nil ? .secondary : .primary)
            if timer.enabled {
                Button { engine.togglePause(timer.id) } label: {
                    Image(systemName: timer.isPaused ? "play.fill" : "pause.fill")
                }
                .help(timer.isPaused ? "Resume" : "Pause")
                Button { engine.breakNow(timer.id) } label: { Image(systemName: "forward.end.fill") }
                    .help("Take break now")
            } else {
                Button { engine.restart(timer.id) } label: { Image(systemName: "arrow.clockwise") }
                    .help("Start")
            }
        }
        .buttonStyle(.borderless)
        .opacity(timer.enabled ? 1 : 0.5)
    }

    private var detail: String {
        if !timer.enabled { return "Off" }
        if timer.isPaused { return "Paused" }
        return engine.remaining(timer).map(formatCountdown) ?? "–"
    }
}
