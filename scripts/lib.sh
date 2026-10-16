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
