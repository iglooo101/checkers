#!/usr/bin/env bash
# Takes the six store screenshots (specs/008-release-1-0/contracts/release-tooling.md, R12):
# runs Screenshots.xctestplan on the iPhone 17 simulator (iOS 26.3) in light appearance, at the
# default text size, with the status bar at 9:41 and full battery and signal, and writes
# release/screenshots/01-home.png … 06-statistics.png as 1206 × 2622 RGB PNG files. It prints
# which files changed; a second run on the same commit must print none (spec FR-019).
# Usage: scripts/screenshots.sh

set -euo pipefail

SIMULATOR_NAME="iPhone 17"
SIMULATOR_RUNTIME="com.apple.CoreSimulator.SimRuntime.iOS-26-3"
NAMES=(01-home 02-computer-game 03-capture-chain 04-king 05-rules 06-statistics)

# The simulator's identifier is read from simctl each time.
udid="$(xcrun simctl list devices available --json | python3 -I -c '
import json, sys
devices = json.load(sys.stdin)["devices"].get(sys.argv[1], [])
print(next((device["udid"] for device in devices if device["name"] == sys.argv[2]), ""))
' "$SIMULATOR_RUNTIME" "$SIMULATOR_NAME")"
if [[ -z "$udid" ]]; then
  echo "No $SIMULATOR_NAME simulator on iOS 26.3; add one in Xcode's Devices and Simulators." >&2
  exit 1
fi
DESTINATION="platform=iOS Simulator,id=$udid"
source "$(dirname "$0")/lib.sh"

SCREENSHOTS="$REPO_ROOT/release/screenshots"
RESULT_BUNDLE="$RESULTS_DIR/Screenshots.xcresult"
LOG="$RESULTS_DIR/Screenshots.log"
exported="$(mktemp -d)"
trap 'xcrun simctl status_bar "$udid" clear 2>/dev/null; rm -rf "$exported"' EXIT

# Booted here, the simulator stays booted through the test run, so its settings hold.
xcrun simctl boot "$udid" 2>/dev/null || true
xcrun simctl bootstatus "$udid" -b >/dev/null
xcrun simctl ui "$udid" appearance light
xcrun simctl ui "$udid" content_size large
xcrun simctl status_bar "$udid" override --time 9:41 --batteryState charged --batteryLevel 100 \
  --cellularMode active --cellularBars 4 --wifiBars 3

mkdir -p "$RESULTS_DIR" "$SCREENSHOTS"
rm -rf "$RESULT_BUNDLE"
if ! xcodebuild test "${XCODEBUILD_FLAGS[@]}" -testPlan Screenshots \
  -resultBundlePath "$RESULT_BUNDLE" >"$LOG" 2>&1; then
  tail -n 30 "$LOG" >&2
  echo "The screenshot tests failed; the whole log is in $LOG." >&2
  exit 1
fi
xcrun xcresulttool export attachments --path "$RESULT_BUNDLE" --output-path "$exported" \
  >/dev/null

# Each attachment is named after its file; prints "name<TAB>exported file" per screenshot.
pairs="$(python3 -I - "$exported/manifest.json" <<'PY'
import json, re, sys
for test in json.load(open(sys.argv[1])):
    for attachment in test.get("attachments", []):
        name = re.match(r"\d\d-[a-z-]+", attachment["suggestedHumanReadableName"])
        if name:
            print(f"{name.group(0)}\t{attachment['exportedFileName']}")
PY
)"

changed=()
for name in "${NAMES[@]}"; do
  file="$(awk -F '\t' -v name="$name" '$1 == name { print $2 }' <<<"$pairs")"
  if [[ -z "$file" || "$(wc -l <<<"$file")" -ne 1 ]]; then
    echo "The test run did not give exactly one $name screenshot." >&2
    exit 1
  fi
  properties="$(sips -g pixelWidth -g pixelHeight -g hasAlpha -g bitsPerSample \
    "$exported/$file")"
  for expected in "pixelWidth: 1206" "pixelHeight: 2622" "hasAlpha: no" "bitsPerSample: 8"; do
    if [[ "$properties" != *"$expected"* ]]; then
      echo "$name is not a 1206 × 2622 8-bit PNG without alpha:" >&2
      echo "$properties" >&2
      exit 1
    fi
  done
  if ! cmp -s "$exported/$file" "$SCREENSHOTS/$name.png"; then
    cp "$exported/$file" "$SCREENSHOTS/$name.png"
    changed+=("$name.png")
  fi
done

if [[ ${#changed[@]} -eq 0 ]]; then
  echo "No screenshot changed."
else
  echo "Changed: ${changed[*]}"
fi
