#!/usr/bin/env bash
# Measures the app on the owner's iPhone (specs/008-release-1-0/contracts/release-tooling.md).
# The phone is found by name (DEVICE_NAME, default HKH16); its identifiers are read from
# devicectl each time and never written to a file.
# Usage: scripts/device.sh status | launch
#   status  the phone is connected and Developer Mode is on
#   launch  ten cold launches of the Release build: every value, the median, pass or miss (0.4 s)

source "$(dirname "$0")/lib.sh"

DEVICE_NAME="${DEVICE_NAME:-HKH16}"
DEVICE_DERIVED_DATA="$REPO_ROOT/.build/DeviceDerivedData"
LAUNCH_BUDGET=0.4

usage() {
  echo "Usage: scripts/device.sh status | launch" >&2
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

# Runs the launch test twice (five launches each) in Release on the phone through the
# checkers-device scheme; `xcodebuild test`, since test-without-building cannot launch the app on
# iOS 27 (research R1).
launch() {
  status
  local result="$RESULTS_DIR/DeviceLaunch.xcresult"
  mkdir -p "$RESULTS_DIR"
  rm -rf "$result"
  xcodebuild test \
    -project "$PROJECT" \
    -scheme checkers-device \
    -configuration Release \
    -destination "id=$DEVICE_UDID" \
    -derivedDataPath "$DEVICE_DERIVED_DATA" \
    -skipPackagePluginValidation \
    -allowProvisioningUpdates \
    -only-testing:checkersUITests/LaunchPerformanceTests \
    -test-iterations 2 \
    -resultBundlePath "$result"
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

case "${1:-}" in
  status) status ;;
  launch) launch ;;
  *) usage ;;
esac
