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
            .receive(on: RunLoop.main)
            .sink { [weak self] newState in
                self?.state = newState
            }
            .store(in: &cancellables)

        failSafeManager.$countdownText
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                self?.countdownText = text
            }
            .store(in: &cancellables)
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