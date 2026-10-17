#!/usr/bin/env bash
# Reads changed file paths (one per line) on stdin and prints "docs" when every path ends in
# .md (or there are none), otherwise "code". See contracts/ci-gate.md.

set -euo pipefail

while IFS= read -r path || [[ -n "$path" ]]; do
  [[ -z "$path" ]] && continue
  if [[ "$path" != *.md ]]; then
    echo code
    exit 0
  fi
done

echo docs
