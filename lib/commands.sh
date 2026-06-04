# shellcheck shell=bash
# lib/commands.sh — orchestration. Depends on paths.sh, json_ops.sh, keychain.sh, desktop.sh.

lock_acquire() { mkdir "$(lock_dir)" 2>/dev/null; }
lock_release() { rmdir "$(lock_dir)" 2>/dev/null || true; }

capture_current_into() {    # $1: profile name <- snapshot live Keychain creds + claude.json identity
  local p="$1" blob creds
  blob="$(keychain_read_blob)" || { echo "ERROR: cannot read Keychain item '$KEYCHAIN_SERVICE'" >&2; return 1; }
  printf '%s' "$blob" | jq -e . >/dev/null 2>&1 || { echo "ERROR: Keychain returned invalid JSON; refusing to capture" >&2; return 1; }
  creds="$(printf '%s' "$blob" | extract_credentials)"
  # Never overwrite a profile's creds with an empty/blank login (jq -e fails on null).
  printf '%s' "$creds" | jq -e . >/dev/null 2>&1 || { echo "ERROR: no active login (claudeAiOauth) in Keychain; refusing to capture into '$p'" >&2; return 1; }
  mkdir -p "$(profile_dir "$p")"
  printf '%s' "$creds" | jq -c . > "$(profile_dir "$p")/claudeAiOauth.json"
  chmod 600 "$(profile_dir "$p")/claudeAiOauth.json"
  extract_identity < "$CLAUDE_JSON" > "$(profile_dir "$p")/identity.json"
}

apply_profile() {           # $1: profile name -> make it the live account
  local p="$1" blob newblob tmp was_running=1 was_frontmost=0
  # 1) Keychain: replace claudeAiOauth, keep mcpOAuth
  blob="$(keychain_read_blob)" || { echo "ERROR: cannot read Keychain" >&2; return 1; }
  printf '%s' "$blob" | jq -e . >/dev/null 2>&1 || { echo "ERROR: Keychain returned invalid JSON; aborting" >&2; return 1; }
  newblob="$(printf '%s' "$blob" | merge_credentials "$(profile_dir "$p")/claudeAiOauth.json")" \
    || { echo "ERROR: failed to build new credential blob" >&2; return 1; }
  printf '%s' "$newblob" | jq -e . >/dev/null 2>&1 || { echo "ERROR: merged credential blob is invalid; aborting" >&2; return 1; }
  keychain_write_blob "$newblob" || { echo "ERROR: Keychain write failed" >&2; return 1; }
  # 2) claude.json: merge identity atomically (temp -> validate -> mv)
  tmp="$(mktemp)"
  if ! merge_identity "$(profile_dir "$p")/identity.json" < "$CLAUDE_JSON" > "$tmp" || ! valid_json "$tmp"; then
    echo "ERROR: produced invalid ~/.claude.json; aborting" >&2; rm -f "$tmp"; return 1
  fi
  mv "$tmp" "$CLAUDE_JSON"
  # 3) Desktop: quit (if running) -> swap folder -> relaunch.
  #    Relaunch backgrounded unless Desktop was the frontmost app, so a switch
  #    triggered from the terminal/menu bar doesn't steal focus.
  desktop_running || was_running=0
  if [ "$was_running" -eq 1 ]; then
    desktop_frontmost && was_frontmost=1
  fi
  if [ "$was_running" -eq 1 ] && ! desktop_quit; then
    echo "WARN: Claude Desktop won't quit; leaving Desktop on previous account" >&2
  else
    desktop_swap "$p"
    if [ "$was_running" -eq 1 ]; then
      if [ "$was_frontmost" -eq 1 ]; then desktop_launch; else desktop_launch background; fi
    fi
  fi
  set_active_profile "$p"
}

