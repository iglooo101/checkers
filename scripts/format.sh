#!/usr/bin/env bash
# Formats Swift sources in place with .swift-format. Paths default to the app, test and engine
# sources. Usage: format.sh [path ...]

source "$(dirname "$0")/lib.sh"

paths=("$@")
if [[ ${#paths[@]} -eq 0 ]]; then
  for path in checkers/checkers checkers/checkersTests checkers/checkersUITests \
    checkers/CheckersEngine/Sources checkers/CheckersEngine/Tests; do
    [[ -d "$REPO_ROOT/$path" ]] && paths+=("$REPO_ROOT/$path")
  done
fi

xcrun swift-format format \
  --configuration "$REPO_ROOT/.swift-format" \
  --in-place --recursive --parallel \
  "${paths[@]}"
