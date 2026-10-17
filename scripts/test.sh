#!/usr/bin/env bash
# Runs a test plan on the iPhone simulator: the blocking plan "checkers" (unit, UI and
# engine tests) by default, or another plan named by TEST_PLAN (for example Performance).
# Extra arguments are passed to xcodebuild as build settings, for example:
#   scripts/test.sh SWIFT_TREAT_WARNINGS_AS_ERRORS=YES

source "$(dirname "$0")/lib.sh"

TEST_PLAN="${TEST_PLAN:-checkers}"
RESULT_BUNDLE="$RESULTS_DIR/$TEST_PLAN.xcresult"
mkdir -p "$RESULTS_DIR"
rm -rf "$RESULT_BUNDLE"

xcodebuild test \
  "${XCODEBUILD_FLAGS[@]}" \
  -testPlan "$TEST_PLAN" \
  -resultBundlePath "$RESULT_BUNDLE" \
  "$@"
