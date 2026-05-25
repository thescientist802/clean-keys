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
        let inputMonitoring = requestInputMonitoring()
        completion(accessibility && inputMonitoring)
    }

    private func checkInputMonitoringPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    private func requestAccessibility() -> Bool {
        if AXIsProcessTrusted() { return true }

        let systemWideElement = AXUIElementCreateSystemWide()
        _ = AXUIElementIsTrusted(systemWideElement)

        return AXIsProcessTrusted()
    }

    private func requestInputMonitoring() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
        return checkInputMonitoringPermission()
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