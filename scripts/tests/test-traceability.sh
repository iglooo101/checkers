#!/usr/bin/env bash
# US1 FR-007: every FRD ID has a test or a manual check (specs/008-release-1-0/contracts/release-tooling.md).

set -uo pipefail
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
FIXTURES="$SCRIPTS/tests/traceability-fixtures"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
failures=0

fail() {
  echo "  FAIL: $1"
  failures=$((failures + 1))
}

# Runs traceability.py over the fixtures with a checklist and an output file.
trace() {
  local checklist="$1" out="$2"
  shift 2
  python3 "$SCRIPTS/traceability.py" --root "$FIXTURES" --frd "$FIXTURES/FRD.md" \
    --tests "$FIXTURES/tests" --checklist "$checklist" --out "$out" "$@"
}

# The matrix: tests from display names and doc comments, manual checks with their results, the
# removed ID marked.
if ! trace "$FIXTURES/release.md" "$TMP/matrix.md" >/dev/null 2>&1; then
  fail "writing the matrix should succeed"
elif ! diff -u "$FIXTURES/expected.md" "$TMP/matrix.md"; then
  fail "the matrix differs from expected.md"
fi

# --check passes on a fresh matrix.
if ! trace "$FIXTURES/release.md" "$TMP/matrix.md" --check >/dev/null 2>&1; then
  fail "--check should pass on a fresh matrix"
fi

# --check fails and names an ID that has neither a test nor a manual check.
grep -v 'RC-01' "$FIXTURES/release.md" > "$TMP/no-rc01.md"
trace "$TMP/no-rc01.md" "$TMP/missing.md" >/dev/null 2>&1
if output="$(trace "$TMP/no-rc01.md" "$TMP/missing.md" --check 2>&1)"; then
  fail "--check should fail when FR-BBB-02 has no test and no manual check"
elif [[ "$output" != *"FR-BBB-02"* ]]; then
  fail "the failure should name FR-BBB-02; it printed: $output"
fi

# --check fails on a matrix that is out of date.
cp "$TMP/matrix.md" "$TMP/stale.md"
echo "| FR-ZZZ-99 | covered | — | — |" >> "$TMP/stale.md"
if output="$(trace "$FIXTURES/release.md" "$TMP/stale.md" --check 2>&1)"; then
  fail "--check should fail on a stale matrix"
elif [[ "$output" != *"out of date"* ]]; then
  fail "the stale failure should say the matrix is out of date; it printed: $output"
fi

# The real matrix covers every FRD ID and is up to date.
if ! output="$(python3 "$SCRIPTS/traceability.py" --check 2>&1)"; then
  fail "the real matrix: $output"
fi

exit $((failures > 0))