cmd_use() {                 # $1: target profile, $2: dry-run flag ("1" = dry-run)
  local target="$1" dry="${2:-0}" active
  [ -n "$target" ] || { echo "usage: claude-switch use <profile>" >&2; return 2; }
  profile_exists "$target" || { echo "No such profile '$target' (try: claude-switch add $target)" >&2; return 1; }
  active="$(active_profile)"
  [ "$active" = "$target" ] && { echo "Already on '$target'"; return 0; }
  if [ "$dry" = "1" ]; then
    echo "DRY-RUN: would switch '${active:-none}' -> '$target':"
    echo "  - capture live login back into '${active:-none}'"
    echo "  - write '$target' claudeAiOauth into Keychain '$KEYCHAIN_SERVICE' (keep mcpOAuth)"
    echo "  - merge '$target' oauthAccount/userID into $CLAUDE_JSON"
    echo "  - quit Claude Desktop, point $CLAUDE_DESKTOP_DIR -> $(desktop_store_dir "$target"), relaunch"
    return 0
  fi
  lock_acquire || { echo "Another switch is in progress" >&2; return 1; }
  trap lock_release EXIT
  [ -n "$active" ] && { capture_current_into "$active" || return 1; }
  apply_profile "$target" || return 1
  echo "Switched to $(cmd_current)."
  echo "Note: shells/sessions already open keep the previous account until restarted."
}

cmd_whoami() {              # $1: json flag -> current ~/.claude.json login email (pre-init)
  local json="${1:-0}" email
  email="$(account_email < "$CLAUDE_JSON" 2>/dev/null || true)"
  if [ "$json" = "1" ]; then
    jq -cn --arg e "$email" '{email: (if $e=="" then null else $e end)}'
    return 0
  fi
  printf '%s\n' "${email:-unknown}"
}

cmd_current() {             # $1: json flag ("1" = JSON output)
  local json="${1:-0}" p email
  p="$(active_profile)"
  if [ "$json" = "1" ]; then
    if [ -z "$p" ]; then jq -cn '{active:null, email:null}'; return 0; fi
    email="$(account_email < "$(profile_dir "$p")/identity.json" 2>/dev/null || true)"
    jq -cn --arg p "$p" --arg e "$email" '{active:$p, email:$e}'
    return 0
  fi
  [ -n "$p" ] || { echo "No active profile (run: claude-switch init <label>)" >&2; return 1; }
  email="$(account_email < "$(profile_dir "$p")/identity.json" 2>/dev/null || true)"
  printf '%s (%s)\n' "$p" "${email:-unknown}"
}

cmd_list() {                # $1: json flag ("1" = JSON output)
  local json="${1:-0}" active p mark email
  active="$(active_profile)"
  if [ "$json" = "1" ]; then
    {
      for p in $(list_profiles); do
        profile_exists "$p" || continue
        email="$(account_email < "$(profile_dir "$p")/identity.json" 2>/dev/null || true)"
        jq -cn --arg n "$p" --arg e "$email" \
          --argjson act "$([ "$p" = "$active" ] && echo true || echo false)" \
          '{name:$n, email:$e, active:$act}'
      done
    } | jq -sc --arg active "$active" '{active: (if $active=="" then null else $active end), profiles: .}'
    return 0
  fi
  for p in $(list_profiles); do
    profile_exists "$p" || continue
    mark=" "; [ "$p" = "$active" ] && mark="*"
    email="$(account_email < "$(profile_dir "$p")/identity.json" 2>/dev/null || true)"
    printf '%s %s (%s)\n' "$mark" "$p" "${email:-unknown}"
  done
}

