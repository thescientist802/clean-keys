import SwiftUI
import AppKit

class OverlayWindowController {

    private var window: NSWindow?
    private var autoHideTimer: Timer?
    private var isPinned: Bool = false

    func show(countdownText: String, onPinToggle: @escaping () -> Void) {
        dismiss()

        let viewModel = OverlayViewModel(countdownText: countdownText, onPinToggle: onPinToggle)
        let contentView = OverlayView(viewModel: viewModel)
            .frame(minWidth: 320, maxWidth: .infinity, minHeight: 180, maxHeight: .infinity)

        let hostingView = NSHostingView(rootView: contentView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.contentView = hostingView
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.hasShadow = true
        window.makeKeyAndOrderFront(nil)

        let screen = NSScreen.main!
        let frame = window.frame
        window.setFrameOrigin(NSPoint(
            x: screen.frame.width - frame.width - 20,
            y: screen.frame.height - frame.height - 80
        ))

        self.window = window

        if !isPinned {
            autoHideTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
                self?.dismiss()
            }
        }
    }

    func dismiss() {
        autoHideTimer?.invalidate()
        autoHideTimer = nil
        window?.orderOut(nil)
        window = nil
    }

    func setPinned(_ pinned: Bool) {
        isPinned = pinned
        if pinned {
            autoHideTimer?.invalidate()
            autoHideTimer = nil
        }
    }
}

struct OverlayView: View {
    @ObservedObject var viewModel: OverlayViewModel

    var body: some View {
        VStack(spacing: 16) {
            headerSection
            countdownSection
            instructionsSection
            pinButton
        }
        .padding()
        .background(overlayBackground)
    }

    private var headerSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "keyboard.fill")
                .font(.largeTitle)
                .foregroundColor(.red)
            VStack(alignment: .leading) {
                Text("Cleaning Mode Active")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("All keyboard input is suppressed")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var countdownSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "timer")
                .foregroundColor(.orange)
            Text(viewModel.countdownText)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(.primary)
        }
    }

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("How to exit:")
                .font(.caption)
                .foregroundColor(.secondary)
            BulletPoint(text: "Click CleanKeys menu bar icon → Exit")
            BulletPoint(text: "Hold Ctrl+Shift+Escape")
            BulletPoint(text: "Wait for auto-timeout")
        }
    }

    private var pinButton: some View {
        Button(action: { viewModel.onPinToggle() }) {
            HStack(spacing: 6) {
                Image(systemName: "pin")
                Text("Pin Overlay")
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(6)
        }
        .buttonStyle(.borderless)
    }

    private var overlayBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white.opacity(0.95))
            .shadow(radius: 20)
    }
}

struct BulletPoint: View {
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "circle.fill")
                .font(.caption2)
                .foregroundColor(.accentColor)
            Text(text)
                .font(.caption)
        }
    }
}

class OverlayViewModel: ObservableObject {
    @Published var countdownText: String
    let onPinToggle: () -> Void

    init(countdownText: String, onPinToggle: @escaping () -> Void) {
        self.countdownText = countdownText
        self.onPinToggle = onPinToggle
    }
}