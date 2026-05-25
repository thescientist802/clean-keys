// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import SwiftUI
import Foundation

@main
struct CleanKeysApp: App {
    @NSApplicationDelegateAdaptor(AppLifecycle.shared) private var appLifecycle

    var body: some Scene {
        MenuBarExtra("", systemImage: appLifecycle.stateMachine.state.appIconName) {
            MenuBarView(viewModel: appLifecycle.menuBarViewModel)
        }.menuBarExtraStyle(.window)
    }
}