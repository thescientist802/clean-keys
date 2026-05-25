import Foundation
import AppKit
import ApplicationServices

class PermissionManager {

    var isAccessibilityGranted: Bool {
        AXIsProcessTrusted()
    }

    var isInputMonitoringGranted: Bool {
        checkInputMonitoringPermission()
    }

    func requestAllPermissions(completion: @escaping (Bool) -> Void) {
        let accessibility = requestAccessibility()
        completion(accessibility)
    }

    private func requestAccessibility() -> Bool {
        if AXIsProcessTrusted() { return true }

        let options: [String: Any] = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true
        ]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
        return AXIsProcessTrusted()
    }

    private func checkInputMonitoringPermission() -> Bool {
        #if swift(>=5.7)
        if #available(macOS 12.3, *) {
            return CGEvent.tapEnabled(tap: .cSessionEventTap, place: .headInsertEventTap, options: .defaultTap)
        }
        #endif
        return AXIsProcessTrusted()
    }

    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    func openInputMonitoringSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_InputMonitoring") {
            NSWorkspace.shared.open(url)
        }
    }
}
