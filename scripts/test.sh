#!/usr/bin/env bash
# Runs the blocking test plan (unit, UI and engine tests) on the iPhone simulator.
# Extra arguments are passed to xcodebuild as build settings, for example:
#   scripts/test.sh SWIFT_TREAT_WARNINGS_AS_ERRORS=YES

source "$(dirname "$0")/lib.sh"

RESULT_BUNDLE="$RESULTS_DIR/checkers.xcresult"
mkdir -p "$RESULTS_DIR"
rm -rf "$RESULT_BUNDLE"

xcodebuild test \
  "${XCODEBUILD_FLAGS[@]}" \
  -testPlan checkers \
  -resultBundlePath "$RESULT_BUNDLE" \
  "$@"
