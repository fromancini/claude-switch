# shellcheck shell=bash
# lib/paths.sh — configurable paths (overridable for tests) + profile-store helpers.
: "${CLAUDE_SWITCH_HOME:=$HOME/.claude-switch}"
: "${CLAUDE_JSON:=$HOME/.claude.json}"
: "${CLAUDE_DESKTOP_DIR:=$HOME/Library/Application Support/Claude}"
: "${KEYCHAIN_SERVICE:=Claude Code-credentials}"

profiles_dir()      { printf '%s\n' "$CLAUDE_SWITCH_HOME/profiles"; }
profile_dir()       { printf '%s\n' "$CLAUDE_SWITCH_HOME/profiles/$1"; }
desktop_store_dir() { printf '%s\n' "$CLAUDE_SWITCH_HOME/desktop/$1"; }
active_file()       { printf '%s\n' "$CLAUDE_SWITCH_HOME/active"; }
backups_dir()       { printf '%s\n' "$CLAUDE_SWITCH_HOME/backups"; }
lock_dir()          { printf '%s\n' "$CLAUDE_SWITCH_HOME/.lock"; }

active_profile()     { cat "$(active_file)" 2>/dev/null || true; }
set_active_profile() { printf '%s\n' "$1" > "$(active_file)"; }

profile_exists() {
  [ -f "$(profile_dir "$1")/claudeAiOauth.json" ] && [ -f "$(profile_dir "$1")/identity.json" ]
}

list_profiles() { ls -1 "$(profiles_dir)" 2>/dev/null || true; }
