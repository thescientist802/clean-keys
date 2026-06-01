import SwiftUI
import Foundation

@main
struct CleanKeysApp: App {
    @NSApplicationDelegateAdaptor(AppLifecycle.self) private var appLifecycle

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(viewModel: appLifecycle.menuBarViewModel)
        } label: {
            MenuBarStatusIcon(viewModel: appLifecycle.menuBarViewModel)
        }
        .menuBarExtraStyle(.window)
    }
}

private struct MenuBarStatusIcon: View {
    @ObservedObject var viewModel: MenuBarViewModel

    var body: some View {
        Image(systemName: viewModel.state.appIconName)
    }
}
