#!/usr/bin/env bash
# E6 US4: the committed sounds match their recipes, and the check names a changed, missing or resized file.

set -uo pipefail
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
SOUNDS="$SCRIPTS/../checkers/checkers/Features/Sound/Sounds"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
failures=0

if ! python3 "$SCRIPTS/make-sounds.py" --check >/dev/null 2>&1; then
  echo "  FAIL: the committed sounds should match their recipes"
  failures=$((failures + 1))
fi

# A fresh copy of the committed sounds in its own directory.
fresh() {
  rm -rf "$TMP/$1"
  mkdir -p "$TMP/$1"
  cp "$SOUNDS"/*.wav "$TMP/$1/" 2>/dev/null
  echo "$TMP/$1"
}

# Rewrites a WAV file's samples with a Python expression over the list `samples`.
edit_samples() {
  python3 -I - "$1" "$2" <<'PY'
import sys, wave
path, change = sys.argv[1], sys.argv[2]
with wave.open(path, "rb") as file:
    params = file.getparams()
    data = file.readframes(file.getnframes())
samples = [int.from_bytes(data[i:i + 2], "little", signed=True) for i in range(0, len(data), 2)]
exec(change)
with wave.open(path, "wb") as file:
    file.setnchannels(params.nchannels)
    file.setsampwidth(params.sampwidth)
    file.setframerate(params.framerate)
    file.writeframes(b"".join(s.to_bytes(2, "little", signed=True) for s in samples))
PY
}

# Expects `--check <dir>` to fail and to name the file.
expect_failure() {
  local directory="$1" file="$2" what="$3" output
  if output="$(python3 "$SCRIPTS/make-sounds.py" --check "$directory" 2>&1)"; then
    echo "  FAIL: $what should fail the check"
    failures=$((failures + 1))
  elif [[ "$output" != *"$file"* ]]; then
    echo "  FAIL: the failure for $what should name $file"
    failures=$((failures + 1))
  fi
}

changed="$(fresh changed)"
edit_samples "$changed/capture.wav" "samples[1000] = samples[1000] + 2 if samples[1000] < 32000 else samples[1000] - 2"
expect_failure "$changed" capture.wav "a sample changed by two steps"

missing="$(fresh missing)"
rm -f "$missing/crowning.wav"
expect_failure "$missing" crowning.wav "a missing file"

longer="$(fresh longer)"
edit_samples "$longer/move.wav" "samples += [0] * 10"
expect_failure "$longer" move.wav "a file of another length"

exit $((failures > 0))
