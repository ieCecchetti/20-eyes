import ChillyCore
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            TimersTab().tabItem { Label("Timers", systemImage: "timer") }
            CategoriesTab().tabItem { Label("Categories", systemImage: "square.grid.2x2") }
            GeneralTab().tabItem { Label("General", systemImage: "gearshape") }
            StatsTab().tabItem { Label("Stats", systemImage: "chart.bar") }
        }
        .frame(width: 620, height: 480)
        .onAppear { NSApp.activate(ignoringOtherApps: true) }
    }
}

private struct TimersTab: View {
    @Environment(TimerEngine.self) private var engine
    @State private var editing: BreakTimer?

    var body: some View {
        VStack(alignment: .leading) {
            List {
                ForEach(engine.state.timers) { t in
                    let c = engine.category(for: t)
                    HStack {
                        Image(systemName: c?.symbol ?? "bell")
                            .foregroundStyle(Color(hex: c?.colorHex ?? "#8E8E93"))
                            .frame(width: 22)
                        VStack(alignment: .leading) {
                            Text(t.name)
                            Text(summary(t)).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("Enabled", isOn: Binding(get: { t.enabled }, set: { engine.setEnabled(t.id, $0) }))
                            .labelsHidden().toggleStyle(.switch)
                        Button("Edit") { editing = t }
                        Button(role: .destructive) { engine.delete(t.id) } label: { Image(systemName: "trash") }
                            .buttonStyle(.borderless)
                    }
                }
            }
            Button {
                editing = BreakTimer(category: engine.state.categories[0])
            } label: { Label("New timer", systemImage: "plus") }
        }
        .padding()
        .sheet(item: $editing) { t in
            TimerForm(timer: t) { engine.save($0) }
        }
    }

    private func summary(_ t: BreakTimer) -> String {
        let breakText = t.breakDuration > 0 ? "\(Int(t.breakDuration))s break" : "alert"
        switch t.kind {
        case .repeating: return "Every \(Int(t.interval / 60)) min · \(breakText) · \(t.style.label)"
        case .pomodoro: return "\(Int(t.interval / 60)) min focus · \(Int(t.breakDuration / 60))/\(Int(t.longBreakDuration / 60)) min breaks"
        case .countdown: return "\(Int(t.interval / 60)) min countdown"
        case .scheduled:
            let times = t.clockTimes.map { String(format: "%02d:%02d", $0.hour, $0.minute) }.joined(separator: ", ")
            return "At \(times) · \(breakText)"
        }
    }
}

private struct GeneralTab: View {
    @Environment(TimerEngine.self) private var engine
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginError: String?

    var body: some View {
        @Bindable var engine = engine
        Form {
            Section {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, on in
                        do {
                            try on ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
                            loginError = nil
                        } catch {
                            loginError = error.localizedDescription
                            launchAtLogin = SMAppService.mainApp.status == .enabled
                        }
                    }
                if let loginError { Text(loginError).font(.caption).foregroundStyle(.red) }
            }
            Section("When you're away") {
                Toggle("Hold timers when idle, locked or asleep", isOn: $engine.state.settings.pauseWhenIdle)
                LabeledContent("Idle after (minutes)") {
                    TextField("", value: $engine.state.settings.idleMinutes, format: .number).frame(width: 60)
                }
                Text("Repeating timers restart when you come back, since you already rested.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Don't interrupt") {
                Toggle("Postpone breaks during calls (camera or mic in use)", isOn: $engine.state.settings.postponeDuringCalls)
                Toggle("Postpone breaks while a fullscreen app is in front", isOn: $engine.state.settings.postponeDuringFullscreen)
            }
            Section("Breaks") {
                LabeledContent("Snooze length (minutes)") {
                    TextField("", value: $engine.state.settings.snoozeMinutes, format: .number).frame(width: 60)
                }
                LabeledContent("Pause / resume all", value: HotKey.display)
            }
        }
        .formStyle(.grouped)
    }
}

private struct StatsTab: View {
    @Environment(TimerEngine.self) private var engine

    var body: some View {
        let days = dailyStats(engine.events, days: 7, now: engine.now)
        let today = days.last!
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 24) {
                stat("Taken today", today.taken)
                stat("Skipped today", today.skipped)
                stat("Snoozed today", today.snoozed)
                stat("Day streak", streak(engine.events, now: engine.now))
            }
            Text("Last 7 days").font(.headline)
            Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 6) {
                GridRow {
                    Text("Day").bold(); Text("Taken").bold(); Text("Skipped").bold(); Text("Snoozed").bold()
                }
                ForEach(days.reversed(), id: \.day) { d in
                    GridRow {
                        Text(d.day.formatted(.dateTime.weekday(.abbreviated).day().month()))
                        Text("\(d.taken)"); Text("\(d.skipped)"); Text("\(d.snoozed)")
                    }
                    .monospacedDigit()
                }
            }
            Text("The streak counts days with at least one break taken and none skipped.")
                .font(.caption).foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }

    private func stat(_ label: String, _ value: Int) -> some View {
        VStack(alignment: .leading) {
            Text("\(value)").font(.title.bold()).monospacedDigit()
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }
}
