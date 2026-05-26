import SwiftUI
import AppKit

struct MenuBarView: View {
    @ObservedObject var viewModel: MenuBarViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            statusHeader
            Divider()
            menuItems
            Divider()
            quitItem
        }
        .padding()
        .frame(width: 280)
    }

    private var statusHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: viewModel.state.appIconName)
                    .font(.title2)
                    .foregroundColor(statusColor)
                Text("CleanKeys")
                    .font(.headline)
                Spacer()
                Text(viewModel.state.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if viewModel.state == .cleaning {
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(.orange)
                    Text(viewModel.countdownText)
                        .font(.body.monospacedDigit())
                        .fontWeight(.semibold)
                    Spacer()
                    Button("Extend +5m") {
                        viewModel.extendTimeout(by: 300)
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.accentColor)
                }
                .font(.caption)
            }
        }
    }

    private var statusColor: Color {
        switch viewModel.state {
        case .cleaning: return .red
        case .exiting: return .orange
        default: return .green
        }
    }

    private var menuItems: some View {
        VStack(alignment: .leading, spacing: 4) {
            if viewModel.state == .cleaning {
                exitButton
                overlayPinButton
            } else {
                activateButton
            }
        }
    }

    private var activateButton: some View {
        Button(action: {
            DialogWindowController.shared.showConfirmation(mode: .activate) {
                viewModel.confirmActivation()
            }
        }) {
            HStack {
                Image(systemName: "hand.tap")
                Text("Activate Cleaning Mode")
                Spacer()
            }
        }
    }

    private var exitButton: some View {
        Button(action: {
            DialogWindowController.shared.showConfirmation(mode: .exit) {
                viewModel.exit()
            }
        }) {
            HStack {
                Image(systemName: "escape")
                Text("Exit Cleaning Mode")
                Spacer()
            }
        }
        .foregroundColor(.red)
    }

    private var overlayPinButton: some View {
        Button(action: { viewModel.toggleOverlayPin() }) {
            HStack {
                Image(systemName: viewModel.isOverlayPinned ? "pin.slash" : "pin")
                Text(viewModel.isOverlayPinned ? "Unpin Overlay" : "Pin Overlay")
                Spacer()
            }
        }
    }

    private var quitItem: some View {
        Button("Quit CleanKeys") {
            NSApp.terminate(nil)
        }
    }
}
