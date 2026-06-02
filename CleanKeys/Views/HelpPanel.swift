import SwiftUI
import AppKit

final class HelpPanelController {

    static let shared = HelpPanelController()

    private var panel: NSPanel?

    private init() {}

    func show() {
        panel?.orderOut(nil)

        let contentView = HelpPanelView {
            self.dismiss()
        }
        .frame(width: 440, height: 340)

        let hostingView = NSHostingView(rootView: contentView)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 340),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.contentView = hostingView
        panel.title = "How to Use CleanKeys"
        panel.level = .floating
        panel.isMovable = true
        panel.hasShadow = true

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

private struct HelpPanelView: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("CleanKeys suppresses keyboard, volume, and brightness while cleaning mode is on.")
                .font(.body)
                .foregroundStyle(.secondary)

            Group {
                helpSection(
                    title: "Enter cleaning mode",
                    items: [
                        "Open the keyboard icon in the menu bar.",
                        "Choose Activate Cleaning Mode and confirm.",
                        "A red overlay appears when input is blocked."
                    ]
                )

                helpSection(
                    title: "Exit cleaning mode",
                    items: [
                        "Menu bar → Exit Cleaning Mode.",
                        "Hardware fail-safe: hold Control + Shift + Escape.",
                        "Wait for the auto-timeout countdown to finish."
                    ]
                )
            }

            Spacer(minLength: 0)

            HStack {
                Spacer()
                Button("Close") { onDismiss() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
    }

    private func helpSection(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                    Text(item)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
