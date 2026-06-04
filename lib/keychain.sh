# shellcheck shell=bash
# lib/keychain.sh — read/write the Claude Code login Keychain item.
# NOTE: security has no stdin path for the password, so the blob is passed via -w.
# On a single-user mac this momentary `ps` exposure is acceptable (see spec §7).

keychain_read_blob() {      # stdout: JSON blob; nonzero if item missing
  # `security -w` returns the secret as HEX whenever the stored data contains a
  # newline / non-printable byte, and raw otherwise. Decode the hex form so the
  # caller always gets the real bytes. (Real JSON always has non-hex chars like
  # '{' or '"', so an all-hex string is unambiguously the encoded form.)
  local out
  out="$(security find-generic-password -s "$KEYCHAIN_SERVICE" -w 2>/dev/null)" || return 1
  # Whole-string all-hex test: raw JSON always contains non-hex chars ('{','"'),
  # and a multi-line raw value contains newlines, so neither matches.
  if [[ "$out" =~ ^[0-9a-f]+$ ]]; then
    printf '%s' "$out" | xxd -r -p
  else
    printf '%s' "$out"
  fi
}

keychain_account() {        # stdout: the item's acct attribute (may be empty)
  security find-generic-password -s "$KEYCHAIN_SERVICE" 2>/dev/null \
    | sed -n 's/^[[:space:]]*"acct"<blob>="\(.*\)"$/\1/p'
}

keychain_write_blob() {     # $1: new blob -> update IN PLACE (preserves acct + ACL, no prompt)
  # Store COMPACT, single-line JSON. jq -c escapes any literal newline, and the
  # command substitution strips the trailing one, so the stored secret has no
  # newline at all -> `security -w` returns it raw on read (no hex round-trip).
  local acct compact
  acct="$(keychain_account)"
  compact="$(printf '%s' "$1" | jq -c .)" || { echo "ERROR: refusing to write non-JSON to Keychain" >&2; return 1; }
  security add-generic-password -U -s "$KEYCHAIN_SERVICE" -a "$acct" -w "$compact"
}
