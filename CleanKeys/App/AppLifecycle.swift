import Foundation
import AppKit

class AppLifecycle: NSObject, NSApplicationDelegate {

    private static let menuBarGuideDefaultsKey = "didShowMenuBarGuide"
    private static let permissionGuideDefaultsKey = "didShowPermissionGuide"
    private static let bundleIdentifier = "com.scientist.CleanKeys"

    let stateMachine: StateMachine
    let eventTapService: EventTapService
    let failSafeManager: FailSafeManager
    let permissionManager: PermissionManager
    let systemObserver: SystemObserver
    let watchdogHeartbeat: WatchdogHeartbeat
    private let hardwareControlsService: HardwareControlsService

    let menuBarViewModel: MenuBarViewModel
    let overlayController: OverlayWindowController

    override init() {
        stateMachine = StateMachine()
        eventTapService = EventTapService(stateMachine: stateMachine)
        failSafeManager = FailSafeManager(stateMachine: stateMachine)
        permissionManager = PermissionManager()
        systemObserver = SystemObserver(stateMachine: stateMachine, eventTapService: eventTapService)
        watchdogHeartbeat = WatchdogHeartbeat()
        hardwareControlsService = HardwareControlsService(stateMachine: stateMachine)
        overlayController = OverlayWindowController()
        menuBarViewModel = MenuBarViewModel(
            stateMachine: stateMachine,
            failSafeManager: failSafeManager,
            permissionManager: permissionManager,
            overlayController: overlayController
        )

        super.init()

        setupStateObserver()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard acquireSingleton() else { return }

        NSApp.activate(ignoringOtherApps: true)
        restoreState()
        systemObserver.startObserving()
        watchdogHeartbeat.start()
        showMenuBarGuideIfNeeded()
        showPermissionGuideIfNeeded()
    }

    func applicationWillTerminate(_ notification: Notification) {
        if stateMachine.state == .cleaning {
            stateMachine.transition(to: .exiting)
            eventTapService.stop()
            failSafeManager.cancel()
            overlayController.dismiss()
        }
        watchdogHeartbeat.stop()
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
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let pinned = self.menuBarViewModel.isOverlayPinned
                self.overlayController.show(
                    failSafeManager: self.failSafeManager,
                    pinned: pinned
                ) { [weak self] in
                    guard let self = self else { return }
                    self.menuBarViewModel.toggleOverlayPin()
                    self.overlayController.setPinned(self.menuBarViewModel.isOverlayPinned)
                }
            }
        case .exiting:
            overlayController.dismiss()
            _ = stateMachine.transition(to: .normal)
        case .normal:
            overlayController.dismiss()
        default:
            break
        }
    }

    /// Returns false when another instance is already running (this process will terminate).
    private func acquireSingleton() -> Bool {
        let currentPID = ProcessInfo.processInfo.processIdentifier
        let otherInstances = NSRunningApplication.runningApplications(withBundleIdentifier: Self.bundleIdentifier)
            .filter { $0.processIdentifier != currentPID }

        if let existing = otherInstances.first {
            existing.activate(options: [.activateIgnoringOtherApps, .activateAllWindows])
            showAlert(
                title: "CleanKeys Already Running",
                message: """
                Another copy of CleanKeys is already active.

                Look for the keyboard icon in the menu bar (top of the screen). If you do not see it, open the menu bar overflow (») near the clock.

                Quit the running copy from that menu (Quit CleanKeys) before starting again from Xcode.
                """
            )
            NSApp.terminate(nil)
            return false
        }

        return true
    }

    private func showMenuBarGuideIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: Self.menuBarGuideDefaultsKey) else { return }
        UserDefaults.standard.set(true, forKey: Self.menuBarGuideDefaultsKey)

        WelcomePanelController.shared.show()
    }

    private func showPermissionGuideIfNeeded() {
        permissionManager.refreshInputMonitoringStatus()
        guard !permissionManager.isInputMonitoringGranted else { return }
        guard !UserDefaults.standard.bool(forKey: Self.permissionGuideDefaultsKey) else { return }

        UserDefaults.standard.set(true, forKey: Self.permissionGuideDefaultsKey)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self, !self.permissionManager.isInputMonitoringGranted else { return }
            PermissionPanelController.shared.show(permissionManager: self.permissionManager, onComplete: nil)
        }
    }

    private func restoreState() {
        let restored = stateMachine.restorePersistedState()
        guard restored else { return }

        let wasCleaning = stateMachine.state == .cleaning
        stateMachine.normalizeToNormalIfNeeded()

        if wasCleaning {
            showAlert(
                title: "CleanKeys Recovered",
                message: "CleanKeys was unexpectedly terminated while in cleaning mode.\nKeyboard, volume, and brightness have been restored."
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
