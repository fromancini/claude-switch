import AppKit

enum Terminal {
    /// Write a .command that runs `claude`, then open it so Terminal.app executes
    /// it (no Automation/TCC permission needed). The user runs /login there.
    static func runClaudeLogin() throws {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude-switch")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let cmd = dir.appendingPathComponent("login.command")
        let script = """
        #!/bin/bash
        echo "Type  /login  and sign in with the account you're adding."
        echo "When done, you can close this window and return to Claude Switch."
        echo
        claude
        """
        try script.write(to: cmd, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: cmd.path)
        NSWorkspace.shared.open(cmd)
    }
}
