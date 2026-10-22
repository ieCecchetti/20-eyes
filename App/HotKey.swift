import Carbon

/// One global shortcut via Carbon, which needs no Accessibility permission.
// ponytail: fixed ⌃⌥⌘P; add a shortcut recorder in Settings if users ask to rebind it.
@MainActor
final class HotKey {
    private static var action: (@MainActor () -> Void)?
    private var ref: EventHotKeyRef?

    init(action: @escaping @MainActor () -> Void) {
        HotKey.action = action
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
            MainActor.assumeIsolated { HotKey.action?() }
            return noErr
        }, 1, &spec, nil, nil)
        RegisterEventHotKey(UInt32(kVK_ANSI_P), UInt32(cmdKey | optionKey | controlKey),
                            EventHotKeyID(signature: OSType(0x4348_4559), id: 1), // "CHEY"
                            GetApplicationEventTarget(), 0, &ref)
    }

    static let display = "⌃⌥⌘P"
}
