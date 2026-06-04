import Foundation

/// "Launch at Login" via a user LaunchAgent. SMAppService.register() fails with
/// "Operation not permitted" for unsigned apps outside /Applications, so for a
/// locally-built personal tool a LaunchAgent is the reliable mechanism: launchd
/// loads ~/Library/LaunchAgents/*.plist automatically at GUI login.
enum LoginItem {
    static let label = "com.claudeswitch.app"

    static var plistURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(label).plist")
    }

    static var isEnabled: Bool {
        FileManager.default.fileExists(atPath: plistURL.path)
    }

    /// The .app bundle path of the currently-running app.
    static var bundlePath: String { Bundle.main.bundleURL.path }

    static func plistData(appPath: String) throws -> Data {
        // `open <app>` launches (or just activates) the app — never duplicates it.
        let dict: [String: Any] = [
            "Label": label,
            "ProgramArguments": ["/usr/bin/open", appPath],
            "RunAtLoad": true,
            "LimitLoadToSessionType": "Aqua",
        ]
        return try PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0)
    }

    static func enable() throws {
        try FileManager.default.createDirectory(
            at: plistURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try plistData(appPath: bundlePath).write(to: plistURL)
    }

    static func disable() throws {
        // Best-effort unload if it was already loaded this session, then remove.
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        p.arguments = ["bootout", "gui/\(getuid())/\(label)"]
        try? p.run(); p.waitUntilExit()
        if FileManager.default.fileExists(atPath: plistURL.path) {
            try FileManager.default.removeItem(at: plistURL)
        }
    }
}
