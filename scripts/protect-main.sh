#!/usr/bin/env bash
# Applies branch protection to main (contracts/ci-gate.md): commits land only when the "CI gate"
# check from GitHub Actions passed for that exact commit; no pull requests are required; the rule
# applies to administrators too; force pushes and deletion are blocked.
# Needs a token with the repo scope in GH_TOKEN (see HANDOFF.md).

set -euo pipefail

GITHUB_ACTIONS_APP_ID=15368

gh api --method PUT repos/iglooo101/checkers/branches/main/protection --input - <<JSON
{
  "required_status_checks": {
    "strict": false,
    "checks": [{ "context": "CI gate", "app_id": $GITHUB_ACTIONS_APP_ID }]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
JSON
