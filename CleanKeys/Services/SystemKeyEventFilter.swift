import CoreGraphics
import AppKit

/// NX key types carried in system-defined (media / brightness) events.
enum SystemKeyEventFilter {

    /// `kCGEventSystemDefined` — not exposed on all SDKs as `CGEventType.systemDefined`.
    static let systemDefinedEventType = CGEventType(rawValue: 14)!

    private static let soundUp: UInt32 = 0
    private static let soundDown: UInt32 = 1
    private static let brightnessUp: UInt32 = 2
    private static let brightnessDown: UInt32 = 3
    private static let mute: UInt32 = 7
    private static let volumeUpAlt: UInt32 = 16
    private static let volumeDownAlt: UInt32 = 17

    static func isHardwareControlEvent(_ event: CGEvent) -> Bool {
        guard event.type == systemDefinedEventType else { return false }
        guard let keyType = systemKeyType(from: event) else { return false }
        return blockedKeyTypes.contains(keyType)
    }

    private static var blockedKeyTypes: Set<UInt32> {
        [soundUp, soundDown, brightnessUp, brightnessDown, mute, volumeUpAlt, volumeDownAlt]
    }

    private static func systemKeyType(from event: CGEvent) -> UInt32? {
        if let nsEvent = NSEvent(cgEvent: event), nsEvent.type == .systemDefined {
            let data1 = Int(nsEvent.data1)
            return UInt32((data1 >> 16) & 0xFF)
        }

        let packed = event.getIntegerValueField(.eventSourceUserData)
        let keyType = UInt32((packed >> 16) & 0xFF)
        return keyType
    }
}
