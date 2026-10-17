#!/usr/bin/env bash
# Checks Swift formatting against .swift-format without changing files.
# Findings are warnings; --strict makes them errors (CI). Paths default to the app, test and
# engine sources. Usage: check-format.sh [--strict] [path ...]

source "$(dirname "$0")/lib.sh"

strict=()
if [[ "${1:-}" == --strict ]]; then
  strict=(--strict)
  shift
fi

paths=("$@")
if [[ ${#paths[@]} -eq 0 ]]; then
  for path in checkers/checkers checkers/checkersTests checkers/checkersUITests \
    checkers/CheckersEngine/Sources checkers/CheckersEngine/Tests; do
    [[ -d "$REPO_ROOT/$path" ]] && paths+=("$REPO_ROOT/$path")
  done
fi

xcrun swift-format lint \
  --configuration "$REPO_ROOT/.swift-format" \
  --recursive --parallel \
  ${strict[@]+"${strict[@]}"} \
  "${paths[@]}"
