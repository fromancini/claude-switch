# claude-switch

Switch Claude between work and personal accounts across the CLI (Terminal/Warp/VS Code)
and the Claude Desktop app. Identity-only: swaps the Keychain login + account fields in
`~/.claude.json` + the Desktop session folder; everything else stays shared.

See `docs/superpowers/specs/2026-06-04-claude-switch-design.md`.

## Install

One-liner:

    curl -fsSL https://raw.githubusercontent.com/fromancini/claude-switch/main/install.sh | bash

Or from a local checkout:

    git clone https://github.com/fromancini/claude-switch.git && cd claude-switch && ./install.sh

Requires macOS, the Xcode Command Line Tools (`xcode-select --install`), and `jq`
(auto-installed via Homebrew if present). Installs the `claude-switch` CLI on your
PATH and `ClaudeSwitch.app` in Applications, then launches the setup wizard.

## Usage
    claude-switch init <label>     # set up; label the account you're currently logged into
    claude-switch add <label>      # add the second account (guided login)
    claude-switch capture <label>  # store the currently-logged-in account into <label>
    claude-switch list
    claude-switch current
    claude-switch use <label>      # switch
    claude-switch use <label> --dry-run

## Run tests
    ./test