usage() {
  cat <<'EOF'
claude-switch — switch Claude work/personal accounts
  init <label>      set up; label the account you're logged into now
  add <label>       add the second account (guided login)
  capture <label>   store the currently-logged-in account into <label>
  remove <label>    forget a profile (only deletes ClaudeSwitch's files for it)
  list              show profiles (active marked with *)
  current           show the active profile + email
  use <label>       switch to <label>   (append --dry-run to preview)
EOF
}

backup_now() {              # snapshot claude.json + Keychain blob before destructive setup; echo dir
  local ts bdir; ts="$(date +%Y%m%d-%H%M%S)"; bdir="$(backups_dir)/$ts"
  mkdir -p "$bdir"
  cp "$CLAUDE_JSON" "$bdir/claude.json" 2>/dev/null || true
  keychain_read_blob > "$bdir/keychain-blob.json" 2>/dev/null || true
  chmod 600 "$bdir/keychain-blob.json" 2>/dev/null || true
  printf '%s\n' "$bdir"
}

cmd_init() {                # $1: label for the CURRENT login
  local name="$1" bdir
  [ -n "$name" ] || { echo "usage: claude-switch init <label-for-current-account>" >&2; return 2; }
  mkdir -p "$(profiles_dir)" "$(backups_dir)" "$CLAUDE_SWITCH_HOME/desktop"
  bdir="$(backup_now)"; echo "Backed up current state to $bdir"
  echo "Current login: $(account_email < "$CLAUDE_JSON" || echo unknown)"
  capture_current_into "$name" || return 1
  # Move the real Desktop folder into this profile's slot once, then symlink.
  if [ ! -L "$CLAUDE_DESKTOP_DIR" ] && [ -d "$CLAUDE_DESKTOP_DIR" ]; then
    if desktop_running; then echo "Quitting Claude Desktop to migrate its folder..."; desktop_quit || true; fi
    mv "$CLAUDE_DESKTOP_DIR" "$(desktop_store_dir "$name")"
    ln -sfn "$(desktop_store_dir "$name")" "$CLAUDE_DESKTOP_DIR"
  fi
  set_active_profile "$name"
  echo "Initialized. Active profile: $name"
}

cmd_add() {                 # $1: label for the SECOND account; prepares a clean login env
  local name="$1" active blob newblob tmp
  [ -n "$name" ] || { echo "usage: claude-switch add <label>" >&2; return 2; }
  profile_exists "$name" && { echo "Profile '$name' already exists" >&2; return 1; }
  active="$(active_profile)"
  [ -n "$active" ] || { echo "Run 'claude-switch init <label>' first" >&2; return 1; }
  # preserve the current account, then make room for a fresh login under <name>
  capture_current_into "$active" || return 1
  mkdir -p "$(profile_dir "$name")" "$(desktop_store_dir "$name")"
  # blank the live login so `claude` /login and Desktop start fresh for the new account
  blob="$(keychain_read_blob)" || true
  [ -n "$blob" ] || blob='{}'
  newblob="$(printf '%s' "$blob" | jq '.claudeAiOauth = null')"
  keychain_write_blob "$newblob" || true
  tmp="$(mktemp)"
  if jq '.oauthAccount = null | .userID = null' < "$CLAUDE_JSON" > "$tmp" && valid_json "$tmp"; then
    mv "$tmp" "$CLAUDE_JSON"
  else
    rm -f "$tmp"
  fi
  if desktop_running; then desktop_quit || true; fi
  ln -sfn "$(desktop_store_dir "$name")" "$CLAUDE_DESKTOP_DIR"
  set_active_profile "$name"
  desktop_launch
  cat <<EOF
Ready to add '$name'. Now:
  1. Run:  claude     then type  /login   and sign in with the '$name' account.
  2. In the Claude Desktop window that just opened, sign in with the '$name' account.
  3. When both are logged in, run:  claude-switch capture $name
EOF
}

cmd_remove() {              # $1: profile to forget; deletes ONLY ClaudeSwitch's files for it
  local name="$1"
  [ -n "$name" ] || { echo "usage: claude-switch remove <label>" >&2; return 2; }
  case "$name" in
    *[!A-Za-z0-9_-]*) echo "ERROR: invalid profile name '$name'" >&2; return 2 ;;
  esac
  [ -d "$(profile_dir "$name")" ] || { echo "No such profile '$name'" >&2; return 1; }
  if [ "$name" = "$(active_profile)" ]; then
    echo "Refusing to remove the active profile '$name' — switch to another profile first." >&2
    return 1
  fi
  rm -rf "$(profile_dir "$name")"
  rm -rf "$(desktop_store_dir "$name")"
  echo "Removed '$name' from ClaudeSwitch. (Your Claude login, ~/.claude, and Keychain were not touched.)"
}

cmd_capture() {             # $1: store the CURRENT live login into profile <name>
  local name="$1"
  [ -n "$name" ] || { echo "usage: claude-switch capture <label>" >&2; return 2; }
  capture_current_into "$name" || return 1
  set_active_profile "$name"
  echo "Captured current login into '$name' ($(account_email < "$(profile_dir "$name")/identity.json" || echo unknown))."
}
