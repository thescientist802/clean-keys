import Foundation
import AppKit

class WatchdogAgent {

    private let heartbeatPath = "/tmp/com.scientist.CleanKeys.heartbeat"
    private let staleThreshold: TimeInterval = 20
    private var timer: Timer?
    private var isMonitoring = false

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.checkHeartbeat()
        }
    }

    func stopMonitoring() {
        isMonitoring = false
        timer?.invalidate()
        timer = nil
    }

    private func checkHeartbeat() {
        guard let timestamp = readHeartbeat() else {
            forceRecovery()
            return
        }

        let age = Date().timeIntervalSince1970 - timestamp
        if age > staleThreshold {
            forceRecovery()
        }
    }

    private func readHeartbeat() -> TimeInterval? {
        do {
            let content = try String(contentsOfFile: heartbeatPath, encoding: .utf8)
            guard let timestamp = TimeInterval(content) else { return nil }
            return timestamp
        } catch {
            return nil
        }
    }

    private func forceRecovery() {
        guard let cleanKeysProcess = findCleanKeysProcess() else { return }

        cleanKeysProcess.forceTerminate()
        removeHeartbeat()
    }

    private func findCleanKeysProcess() -> NSRunningApplication? {
        NSRunningApplication.runningApplications(withBundleIdentifier: "com.scientist.CleanKeys").first
    }

    private func removeHeartbeat() {
        try? FileManager.default.removeItem(atPath: heartbeatPath)
    }
}
