import SwiftUI

struct SetupView: View {
    @ObservedObject var model: SetupModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            VStack(alignment: .leading, spacing: 20) {
                switch model.step {
                case .current:   currentStep
                case .addSecond: addStep
                case .done:      doneStep
                }
                if let e = model.lastError {
                    Label(e, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red).font(.callout).textSelection(.enabled)
                }
                Spacer(minLength: 0)
            }
            .padding(28)
        }
        .frame(width: 520, height: 460)
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 16) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable().frame(width: 56, height: 56)
            VStack(alignment: .leading, spacing: 3) {
                Text("Claude Switch").font(.title).bold()
                Text(headerSubtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            if model.step != .done { stepBadge }
        }
        .padding(.horizontal, 24).padding(.vertical, 20)
    }

    private var headerSubtitle: String {
        switch model.step {
        case .current:   return "Let’s set up your first account."
        case .addSecond: return "Now add your second account."
        case .done:      return "Setup complete."
        }
    }

    private var stepBadge: some View {
        Text(model.step == .current ? "Step 1 of 2" : "Step 2 of 2")
            .font(.caption).fontWeight(.medium).foregroundStyle(.secondary)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(.quaternary, in: Capsule())
    }

    // MARK: Step 1 — current account

    private var currentStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            infoRow(icon: "person.crop.circle", title: "Signed in as", value: model.currentEmail)
            VStack(alignment: .leading, spacing: 6) {
                Text("Name this profile").font(.headline)
                TextField("work", text: $model.firstLabel)
                    .textFieldStyle(.roundedBorder).frame(maxWidth: 240)
            }
            Button("Continue") { model.runInit() }
                .buttonStyle(.borderedProminent).controlSize(.large)
                .disabled(model.busy || model.firstLabel.isEmpty)
        }
    }

    // MARK: Step 2 — add second account

    private var addStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Name this profile").font(.headline)
                TextField("personal", text: $model.secondLabel)
                    .textFieldStyle(.roundedBorder).frame(maxWidth: 240)
                    .disabled(model.addStarted)
            }
            if !model.addStarted {
                Button("Start") { model.runAdd() }
                    .buttonStyle(.borderedProminent).controlSize(.large)
                    .disabled(model.busy || model.secondLabel.isEmpty)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sign in with your \(model.secondLabel) account").font(.headline)
                    numberedRow(1, "Click Open Terminal, then type  /login  and sign in.")
                    numberedRow(2, "Sign in to the Claude Desktop window that opened.")
                    numberedRow(3, "Click Done to capture it.")
                }
                HStack(spacing: 12) {
                    Button { model.openLoginTerminal() } label: {
                        Label("Open Terminal", systemImage: "terminal")
                    }.controlSize(.large)
                    Button("Done — capture") { model.runCapture() }
                        .buttonStyle(.borderedProminent).controlSize(.large)
                        .keyboardShortcut(.defaultAction)
                        .disabled(model.busy)
                }
            }
        }
    }

    // MARK: Done

    private var doneStep: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 52)).foregroundStyle(.green)
            Text("You’re all set").font(.title2).bold()
            Text("Claude Switch lives in your menu bar — switch accounts anytime from there.")
                .multilineTextAlignment(.center).foregroundStyle(.secondary)
            Button("Finish") { model.finish() }
                .buttonStyle(.borderedProminent).controlSize(.large)
                .keyboardShortcut(.defaultAction)
        }
        .frame(maxWidth: .infinity).padding(.top, 16)
    }

    // MARK: Reusable bits

    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.title2).foregroundStyle(.secondary).frame(width: 26)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.body).fontWeight(.medium)
            }
            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }

    private func numberedRow(_ n: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(n)").font(.caption).fontWeight(.bold).foregroundStyle(.white)
                .frame(width: 18, height: 18).background(Color.accentColor, in: Circle())
            Text(text).font(.callout).foregroundStyle(.secondary)
            Spacer()
        }
    }
}
