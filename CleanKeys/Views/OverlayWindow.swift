import SwiftUI
import AppKit
import Combine

class OverlayWindowController: ObservableObject {

    private var window: NSPanel?
    private var autoHideTimer: Timer?
    @Published var isPinned: Bool = false

    func show(failSafeManager: FailSafeManager, pinned: Bool, onPinToggle: @escaping () -> Void) {
        dismiss()

        isPinned = pinned
        let overlayViewModel = OverlayViewModel(failSafeManager: failSafeManager, onPinToggle: onPinToggle)
        let contentView = OverlayView(viewModel: overlayViewModel)
            .frame(width: 380)

        let hostingView = NSHostingView(rootView: contentView)
        hostingView.appearance = NSAppearance(named: .aqua)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 280),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.contentView = hostingView
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isMovableByWindowBackground = true
        panel.hasShadow = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hidesOnDeactivate = false

        guard let screen = NSScreen.main else { return }
        let panelFrame = panel.frame
        panel.setFrameOrigin(NSPoint(
            x: screen.frame.midX - panelFrame.width / 2,
            y: screen.frame.midY - panelFrame.height / 2
        ))

        panel.orderFrontRegardless()
        self.window = panel

        if !isPinned {
            autoHideTimer = Timer.scheduledTimer(withTimeInterval: 12.0, repeats: false) { [weak self] _ in
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

    private let textPrimary = Color(red: 0.11, green: 0.11, blue: 0.13)
    private let textSecondary = Color(red: 0.35, green: 0.36, blue: 0.4)
    private let cardBackground = Color.white
    private let bannerRed = Color(red: 0.85, green: 0.15, blue: 0.18)

    var body: some View {
        VStack(spacing: 0) {
            banner
            VStack(alignment: .leading, spacing: 16) {
                countdownSection
                instructionsSection
                pinButton
            }
            .padding(20)
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(cardBackground)
                .shadow(color: .black.opacity(0.28), radius: 24, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
        )
        .preferredColorScheme(.light)
    }

    private var banner: some View {
        HStack(spacing: 12) {
            Image(systemName: "keyboard.fill")
                .font(.title)
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text("Cleaning Mode Active")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("Keyboard · volume · brightness blocked")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(bannerRed)
                .padding(.bottom, -14)
        )
    }

    private var countdownSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "timer")
                .font(.title2)
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("Auto-exit in")
                    .font(.caption)
                    .foregroundStyle(textSecondary)
                Text(viewModel.countdownText)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(textPrimary)
            }
            Spacer()
        }
    }

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How to exit")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(textPrimary)
            BulletPoint(text: "Menu bar keyboard icon → Exit Cleaning Mode", textColor: textSecondary)
            BulletPoint(text: "Hold Control + Shift + Escape", textColor: textSecondary)
            BulletPoint(text: "Wait for the countdown above", textColor: textSecondary)
        }
    }

    private var pinButton: some View {
        Button(action: { viewModel.onPinToggle() }) {
            Label("Keep this window visible", systemImage: "pin.fill")
                .font(.subheadline.weight(.medium))
        }
        .buttonStyle(.borderedProminent)
        .tint(bannerRed)
        .frame(maxWidth: .infinity)
    }
}

struct BulletPoint: View {
    let text: String
    var textColor: Color = Color(red: 0.35, green: 0.36, blue: 0.4)

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
                .padding(.top, 2)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(textColor)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

class OverlayViewModel: ObservableObject {
    @Published var countdownText: String
    let onPinToggle: () -> Void

    private var cancellables = Set<AnyCancellable>()

    init(failSafeManager: FailSafeManager, onPinToggle: @escaping () -> Void) {
        self.countdownText = failSafeManager.countdownText
        self.onPinToggle = onPinToggle

        failSafeManager.$countdownText
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                self?.countdownText = text
            }
            .store(in: &cancellables)
    }
}
