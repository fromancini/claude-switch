# shellcheck shell=bash
# lib/desktop.sh — control the Claude Desktop app and swap its session folder.

desktop_running() { pgrep -x "Claude" >/dev/null 2>&1; }

desktop_quit() {            # returns 0 if Claude is not running afterward
  # Claude is an Electron app and can take >5s to terminate (especially just
  # after launch/login), so poll up to ~30s rather than giving up early.
  desktop_running || return 0
  osascript -e 'tell application "Claude" to quit' >/dev/null 2>&1 || true
  local i=0
  while desktop_running && [ "$i" -lt 60 ]; do sleep 0.5; i=$((i + 1)); done
  ! desktop_running
}

desktop_frontmost() {       # 0 if Claude Desktop is the frontmost app (no TCC prompt)
  case "$(lsappinfo info -only name "$(lsappinfo front 2>/dev/null)" 2>/dev/null)" in
    *'"Claude"'*) return 0 ;;
    *) return 1 ;;
  esac
}

desktop_launch() {          # $1: "background" => launch without stealing focus (open -g)
  if [ "${1:-}" = "background" ]; then
    open -g -a "Claude" >/dev/null 2>&1 || true
  else
    open -a "Claude" >/dev/null 2>&1 || true
  fi
}

desktop_swap() {            # $1: profile name -> repoint the session symlink atomically
  ln -sfn "$(desktop_store_dir "$1")" "$CLAUDE_DESKTOP_DIR"
}
