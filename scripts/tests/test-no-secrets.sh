#!/usr/bin/env bash
# US5 FR-024: no key material is tracked (specs/008-release-1-0/contracts/release-tooling.md).

set -uo pipefail
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
failures=0

# A private key's header line, built from two parts so that this file never matches itself.
BEGIN_MARK='-----BEGIN'
KEY_MARK='PRIVATE KEY-----'
HEADER="${BEGIN_MARK}[A-Z ]*${KEY_MARK}"

# Prints one line per problem in the git repository at $1.
problems() {
  local repo="$1"
  if ! grep -qxF '*.p8' "$repo/.gitignore" 2>/dev/null; then
    echo ".gitignore does not list *.p8"
  fi
  git -C "$repo" ls-files -- '*.p8' | sed 's/^/tracked key file: /'
  git -C "$repo" grep -I -l -E -e "$HEADER" -- . 2>/dev/null | sed 's/^/tracked file holds a private key: /'
}

found="$(problems "$REPO")"
if [[ -n "$found" ]]; then
  echo "$found" | sed 's/^/  FAIL: /'
  failures=$((failures + 1))
fi

# The check itself: a repository with every problem must report all three.
git -C "$TMP" init -q
printf '.DS_Store\n' > "$TMP/.gitignore"
printf 'not a key\n' > "$TMP/AuthKey_TEST.p8"
printf '%s\nAAAA\n-----END %s\n' "${BEGIN_MARK} ${KEY_MARK}" "${KEY_MARK}" > "$TMP/notes.txt"
git -C "$TMP" add -A
planted="$(problems "$TMP")"
for expected in ".gitignore does not list" "tracked key file: AuthKey_TEST.p8" \
  "tracked file holds a private key: notes.txt"; do
  if [[ "$planted" != *"$expected"* ]]; then
    echo "  FAIL: a planted problem was not found: $expected"
    failures=$((failures + 1))
  fi
done

exit $((failures > 0))
