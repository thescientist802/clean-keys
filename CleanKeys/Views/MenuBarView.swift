import SwiftUI
import AppKit

struct MenuBarView: View {
    @ObservedObject var viewModel: MenuBarViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            statusHeader
            if !viewModel.isInputMonitoringGranted {
                permissionBanner
            }
            if let error = viewModel.activationError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Divider()
            menuItems
            Divider()
            footerRow
        }
        .padding()
        .frame(width: 300)
    }

    private var statusHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: viewModel.state.appIconName)
                    .font(.title2)
                    .foregroundColor(statusColor)
                Text("CleanKeys")
                    .font(.headline)
                Spacer()
                Text(viewModel.state.displayName)
                    .font(.caption)
                    .fontWeight(viewModel.state == .cleaning ? .bold : .regular)
                    .foregroundColor(statusColor)
            }

            Text(viewModel.statusDetail)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

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
        case .activated: return .blue
        default: return .green
        }
    }

    private var permissionBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Input Monitoring is off", systemImage: "shield.slash")
                .font(.caption.bold())
                .foregroundColor(.orange)
            Button("Set Up Input Monitoring…") {
                viewModel.showInputMonitoringSetup()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
    }

    private var menuItems: some View {
        VStack(alignment: .leading, spacing: 4) {
            if viewModel.state == .cleaning {
                exitButton
                overlayPinButton
            } else if viewModel.state == .normal {
                activateButton
                    .disabled(!viewModel.isInputMonitoringGranted)
            } else {
                Text("Please wait…")
                    .font(.caption)
                    .foregroundColor(.secondary)
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

    private var footerRow: some View {
        HStack {
            Button {
                viewModel.showHelp()
            } label: {
                Image(systemName: "questionmark.circle")
            }
            .buttonStyle(.borderless)
            .help("How to use CleanKeys")

            Spacer()

            Button("Quit CleanKeys") {
                NSApp.terminate(nil)
            }
        }
    }
}
