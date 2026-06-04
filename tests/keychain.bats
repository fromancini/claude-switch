setup() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export PATH="$ROOT/tests/helpers/stubs:$PATH"
  export KC_STORE="$BATS_TEST_TMPDIR/kc"
  export KC_ACCT="you@work.example"
  export KEYCHAIN_SERVICE="Claude Code-credentials"
  source "$ROOT/lib/paths.sh"
  source "$ROOT/lib/keychain.sh"
}

@test "read decodes hex when stored value is multi-line (security hex mode)" {
  printf '{\n  "claudeAiOauth": {"accessToken":"AT"},\n  "mcpOAuth": {"x":1}\n}\n' > "$KC_STORE"
  run keychain_read_blob
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | jq -r '.claudeAiOauth.accessToken')" = "AT" ]
}

@test "read returns raw when stored value is single-line" {
  printf '{"claudeAiOauth":{"accessToken":"AT"},"mcpOAuth":{"x":1}}' > "$KC_STORE"
  run keychain_read_blob
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | jq -r '.claudeAiOauth.accessToken')" = "AT" ]
}

@test "write stores compact single-line so security returns it raw (round-trip)" {
  ml="$(printf '{\n  "claudeAiOauth": {"accessToken":"AT2"},\n  "mcpOAuth": {"y":2}\n}')"
  keychain_write_blob "$ml"
  # stored value must have NO newline (else security would hex-encode it on read)
  [ "$(wc -l < "$KC_STORE" | tr -d ' ')" -eq 0 ]
  run keychain_read_blob
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | jq -r '.claudeAiOauth.accessToken')" = "AT2" ]
  [ "$(echo "$output" | jq -r '.mcpOAuth.y')" = "2" ]
}
