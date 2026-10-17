#!/usr/bin/env bash
# Runs every scripts/tests/test-*.sh and reports PASS or FAIL for each.

set -uo pipefail
cd "$(dirname "$0")"
failed=0

for test in test-*.sh; do
  name="$(sed -n '2s/^# //p' "$test")"
  if output="$(bash "$test" 2>&1)"; then
    echo "PASS $test — $name"
  else
    echo "FAIL $test — $name"
    [[ -n "$output" ]] && echo "$output"
    failed=$((failed + 1))
  fi
done

exit $((failed > 0))
