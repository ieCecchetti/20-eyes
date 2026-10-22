// Renders the real app views with demo data into docs/images. Run via scripts/render-screenshots.sh.
import AppKit
import SwiftUI

@main
struct Screenshots {
    @MainActor static func main() throws {
        _ = NSApplication.shared
        let out = URL(fileURLWithPath: CommandLine.arguments[1])
        let now = Date.now
        try seedDemoData(now: now)
        let engine = TimerEngine()
        let state = engine.state
        let eyes = state.timers[0]

        render(MenuView().environment(engine).background(panel(12)), to: out, "menu.png")
        render(WidgetView(entry: Entry(date: now, state: state)).padding(16).frame(width: 340, height: 160)
                .background(panel(22)), to: out, "widget.png")
        render(ZStack {
            wallpaper
            BreakView(timer: state.timers[2], category: state.category(for: state.timers[2]), end: nil,
                      snoozeMinutes: 5, overlay: false, finish: { _ in })
                .frame(width: 340, height: 200).opacity(0.9).shadow(radius: 20)
        }.frame(width: 460, height: 300), to: out, "popup.png")
        render(ZStack {
            wallpaper
            BreakView(timer: eyes, category: state.category(for: eyes), end: now.addingTimeInterval(17),
                      snoozeMinutes: 5, overlay: true, finish: { _ in })
                .opacity(0.6) // offscreen the blur has no desktop behind it; let the wallpaper show through
        }.frame(width: 1280, height: 760), to: out, "overlay.png")
        var draft = BreakTimer(category: state.categories[4])
        draft.name = "Deep work"
        render(TimerForm(timer: draft, onSave: { _ in }).environment(engine).background(panel(12)), to: out, "new-timer.png")
    }

    static var wallpaper: some View {
        LinearGradient(colors: [Color(hex: "#1D2B64"), Color(hex: "#5B4B8A"), Color(hex: "#F8CDDA")],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func panel(_ radius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: radius).fill(Color(nsColor: .windowBackgroundColor))
    }

    @MainActor static func render(_ view: some View, to dir: URL, _ name: String) {
        let host = NSHostingView(rootView: view.environment(\.colorScheme, .light))
        host.frame.size = host.fittingSize
        let window = NSWindow(contentRect: host.frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.backgroundColor = .clear
        window.isOpaque = false
        window.contentView = host
        window.orderFrontRegardless() // offscreen layout needs a live window for AppKit controls
        RunLoop.main.run(until: .now.addingTimeInterval(1))
        let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds)!
        host.cacheDisplay(in: host.bounds, to: rep)
        try! rep.representation(using: .png, properties: [:])!.write(to: dir.appendingPathComponent(name))
        window.orderOut(nil)
        print("wrote \(name) \(rep.pixelsWide)x\(rep.pixelsHigh)")
    }

    static func seedDemoData(now: Date) throws {
        var state = AppState(categories: TimerCategory.builtIns, timers: [])
        func timer(_ cat: Int, _ name: String, in seconds: TimeInterval?, paused: TimeInterval? = nil,
                   enabled: Bool = true, edit: (inout BreakTimer) -> Void = { _ in }) {
            var t = BreakTimer(category: state.categories[cat])
            t.name = name
            t.nextFire = seconds.map { now.addingTimeInterval($0) }
            t.pausedRemaining = paused
            t.enabled = enabled
            edit(&t)
            state.timers.append(t)
        }
        timer(0, "Eyes 20-20-20", in: 12 * 60 + 41)
        timer(1, "Posture check", in: 3 * 60 + 5)
        timer(2, "Drink water", in: 41 * 60 + 10)
        timer(4, "Deep work", in: nil, paused: 18 * 60 + 30)
        timer(6, "Stand-up walk", in: 2 * 3600 + 14 * 60) { $0.style = .popup }
        try Store.save(state, to: Store.stateFile)

        let cal = Calendar.current
        var events: [BreakEvent] = []
        for day in 0..<6 {
            let date = cal.date(byAdding: .day, value: -day, to: now)!
            for i in 0..<(9 - day % 3) {
                events.append(BreakEvent(date: date, timerName: "Eyes", categoryID: state.categories[0].id,
                                         outcome: i == 0 && day == 4 ? .skipped : .taken))
            }
        }
        try Store.save(events, to: Store.statsFile)
    }
}
