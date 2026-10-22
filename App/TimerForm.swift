import ChillyCore
import SwiftUI

/// Pick a category, get its defaults, then tweak them.
struct TimerForm: View {
    @Environment(TimerEngine.self) private var engine
    @Environment(\.dismiss) private var dismiss
    @State var timer: BreakTimer
    let onSave: (BreakTimer) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    Picker("Category", selection: $timer.categoryID) {
                        ForEach(engine.state.categories) { c in
                            Label(c.name, systemImage: c.symbol).tag(c.id)
                        }
                    }
                    .onChange(of: timer.categoryID) { _, id in applyDefaults(id) }
                    TextField("Name", text: $timer.name)
                    Picker("Type", selection: $timer.kind) {
                        ForEach(TimerKind.allCases, id: \.self) { Text($0.label).tag($0) }
                    }
                }
                Section("Timing") { timing }
                Section("Break") {
                    TextField("Message", text: $timer.message, axis: .vertical)
                    Picker("Style", selection: $timer.style) {
                        ForEach(BreakStyle.allCases, id: \.self) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    Toggle("Play sound", isOn: $timer.playSound)
                    Toggle("Show countdown in menu bar", isOn: $timer.showInMenuBar)
                }
                Section("Active hours") { activeHours }
            }
            .formStyle(.grouped)
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Save") { onSave(timer); dismiss() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isValid)
            }
            .padding()
        }
        .frame(width: 460, height: 600)
    }

    @ViewBuilder private var timing: some View {
        switch timer.kind {
        case .repeating:
            number("Every (minutes)", minutes(\.interval))
            number("Break (seconds, 0 = alert only)", $timer.breakDuration)
        case .pomodoro:
            number("Focus (minutes)", minutes(\.interval))
            number("Short break (minutes)", minutes(\.breakDuration))
            number("Long break (minutes)", minutes(\.longBreakDuration))
            Stepper("Long break every \(timer.roundsBeforeLongBreak) rounds",
                    value: $timer.roundsBeforeLongBreak, in: 1...12)
        case .countdown:
            number("Duration (minutes)", minutes(\.interval))
            number("Break (seconds, 0 = alert only)", $timer.breakDuration)
        case .scheduled:
            ForEach(timer.clockTimes.indices, id: \.self) { i in
                HStack {
                    DatePicker("At", selection: clock(i), displayedComponents: .hourAndMinute)
                    Button { timer.clockTimes.remove(at: i) } label: { Image(systemName: "minus.circle") }
                        .buttonStyle(.borderless)
                }
            }
            Button("Add time") { timer.clockTimes.append(.init(hour: 12, minute: 0)) }
            number("Break (seconds, 0 = alert only)", $timer.breakDuration)
        }
    }

    @ViewBuilder private var activeHours: some View {
        Toggle("Only during active hours", isOn: Binding(
            get: { timer.activeHours != nil },
            set: { timer.activeHours = $0 ? ActiveHours() : nil }))
        if timer.activeHours != nil {
            HStack {
                ForEach(1...7, id: \.self) { day in
                    Toggle(Calendar.current.veryShortWeekdaySymbols[day - 1], isOn: Binding(
                        get: { timer.activeHours?.weekdays.contains(day) ?? false },
                        set: { on in
                            if on { timer.activeHours?.weekdays.insert(day) } else { timer.activeHours?.weekdays.remove(day) }
                        }))
                    .toggleStyle(.button)
                }
            }
            DatePicker("From", selection: hours(\.start), displayedComponents: .hourAndMinute)
            DatePicker("To", selection: hours(\.end), displayedComponents: .hourAndMinute)
        }
    }

    private var isValid: Bool {
        guard !timer.name.trimmingCharacters(in: .whitespaces).isEmpty, timer.breakDuration >= 0 else { return false }
        switch timer.kind {
        case .scheduled: return !timer.clockTimes.isEmpty
        case .pomodoro: return timer.interval > 0 && timer.longBreakDuration >= 0
        default: return timer.interval > 0
        }
    }

    private func applyDefaults(_ id: UUID) {
        guard let c = engine.state.categories.first(where: { $0.id == id }) else { return }
        let fresh = BreakTimer(category: c)
        timer.name = fresh.name
        timer.kind = fresh.kind
        timer.interval = fresh.interval
        timer.breakDuration = fresh.breakDuration
        timer.message = fresh.message
        timer.clockTimes = fresh.clockTimes
    }

    private func number(_ label: String, _ value: Binding<Double>) -> some View {
        LabeledContent(label) {
            TextField("", value: value, format: .number).frame(width: 70).multilineTextAlignment(.trailing)
        }
    }

    private func minutes(_ kp: WritableKeyPath<BreakTimer, TimeInterval>) -> Binding<Double> {
        Binding(get: { timer[keyPath: kp] / 60 }, set: { timer[keyPath: kp] = $0 * 60 })
    }

    private func clock(_ i: Int) -> Binding<Date> {
        Binding(get: { date(from: timer.clockTimes[i]) },
                set: { timer.clockTimes[i] = clockTime(from: $0) })
    }

    private func hours(_ kp: WritableKeyPath<ActiveHours, ClockTime>) -> Binding<Date> {
        Binding(get: { date(from: timer.activeHours?[keyPath: kp] ?? .init(hour: 9, minute: 0)) },
                set: { timer.activeHours?[keyPath: kp] = clockTime(from: $0) })
    }

    private func date(from t: ClockTime) -> Date {
        Calendar.current.date(bySettingHour: t.hour, minute: t.minute, second: 0, of: .now) ?? .now
    }

    private func clockTime(from d: Date) -> ClockTime {
        let c = Calendar.current.dateComponents([.hour, .minute], from: d)
        return .init(hour: c.hour ?? 0, minute: c.minute ?? 0)
    }
}
