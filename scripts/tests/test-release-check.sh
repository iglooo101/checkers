#!/usr/bin/env bash
# US1 FR-002 FR-004, US4 FR-016 FR-022: the archive declares nothing collected, asks for nothing, and is Checkers 1.0 without non-exempt encryption (specs/008-release-1-0/contracts/release-tooling.md).

set -uo pipefail
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
GOOD="$SCRIPTS/tests/release-fixtures/good.xcarchive"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
failures=0

# A copy of the good archive to change; prints its path.
variant() {
  rm -rf "$TMP/$1.xcarchive"
  cp -R "$GOOD" "$TMP/$1.xcarchive"
  echo "$TMP/$1.xcarchive"
}

app() {
  echo "$1/Products/Applications/checkers.app"
}

# Expects `release.sh check` to fail on an archive and to name the problem.
expect_failure() {
  local archive="$1" text="$2" what="$3" output
  if output="$(bash "$SCRIPTS/release.sh" check "$archive" 2>&1)"; then
    echo "  FAIL: $what should fail the check"
    failures=$((failures + 1))
  elif [[ "$output" != *"$text"* ]]; then
    echo "  FAIL: the failure for $what should say \"$text\"; it printed: $output"
    failures=$((failures + 1))
  fi
}

if ! output="$(bash "$SCRIPTS/release.sh" check "$GOOD" 2>&1)"; then
  echo "  FAIL: the good archive should pass the check; it printed: $output"
  failures=$((failures + 1))
fi

archive="$(variant tracking)"
plutil -replace NSPrivacyTracking -bool YES "$(app "$archive")/PrivacyInfo.xcprivacy"
expect_failure "$archive" "declares tracking" "tracking"

archive="$(variant collected)"
plutil -insert NSPrivacyCollectedDataTypes.0 \
  -json '{"NSPrivacyCollectedDataType": "NSPrivacyCollectedDataTypeCrashData"}' \
  "$(app "$archive")/PrivacyInfo.xcprivacy"
expect_failure "$archive" "declares collected data" "a collected data type"

archive="$(variant domain)"
plutil -insert NSPrivacyTrackingDomains.0 -string "example.com" \
  "$(app "$archive")/PrivacyInfo.xcprivacy"
expect_failure "$archive" "declares tracking domains" "a tracking domain"

archive="$(variant category)"
plutil -insert NSPrivacyAccessedAPITypes.1 \
  -json '{"NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryFileTimestamp", "NSPrivacyAccessedAPITypeReasons": ["C617.1"]}' \
  "$(app "$archive")/PrivacyInfo.xcprivacy"
expect_failure "$archive" "NSPrivacyAccessedAPICategoryFileTimestamp" "a second required-reason API"

archive="$(variant reason)"
plutil -replace NSPrivacyAccessedAPITypes.0.NSPrivacyAccessedAPITypeReasons.0 -string "1C8F.1" \
  "$(app "$archive")/PrivacyInfo.xcprivacy"
expect_failure "$archive" "CA92.1" "a reason other than CA92.1"

archive="$(variant camera)"
plutil -insert NSCameraUsageDescription -string "To take photos." "$(app "$archive")/Info.plist"
expect_failure "$archive" "NSCameraUsageDescription" "a usage description"

archive="$(variant manifest)"
rm "$(app "$archive")/PrivacyInfo.xcprivacy"
expect_failure "$archive" "no privacy manifest" "a missing privacy manifest"

archive="$(variant name)"
plutil -replace CFBundleDisplayName -string "checkers" "$(app "$archive")/Info.plist"
expect_failure "$archive" "CFBundleDisplayName" "the lowercase target name under the icon"

archive="$(variant encryption)"
plutil -remove ITSAppUsesNonExemptEncryption "$(app "$archive")/Info.plist"
expect_failure "$archive" "ITSAppUsesNonExemptEncryption" "a missing encryption declaration"

archive="$(variant version)"
plutil -replace CFBundleShortVersionString -string "1.1" "$(app "$archive")/Info.plist"
expect_failure "$archive" "CFBundleShortVersionString" "a version other than 1.0"

exit $((failures > 0))
