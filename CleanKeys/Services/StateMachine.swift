import Foundation
import Combine

class StateMachine: ObservableObject {

    @Published private(set) var state: AppState = .normal

    private let persistencePath: URL = {
        let fm = FileManager.default
        return fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("com.scientist.CleanKeys")
            .appendingPathComponent("state.json")
    }()

    func transition(to newState: AppState) {
        guard isValidTransition(from: state, to: newState) else { return }
        state = newState
        persistState()
        NotificationCenter.default.post(name: .stateMachineDidChange, object: self, userInfo: ["newState": newState])
    }

    func restorePersistedState() -> Bool {
        do {
            let data = try Data(contentsOf: persistencePath)
            let decoder = JSONDecoder()
            let persistedState = try decoder.decode(PersistedState.self, from: data)
            state = persistedState.state
            return true
        } catch {
            return false
        }
    }

    private func isValidTransition(from current: AppState, to target: AppState) -> Bool {
        switch (current, target) {
        case (.normal, .activated): return true
        case (.normal, .cleaning): return true
        case (.activated, .cleaning): return true
        case (.activated, .normal): return true
        case (.cleaning, .exiting): return true
        case (.exiting, .normal): return true
        default: return false
        }
    }

    func persistState() {
        let persisted = PersistedState(state: state)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            let data = try encoder.encode(persisted)
            try data.write(to: persistencePath, options: .atomic)
        } catch {
            print("Failed to persist state: \(error.localizedDescription)")
        }
    }
}

struct PersistedState: Codable {
    let state: AppState
}

extension Notification.Name {
    static let stateMachineDidChange = Notification.Name("stateMachineDidChange")
}