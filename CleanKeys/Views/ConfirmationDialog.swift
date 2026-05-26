import SwiftUI
import AppKit

class DialogWindowController {

    static let shared = DialogWindowController()

    private var panel: NSPanel?
    
    func dismiss() {
        panel?.orderOut(nil)
        
        panel = nil
    }

    func showConfirmation(mode: DialogMode, onConfirm: @escaping () -> Void) {
        panel?.orderOut(nil)

        let dialogViewModel = DialogViewModel(mode: mode, onConfirm: onConfirm)
        let contentView = ConfirmationDialogView(viewModel: dialogViewModel)
            .frame(width: 380, height: 220)

        let hostingView = NSHostingView(rootView: contentView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 220),
            styleMask: [.titled, .closable, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.contentView = hostingView
        panel.level = .modalPanel
        panel.isMovable = false
        panel.titlebarAppearsTransparent = true
        panel.hasShadow = true
        panel.backgroundColor = NSColor.windowBackgroundColor
        panel.isOpaque = false

        guard let screen = NSScreen.main else { return }
        let panelFrame = panel.frame
        panel.setFrameOrigin(NSPoint(
            x: screen.frame.midX - panelFrame.width / 2,
            y: screen.frame.midY - panelFrame.height / 2
        ))

        panel.makeKeyAndOrderFront(nil)
        self.panel = panel
    }
}

struct ConfirmationDialogView: View {
    @ObservedObject var viewModel: DialogViewModel

    var body: some View {
        VStack(spacing: 20) {
            iconSection
            messageSection
            buttonSection
        }
        .padding(24)
    }

    private var iconSection: some View {
        Group {
            if #available(macOS 14.0, *) {
                Image(systemName: viewModel.mode.iconName)
                    .font(.system(size: 48))
                    .foregroundColor(viewModel.mode.iconColor)
                    .symbolEffect(.pulse)
            } else {
                Image(systemName: viewModel.mode.iconName)
                                .font(.system(size: 48))
                                .foregroundColor(viewModel.mode.iconColor)
            }
        }
    }

    private var messageSection: some View {
        VStack(spacing: 8) {
            Text(viewModel.mode.title)
                .font(.title2)
                .fontWeight(.bold)
            Text(viewModel.mode.message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var buttonSection: some View {
        HStack(spacing: 12) {
            Button("Cancel") {
                DialogWindowController.shared.dismiss()
            }
            .buttonStyle(.bordered)

            Button(viewModel.mode.confirmTitle) {
                viewModel.onConfirm()
                DialogWindowController.shared.dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
}

class DialogViewModel: ObservableObject {
    let mode: DialogMode
    let onConfirm: () -> Void

    init(mode: DialogMode, onConfirm: @escaping () -> Void) {
        self.mode = mode
        self.onConfirm = onConfirm
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
