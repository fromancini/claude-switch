setup() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  FIX="$ROOT/tests/fixtures"
  export PATH="$ROOT/tests/helpers/stubs:$PATH"
  export CLAUDE_SWITCH_HOME="$BATS_TEST_TMPDIR/cs"
  export CLAUDE_JSON="$BATS_TEST_TMPDIR/claude.json"
  export CLAUDE_DESKTOP_DIR="$BATS_TEST_TMPDIR/Claude-link"
  export KC_STORE="$BATS_TEST_TMPDIR/keychain.json"
  export KC_ACCT="you@work.example"
  # live state = work account
  cp "$FIX/claude.json" "$CLAUDE_JSON"
  cp "$FIX/keychain-blob.json" "$KC_STORE"
  # profiles: work (active, creds will be captured) + personal (target)
  mkdir -p "$CLAUDE_SWITCH_HOME/profiles/work" "$CLAUDE_SWITCH_HOME/profiles/personal"
  mkdir -p "$CLAUDE_SWITCH_HOME/desktop/work" "$CLAUDE_SWITCH_HOME/desktop/personal"
  echo '{"accessToken":"AT-work"}' > "$CLAUDE_SWITCH_HOME/profiles/work/claudeAiOauth.json"
  cp "$FIX/identity-personal.json" "$CLAUDE_SWITCH_HOME/profiles/work/identity.json"
  cp "$FIX/claudeAiOauth-personal.json" "$CLAUDE_SWITCH_HOME/profiles/personal/claudeAiOauth.json"
  cp "$FIX/identity-personal.json" "$CLAUDE_SWITCH_HOME/profiles/personal/identity.json"
  echo work > "$CLAUDE_SWITCH_HOME/active"
}

@test "use personal swaps creds+identity+desktop and captures work first" {
  run "$ROOT/bin/claude-switch" use personal
  [ "$status" -eq 0 ]
  # Keychain now has personal creds, mcpOAuth preserved
  [ "$(jq -r '.claudeAiOauth.accessToken' "$KC_STORE")" = "AT-home" ]
  [ "$(jq -r '.mcpOAuth["plugin:gitlab:gitlab|abc"].accessToken' "$KC_STORE")" = "GL-keep-me" ]
  # claude.json identity swapped, non-account keys preserved
  [ "$(jq -r '.oauthAccount.emailAddress' "$CLAUDE_JSON")" = "you@personal.example" ]
  [ "$(jq -r '.numStartups' "$CLAUDE_JSON")" = "42" ]
  # active updated
  [ "$(cat "$CLAUDE_SWITCH_HOME/active")" = "personal" ]
  # work creds were captured back from the live blob before the swap
  [ "$(jq -r '.accessToken' "$CLAUDE_SWITCH_HOME/profiles/work/claudeAiOauth.json")" = "AT-work" ]
  # desktop symlink repointed
  [ "$(readlink "$CLAUDE_DESKTOP_DIR")" = "$CLAUDE_SWITCH_HOME/desktop/personal" ]
}

@test "use refuses unknown profile" {
  run "$ROOT/bin/claude-switch" use nope
  [ "$status" -ne 0 ]
  [[ "$output" == *"No such profile"* ]]
}

@test "use --dry-run changes nothing" {
  run "$ROOT/bin/claude-switch" use personal --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"DRY-RUN"* ]]
  [ "$(jq -r '.claudeAiOauth.accessToken' "$KC_STORE")" = "AT-work" ]
  [ "$(cat "$CLAUDE_SWITCH_HOME/active")" = "work" ]
}

@test "current prints active profile and email" {
  cp "$FIX/identity-personal.json" "$CLAUDE_SWITCH_HOME/profiles/personal/identity.json"
  echo personal > "$CLAUDE_SWITCH_HOME/active"
  run "$ROOT/bin/claude-switch" current
  [ "$status" -eq 0 ]
  [[ "$output" == *"personal"* ]]
  [[ "$output" == *"you@personal.example"* ]]
}

@test "list marks the active profile" {
  run "$ROOT/bin/claude-switch" list
  [ "$status" -eq 0 ]
  [[ "$output" == *"* work"* ]]
  [[ "$output" == *"personal"* ]]
}

@test "list --json emits active + profiles array" {
  run "$ROOT/bin/claude-switch" list --json
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | jq -r '.active')" = "work" ]
  [ "$(echo "$output" | jq -r '.profiles | length')" = "2" ]
  [ "$(echo "$output" | jq -r '.profiles[] | select(.name=="work") | .active')" = "true" ]
  [ "$(echo "$output" | jq -r '.profiles[] | select(.name=="personal") | .email')" = "you@personal.example" ]
}

@test "current --json emits active + email" {
  echo personal > "$CLAUDE_SWITCH_HOME/active"
  run "$ROOT/bin/claude-switch" current --json
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | jq -r '.active')" = "personal" ]
  [ "$(echo "$output" | jq -r '.email')" = "you@personal.example" ]
}

@test "current --json with no active profile yields null" {
  rm -f "$CLAUDE_SWITCH_HOME/active"
  run "$ROOT/bin/claude-switch" current --json
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | jq -r '.active')" = "null" ]
}

@test "whoami prints current login email" {
  run "$ROOT/bin/claude-switch" whoami
  [ "$status" -eq 0 ]
  [ "$output" = "you@work.example" ]
}

@test "whoami --json emits email" {
  run "$ROOT/bin/claude-switch" whoami --json
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | jq -r '.email')" = "you@work.example" ]
}

@test "list ignores incomplete profiles (dir without creds)" {
  mkdir -p "$CLAUDE_SWITCH_HOME/profiles/halfbaked"
  run "$ROOT/bin/claude-switch" list --json
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | jq -r '.profiles | length')" = "2" ]
  [ "$(echo "$output" | jq -r '[.profiles[].name] | index("halfbaked")')" = "null" ]
}

@test "remove deletes a non-active profile's ClaudeSwitch files only" {
  mkdir -p "$CLAUDE_SWITCH_HOME/desktop/personal"
  run "$ROOT/bin/claude-switch" remove personal
  [ "$status" -eq 0 ]
  [ ! -d "$CLAUDE_SWITCH_HOME/profiles/personal" ]
  [ ! -d "$CLAUDE_SWITCH_HOME/desktop/personal" ]
  [ -d "$CLAUDE_SWITCH_HOME/profiles/work" ]
  [ -f "$CLAUDE_JSON" ]
}

@test "remove refuses the active profile" {
  run "$ROOT/bin/claude-switch" remove work
  [ "$status" -ne 0 ]
  [[ "$output" == *"active profile"* ]]
  [ -d "$CLAUDE_SWITCH_HOME/profiles/work" ]
}

@test "remove rejects unsafe names" {
  run "$ROOT/bin/claude-switch" remove "../../etc"
  [ "$status" -ne 0 ]
  [[ "$output" == *"invalid"* ]]
}
