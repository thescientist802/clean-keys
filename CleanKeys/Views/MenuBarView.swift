import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: MenuBarViewModel
    @State private var showingActivationDialog = false
    @State private var showingSettings = false

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
        .sheet(isPresented: $showingActivationDialog) {
            ConfirmationDialog(mode: .activate) {
                viewModel.confirmActivation()
            }
        }
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
                Text(viewModel.state.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if viewModel.state == .cleaning {
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(.orange)
                    Text(viewModel.countdownText)
                        .font(.monospacedDigit)
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
                extendOverlayButton
            } else {
                activateButton
            }
        }
    }

    private var activateButton: some View {
        Button(action: { showingActivationDialog = true }) {
            HStack {
                Image(systemName: "hand.tap")
                Text("Activate Cleaning Mode")
                Spacer()
            }
        }
    }

    private var exitButton: some View {
        Button(action: { viewModel.exit() }) {
            HStack {
                Image(systemName: "escape")
                Text("Exit Cleaning Mode")
                Spacer()
            }
        }
        .foregroundColor(.red)
    }

    private var extendOverlayButton: some View {
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