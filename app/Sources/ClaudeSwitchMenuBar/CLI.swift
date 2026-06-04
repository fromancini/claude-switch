import Foundation

enum CLIError: Error, CustomStringConvertible {
    case notFound
    case failed(String)
    var description: String {
        switch self {
        case .notFound: return "claude-switch not found on PATH"
        case .failed(let m): return m.isEmpty ? "claude-switch failed" : m
        }
    }
}

enum CLI {
    /// GUI apps don't inherit the shell PATH, so the CLI (and the jq/security it
    /// calls) won't resolve unless we both locate the binary and augment PATH.
    static let searchPaths = [
        "/usr/local/bin/claude-switch",
        "/opt/homebrew/bin/claude-switch",
        NSHomeDirectory() + "/bin/claude-switch",
    ]

    static func binaryPath() -> String? {
        searchPaths.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    @discardableResult
    static func run(_ args: [String]) throws -> String {
        guard let path = binaryPath() else { throw CLIError.notFound }
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: path)
        proc.arguments = args
        var env = ProcessInfo.processInfo.environment
        let extra = "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        env["PATH"] = extra + ":" + (env["PATH"] ?? "")
        proc.environment = env
        let outPipe = Pipe(), errPipe = Pipe()
        proc.standardOutput = outPipe
        proc.standardError = errPipe
        try proc.run()
        proc.waitUntilExit()
        let out = String(data: outPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        if proc.terminationStatus != 0 {
            let err = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw CLIError.failed(err.isEmpty ? out : err)
        }
        return out
    }

    static func list() throws -> ListResult {
        let json = try run(["list", "--json"])
        return try JSONDecoder().decode(ListResult.self, from: Data(json.utf8))
    }

    static func use(_ name: String) throws {
        try run(["use", name])
    }

    static func whoami() -> String? {
        guard let json = try? run(["whoami", "--json"]),
              let r = try? JSONDecoder().decode(WhoAmI.self, from: Data(json.utf8))
        else { return nil }
        return r.email
    }

    static func initProfile(_ label: String) throws { try run(["init", label]) }
    static func add(_ label: String) throws { try run(["add", label]) }
    static func capture(_ label: String) throws { try run(["capture", label]) }
    static func remove(_ label: String) throws { try run(["remove", label]) }
}
