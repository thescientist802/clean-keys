import Foundation
import Combine

class MenuBarViewModel: ObservableObject {

    @Published var state: AppState = .normal
    @Published var countdownText: String = ""
    @Published var isOverlayPinned: Bool = false

    private let stateMachine: StateMachine
    private let failSafeManager: FailSafeManager
    private var cancellables = Set<AnyCancellable>()

    init(stateMachine: StateMachine, failSafeManager: FailSafeManager) {
        self.stateMachine = stateMachine
        self.failSafeManager = failSafeManager

        stateMachine.$state
            .assign(to: &$state)

        failSafeManager.$countdownText
            .assign(to: &$countdownText)
    }

    func activate() {
        stateMachine.transition(to: .activated)
    }

    func confirmActivation() {
        stateMachine.transition(to: .cleaning)
    }

    func exit() {
        stateMachine.transition(to: .exiting)
    }

    func extendTimeout(by seconds: Int) {
        failSafeManager.extend(by: seconds)
    }

    func toggleOverlayPin() {
        isOverlayPinned.toggle()
        let settings = Settings.load()
        var updatedSettings = settings
        updatedSettings.overlayPinned = isOverlayPinned
        try? updatedSettings.save()
    }
}