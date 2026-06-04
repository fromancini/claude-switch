setup() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  source "$ROOT/lib/json_ops.sh"
  FIX="$ROOT/tests/fixtures"
}

@test "extract_identity keeps only oauthAccount and userID" {
  run extract_identity < "$FIX/claude.json"
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | jq -r '.oauthAccount.emailAddress')" = "you@work.example" ]
  [ "$(echo "$output" | jq -r '.userID')" = "user-WORK-aaa" ]
  [ "$(echo "$output" | jq -r 'has("numStartups")')" = "false" ]
}

@test "merge_identity swaps identity but preserves other keys" {
  run merge_identity "$FIX/identity-personal.json" < "$FIX/claude.json"
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | jq -r '.oauthAccount.emailAddress')" = "you@personal.example" ]
  [ "$(echo "$output" | jq -r '.userID')" = "user-HOME-bbb" ]
  [ "$(echo "$output" | jq -r '.numStartups')" = "42" ]
  [ "$(echo "$output" | jq -r '.projects["/Users/x/proj"].allowedTools[0]')" = "Bash" ]
}

@test "extract_credentials returns only claudeAiOauth" {
  run extract_credentials < "$FIX/keychain-blob.json"
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | jq -r '.accessToken')" = "AT-work" ]
}

@test "merge_credentials swaps claudeAiOauth but preserves mcpOAuth" {
  run merge_credentials "$FIX/claudeAiOauth-personal.json" < "$FIX/keychain-blob.json"
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | jq -r '.claudeAiOauth.accessToken')" = "AT-home" ]
  [ "$(echo "$output" | jq -r '.mcpOAuth["plugin:gitlab:gitlab|abc"].accessToken')" = "GL-keep-me" ]
}

@test "account_email reads oauthAccount.emailAddress" {
  run account_email < "$FIX/claude.json"
  [ "$status" -eq 0 ]
  [ "$output" = "you@work.example" ]
}

@test "account_email is empty when no account" {
  printf '{}' > "$BATS_TEST_TMPDIR/empty.json"
  run account_email < "$BATS_TEST_TMPDIR/empty.json"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "valid_json accepts good, rejects bad" {
  run valid_json "$FIX/claude.json"
  [ "$status" -eq 0 ]
  echo 'not json' > "$BATS_TEST_TMPDIR/bad.json"
  run valid_json "$BATS_TEST_TMPDIR/bad.json"
  [ "$status" -ne 0 ]
}
