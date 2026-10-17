#!/usr/bin/env bash
# Project tools: update_plan.py replaces only the generated sections of EXECUTION_PLAN.md.

set -uo pipefail
PROJECT="$(cd "$(dirname "$0")/../project" && pwd)"

python3 - "$PROJECT" <<'PY'
import sys

sys.path.insert(0, sys.argv[1])
from update_plan import replace_generated  # noqa: E402

failures = 0


def check(condition, message):
    global failures
    if not condition:
        print(f"  FAIL: {message}")
        failures += 1


text = (
    "# Plan\n\nHand-written intro.\n\n"
    "<!-- BEGIN GENERATED: progress -->\nold table\n<!-- END GENERATED: progress -->\n\n"
    "## Risks\n\nHand-written risk.\n"
)
updated = replace_generated(text, "progress", "new table")
check("new table" in updated, "generated content is replaced")
check("old table" not in updated, "old generated content is removed")
check("Hand-written intro." in updated and "Hand-written risk." in updated,
      "hand-written content outside the markers is kept")
check(updated.count("<!-- BEGIN GENERATED: progress -->") == 1
      and updated.count("<!-- END GENERATED: progress -->") == 1, "markers are kept once")
check(replace_generated(updated, "progress", "new table") == updated,
      "running twice with the same content changes nothing")

try:
    replace_generated(text, "backlog", "x")
    check(False, "a missing section raises an error")
except ValueError:
    pass

sys.exit(1 if failures else 0)
PY
