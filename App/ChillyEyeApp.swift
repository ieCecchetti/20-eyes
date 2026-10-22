import ChillyCore
import SwiftUI

@main
struct ChillyEyeApp: App {
    @State private var engine = TimerEngine()

    var body: some Scene {
        MenuBarExtra {
            MenuView().environment(engine)
        } label: {
            MenuBarLabel(engine: engine)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView().environment(engine)
        }
    }
}

struct MenuBarLabel: View {
    let engine: TimerEngine

    var body: some View {
        if engine.state.isPausedAll {
            Image(systemName: "pause.circle")
        } else if let t = engine.menuBarTimer, let left = engine.remaining(t) {
            Image(systemName: engine.category(for: t)?.symbol ?? "eye")
            Text(formatCountdown(left)).monospacedDigit()
        } else {
            Image(systemName: "eye")
        }
    }
}
