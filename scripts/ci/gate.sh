#!/usr/bin/env bash
# Decides the required "CI gate" check. See contracts/ci-gate.md, "Outcomes".
# Usage: gate.sh <changes job result> <code flag: true|false> <build-and-test job result>
#        <engine-strength job result>

set -euo pipefail

if [[ $# -ne 4 ]]; then
  echo "CI gate failed: expected 4 arguments, got $#."
  exit 1
fi

changes_result="$1"
code="$2"
build_result="$3"
strength_result="$4"

if [[ "$changes_result" != success ]]; then
  echo "CI gate failed: classifying the push ended with '$changes_result'."
  exit 1
fi

if [[ "$code" == false && "$build_result" == skipped && "$strength_result" == skipped ]]; then
  echo "CI gate passed: documentation-only push, build, tests and strength matches skipped."
  exit 0
fi

if [[ "$code" == true && "$build_result" == success && "$strength_result" == success ]]; then
  echo "CI gate passed: build, tests and strength matches succeeded."
  exit 0
fi

echo "CI gate failed: code=$code, build-and-test ended with '$build_result'," \
  "engine-strength with '$strength_result'."
exit 1
