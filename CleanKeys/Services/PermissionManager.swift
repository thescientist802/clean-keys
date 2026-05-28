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
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
        return AXIsProcessTrusted()
    }

    private func checkInputMonitoringPermission() -> Bool {
        if #available(macOS 10.15, *) {
            return CGPreflightListenEventAccess()
        }
        return true
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
