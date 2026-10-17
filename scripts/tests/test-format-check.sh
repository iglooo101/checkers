#!/usr/bin/env bash
# US3: format check warns locally and fails in strict (CI) mode (contracts/lint-rules.md).

set -uo pipefail
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
failures=0

mkdir -p "$TMP/bad" "$TMP/good"
printf 'struct Sample {\n   let value: Int\n}\n' > "$TMP/bad/Bad.swift"
printf 'struct Sample {\n    let value: Int\n}\n' > "$TMP/good/Good.swift"

if "$SCRIPTS/check-format.sh" --strict "$TMP/bad" >/dev/null 2>&1; then
  echo "  FAIL: strict check should fail on a 3-space indent"
  failures=$((failures + 1))
fi

if ! "$SCRIPTS/check-format.sh" --strict "$TMP/good" >/dev/null 2>&1; then
  echo "  FAIL: strict check should pass on correctly formatted code"
  failures=$((failures + 1))
fi

if ! output="$("$SCRIPTS/check-format.sh" "$TMP/bad" 2>&1)"; then
  echo "  FAIL: non-strict check should exit 0"
  failures=$((failures + 1))
elif [[ "$output" != *warning* ]]; then
  echo "  FAIL: non-strict check should print a warning"
  failures=$((failures + 1))
fi

exit $((failures > 0))
