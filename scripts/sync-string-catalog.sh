#!/usr/bin/env bash
# Updates the string catalog in place from the strings the last build extracted, the way Xcode
# does when it builds. Command-line builds never update the catalog themselves, so run this after
# adding or removing user-facing strings and commit the result.
# Usage: sync-string-catalog.sh [catalog] [derived-data]

source "$(dirname "$0")/lib.sh"

catalog="${1:-$REPO_ROOT/checkers/checkers/Localizable.xcstrings}"
derived_data="${2:-$DERIVED_DATA}"

stringsdata=()
while IFS= read -r file; do
  stringsdata+=("$file")
done < <(find "$derived_data/Build/Intermediates.noindex" -path '*/checkers.build/Objects-normal/*' \
  -name '*.stringsdata' 2>/dev/null | sort)
if [[ ${#stringsdata[@]} -eq 0 ]]; then
  echo "error: no extracted strings found under $derived_data; build the app first." >&2
  exit 1
fi

before="$(mktemp)"
trap 'rm -f "$before"' EXIT
cp "$catalog" "$before"
xcrun xcstringstool sync "$catalog" --stringsdata "${stringsdata[@]}"

python3 - "$before" "$catalog" <<'PY'
import json
import sys

old = json.load(open(sys.argv[1]))["strings"]
catalog = json.load(open(sys.argv[2]))
new = catalog["strings"]
added = sorted(set(new) - set(old))
stale = sorted(key for key, value in new.items() if value.get("extractionState") == "stale")
for key in added:
    print(f"added: {key}")
for key in stale:
    print(f"removed (no longer used): {key}")
    del new[key]
if stale:
    json.dump(catalog, open(sys.argv[2], "w"), ensure_ascii=False, indent=2)
if not added and not stale:
    print("String catalog already matches the last build.")
PY

# A second sync writes the pruned catalog back in Xcode's own format, which CI compares byte for
# byte (scripts/check-string-catalog.sh).
xcrun xcstringstool sync "$catalog" --stringsdata "${stringsdata[@]}"
