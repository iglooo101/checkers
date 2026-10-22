#!/usr/bin/env bash
# US2: CI gate decisions (contracts/ci-gate.md, "Outcomes").
# Arguments to gate.sh: <changes job result> <code flag: true|false> <build-and-test job result>
# <engine-strength job result>

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

expect pass success false skipped skipped     # docs-only push
expect pass success true success success      # code push, both jobs green
expect fail success true failure success      # code push, a blocking build step failed
expect fail success true success failure      # code push, the strength matches failed
expect fail success true cancelled success    # code push, run cancelled
expect fail success true success cancelled
expect fail success true skipped success      # code push but build did not run
expect fail success true success skipped      # code push but the matches did not run
expect fail success false failure skipped     # docs-only classification yet build failed
expect fail success false skipped failure     # docs-only classification yet the matches failed
expect fail failure false skipped skipped     # classification itself failed
expect fail failure true success success
expect fail cancelled false skipped skipped
expect fail success true success              # the engine-strength result is missing

exit $((failures > 0))
