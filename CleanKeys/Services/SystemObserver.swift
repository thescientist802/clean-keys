import Foundation
import AppKit

class SystemObserver {

    private let stateMachine: StateMachine
    private let eventTapService: EventTapService

    init(stateMachine: StateMachine, eventTapService: EventTapService) {
        self.stateMachine = stateMachine
        self.eventTapService = eventTapService
    }

    func startObserving() {
        let workspace = NSWorkspace.shared
        let notificationCenter = workspace.notificationCenter

        notificationCenter.addObserver(
            self,
            selector: #selector(handleScreenSleep),
            name: NSWorkspace.screensDidSleepNotification,
            object: nil
        )

        notificationCenter.addObserver(
            self,
            selector: #selector(handleScreenWake),
            name: NSWorkspace.screensDidWakeNotification,
            object: nil
        )

        notificationCenter.addObserver(
            self,
            selector: #selector(handleSessionDidResignActive),
            name: NSWorkspace.sessionDidResignActiveNotification,
            object: nil
        )
    }

    @objc private func handleScreenSleep() {
        stateMachine.persistState()
    }

    @objc private func handleScreenWake() {
        if stateMachine.state == .cleaning {
            eventTapService.reinstall()
        }
    }

    @objc private func handleSessionDidResignActive() {
        if stateMachine.state == .cleaning {
            eventTapService.reinstall()
        }
    }

    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
}
