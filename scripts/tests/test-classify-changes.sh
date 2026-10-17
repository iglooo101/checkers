#!/usr/bin/env bash
# US2: classify pushes as docs-only or code (contracts/ci-gate.md, "Classification of a push").

set -uo pipefail
CLASSIFY="$(cd "$(dirname "$0")/.." && pwd)/ci/classify-changes.sh"
failures=0

expect() {
  local expected="$1" files="$2" actual
  actual="$(printf '%b' "$files" | "$CLASSIFY")"
  if [[ "$actual" != "$expected" ]]; then
    echo "  FAIL: [${files//\\n/, }] -> '$actual', expected '$expected'"
    failures=$((failures + 1))
  fi
}

expect docs 'FRD.md\n'
expect docs 'specs/001-project-foundation/plan.md\nHANDOFF.md\n'
expect docs ''
expect code 'checkers/checkers/ContentView.swift\n'
expect code 'checkers/checkers.xcodeproj/project.pbxproj\n'
expect code '.gitignore\n'
expect code '.github/workflows/ci.yml\n'
expect code 'scripts/test.sh\n'
expect code 'EXECUTION_PLAN.md\ncheckers/checkers/ContentView.swift\n'
expect code 'README.markdown\n'

exit $((failures > 0))
