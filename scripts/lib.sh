#!/usr/bin/env bash
# Shared settings for the project scripts. Source it; do not run it.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$REPO_ROOT/checkers/checkers.xcodeproj"
SCHEME="checkers"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=iPhone 17}"
DERIVED_DATA="${DERIVED_DATA:-$REPO_ROOT/.build/DerivedData}"
RESULTS_DIR="$REPO_ROOT/.build/TestResults"

# Flags every xcodebuild call needs. The SwiftLint build tool plugin would otherwise
# wait for an interactive trust prompt.
XCODEBUILD_FLAGS=(
  -project "$PROJECT"
  -scheme "$SCHEME"
  -destination "$DESTINATION"
  -derivedDataPath "$DERIVED_DATA"
  -skipPackagePluginValidation
)

# Prints the path of the SwiftLint executable from the SwiftLintPlugins package (the version
# pinned in Package.resolved), resolving packages first if needed.
swiftlint_bin() {
  local artifacts="$DERIVED_DATA/SourcePackages/artifacts/swiftlintplugins/SwiftLintBinary"
  if [[ ! -d "$artifacts" ]]; then
    xcodebuild -resolvePackageDependencies "${XCODEBUILD_FLAGS[@]}" >/dev/null
  fi
  local binary
  binary="$(find "$artifacts" -path '*macos*' -name swiftlint -type f -perm -u+x | head -1)"
  [[ -n "$binary" ]] || return 1
  echo "$binary"
}
