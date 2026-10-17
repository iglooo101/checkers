#!/usr/bin/env bash
# Fails when the committed string catalog is missing strings the app uses, or keeps strings it no
# longer uses. It syncs a copy of the catalog with the strings the last build extracted, the way
# Xcode does, and compares. Usage: check-string-catalog.sh <catalog> <derived-data>

source "$(dirname "$0")/lib.sh"

catalog="$1"
derived_data="$2"

stringsdata=()
while IFS= read -r file; do
  stringsdata+=("$file")
done < <(find "$derived_data/Build/Intermediates.noindex" -path '*/checkers.build/Objects-normal/*' \
  -name '*.stringsdata' 2>/dev/null | sort)
if [[ ${#stringsdata[@]} -eq 0 ]]; then
  echo "error: no extracted strings found under $derived_data; build the app first." >&2
  exit 1
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
synced="$work/$(basename "$catalog")"
cp "$catalog" "$synced"
xcrun xcstringstool sync "$synced" --stringsdata "${stringsdata[@]}"

if cmp -s "$catalog" "$synced"; then
  echo "String catalog is up to date."
  exit 0
fi

python3 - "$catalog" "$synced" <<'PY'
import json
import sys

old = json.load(open(sys.argv[1]))["strings"]
new = json.load(open(sys.argv[2]))["strings"]
missing = sorted(set(new) - set(old))
stale = sorted(
    key for key, value in new.items()
    if value.get("extractionState") == "stale"
    and old.get(key, {}).get("extractionState") != "stale"
)
for key in missing:
    print(f"error: string catalog is missing '{key}'")
for key in stale:
    print(f"error: string catalog keeps unused '{key}'")
if not missing and not stale:
    print("error: string catalog differs from a fresh sync; open the project in Xcode and build.")
PY
echo "Fix: build in Xcode (it updates $catalog) and commit the catalog." >&2
exit 1
