#!/usr/bin/env bash
# Reports the cold-launch timing from a Performance test plan result bundle as Markdown, compared
# with the baseline recorded for this machine in checkers/launch-baselines.json. Timing never fails
# anything (clarification Q2); a result more than 20% slower than the baseline is flagged.
# Usage: report-launch.sh <result.xcresult> [--record]
#   --record  saves the measured average as this machine's baseline.

source "$(dirname "$0")/lib.sh"

result="$1"
record="${2:-}"
baselines="$REPO_ROOT/checkers/launch-baselines.json"
if [[ -n "${CI:-}" ]]; then machine="ci-$(uname -m)"; else machine="local-$(uname -m)"; fi

if ! metrics="$(xcrun xcresulttool get test-results metrics --path "$result" 2>/dev/null)"; then
  echo "Launch timing: no result bundle at $result."
  exit 0
fi

METRICS="$metrics" python3 - "$baselines" "$machine" "$record" <<'PY'
import datetime
import json
import os
import sys

path, machine, record = sys.argv[1], sys.argv[2], sys.argv[3] == "--record"
metric_id = "com.apple.dt.XCTMetric_ApplicationLaunch-AppLaunch.duration"
runs = [(run["device"]["deviceName"], metric["measurements"])
        for test in json.loads(os.environ["METRICS"]) for run in test["testRuns"]
        for metric in run["metrics"] if metric["identifier"] == metric_id]
if not runs:
    print("Launch timing: no launch measurement in the result bundle.")
    sys.exit(0)

device, values = runs[0]
average = sum(values) / len(values)
key = f"{machine} {device}"
baselines = json.load(open(path)) if os.path.exists(path) else {}

if record:
    baselines[key] = {"seconds": round(average, 3), "recorded": datetime.date.today().isoformat()}
    with open(path, "w") as f:
        json.dump(baselines, f, indent=2, sort_keys=True)
        f.write("\n")
    print(f"Recorded launch baseline for {key}: {average:.3f} s")
    sys.exit(0)

line = f"**Cold launch** ({key}): {average:.3f} s average of {len(values)} runs"
baseline = baselines.get(key)
if baseline:
    change = (average - baseline["seconds"]) / baseline["seconds"] * 100
    line += f"; baseline {baseline['seconds']:.3f} s ({change:+.1f}%)"
    if change > 20:
        line += ". Regression: more than 20% slower than the baseline."
else:
    line += "; no baseline recorded for this machine (record one with --record)."
print(line)
PY
