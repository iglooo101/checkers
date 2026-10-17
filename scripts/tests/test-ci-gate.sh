#!/usr/bin/env bash
# US2: CI gate decisions (contracts/ci-gate.md, "Outcomes").
# Arguments to gate.sh: <changes job result> <code flag: true|false> <build-and-test job result>

set -uo pipefail
GATE="$(cd "$(dirname "$0")/.." && pwd)/ci/gate.sh"
failures=0

expect() {
  local expected="$1"; shift
  if "$GATE" "$@" >/dev/null 2>&1; then actual=pass; else actual=fail; fi
  if [[ "$actual" != "$expected" ]]; then
    echo "  FAIL: gate.sh $* -> $actual, expected $expected"
    failures=$((failures + 1))
  fi
}

expect pass success false skipped   # docs-only push
expect pass success true success    # code push, all steps green
expect fail success true failure    # code push, a blocking step failed
expect fail success true cancelled  # code push, run cancelled
expect fail success true skipped    # code push but build did not run
expect fail success false failure   # docs-only classification yet build failed
expect fail failure false skipped   # classification itself failed
expect fail failure true success
expect fail cancelled false skipped

exit $((failures > 0))
