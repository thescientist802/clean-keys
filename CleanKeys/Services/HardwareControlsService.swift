import Foundation
import CoreAudio
import IOKit

/// Mutes volume and dims display on cleaning entry; blocks are reinforced in EventTapService.
final class HardwareControlsService {

    private let stateMachine: StateMachine
    private var savedBrightness: Float?
    private var savedMuted: Bool?
    private var didApplyCleaningControls = false

    init(stateMachine: StateMachine) {
        self.stateMachine = stateMachine
        setupStateObserver()
    }

    private func setupStateObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStateChange(_:)),
            name: .stateMachineDidChange,
            object: nil
        )
    }

    @objc private func handleStateChange(_ notification: Notification) {
        guard (notification.object as? StateMachine) === stateMachine else { return }
        guard let newState = notification.userInfo?["newState"] as? AppState else { return }

        switch newState {
        case .cleaning:
            applyCleaningControls()
        case .exiting, .normal:
            restoreControls()
        default:
            break
        }
    }

    private func applyCleaningControls() {
        guard !didApplyCleaningControls else { return }
        didApplyCleaningControls = true

        if let brightness = readBrightness() {
            savedBrightness = brightness
            _ = writeBrightness(0)
        }

        if let muted = readSystemMuted() {
            savedMuted = muted
            _ = writeSystemMuted(true)
        }
    }

    private func restoreControls() {
        guard didApplyCleaningControls else { return }
        didApplyCleaningControls = false

        if let savedBrightness {
            _ = writeBrightness(savedBrightness)
            self.savedBrightness = nil
        }

        if let savedMuted {
            _ = writeSystemMuted(savedMuted)
            self.savedMuted = nil
        }
    }

    // MARK: - Brightness (IOKit)

    private func readBrightness() -> Float? {
        var brightness: Float = 0
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IODisplayConnect"))
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }

        let result = IODisplayGetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, &brightness)
        return result == kIOReturnSuccess ? brightness : nil
    }

    @discardableResult
    private func writeBrightness(_ value: Float) -> Bool {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IODisplayConnect"))
        guard service != 0 else { return false }
        defer { IOObjectRelease(service) }

        let clamped = max(0, min(1, value))
        return IODisplaySetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, clamped) == kIOReturnSuccess
    }

    // MARK: - Volume (CoreAudio)

    private func defaultOutputDeviceID() -> AudioDeviceID? {
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )
        return status == noErr ? deviceID : nil
    }

    private func readSystemMuted() -> Bool? {
        guard let deviceID = defaultOutputDeviceID() else { return nil }

        var muted: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &muted)
        return status == noErr ? (muted != 0) : nil
    }

    @discardableResult
    private func writeSystemMuted(_ muted: Bool) -> Bool {
        guard let deviceID = defaultOutputDeviceID() else { return false }

        var value: UInt32 = muted ? 1 : 0
        let size = UInt32(MemoryLayout<UInt32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        return AudioObjectSetPropertyData(deviceID, &address, 0, nil, size, &value) == noErr
    }

    deinit {
        restoreControls()
        NotificationCenter.default.removeObserver(self)
    }
}
