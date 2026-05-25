import SwiftUI

struct ConfirmationDialog: View {
    let mode: DialogMode
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            iconSection
            messageSection
            buttonSection
        }
        .padding(24)
        .frame(width: 340)
    }

    private var iconSection: some View {
        Image(systemName: mode.iconName)
            .font(.system(size: 48))
            .foregroundColor(mode.iconColor)
            .symbolEffect(.pulse)
    }

    private var messageSection: some View {
        VStack(spacing: 8) {
            Text(mode.title)
                .font(.title2)
                .fontWeight(.bold)
            Text(mode.message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var buttonSection: some View {
        HStack(spacing: 12) {
            Button("Cancel") { dismiss() }
                .buttonStyle(.bordered)

            Button(mode.confirmTitle) {
                onConfirm()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
}

enum DialogMode {
    case activate
    case exit

    var iconName: String {
        switch self {
        case .activate: return "hand.tap"
        case .exit: return "escape"
        }
    }

    var iconColor: Color {
        switch self {
        case .activate: return .blue
        case .exit: return .red
        }
    }

    var title: String {
        switch self {
        case .activate: return "Activate Cleaning Mode?"
        case .exit: return "Exit Cleaning Mode?"
        }
    }

    var message: String {
        switch self {
        case .activate: return "All keyboard input will be suppressed until timeout or manual exit."
        case .exit: return "Keyboard input will be restored."
        }
    }

    var confirmTitle: String {
        switch self {
        case .activate: return "Activate"
        case .exit: return "Exit"
        }
    }
}