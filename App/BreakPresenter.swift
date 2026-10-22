import AppKit
import ChillyCore
import SwiftUI

/// Shows a break as a full-screen overlay on every display, or as a small popup.
@MainActor
final class BreakPresenter {
    private var windows: [NSWindow] = []
    private var autoFinish: Task<Void, Never>?
    private var completion: ((BreakOutcome) -> Void)?
    private lazy var sound = Bundle.main.url(forResource: "notification", withExtension: "mp3")
        .flatMap { NSSound(contentsOf: $0, byReference: true) }

    var isShowing: Bool { completion != nil }

    func show(timer: BreakTimer, category: TimerCategory?, duration: TimeInterval, snoozeMinutes: Double,
              completion: @escaping (BreakOutcome) -> Void) {
        self.completion = completion
        let end = Date.now.addingTimeInterval(duration)
        let content = { [unowned self] (overlay: Bool) in
            BreakView(timer: timer, category: category, end: duration > 0 ? end : nil,
                      snoozeMinutes: snoozeMinutes, overlay: overlay) { self.finish($0) }
        }

        switch timer.style {
        case .overlay:
            windows = NSScreen.screens.map { makeWindow(frame: $0.frame, level: .screenSaver, content: content(true)) }
        case .popup:
            let size = CGSize(width: 340, height: 200)
            let visible = (NSScreen.main ?? NSScreen.screens[0]).visibleFrame
            let frame = CGRect(x: visible.maxX - size.width - 16, y: visible.maxY - size.height - 16,
                               width: size.width, height: size.height)
            windows = [makeWindow(frame: frame, level: .floating, content: content(false))]
        }
        windows.forEach { $0.orderFrontRegardless() }
        windows.first?.makeKey()
        if timer.playSound, sound?.play() != true { NSSound.beep() }

        if duration > 0 {
            autoFinish = Task { [weak self] in
                try? await Task.sleep(for: .seconds(duration))
                guard !Task.isCancelled else { return }
                self?.finish(.taken)
            }
        }
    }

    private func finish(_ outcome: BreakOutcome) {
        guard let completion else { return } // several screens may report at once
        self.completion = nil
        autoFinish?.cancel()
        windows.forEach { $0.orderOut(nil) }
        windows = []
        completion(outcome)
    }

    private func makeWindow(frame: CGRect, level: NSWindow.Level, content: some View) -> NSWindow {
        let w = BreakWindow(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: false)
        w.level = level
        w.isOpaque = false
        w.backgroundColor = .clear
        w.hasShadow = level != .screenSaver
        w.isReleasedWhenClosed = false
        w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        w.contentView = NSHostingView(rootView: content)
        w.setFrame(frame, display: true)
        return w
    }
}

private final class BreakWindow: NSWindow {
    override var canBecomeKey: Bool { true }
}
