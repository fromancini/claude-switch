setup() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export CLAUDE_SWITCH_HOME="$BATS_TEST_TMPDIR/cs"
  source "$ROOT/lib/paths.sh"
  mkdir -p "$(profiles_dir)"
}

@test "active profile roundtrips" {
  [ -z "$(active_profile)" ]
  set_active_profile work
  [ "$(active_profile)" = "work" ]
}

@test "profile_exists requires both files" {
  mkdir -p "$(profile_dir work)"
  run profile_exists work
  [ "$status" -ne 0 ]
  echo '{}' > "$(profile_dir work)/claudeAiOauth.json"
  echo '{}' > "$(profile_dir work)/identity.json"
  run profile_exists work
  [ "$status" -eq 0 ]
}

@test "list_profiles lists created profiles" {
  mkdir -p "$(profile_dir work)" "$(profile_dir personal)"
  run list_profiles
  [[ "$output" == *work* ]]
  [[ "$output" == *personal* ]]
}
