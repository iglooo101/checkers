#!/usr/bin/env bash
# US2 FR-013 SC-005: the computer's timing and the sound delay are judged (specs/008-release-1-0/contracts/release-tooling.md).

set -uo pipefail
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
FIXTURES="$SCRIPTS/tests/timing-fixtures"
failures=0

fail() {
  echo "  FAIL: $1"
  failures=$((failures + 1))
}

# Runs device-timings.py on a fixture; sets $output and $status.
judge() {
  output="$(python3 "$SCRIPTS/device-timings.py" "$FIXTURES/$1" 2>&1)"
  status=$?
}

# Expects the report on a fixture to fail and to say why.
expect_miss() {
  local fixture="$1" text="$2"
  judge "$fixture"
  if [[ $status -ne 1 ]]; then
    fail "$fixture should exit 1, it exited $status: $output"
  elif [[ "$output" != *"$text"* ]]; then
    fail "the report on $fixture should say \"$text\"; it printed: $output"
  fi
}

judge all-pass.txt
if [[ $status -ne 0 ]]; then
  fail "all-pass.txt should exit 0, it exited $status: $output"
fi
for text in "easy: 12 turns, 100.0% within 0.5–1.0 s, slowest 960 ms" \
  "medium: 12 turns, 100.0% within 0.5–1.0 s, slowest 930 ms" \
  "hard: 12 turns, 100.0% within 0.5–1.0 s, slowest 999 ms" \
  "slowest start 18.5 ms, output latency 21.3 ms, sum 39.8 ms"; do
  if [[ "$output" != *"$text"* ]]; then
    fail "the report on all-pass.txt should say \"$text\"; it printed: $output"
  fi
done

expect_miss slow-hard-turn.txt "hard: 12 turns, 91.7% within 0.5–1.0 s, slowest 1600 ms"
expect_miss easy-out-of-range.txt "easy: 50 turns, 94.0% within 0.5–1.0 s, slowest 1100 ms"
expect_miss slow-sound.txt "sum 120.0 ms"
expect_miss no-medium.txt "no computer turns at medium"
expect_miss no-sound.txt "no sound lines"

exit $((failures > 0))
