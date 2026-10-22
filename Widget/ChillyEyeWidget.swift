import ChillyCore
import SwiftUI
import WidgetKit

struct Entry: TimelineEntry {
    let date: Date
    let state: AppState
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry { Entry(date: .now, state: .makeDefault()) }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        completion(Entry(date: .now, state: load()))
    }

    /// Countdowns tick on their own via Text(.timer); refresh when the soonest one fires so order stays right.
    /// The app also reloads the widget whenever timers change.
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let state = load()
        let next = state.sortedTimers.compactMap(\.nextFire).filter { $0 > .now }.min()
        completion(Timeline(entries: [Entry(date: .now, state: state)],
                            policy: .after(next ?? .now.addingTimeInterval(15 * 60))))
    }

    private func load() -> AppState {
        Store.load(AppState.self, from: Store.stateFile) ?? AppState(categories: [], timers: [])
    }
}

struct WidgetView: View {
    let entry: Entry

    var body: some View {
        let timers = entry.state.sortedTimers.filter { $0.enabled }.prefix(3)
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Chilly Eye").font(.caption.bold()).foregroundStyle(.secondary)
                Spacer()
                if entry.state.isPausedAll {
                    Label("Paused", systemImage: "pause.fill").font(.caption).foregroundStyle(.secondary)
                }
            }
            if timers.isEmpty {
                Spacer()
                Text("No running timers").foregroundStyle(.secondary).frame(maxWidth: .infinity)
                Spacer()
            }
            ForEach(Array(timers)) { t in
                let c = entry.state.category(for: t)
                HStack {
                    Image(systemName: c?.symbol ?? "bell")
                        .foregroundStyle(Color(hex: c?.colorHex ?? "#8E8E93"))
                        .frame(width: 20)
                    Text(t.name).lineLimit(1)
                    Spacer()
                    countdown(t).font(.body.monospacedDigit().weight(.semibold))
                }
            }
            Spacer(minLength: 0)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    @ViewBuilder private func countdown(_ t: BreakTimer) -> some View {
        if let left = t.pausedRemaining {
            Text(formatCountdown(left)).foregroundStyle(.secondary)
        } else if let fire = t.nextFire, !entry.state.isPausedAll, fire > entry.date {
            Text(timerInterval: entry.date...fire, countsDown: true).multilineTextAlignment(.trailing)
                .frame(width: 80, alignment: .trailing)
        } else if let fire = t.nextFire, let pausedAt = entry.state.pausedAt {
            Text(formatCountdown(fire.timeIntervalSince(pausedAt))).foregroundStyle(.secondary)
        } else {
            Text("Now")
        }
    }
}

@main
struct ChillyEyeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ChillyEyeWidget", provider: Provider()) { WidgetView(entry: $0) }
            .configurationDisplayName("Upcoming timers")
            .description("The next three timers to ring.")
            .supportedFamilies([.systemMedium])
    }
}
