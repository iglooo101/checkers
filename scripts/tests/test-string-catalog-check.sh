#!/usr/bin/env bash
# US5: the string catalog check fails on missing keys and passes on a complete catalog.

set -uo pipefail
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
failures=0

objects="$TMP/dd/Build/Intermediates.noindex/checkers.build/Debug-iphonesimulator/checkers.build/Objects-normal/arm64"
mkdir -p "$objects"
cat > "$objects/Sample.stringsdata" <<'JSON'
{
  "source": "/tmp/Sample.swift",
  "tables": {
    "Localizable": [
      { "comment": "", "key": "Hello", "location": { "startingColumn": 1, "startingLine": 1 } }
    ]
  },
  "version": 1
}
JSON

printf '{\n  "sourceLanguage" : "en",\n  "strings" : {\n\n  },\n  "version" : "1.0"\n}\n' > "$TMP/Localizable.xcstrings"
if output="$("$SCRIPTS/check-string-catalog.sh" "$TMP/Localizable.xcstrings" "$TMP/dd" 2>&1)"; then
  echo "  FAIL: a catalog missing 'Hello' should fail the check"
  failures=$((failures + 1))
elif [[ "$output" != *Hello* ]]; then
  echo "  FAIL: the failure should name the missing key 'Hello'"
  failures=$((failures + 1))
fi

xcrun xcstringstool sync "$TMP/Localizable.xcstrings" --stringsdata "$objects/Sample.stringsdata"
if ! "$SCRIPTS/check-string-catalog.sh" "$TMP/Localizable.xcstrings" "$TMP/dd" >/dev/null 2>&1; then
  echo "  FAIL: a complete catalog should pass the check"
  failures=$((failures + 1))
fi

exit $((failures > 0))
