import ChillyCore
import SwiftUI

struct BreakView: View {
    let timer: BreakTimer
    let category: TimerCategory?
    /// nil = plain alert with no countdown.
    let end: Date?
    let snoozeMinutes: Double
    let overlay: Bool
    let finish: (BreakOutcome) -> Void

    private var tint: Color { Color(hex: category?.colorHex ?? "#8E8E93") }

    var body: some View {
        ZStack {
            VisualEffect(material: overlay ? .fullScreenUI : .popover)
            if overlay { Color.black.opacity(0.35) }
            content.padding(overlay ? 40 : 16)
        }
        .clipShape(RoundedRectangle(cornerRadius: overlay ? 0 : 14))
        .environment(\.colorScheme, overlay ? .dark : .light)
    }

    private var content: some View {
        VStack(spacing: overlay ? 20 : 10) {
            Image(systemName: category?.symbol ?? "bell")
                .font(.system(size: overlay ? 64 : 28))
                .foregroundStyle(tint)
            Text(timer.name).font(overlay ? .largeTitle.bold() : .headline)
            Text(timer.message)
                .font(overlay ? .title2 : .callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            if let end {
                Text(timerInterval: Date.now...end, countsDown: true)
                    .font(.system(size: overlay ? 56 : 24, weight: .semibold, design: .rounded).monospacedDigit())
            }
            HStack {
                if end == nil {
                    Button("Done") { finish(.taken) }.keyboardShortcut(.defaultAction)
                } else {
                    Button("Skip") { finish(.skipped) }.keyboardShortcut(.cancelAction)
                }
                Button("Snooze \(Int(snoozeMinutes)) min") { finish(.snoozed) }
            }
            .controlSize(overlay ? .large : .regular)
        }
    }
}

struct VisualEffect: NSViewRepresentable {
    let material: NSVisualEffectView.Material

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material
        v.blendingMode = .behindWindow
        v.state = .active
        return v
    }

    func updateNSView(_ v: NSVisualEffectView, context: Context) {}
}
