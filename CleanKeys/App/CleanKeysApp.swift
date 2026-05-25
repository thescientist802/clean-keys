import SwiftUI
import Foundation

@main
struct CleanKeysApp: App {
    @NSApplicationDelegateAdaptor(AppLifecycle.shared) private var appLifecycle
    @StateObject private var viewModel: MenuBarViewModel

    init() {
        let vm = AppLifecycle.shared.menuBarViewModel
        _viewModel = StateObject(wrappedValue: vm)
    }

    var body: some Scene {
        MenuBarExtra("", systemImage: viewModel.state.appIconName) {
            MenuBarView(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}