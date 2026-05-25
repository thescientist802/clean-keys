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
            name: NSWorkspace.didSleepNotification,
            object: nil
        )

        notificationCenter.addObserver(
            self,
            selector: #selector(handleScreenWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        notificationCenter.addObserver(
            self,
            selector: #selector(handleSessionDidEnd),
            name: NSWorkspace.sessionDidEndNotification,
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

    @objc private func handleSessionDidEnd() {
        if stateMachine.state == .cleaning {
            eventTapService.reinstall()
        }
    }

    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
}
