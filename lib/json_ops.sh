# shellcheck shell=bash
# lib/json_ops.sh — pure JSON transforms. Read stdin/file args, write stdout. Need jq.

extract_identity() {        # stdin: claude.json  -> stdout: {oauthAccount,userID}
  jq '{oauthAccount, userID}'
}

merge_identity() {          # $1: identity.json file; stdin: claude.json -> stdout: merged
  jq --argjson id "$(cat "$1")" '.oauthAccount = $id.oauthAccount | .userID = $id.userID'
}

extract_credentials() {     # stdin: keychain blob -> stdout: claudeAiOauth object
  jq '.claudeAiOauth'
}

merge_credentials() {       # $1: claudeAiOauth.json file; stdin: live blob -> stdout: merged blob
  jq --argjson cred "$(cat "$1")" '.claudeAiOauth = $cred'
}

account_email() {           # stdin: identity.json OR claude.json -> stdout: email (or empty)
  jq -r '.oauthAccount.emailAddress // empty'
}

valid_json() {              # $1: file -> exit 0 iff valid JSON
  jq -e . "$1" >/dev/null 2>&1
}
