import Foundation
import AppKit
import ApplicationServices
import Combine

final class PermissionManager: ObservableObject {

    @Published private(set) var isInputMonitoringGranted: Bool = false

    var isAccessibilityGranted: Bool {
        AXIsProcessTrusted()
    }

    init() {
        refreshInputMonitoringStatus()
    }

    func refreshInputMonitoringStatus() {
        let granted = checkInputMonitoringPermission()
        if isInputMonitoringGranted != granted {
            isInputMonitoringGranted = granted
        }
    }

    /// Shows the system prompt (if available) asking the user to allow listen-event access.
    func requestInputMonitoringAccess() {
        if #available(macOS 10.15, *) {
            CGRequestListenEventAccess()
        }
        refreshInputMonitoringStatus()
    }

    /// Opens Privacy & Security → Input Monitoring.
    func openInputMonitoringSettings() {
        let candidates = [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_InputMonitoring",
        ]
        for scheme in candidates {
            guard let url = URL(string: scheme) else { continue }
            if NSWorkspace.shared.open(url) { return }
        }
    }

    /// Returns true when the app can install a session event tap (required for cleaning mode).
    @discardableResult
    func ensureInputMonitoringAccess() -> Bool {
        if checkInputMonitoringPermission() {
            refreshInputMonitoringStatus()
            return true
        }
        requestInputMonitoringAccess()
        refreshInputMonitoringStatus()
        return isInputMonitoringGranted
    }

    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func checkInputMonitoringPermission() -> Bool {
        if #available(macOS 10.15, *) {
            return CGPreflightListenEventAccess()
        }
        return true
    }
}
