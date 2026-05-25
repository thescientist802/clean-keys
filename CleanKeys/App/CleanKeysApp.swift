import SwiftUI
import Foundation

@main
struct CleanKeysApp: App {
    @NSApplicationDelegateAdaptor(AppLifecycle()) private var appLifecycle

    var body: some Scene {
        MenuBarExtra("", systemImage: appLifecycle.menuBarViewModel.state.appIconName) {
            MenuBarView(viewModel: appLifecycle.menuBarViewModel)
        }
        .menuBarExtraStyle(.window)
    }
}
