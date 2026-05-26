import SwiftUI
import Foundation

@main
struct CleanKeysApp: App {
    @NSApplicationDelegateAdaptor(AppLifecycle.self) private var appLifecycle
    @StateObject private var viewModel: MenuBarViewModel

    init() {
        _viewModel = StateObject(wrappedValue: AppLifecycle.shared.menuBarViewModel)
    }

    var body: some Scene {
        MenuBarExtra("", systemImage: viewModel.state.appIconName) {
            MenuBarView(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}
