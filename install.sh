#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${CLAUDE_SWITCH_REPO:-https://github.com/fromancini/claude-switch.git}"
DEST="${CLAUDE_SWITCH_DIR:-$HOME/.local/share/claude-switch}"

# ----- pretty output (degrades gracefully when not a TTY) -----
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  B=$'\033[1m'; D=$'\033[2m'; R=$'\033[0m'
  CORAL=$'\033[38;5;209m'; CYAN=$'\033[38;5;43m'; GREEN=$'\033[38;5;78m'; REDC=$'\033[38;5;203m'
else
  B=; D=; R=; CORAL=; CYAN=; GREEN=; REDC=
fi

banner() {
  printf '%s' "$CORAL$B"
  cat <<'ART'
              .  *  .
          .  \ | /  .            ___ _      _   _   _ ___  ___
       --  --(*)--  --          / __| |    /_\ | | | |   \| __|
          '  / | \  '          | (__| |__ / _ \| |_| | |) | _|
              '  *              \___|____/_/ \_ \___/|___/|___|
                                      S W I T C H
ART
  printf '%s' "$R"
  printf '   %sone menu bar — all your Claude accounts%s\n\n' "$D" "$R"
}

step() { printf '\n%s%s▸%s %s%s\n' "$CYAN" "$B" "$R" "$B" "$1$R"; }
ok()   { printf '   %s✓%s %s\n' "$GREEN" "$R" "$1"; }
info() { printf '   %s%s%s\n' "$D" "$1" "$R"; }
die()  { printf '\n   %s✗ %s%s\n\n' "$REDC$B" "$1" "$R" >&2; exit 1; }

success_box() {
  printf '\n%s%s' "$GREEN" "$B"
  cat <<'BOX'
   ╭───────────────────────────────────────────────╮
   │   ✓  Claude Switch is installed and running   │
   ╰───────────────────────────────────────────────╯
BOX
  printf '%s' "$R"
  printf '   %sLook in your menu bar — the setup window guides first-time use.%s\n\n' "$D" "$R"
}

banner

step "Checking requirements"
[ "$(uname -s)" = "Darwin" ] || die "Claude Switch is macOS-only."
ok "macOS"
command -v git >/dev/null || die "git is required."
ok "git"
command -v swift >/dev/null || die "Swift is required — run: xcode-select --install"
ok "Swift toolchain"
if command -v jq >/dev/null; then
  ok "jq"
elif command -v brew >/dev/null; then
  info "installing jq via Homebrew…"; brew install jq >/dev/null && ok "jq (installed)"
else
  die "jq is required and Homebrew was not found — https://jqlang.github.io/jq/"
fi

step "Fetching Claude Switch"
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
if [ -n "$SELF_DIR" ] && [ -f "$SELF_DIR/bin/claude-switch" ]; then
  REPO="$SELF_DIR"; ok "using local checkout: $REPO"
elif [ -d "$DEST/.git" ]; then
  REPO="$DEST"; git -C "$REPO" pull --ff-only >/dev/null; ok "updated $REPO"
else
  case "$REPO_URL" in
    *REPLACE_ME*) die "Set CLAUDE_SWITCH_REPO to your repo, or run install.sh from a local checkout." ;;
  esac
  REPO="$DEST"; mkdir -p "$(dirname "$REPO")"; git clone --quiet "$REPO_URL" "$REPO"; ok "cloned into $REPO"
fi

step "Installing the claude-switch CLI"
BIN_DIR="/usr/local/bin"
if ! ln -sf "$REPO/bin/claude-switch" "$BIN_DIR/claude-switch" 2>/dev/null; then
  BIN_DIR="$HOME/.local/bin"; mkdir -p "$BIN_DIR"
  ln -sf "$REPO/bin/claude-switch" "$BIN_DIR/claude-switch"
  case ":$PATH:" in *":$BIN_DIR:"*) : ;; *) info "add $BIN_DIR to your PATH" ;; esac
fi
ok "linked → $BIN_DIR/claude-switch"

step "Building the menu-bar app"
info "compiling (first build can take a minute)…"
"$REPO/app/build-app.sh" >/dev/null
ok "built ClaudeSwitch.app"
APP_DEST="/Applications"; [ -w "$APP_DEST" ] || APP_DEST="$HOME/Applications"
mkdir -p "$APP_DEST"; rm -rf "$APP_DEST/ClaudeSwitch.app"
cp -R "$REPO/app/ClaudeSwitch.app" "$APP_DEST/"
ok "installed → $APP_DEST/ClaudeSwitch.app"

open "$APP_DEST/ClaudeSwitch.app" || true
success_box
