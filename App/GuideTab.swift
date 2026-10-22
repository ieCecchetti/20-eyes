import SwiftUI

/// In-app explanation of how timers and breaks behave.
struct GuideTab: View {
    private struct Topic: Identifiable {
        let symbol: String
        let title: String
        let text: String
        var id: String { title }
    }

    private let topics = [
        Topic(symbol: "eye", title: "The 20-20-20 rule",
              text: "Every 20 minutes, look at something 20 feet (6 m) away for 20 seconds. The Eyes timer does this for you."),
        Topic(symbol: "square.grid.2x2", title: "Timers and categories",
              text: "Add as many timers as you like. Pick a category (Eyes, Posture, Water, Stretch, Pomodoro, Countdown, Scheduled, Custom, or your own) and it fills in sensible defaults that you can change."),
        Topic(symbol: "timer", title: "Timer types",
              text: "Repeating rings every N minutes. Pomodoro alternates focus and breaks, with a long break every few rounds. Countdown rings once, then switches off. Scheduled rings at fixed clock times."),
        Topic(symbol: "rectangle.inset.filled", title: "Breaks",
              text: "A break is either a full-screen overlay on every display or a small popup. It ends by itself when its countdown finishes. Done ends it early and counts it as taken (only if \"Allow Done\" is on for that timer). Skip counts it as skipped. Snooze brings it back in a few minutes."),
        Topic(symbol: "pencil", title: "Editing a timer",
              text: "Changing the type, interval or clock times restarts the countdown. Any other change, like the message, style or Allow Done, keeps it running."),
        Topic(symbol: "moon.zzz", title: "When you're away",
              text: "If you're idle, the screen is locked or the Mac sleeps, timers wait. Repeating timers start over when you come back, because you already rested."),
        Topic(symbol: "video", title: "During calls",
              text: "While your camera or microphone is in use, a due break waits until the call ends. Fullscreen apps don't hold breaks back."),
        Topic(symbol: "calendar.badge.clock", title: "Active hours",
              text: "A timer can be limited to certain days and hours, for example Monday to Friday, 9:00 to 18:00. Outside them it stays quiet."),
        Topic(symbol: "pause.circle", title: "Pausing",
              text: "Pause one timer from the menu, or pause all of them for 30 minutes, 1 hour, until tomorrow, or until you resume. \(HotKey.display) pauses and resumes everything."),
        Topic(symbol: "menubar.rectangle", title: "Menu bar and widget",
              text: "The menu bar shows the soonest timer that has \"Show countdown in menu bar\" on. The widget (right-click the desktop → Edit Widgets) shows the next three."),
        Topic(symbol: "chart.bar", title: "Stats",
              text: "Counts breaks taken, skipped and snoozed per day. The streak counts days with at least one break taken and none skipped."),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(topics) { t in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: t.symbol)
                            .font(.title3)
                            .foregroundStyle(.tint)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(t.title).font(.headline)
                            Text(t.text).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                Divider()
                HStack {
                    Text("Chilly Eye \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Link("Website", destination: URL(string: "https://github.com/ieCecchetti/20-eyes")!)
                    Link("Report a problem", destination: URL(string: "https://github.com/ieCecchetti/20-eyes/issues/new")!)
                }
            }
            .padding()
        }
    }
}
