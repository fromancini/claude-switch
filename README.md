<div align="center">

<img src="app/AppIcon.png" alt="Claude Switch" width="128" />

# Claude Switch

**One menu bar — all your Claude accounts.**

Switch between Claude accounts (e.g. work / personal) across Claude Code
(Terminal, Warp, VS Code) and the Claude Desktop app — in one click.

</div>

## Install

One-liner:

```bash
curl -fsSL https://raw.githubusercontent.com/fromancini/claude-switch/main/install.sh | bash
```

Or from a local checkout:

```bash
git clone https://github.com/fromancini/claude-switch.git && cd claude-switch && ./install.sh
```

Requires macOS, the Xcode Command Line Tools (`xcode-select --install`), and `jq`
(auto-installed via Homebrew if present). Installs the `claude-switch` CLI on your
PATH and `ClaudeSwitch.app` in Applications, then launches the first-run setup wizard.

## Usage

The menu-bar app handles everyday switching, but everything is also a CLI:

```bash
claude-switch init <label>     # set up; label the account you're currently logged into
claude-switch add <label>      # add another account (guided login)
claude-switch capture <label>  # store the currently-logged-in account into <label>
claude-switch list             # show profiles (active marked with *)
claude-switch current          # show the active profile + email
claude-switch use <label>      # switch  (append --dry-run to preview)
claude-switch remove <label>   # forget a profile (deletes only Claude Switch's files for it)
```

## How it works

Switching is **identity-only**: it swaps the Keychain login (`claudeAiOauth`) and the
account fields in `~/.claude.json`, plus the Claude Desktop session folder. Everything
else — your skills, plugins, settings, MCP servers, and history — stays shared across
accounts. Claude Desktop is quit and relaunched (backgrounded unless it was frontmost);
the CLI surfaces all pick up the new account on their next session.

## Run tests

```bash
./test        # shellcheck + bats (CLI)
swift test --package-path app   # Swift model tests
```

## License

MIT — see [LICENSE](LICENSE).
