import Foundation
import Combine
import AppKit

class MenuBarViewModel: ObservableObject {

    @Published var state: AppState = .normal
    @Published var countdownText: String = ""
    @Published var isOverlayPinned: Bool = Settings.shared.overlayPinned
    @Published var statusDetail: String = AppState.normal.statusDetail
    @Published var activationError: String?

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

        NotificationCenter.default.publisher(for: .eventTapFailed)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.handleEventTapFailure()
            }
            .store(in: &cancellables)
    }

    var canActivateCleaningMode: Bool {
        state == .normal
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

        guard permissionManager.ensureInputMonitoringAccess() else {
            activationError = "Input Monitoring permission is required. Enable CleanKeys in System Settings → Privacy & Security → Input Monitoring, then try again."
            permissionManager.openInputMonitoringSettings()
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

    private func handleEventTapFailure() {
        activationError = "Could not block keyboard input. Grant Input Monitoring permission and activate again."
        permissionManager.openInputMonitoringSettings()
        if stateMachine.state == .cleaning {
            _ = stateMachine.transition(to: .exiting)
        }
    }
}
