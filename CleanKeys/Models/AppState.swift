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

    var description: String {
        switch self {
        case .normal: return "Normal"
        case .activated: return "Activated"
        case .cleaning: return "Cleaning"
        case .exiting: return "Exiting"
        }
    }
}