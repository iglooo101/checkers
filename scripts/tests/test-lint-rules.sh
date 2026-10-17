#!/usr/bin/env bash
# US3: lint rules report the constitution's banned constructs as errors (contracts/lint-rules.md).

set -uo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib.sh"
set +e

FIXTURES="$REPO_ROOT/scripts/tests/lint-fixtures"
APP_CONFIG="$REPO_ROOT/checkers/.swiftlint.yml"
TEST_CONFIG="$REPO_ROOT/checkers/checkersTests/.swiftlint.yml"
failures=0

if ! SWIFTLINT="$(swiftlint_bin)"; then
  echo "  FAIL: SwiftLint binary not found"
  exit 1
fi

# Prints "<rule_id> <severity>" for each finding.
findings() {
  "$SWIFTLINT" lint --quiet --reporter json "$@" 2>/dev/null |
    python3 -c 'import json,sys; [print(v["rule_id"], v["severity"]) for v in json.load(sys.stdin)]'
}

expect_error() {
  local fixture="$1" rule="$2" output
  output="$(findings --config "$APP_CONFIG" "$FIXTURES/$fixture")"
  if ! grep -qx "$rule Error" <<<"$output"; then
    echo "  FAIL: $fixture should report '$rule' as an error"
    failures=$((failures + 1))
  fi
}

expect_error app/ForceUnwrap.swift force_unwrapping
expect_error app/ForceCast.swift force_cast
expect_error app/ForceTry.swift force_try
expect_error app/ImplicitlyUnwrapped.swift implicitly_unwrapped_optional
expect_error app/ObservableObject.swift no_observable_object
expect_error app/Published.swift no_observable_object
expect_error app/CombineImport.swift no_combine
expect_error app/DispatchQueue.swift no_legacy_concurrency
expect_error app/OperationQueue.swift no_legacy_concurrency
expect_error app/Thread.swift no_legacy_concurrency
expect_error app/Print.swift no_print
expect_error CheckersEngine/Sources/UIImport.swift engine_no_ui_imports

if grep -q ' Error$' <<<"$(findings --config "$APP_CONFIG" "$FIXTURES/app/Clean.swift")"; then
  echo "  FAIL: Clean.swift should have no errors"
  failures=$((failures + 1))
fi

if grep -q ' Error$' <<<"$(findings --config "$APP_CONFIG" --config "$TEST_CONFIG" "$FIXTURES/test-code")"; then
  echo "  FAIL: print( and force unwraps should be allowed in test code"
  failures=$((failures + 1))
fi

exit $((failures > 0))
