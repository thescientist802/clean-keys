import SwiftUI
import AppKit

/// Walks the user through granting Input Monitoring for this build of CleanKeys.
final class PermissionPanelController {

    static let shared = PermissionPanelController()

    private var panel: NSPanel?
    private var onComplete: ((Bool) -> Void)?

    private init() {}

    func show(permissionManager: PermissionManager, onComplete: ((Bool) -> Void)? = nil) {
        self.onComplete = onComplete
        panel?.orderOut(nil)

        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "CleanKeys"

        let contentView = PermissionPanelView(
            permissionManager: permissionManager,
            appName: appName,
            onRequest: { permissionManager.requestInputMonitoringAccess() },
            onOpenSettings: { permissionManager.openInputMonitoringSettings() },
            onDone: { [weak self] granted in
                self?.finish(granted: granted)
            }
        )
        .frame(width: 460, height: 380)

        let hostingView = NSHostingView(rootView: contentView)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 380),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.contentView = hostingView
        panel.title = "Input Monitoring Required"
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

    private func finish(granted: Bool) {
        dismiss()
        onComplete?(granted)
        onComplete = nil
    }
}

private struct PermissionPanelView: View {
    @ObservedObject var permissionManager: PermissionManager
    let appName: String
    let onRequest: () -> Void
    let onOpenSettings: () -> Void
    let onDone: (Bool) -> Void

    var body: some View {
        let granted = permissionManager.isInputMonitoringGranted

        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: granted ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                    .font(.largeTitle)
                    .foregroundStyle(granted ? .green : .orange)
                Text(granted ? "Input Monitoring is enabled" : "CleanKeys needs Input Monitoring")
                    .font(.title3.bold())
            }

            Text(
                granted
                ? "\(appName) can block keyboard, volume, and brightness keys during cleaning mode."
                : "macOS requires you to allow \(appName) under Privacy & Security → Input Monitoring before cleaning mode can work."
            )
            .font(.body)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)

            if !granted {
                stepsSection
                actionButtons
            }

            Spacer(minLength: 0)

            HStack {
                Spacer()
                Button(granted ? "Done" : "Close") {
                    onDone(granted)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            step(1, "Click **Request Permission** below (macOS may show a prompt).")
            step(2, "Click **Open System Settings**, find **\(appName)**, and turn it **on**.")
            step(3, "Return here and click **Check Again**.")
            Text("Running from Xcode? You may see several \(appName) entries — enable the one you just launched (newest build).")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func step(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number).")
                .font(.subheadline.bold())
                .frame(width: 18, alignment: .trailing)
            Text(.init(text))
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var actionButtons: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button("Request Permission") {
                onRequest()
            }
            .buttonStyle(.bordered)

            Button("Open System Settings") {
                onOpenSettings()
            }
            .buttonStyle(.bordered)

            Button("Check Again") {
                permissionManager.refreshInputMonitoringStatus()
            }
            .buttonStyle(.borderless)
        }
    }
}
