import Foundation
import Combine
import AppKit

class FailSafeManager: ObservableObject {

    private let stateMachine: StateMachine
    private var timer: Timer?
    private var remainingSeconds: Int = 0
    private let warningTimes: Set<Int> = [30, 10, 5]
    private var warningsFired: Set<Int> = []

    @Published var countdownText: String = ""

    init(stateMachine: StateMachine) {
        self.stateMachine = stateMachine
        setupStateObserver()
    }

    func startCountdown(timeoutSeconds: Int) {
        cancel()
        guard timeoutSeconds > 0 else {
            stateMachine.transition(to: .exiting)
            return
        }
        remainingSeconds = timeoutSeconds
        warningsFired = []

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.remainingSeconds -= 1
            self.updateCountdownText()
            self.checkWarnings()

            if self.remainingSeconds <= 0 {
                self.cancel()
                self.stateMachine.transition(to: .exiting)
            }
        }
        updateCountdownText()
    }

    func cancel() {
        timer?.invalidate()
        timer = nil
        remainingSeconds = 0
        countdownText = ""
        warningsFired = []
    }

    func extend(by seconds: Int) {
        guard timer != nil else { return }
        remainingSeconds = max(0, remainingSeconds + seconds)
        updateCountdownText()
    }

    private func updateCountdownText() {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        countdownText = String(format: "%02d:%02d", minutes, seconds)
    }

    private func checkWarnings() {
        guard warningTimes.contains(remainingSeconds) && !warningsFired.contains(remainingSeconds) else { return }
        warningsFired.insert(remainingSeconds)
        playWarningSound()
    }

    private func playWarningSound() {
        guard Settings.shared.soundWarningsEnabled else { return }
        if let sound = NSSound(named: "Glass") {
            sound.play()
        } else {
            NSSound.beep()
        }
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
            startCountdown(timeoutSeconds: Settings.shared.timeoutSeconds)
        case .exiting, .normal:
            cancel()
        default:
            break
        }
    }

    deinit {
        cancel()
        NotificationCenter.default.removeObserver(self)
    }
}
