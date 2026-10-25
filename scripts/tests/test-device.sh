#!/usr/bin/env bash
# US2 FR-011: device.sh finds the phone and checks Developer Mode (specs/008-release-1-0/contracts/release-tooling.md).

set -uo pipefail
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
FIXTURES="$SCRIPTS/tests/device-fixtures"
failures=0

# Expects `device.sh <command>` over a fixture device list to exit with a status and to print a
# text.
expect() {
  local command="$1" fixture="$2" status="$3" text="$4" output actual
  output="$(DEVICECTL_FIXTURES="$FIXTURES/$fixture" DEVICE_NAME=HKH16 \
    bash "$SCRIPTS/device.sh" "$command" 2>&1)"
  actual=$?
  if [[ "$actual" != "$status" ]]; then
    echo "  FAIL: $command with $fixture exited $actual, expected $status"
    failures=$((failures + 1))
  fi
  if [[ "$output" != *"$text"* ]]; then
    echo "  FAIL: $command with $fixture should print \"$text\"; it printed: $output"
    failures=$((failures + 1))
  fi
}

expect status connected.json 0 "HKH16: iPhone 16 (iPhone17,3), iOS 27.0.1, connected, Developer Mode enabled"
expect status developer-mode-off.json 1 "Turn on Developer Mode: Settings › Privacy & Security › Developer Mode"
expect status unavailable.json 1 "HKH16 is not connected: connect it by cable and unlock it."
expect status other-device.json 1 "No device named HKH16: connect the iPhone and unlock it."
# `launch` checks the phone before it builds anything.
expect launch developer-mode-off.json 1 "Turn on Developer Mode"
expect launch unavailable.json 1 "is not connected"
# An unknown command names the commands.
expect measure connected.json 2 "Usage: scripts/device.sh status | launch"

exit $((failures > 0))
