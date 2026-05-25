import Foundation

class WatchdogHeartbeat {

    private let heartbeatPath = "/tmp/com.scientist.CleanKeys.heartbeat"
    private var timer: Timer?

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.writeHeartbeat()
        }
        writeHeartbeat()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        removeHeartbeat()
    }

    private func writeHeartbeat() {
        let timestamp = String(Int(Date().timeIntervalSince1970))
        try? timestamp.write(toFile: heartbeatPath, atomically: true, encoding: .utf8)
    }

    private func removeHeartbeat() {
        try? FileManager.default.removeItem(atPath: heartbeatPath)
    }
}