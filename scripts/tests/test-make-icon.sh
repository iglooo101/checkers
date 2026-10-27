#!/usr/bin/env bash
# US4 FR-015 SC-007: the icon matches its script, in its three variants (specs/008-release-1-0/contracts/release-tooling.md).

set -uo pipefail
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
ICONS="$SCRIPTS/../checkers/checkers/Assets.xcassets/AppIcon.appiconset"
failures=0

fail() {
  echo "  FAIL: $1"
  failures=$((failures + 1))
}

if ! output="$(python3 "$SCRIPTS/make-icon.py" --check 2>&1)"; then
  fail "the committed icons should match the script; it printed: $output"
fi

# Expects `sips` to report a property of an icon file with the given value.
expect_property() {
  local file="$1" property="$2" expected="$3" actual
  actual="$(sips -g "$property" "$ICONS/$file" 2>/dev/null | awk -v key="$property:" '$1 == key { print $2 }')"
  [[ "$actual" == "$expected" ]] || fail "$file should have $property $expected, not ${actual:-nothing}"
}

for file in AppIcon.png AppIcon-Dark.png AppIcon-Tinted.png; do
  if [[ ! -f "$ICONS/$file" ]]; then
    fail "$file is missing"
    continue
  fi
  expect_property "$file" pixelWidth 1024
  expect_property "$file" pixelHeight 1024
done
expect_property AppIcon.png hasAlpha no
expect_property AppIcon.png space RGB
expect_property AppIcon-Dark.png hasAlpha yes
expect_property AppIcon-Tinted.png space Gray

# Each entry of Contents.json names its file: no appearance, dark and tinted.
if ! output="$(python3 -I - "$ICONS/Contents.json" <<'PY' 2>&1
import json, sys
expected = {None: "AppIcon.png", "dark": "AppIcon-Dark.png", "tinted": "AppIcon-Tinted.png"}
images = json.load(open(sys.argv[1]))["images"]
found = {}
for image in images:
    appearance = next((a["value"] for a in image.get("appearances", [])
                       if a.get("appearance") == "luminosity"), None)
    found[appearance] = image.get("filename")
problems = [f"{name or 'any'} entry names {found.get(name)}, not {file}"
            for name, file in expected.items() if found.get(name) != file]
print("; ".join(problems))
sys.exit(1 if problems else 0)
PY
)"; then
  fail "Contents.json: $output"
fi

exit $((failures > 0))
