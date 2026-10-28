#!/usr/bin/env bash
# Measures the app on the owner's iPhone (specs/008-release-1-0/contracts/release-tooling.md).
# The phone is found by name (DEVICE_NAME, default HKH16); its identifiers are read from
# devicectl each time and never written to a file.
# Usage: scripts/device.sh status | launch | session
#   status   the phone is connected and Developer Mode is on
#   launch   ten cold launches of the Release build: every value, the median, pass or miss (0.4 s)
#   session  the scripted session on the Release build: hitches, the computer's timing and the
#            sound delay, each with pass or miss

source "$(dirname "$0")/lib.sh"

DEVICE_NAME="${DEVICE_NAME:-HKH16}"
DEVICE_DERIVED_DATA="$REPO_ROOT/.build/DeviceDerivedData"
LAUNCH_BUDGET=0.4
SESSION_DIR="$REPO_ROOT/.build/DeviceSession"
BUNDLE_ID="Hussein-Helmy.checkers"

usage() {
  echo "Usage: scripts/device.sh status | launch | session" >&2
  exit 2
}

# Reads the device list (from devicectl, or from the file DEVICECTL_FIXTURES names, for the
# script tests) and sets the phone's fields; stops with a sentence when it cannot be used.
find_device() {
  local list
  if [[ -n "${DEVICECTL_FIXTURES:-}" ]]; then
    list="$DEVICECTL_FIXTURES"
  else
    list="$(mktemp)"
    xcrun devicectl list devices --json-output "$list" >/dev/null 2>&1 || true
  fi
  local fields
  fields="$(python3 -I - "$list" "$DEVICE_NAME" <<'PY'
import json, sys
path, name = sys.argv[1], sys.argv[2]
try:
    devices = json.load(open(path))["result"]["devices"]
except (OSError, ValueError, KeyError):
    devices = []
for device in devices:
    properties = device.get("deviceProperties", {})
    if properties.get("name") != name:
        continue
    hardware = device.get("hardwareProperties", {})
    print("\t".join([
        device.get("identifier", ""), hardware.get("udid", ""),
        hardware.get("marketingName", ""), hardware.get("productType", ""),
        properties.get("osVersionNumber", ""),
        device.get("connectionProperties", {}).get("tunnelState", ""),
        properties.get("developerModeStatus", ""),
    ]))
    break
PY
)"
  [[ -n "${DEVICECTL_FIXTURES:-}" ]] || rm -f "$list"
  if [[ -z "$fields" ]]; then
    echo "No device named $DEVICE_NAME: connect the iPhone and unlock it." >&2
    exit 1
  fi
  IFS=$'\t' read -r DEVICE_ID DEVICE_UDID DEVICE_MODEL DEVICE_PRODUCT DEVICE_OS DEVICE_TUNNEL \
    DEVICE_DEVELOPER_MODE <<<"$fields"
}

status() {
  find_device
  # A phone that is not connected reports a stale Developer Mode, so the tunnel comes first.
  if [[ "$DEVICE_TUNNEL" != connected ]]; then
    echo "$DEVICE_NAME is not connected: connect it by cable and unlock it." >&2
    exit 1
  fi
  echo "$DEVICE_NAME: $DEVICE_MODEL ($DEVICE_PRODUCT), iOS $DEVICE_OS, $DEVICE_TUNNEL," \
    "Developer Mode $DEVICE_DEVELOPER_MODE"
  if [[ "$DEVICE_DEVELOPER_MODE" != enabled ]]; then
    echo "Turn on Developer Mode: Settings › Privacy & Security › Developer Mode" >&2
    exit 1
  fi
}

# The flags of every xcodebuild call on the phone.
device_flags() {
  DEVICE_FLAGS=(
    -project "$PROJECT"
    -scheme checkers-device
    -configuration Release
    -destination "id=$DEVICE_UDID"
    -derivedDataPath "$DEVICE_DERIVED_DATA"
    -skipPackagePluginValidation
    -allowProvisioningUpdates
  )
}

# Runs the launch test twice (five launches each) in Release on the phone through the
# checkers-device scheme; `xcodebuild test`, since test-without-building cannot launch the app on
# iOS 27 (research R1).
launch() {
  status
  device_flags
  local result="$RESULTS_DIR/DeviceLaunch.xcresult"
  mkdir -p "$RESULTS_DIR"
  rm -rf "$result"
  xcodebuild test "${DEVICE_FLAGS[@]}" -only-testing:checkersUITests/LaunchPerformanceTests \
    -test-iterations 2 -resultBundlePath "$result"
  xcrun xcresulttool get test-results metrics --path "$result" \
    | python3 -I - "$LAUNCH_BUDGET" <<'PY'
import json, statistics, sys
budget = float(sys.argv[1])
metric_id = "com.apple.dt.XCTMetric_ApplicationLaunch-AppLaunch.duration"
values = [value for test in json.load(sys.stdin) for run in test["testRuns"]
          for metric in run["metrics"] if metric["identifier"] == metric_id
          for value in metric["measurements"]]
print("Cold launches (s): " + ", ".join(f"{value:.3f}" for value in values))
if len(values) < 10:
    print(f"Only {len(values)} launches were measured; ten are needed.")
    sys.exit(1)
median = statistics.median(values)
verdict = "pass" if median < budget else "miss"
print(f"Median: {median:.3f} s against {budget} s: {verdict}")
sys.exit(0 if verdict == "pass" else 1)
PY
}

