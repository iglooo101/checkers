#!/usr/bin/env bash
# Decides the required "CI gate" check. See contracts/ci-gate.md, "Outcomes".
# Usage: gate.sh <changes job result> <code flag: true|false> <build-and-test job result>

set -euo pipefail

changes_result="$1"
code="$2"
build_result="$3"

if [[ "$changes_result" != success ]]; then
  echo "CI gate failed: classifying the push ended with '$changes_result'."
  exit 1
fi

if [[ "$code" == false && "$build_result" == skipped ]]; then
  echo "CI gate passed: documentation-only push, build and tests skipped."
  exit 0
fi

if [[ "$code" == true && "$build_result" == success ]]; then
  echo "CI gate passed: build and tests succeeded."
  exit 0
fi

echo "CI gate failed: code=$code, build-and-test ended with '$build_result'."
exit 1
