import Foundation
import AppKit

class AppLifecycle: NSObject, NSApplicationDelegate {

    static let shared = AppLifecycle()

    let stateMachine: StateMachine
    let eventTapService: EventTapService
    let failSafeManager: FailSafeManager
    let permissionManager: PermissionManager
    let systemObserver: SystemObserver
    let watchdogHeartbeat: WatchdogHeartbeat

    let menuBarViewModel: MenuBarViewModel

    private let singletonLockPath = "/tmp/com.scientist.CleanKeys.lock"
    private var fileLock: FileHandle?

    override private init() {
        stateMachine = StateMachine()
        eventTapService = EventTapService(stateMachine: stateMachine)
        failSafeManager = FailSafeManager(stateMachine: stateMachine)
        permissionManager = PermissionManager()
        systemObserver = SystemObserver(stateMachine: stateMachine, eventTapService: eventTapService)
        watchdogHeartbeat = WatchdogHeartbeat()
        menuBarViewModel = MenuBarViewModel(stateMachine: stateMachine, failSafeManager: failSafeManager)

        super.init()

        enforceSingleton()
        restoreState()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        systemObserver.startObserving()
        watchdogHeartbeat.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        if stateMachine.state == .cleaning {
            stateMachine.transition(to: .exiting)
            eventTapService.stop()
            failSafeManager.cancel()
        }
        watchdogHeartbeat.stop()
        removeLockFile()
    }

    private func enforceSingleton() {
        guard createLockFile() else {
            NSAlert.alert(
                title: "CleanKeys Already Running",
                message: "Another instance of CleanKeys is already active."
            ).runModal()
            NSApp.terminate(nil)
            exit(0)
        }
    }

    private func createLockFile() -> Bool {
        do {
            if FileManager.default.fileExists(atPath: singletonLockPath) {
                let content = try String(contentsOfFile: singletonLockPath, encoding: .utf8)
                if let pid = Int(content) {
                    let running = ProcessInfo.processInfo.processWithProcessIdentifier(pid) != nil
                    if running { return false }
                }
            }

            let pidString = String(ProcessInfo.processInfo.processIdentifier)
            try pidString.write(toFile: singletonLockPath, atomically: true, encoding: .utf8)
            return true
        } catch {
            return false
        }
    }

    private func removeLockFile() {
        try? FileManager.default.removeItem(atPath: singletonLockPath)
    }

    private func restoreState() {
        let restored = stateMachine.restorePersistedState()
        if restored && stateMachine.state == .cleaning {
            stateMachine.transition(to: .normal)
            showRecoveryAlert()
        }
    }

    private func showRecoveryAlert() {
        NSAlert.alert(
            title: "CleanKeys Recovered",
            message: "CleanKeys was unexpectedly terminated while in cleaning mode.\nKeyboard input has been restored."
        ).runModal()
    }
}