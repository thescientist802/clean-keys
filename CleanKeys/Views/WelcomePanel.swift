import SwiftUI
import AppKit

/// Shown once on first launch so users know CleanKeys is a menu bar app (no Dock icon).
final class WelcomePanelController {

    static let shared = WelcomePanelController()

    private var panel: NSPanel?

    private init() {}

    func show() {
        panel?.orderOut(nil)

        let contentView = WelcomePanelView {
            self.dismiss()
        }
        .frame(width: 420, height: 260)

        let hostingView = NSHostingView(rootView: contentView)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 260),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.contentView = hostingView
        panel.title = "CleanKeys"
        panel.level = .floating
        panel.isMovable = true
        panel.hasShadow = true
        panel.backgroundColor = NSColor.windowBackgroundColor

        if let screen = NSScreen.main {
            let frame = panel.frame
            panel.setFrameOrigin(NSPoint(
                x: screen.frame.midX - frame.width / 2,
                y: screen.frame.midY - frame.height / 2
            ))
        }

        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.panel = panel
    }

    func dismiss() {
        panel?.orderOut(nil)
        panel = nil
    }
}

private struct WelcomePanelView: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "keyboard")
                    .font(.system(size: 36))
                    .foregroundStyle(.tint)
                Text("CleanKeys is in the menu bar")
                    .font(.title2.bold())
            }

            Text(
                """
                CleanKeys runs from the menu bar only — it does not appear in the Dock.

                Click the keyboard icon near the clock to open controls. If the icon is hidden, click the » overflow in the menu bar.
                """
            )
            .font(.body)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            HStack {
                Spacer()
                Button("Got it") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
    }
}
