import AppKit
import CoreAudio
import CoreMediaIO
import ChillyCore

/// Detects when the user is away or busy, using only APIs that need no permission prompt.
enum Presence {
    static var idleSeconds: TimeInterval {
        CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: CGEventType(rawValue: ~0)!)
    }

    static func postponeReason(_ settings: AppSettings) -> String? {
        if settings.postponeDuringCalls && (micInUse || cameraInUse) { return "In a call" }
        return nil
    }

    static var micInUse: Bool {
        var addr = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultInputDevice,
                                              mScope: kAudioObjectPropertyScopeGlobal,
                                              mElement: kAudioObjectPropertyElementMain)
        var device = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size, &device) == noErr
        else { return false }
        addr.mSelector = kAudioDevicePropertyDeviceIsRunningSomewhere
        var running: UInt32 = 0
        size = UInt32(MemoryLayout<UInt32>.size)
        return AudioObjectGetPropertyData(device, &addr, 0, nil, &size, &running) == noErr && running != 0
    }

    static var cameraInUse: Bool {
        var addr = CMIOObjectPropertyAddress(mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
                                             mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
                                             mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain))
        let system = CMIOObjectID(kCMIOObjectSystemObject)
        var size: UInt32 = 0
        guard CMIOObjectGetPropertyDataSize(system, &addr, 0, nil, &size) == noErr else { return false }
        var devices = [CMIOObjectID](repeating: 0, count: Int(size) / MemoryLayout<CMIOObjectID>.size)
        guard CMIOObjectGetPropertyData(system, &addr, 0, nil, size, &size, &devices) == noErr else { return false }
        addr.mSelector = CMIOObjectPropertySelector(kCMIODevicePropertyDeviceIsRunningSomewhere)
        return devices.contains { device in
            var running: UInt32 = 0
            var used = UInt32(MemoryLayout<UInt32>.size)
            return CMIOObjectGetPropertyData(device, &addr, 0, nil, used, &used, &running) == noErr && running != 0
        }
    }
}
