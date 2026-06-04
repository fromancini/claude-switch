import SwiftUI

extension Notification.Name {
    static let claudeSwitchRefresh = Notification.Name("claudeSwitchRefresh")
}

@MainActor
final class AppModel: ObservableObject {
    @Published var result = ListResult(active: nil, profiles: [])
    @Published var busy = false
    @Published var lastError: String?

    init() {
        refresh()
        NotificationCenter.default.addObserver(
            forName: .claudeSwitchRefresh, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    var menuTitle: String { result.active ?? "Claude" }

    /// Menu-bar label reflects state, because clicking a profile closes the menu
    /// and the switch can take up to ~30s (Desktop quit/relaunch).
    enum BarState { case idle, busy, error }
    var barState: BarState { busy ? .busy : (lastError != nil ? .error : .idle) }

    var labelText: String { busy ? "Switching…" : menuTitle }

    var activeEmail: String? {
        guard let a = result.active else { return nil }
        return result.profiles.first { $0.name == a }?.email
    }

    func refresh() {
        do { result = try CLI.list(); lastError = nil }
        catch { lastError = String(describing: error) }
    }

    func switchTo(_ name: String) {
        guard !busy else { return }
        busy = true
        Task.detached {
            var failure: String?
            do { try CLI.use(name) } catch { failure = String(describing: error) }
            await self.finishSwitch(error: failure)
        }
    }

    private func finishSwitch(error: String?) {
        busy = false
        lastError = error
        refresh()
    }

    @Published var loginEnabled: Bool = LoginItem.isEnabled

    func toggleLogin() {
        do {
            if loginEnabled { try LoginItem.disable() } else { try LoginItem.enable() }
            loginEnabled = LoginItem.isEnabled
            lastError = nil
        } catch { lastError = String(describing: error) }
    }

    func remove(_ name: String) {
        let alert = NSAlert()
        alert.messageText = "Remove “\(name)” from Claude Switch?"
        alert.informativeText = "This only forgets it in Claude Switch (deletes its stored profile and Desktop session under ~/.claude-switch). Your Claude login, ~/.claude, and Keychain are not touched."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Remove")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        do { try CLI.remove(name); refresh() }
        catch { lastError = String(describing: error) }
    }
}