# Prints the three hitch metrics of a result bundle with pass or miss (ratio under 5 ms/s, total
# under 0.25 s). Returns 0 when all pass, 1 on a miss, 3 when the bundle has none of them.
judge_hitches() {
  xcrun xcresulttool get test-results metrics --path "$1" | python3 -I - <<'PY'
import json, sys
prefix = "com.apple.dt.XCTMetric_Hitch-checkers."
# Each metric with its limit; the total is converted to seconds whatever unit it comes in.
limits = {"time.ratio": ("ms/s", 5.0), "number": ("", None), "total.duration": ("s", 0.25)}
found = {}
for test in json.load(sys.stdin):
    for run in test["testRuns"]:
        for metric in run["metrics"]:
            name = metric["identifier"].removeprefix(prefix)
            if metric["identifier"].startswith(prefix) and name in limits:
                value = max(metric["measurements"])
                if name == "total.duration" and metric.get("unitOfMeasurement") == "ms":
                    value /= 1000
                found[name] = value
if not found:
    sys.exit(3)
print("Hitches (ratio under 5 ms/s, total under 0.25 s):")
missed = False
for name, (unit, limit) in limits.items():
    if name not in found:
        print(f"  {name}: absent")
        missed = True
        continue
    verdict = "" if limit is None else (": pass" if found[name] < limit else ": miss")
    missed = missed or verdict == ": miss"
    print(f"  {name}: {found[name]:g} {unit}{verdict}".rstrip())
sys.exit(1 if missed else 0)
PY
}

# Runs the scripted session on the phone (research R5 and R6): installs the Release app, launches
# it with the session's saved game and its log mirrored to the Mac, lets DeviceSessionUITests
# drive that same process while the log is captured, then judges the hitch metrics and the
# timing lines. Sound effects and hints are on for this launch whatever the phone's settings.
session() {
  status
  device_flags
  local result="$RESULTS_DIR/DeviceSession.xcresult" console="$SESSION_DIR/console.txt"
  local game
  game="$(xxd -p "$REPO_ROOT/scripts/device-session-game.json" | tr -d '\n')"
  mkdir -p "$RESULTS_DIR" "$SESSION_DIR"
  rm -rf "$result" "$console"

  if ! xcodebuild build "${DEVICE_FLAGS[@]}" >"$SESSION_DIR/build.log" 2>&1; then
    tail -n 20 "$SESSION_DIR/build.log" >&2
    echo "The Release build failed; the whole log is in $SESSION_DIR/build.log." >&2
    exit 1
  fi
  xcrun devicectl device install app --device "$DEVICE_ID" \
    "$DEVICE_DERIVED_DATA/Build/Products/Release-iphoneos/checkers.app" >/dev/null

  xcrun devicectl device process launch --device "$DEVICE_ID" --console --terminate-existing \
    --environment-variables '{"OS_ACTIVITY_DT_MODE":"YES"}' "$BUNDLE_ID" -- \
    -savedGame "<$game>" -soundEffects "<true/>" -moveHints "<true/>" >"$console" 2>&1 &
  local capture=$!
  # The sound bank prepares right after launch, so its latency line shows the app is running.
  local waited=0
  until grep -q "Output latency" "$console" 2>/dev/null; do
    if ((waited >= 60)) || ! kill -0 "$capture" 2>/dev/null; then
      kill "$capture" 2>/dev/null || true
      cat "$console" >&2
      echo "The app did not start on $DEVICE_NAME within a minute." >&2
      exit 1
    fi
    sleep 1
    waited=$((waited + 1))
  done

  local tested=0
  xcodebuild test "${DEVICE_FLAGS[@]}" -only-testing:checkersUITests/DeviceSessionUITests \
    -resultBundlePath "$result" >"$SESSION_DIR/test.log" 2>&1 || tested=$?
  kill "$capture" 2>/dev/null || true
  wait "$capture" 2>/dev/null || true
  if ((tested != 0)); then
    tail -n 30 "$SESSION_DIR/test.log" >&2
    echo "The session test failed; the whole log is in $SESSION_DIR/test.log." >&2
    exit 1
  fi

  # XCTest may give no hitch metrics for an app the test attached to (research R6); then a
  # second run, in which the test launches the app itself with the same game, measures them.
  local hitches="$result" judged=0
  judge_hitches "$result" || judged=$?
  if ((judged == 3)); then
    echo "No hitch metrics from the attached run; measuring them in a run that launches the app."
    hitches="$RESULTS_DIR/DeviceSessionLaunched.xcresult"
    rm -rf "$hitches"
    tested=0
    TEST_RUNNER_SESSION_GAME="$game" xcodebuild test "${DEVICE_FLAGS[@]}" \
      -only-testing:checkersUITests/DeviceSessionUITests -resultBundlePath "$hitches" \
      >"$SESSION_DIR/test-launched.log" 2>&1 || tested=$?
    if ((tested != 0)); then
      tail -n 30 "$SESSION_DIR/test-launched.log" >&2
      echo "The launched session failed; the log is in $SESSION_DIR/test-launched.log." >&2
      exit 1
    fi
    judged=0
    judge_hitches "$hitches" || judged=$?
    if ((judged == 3)); then
      echo "Neither run gave hitch metrics; record the session in Instruments instead (T022)." >&2
    fi
  fi
  local missed=0
  ((judged == 0)) || missed=1
  python3 "$REPO_ROOT/scripts/device-timings.py" "$console" || missed=1
  echo "Hitches from: $hitches"
  echo "Console capture: $console"
  exit "$missed"
}

case "${1:-}" in
  status) status ;;
  launch) launch ;;
  session) session ;;
  *) usage ;;
esac
