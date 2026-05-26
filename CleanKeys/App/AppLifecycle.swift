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
    let overlayController: OverlayWindowController

    private let singletonLockPath = "/tmp/com.scientist.CleanKeys.lock"

    override init() {
        stateMachine = StateMachine()
        eventTapService = EventTapService(stateMachine: stateMachine)
        failSafeManager = FailSafeManager(stateMachine: stateMachine)
        permissionManager = PermissionManager()
        systemObserver = SystemObserver(stateMachine: stateMachine, eventTapService: eventTapService)
        watchdogHeartbeat = WatchdogHeartbeat()
        overlayController = OverlayWindowController()
        menuBarViewModel = MenuBarViewModel(stateMachine: stateMachine, failSafeManager: failSafeManager)

        super.init()

        setupStateObserver()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        enforceSingleton()
        restoreState()
        systemObserver.startObserving()
        watchdogHeartbeat.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        if stateMachine.state == .cleaning {
            stateMachine.transition(to: .exiting)
            eventTapService.stop()
            failSafeManager.cancel()
            overlayController.dismiss()
        }
        watchdogHeartbeat.stop()
        removeLockFile()
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
        guard let newState = notification.userInfo?["newState"] as? AppState else { return }

        switch newState {
        case .cleaning:
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.overlayController.show(
                    countdownText: self.failSafeManager.countdownText
                ) { [weak self] in
                    self?.menuBarViewModel.toggleOverlayPin()
                }
            }
        case .exiting, .normal:
            overlayController.dismiss()
        default:
            break
        }
    }

    private func enforceSingleton() {
        guard createLockFile() else {
            showAlert(
                title: "CleanKeys Already Running",
                message: "Another instance of CleanKeys is already active."
            )
            NSApp.terminate(nil)
            exit(0)
        }
    }

    private func createLockFile() -> Bool {
        do {
            if FileManager.default.fileExists(atPath: singletonLockPath) {
                let content = try String(contentsOfFile: singletonLockPath, encoding: .utf8)
                if let pid = Int(content) {
                    let isRunning = NSRunningApplication.runningApplications(withBundleIdentifier: "com.scientist.CleanKeys").contains {
                        $0.processIdentifier == pid
                    }
                    if isRunning { return false }
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
            stateMachine.transition(to: .exiting)
            stateMachine.transition(to: .normal)
            showAlert(
                title: "CleanKeys Recovered",
                message: "CleanKeys was unexpectedly terminated while in cleaning mode.\nKeyboard input has been restored."
            )
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = title
        alert.informativeText = message
        alert.runModal()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
