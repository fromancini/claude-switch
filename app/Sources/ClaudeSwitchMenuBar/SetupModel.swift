import SwiftUI

@MainActor
final class SetupModel: ObservableObject {
    enum Step { case current, addSecond, done }

    @Published var step: Step = .current
    @Published var currentEmail = "your current account"
    @Published var firstLabel = "work"
    @Published var secondLabel = "personal"
    @Published var busy = false
    @Published var lastError: String?
    @Published var addStarted = false   // `add` has run -> show login guidance

    var onFinished: (() -> Void)?

    init() { refreshStep() }

    /// Derive the step from how many *complete* profiles exist.
    func refreshStep() {
        let count = (try? CLI.list().profiles.count) ?? 0
        if count >= 2 {
            step = .done
        } else if count == 1 {
            step = .addSecond
        } else {
            step = .current
            currentEmail = CLI.whoami() ?? "your current account"
        }
    }

    func runInit() { runStep { try CLI.initProfile(self.firstLabel) } }

    func runAdd() {
        runStep({ try CLI.add(self.secondLabel) }, onSuccess: { self.addStarted = true })
    }

    func openLoginTerminal() {
        do { try Terminal.runClaudeLogin() } catch { lastError = String(describing: error) }
    }

    func runCapture() { runStep { try CLI.capture(self.secondLabel) } }

    func finish() { onFinished?() }

    private func runStep(_ work: @escaping () throws -> Void,
                         onSuccess: (() -> Void)? = nil) {
        guard !busy else { return }
        busy = true
        lastError = nil
        Task.detached {
            var failure: String?
            do { try work() } catch { failure = String(describing: error) }
            await self.finishStep(error: failure, onSuccess: onSuccess)
        }
    }

    private func finishStep(error: String?, onSuccess: (() -> Void)?) {
        busy = false
        lastError = error
        if error == nil {
            onSuccess?()
            refreshStep()
        }
    }
}
