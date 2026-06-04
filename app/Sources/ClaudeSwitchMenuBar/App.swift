import SwiftUI

@main
struct ClaudeSwitchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuContent(model: model)
        } label: {
            switch model.barState {
            case .busy:
                Image(systemName: "arrow.triangle.2.circlepath")
            case .error:
                Image(systemName: "exclamationmark.triangle.fill")
            case .idle:
                Image(nsImage: BrandIcon.sunburst())
            }
            Text(model.labelText)
        }
        .menuBarExtraStyle(.menu)
    }
}

struct MenuContent: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Group {
            if let email = model.activeEmail {
                Text("Active: \(email)")
            } else {
                Text("No active profile — open the app to set up")
            }
        }
        .onAppear { model.refresh() }
        Divider()

        ForEach(model.result.profiles) { p in
            Button {
                model.switchTo(p.name)
            } label: {
                Text("\(p.active ? "✓ " : "    ")\(p.name) — \(p.email)")
            }
            .disabled(model.busy || p.active)
        }

        if model.busy { Text("Switching…") }
        if let e = model.lastError { Text("⚠︎ \(e)") }

        let removable = model.result.profiles.filter { !$0.active }
        if !removable.isEmpty {
            Menu("Remove account") {
                ForEach(removable) { p in
                    Button("Remove \(p.name) — \(p.email)") { model.remove(p.name) }
                }
            }
        }

        Divider()
        Button("Refresh") { model.refresh() }
        Button(model.loginEnabled ? "✓ Launch at Login" : "Launch at Login") {
            model.toggleLogin()
        }
        Divider()
        Button("Quit") { NSApplication.shared.terminate(nil) }
    }
}
