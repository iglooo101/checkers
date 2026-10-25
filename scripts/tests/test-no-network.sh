#!/usr/bin/env bash
# US1 FR-001 FR-003: no networking, web, account, analytics or advertising API (specs/008-release-1-0/contracts/release-tooling.md).

set -uo pipefail
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
failures=0

# Networking and web APIs, and the frameworks for accounts, tracking, advertising, purchases,
# cloud data and online games: the app uses none of them (FRD FR-PRIV-01).
FORBIDDEN='URLSession|URLRequest|NWConnection|NWPathMonitor|import Network|import WebKit|WKWebView|CFNetwork|CFStream|Socket|import AuthenticationServices|import AppTrackingTransparency|import AdSupport|import StoreKit|import CloudKit|import GameKit|ASIdentifierManager|NSAppTransportSecurity'

# Prints every match in the app's and the engine's sources and the project's build settings
# under the root $1.
matches() {
  local root="$1" paths=()
  for path in checkers/checkers checkers/CheckersEngine/Sources \
    checkers/checkers.xcodeproj/project.pbxproj; do
    [[ -e "$root/$path" ]] && paths+=("$root/$path")
  done
  [[ ${#paths[@]} -gt 0 ]] || return 0
  grep -rnE --include='*.swift' --include='*.pbxproj' --include='*.plist' "$FORBIDDEN" \
    "${paths[@]}" | sed "s|^$root/||"
}

found="$(matches "$REPO")"
if [[ -n "$found" ]]; then
  echo "$found" | sed 's/^/  FAIL: /'
  failures=$((failures + 1))
fi

# The check itself: a planted request in the app's sources and an ATS exception in the project
# must both be found.
mkdir -p "$TMP/checkers/checkers/Features/Probe" "$TMP/checkers/checkers.xcodeproj"
printf 'let task = URLSession.shared.dataTask(with: url)\n' \
  > "$TMP/checkers/checkers/Features/Probe/Probe.swift"
printf 'INFOPLIST_KEY_NSAppTransportSecurity = YES;\n' \
  > "$TMP/checkers/checkers.xcodeproj/project.pbxproj"
planted="$(matches "$TMP")"
for expected in "Probe.swift" "project.pbxproj"; do
  if [[ "$planted" != *"$expected"* ]]; then
    echo "  FAIL: a planted use was not found in $expected"
    failures=$((failures + 1))
  fi
done

exit $((failures > 0))
