import Foundation

enum AppState: String, Codable, CaseIterable {
    case normal
    case activated
    case cleaning
    case exiting

    var appIconName: String {
        switch self {
        case .normal: return "keyboard"
        case .activated: return "keyboard"
        case .cleaning: return "keyboard.fill"
        case .exiting: return "keyboard"
        }
    }

    var displayName: String {
        switch self {
        case .normal: return "Ready"
        case .activated: return "Activating…"
        case .cleaning: return "Cleaning"
        case .exiting: return "Restoring…"
        }
    }

    var statusDetail: String {
        switch self {
        case .normal:
            return "Keyboard, volume, and brightness are active."
        case .activated:
            return "Starting cleaning mode…"
        case .cleaning:
            return "Keyboard, volume, and brightness inputs are blocked."
        case .exiting:
            return "Restoring keyboard, volume, and brightness…"
        }
    }
}