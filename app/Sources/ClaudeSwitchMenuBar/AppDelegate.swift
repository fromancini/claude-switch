import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var setup: SetupModel?
    private var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Task { @MainActor in
            let count = (try? CLI.list().profiles.count) ?? 0
            guard count < 2 else { return }   // already configured -> menu-bar only
            self.showSetup()
        }
    }

    @MainActor private func showSetup() {
        let model = SetupModel()
        model.onFinished = { [weak self] in self?.closeSetup() }
        setup = model
        NSApp.setActivationPolicy(.regular)
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 460),
            styleMask: [.titled, .closable],
            backing: .buffered, defer: false)
        win.title = "Set up Claude Switch"
        win.contentView = NSHostingView(rootView: SetupView(model: model))
        win.isReleasedWhenClosed = false
        win.center()
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = win
    }

    @MainActor private func closeSetup() {
        window?.close()
        window = nil
        setup = nil
        NSApp.setActivationPolicy(.accessory)
        NotificationCenter.default.post(name: .claudeSwitchRefresh, object: nil)
    }
}
