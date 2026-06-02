import Foundation
import Combine
import AppKit

class MenuBarViewModel: ObservableObject {

    @Published var state: AppState = .normal
    @Published var countdownText: String = ""
    @Published var isOverlayPinned: Bool = Settings.shared.overlayPinned
    @Published var statusDetail: String = AppState.normal.statusDetail
    @Published var activationError: String?
    @Published var isInputMonitoringGranted: Bool = false

    private let stateMachine: StateMachine
    private let failSafeManager: FailSafeManager
    private let permissionManager: PermissionManager
    private weak var overlayController: OverlayWindowController?
    private var cancellables = Set<AnyCancellable>()

    init(
        stateMachine: StateMachine,
        failSafeManager: FailSafeManager,
        permissionManager: PermissionManager,
        overlayController: OverlayWindowController
    ) {
        self.stateMachine = stateMachine
        self.failSafeManager = failSafeManager
        self.permissionManager = permissionManager
        self.overlayController = overlayController
        self.isInputMonitoringGranted = permissionManager.isInputMonitoringGranted

        stateMachine.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] newState in
                self?.state = newState
                self?.statusDetail = newState.statusDetail
                if newState == .cleaning {
                    self?.activationError = nil
                }
            }
            .store(in: &cancellables)

        failSafeManager.$countdownText
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                self?.countdownText = text
            }
            .store(in: &cancellables)

        permissionManager.$isInputMonitoringGranted
            .receive(on: RunLoop.main)
            .sink { [weak self] granted in
                self?.isInputMonitoringGranted = granted
                if granted {
                    self?.activationError = nil
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .eventTapFailed)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.handleEventTapFailure()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.permissionManager.refreshInputMonitoringStatus()
            }
            .store(in: &cancellables)
    }

    var canActivateCleaningMode: Bool {
        state == .normal && isInputMonitoringGranted
    }

    func confirmActivation() {
        activationError = nil

        if state == .exiting || state == .activated {
            _ = stateMachine.transition(to: .normal)
        }

        guard state == .normal else {
            activationError = "Finish exiting cleaning mode before activating again."
            return
        }

        guard isInputMonitoringGranted else {
            showInputMonitoringSetup()
            return
        }

        guard stateMachine.transition(to: .cleaning) else {
            activationError = "Could not enter cleaning mode. Try again."
            return
        }
    }

    func exit() {
        _ = stateMachine.transition(to: .exiting)
    }

    func extendTimeout(by seconds: Int) {
        failSafeManager.extend(by: seconds)
    }

    func toggleOverlayPin() {
        isOverlayPinned.toggle()
        Settings.shared.overlayPinned = isOverlayPinned
        try? Settings.shared.save()
        overlayController?.setPinned(isOverlayPinned)
    }

    func showHelp() {
        HelpPanelController.shared.show()
    }

    func showInputMonitoringSetup() {
        PermissionPanelController.shared.show(permissionManager: permissionManager) { [weak self] granted in
            guard granted else { return }
            self?.activationError = nil
        }
    }

    private func handleEventTapFailure() {
        activationError = "Could not block keyboard input. Grant Input Monitoring and try again."
        showInputMonitoringSetup()
        if stateMachine.state == .cleaning {
            _ = stateMachine.transition(to: .exiting)
        }
    }
}
