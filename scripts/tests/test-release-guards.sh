#!/usr/bin/env bash
# US5 FR-023: only checked commits become builds, in order (specs/008-release-1-0/contracts/release-tooling.md).
# US6 FR-028: only a fully checked build is submitted.

set -uo pipefail
SCRIPTS="$(cd "$(dirname "$0")/.." && pwd)"
FIXTURES="$SCRIPTS/tests/release-fixtures"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
failures=0

fail() {
  echo "  FAIL: $1"
  failures=$((failures + 1))
}

# Stubs first on PATH: gh answers release.sh's question about a commit's CI gate, and xcodebuild
# only notes its arguments, so no test can start a real build even if the dry run failed.
mkdir -p "$TMP/bin"
printf '#!/usr/bin/env bash\necho "${STUB_GATE:-}"\n' >"$TMP/bin/gh"
printf '#!/usr/bin/env bash\necho "$*" >>"%s"\n' "$TMP/xcodebuild.log" >"$TMP/bin/xcodebuild"
chmod +x "$TMP/bin/gh" "$TMP/bin/xcodebuild"
export PATH="$TMP/bin:$PATH"

# A new git repository holding a fixture builds.md and, if named, a fixture release checklist,
# committed; sets $repo.
make_repo() {
  repo="$TMP/repo-$1"
  rm -rf "$repo"
  mkdir -p "$repo/release" "$repo/specs/008-release-1-0/checklists"
  cp "$FIXTURES/$2" "$repo/release/builds.md"
  if [[ -n "${3:-}" ]]; then
    cp "$FIXTURES/$3" "$repo/specs/008-release-1-0/checklists/release.md"
  fi
  git -C "$repo" init -q
  git -C "$repo" add -A
  git -C "$repo" -c user.name=Test -c user.email=test@example.com commit -q -m Fixture
}

# Runs release.sh against $repo in dry-run mode; sets $output and $status.
release() {
  rm -f "$TMP/xcodebuild.log"
  output="$(RELEASE_REPO="$repo" RELEASE_DRY_RUN=1 bash "$SCRIPTS/release.sh" "$@" 2>&1)"
  status=$?
}

# Expects release.sh to fail, to say why and, for archive, never to reach xcodebuild.
expect_refusal() {
  local text="$1" what="$2"
  shift 2
  release "$@"
  if [[ $status -eq 0 ]]; then
    fail "$what should be refused; it printed: $output"
  elif [[ "$output" != *"$text"* ]]; then
    fail "the refusal of $what should say \"$text\"; it printed: $output"
  elif [[ "$output" == *"xcodebuild"* || -e "$TMP/xcodebuild.log" ]]; then
    fail "$what reached xcodebuild: $output"
  fi
}

# The State cell of a build's row in $repo's builds.md.
state_of() {
  awk -F '|' -v build="$1" '$2 ~ "^ *" build " *$" { gsub(/^ +| +$/, "", $5); print $5 }' \
    "$repo/release/builds.md"
}

# Archive: a clean tree, a passed CI gate and a higher build number reach xcodebuild.
make_repo archive builds.md
STUB_GATE=success release archive 3
if [[ $status -ne 0 || "$output" != *"xcodebuild archive"* \
  || "$output" != *"CURRENT_PROJECT_VERSION=3"* ]]; then
  fail "a checked commit should be archived as build 3; it printed: $output"
fi
STUB_GATE=failure expect_refusal "CI gate" "a commit whose CI gate failed" archive 3
STUB_GATE="" expect_refusal "CI gate" "a commit without a CI gate" archive 3
STUB_GATE=success expect_refusal "not higher" "build 2, already recorded" archive 2
STUB_GATE=success expect_refusal "not higher" "build 1, lower than build 2" archive 1
echo "changed" >>"$repo/release/builds.md"
STUB_GATE=success expect_refusal "uncommitted" "a tree with a changed file" archive 3
git -C "$repo" checkout -q -- release/builds.md
touch "$repo/new-file"
STUB_GATE=success expect_refusal "uncommitted" "a tree with a new file" archive 3

# Record: rows in order, states forward only, a rejected build stays rejected.
make_repo record builds.md
release record 3 uploaded "Fixes the board's frame."
if [[ $status -ne 0 || "$(state_of 3)" != uploaded ]]; then
  fail "record 3 uploaded should add build 3; it printed: $output"
fi
if ! grep -q "| 3 | $(git -C "$repo" rev-parse HEAD) | $(date +%F) | uploaded | Fixes the board's frame. |" \
  "$repo/release/builds.md"; then
  fail "build 3's row should hold HEAD, today and the note: $(cat "$repo/release/builds.md")"
fi
release record 3 processed
[[ $status -eq 0 && "$(state_of 3)" == processed ]] || fail "build 3 should move to processed: $output"
release record 3 "TestFlight internal"
[[ $status -eq 0 && "$(state_of 3)" == "TestFlight internal" ]] \
  || fail "build 3 should move to TestFlight internal: $output"
expect_refusal "backward" "moving build 3 back to processed" record 3 processed
[[ "$(state_of 3)" == "TestFlight internal" ]] || fail "a refused move should change nothing"
expect_refusal "not higher" "a new build 0" record 0 uploaded
expect_refusal "not a state" "an unknown state" record 3 shipped
release record 2 rejected "Crashed at launch."
[[ $status -eq 0 && "$(state_of 2)" == rejected ]] || fail "build 2 should be rejected: $output"
expect_refusal "rejected" "moving a rejected build on" record 2 submitted

# Upload: the key must exist and be readable by its owner only; its values are never printed.
make_repo upload builds.md
secrets="$TMP/secrets"
mkdir -p "$secrets"
RELEASE_SECRETS="$secrets" expect_refusal "appstoreconnect.txt" \
  "an upload without the key's settings" upload "$FIXTURES/good.xcarchive"
printf 'KEY_ID=TESTKEY123\nISSUER_ID=test-issuer-0000\n' >"$secrets/appstoreconnect.txt"
RELEASE_SECRETS="$secrets" expect_refusal "AuthKey" "an upload without the key file" \
  upload "$FIXTURES/good.xcarchive"
echo "not a real key" >"$secrets/AuthKey_TESTKEY123.p8"
chmod 644 "$secrets/AuthKey_TESTKEY123.p8"
RELEASE_SECRETS="$secrets" expect_refusal "600" "a key file others can read" \
  upload "$FIXTURES/good.xcarchive"
chmod 600 "$secrets/AuthKey_TESTKEY123.p8"
RELEASE_SECRETS="$secrets" release upload "$FIXTURES/good.xcarchive"
if [[ $status -ne 0 || "$output" != *"xcodebuild -exportArchive"* ]]; then
  fail "an upload with the key should reach xcodebuild; it printed: $output"
elif [[ "$output" == *TESTKEY123* || "$output" == *test-issuer-0000* ]]; then
  fail "the upload printed the key's values: $output"
fi

# Submit-check: every item passed or accepted on the build, or on an earlier build that every
# later build's notes say they cannot affect; the build is the latest and processed.
make_repo submit submit-builds.md submit-release.md
checklist="$repo/specs/008-release-1-0/checklists/release.md"
release submit-check 2
[[ $status -eq 0 ]] || fail "build 2 should be ready to submit; it printed: $output"
expect_refusal "not the latest" "submitting build 1 while build 2 exists" submit-check 1

# Changes one fixture file of $repo for one case, runs it, and puts the file back.
expect_refusal_with() {
  local file="$1" expression="$2"
  shift 2
  cp "$file" "$TMP/saved"
  sed -i '' "$expression" "$file"
  expect_refusal "$@"
  cp "$TMP/saved" "$file"
}
expect_refusal_with "$checklist" 's/| 2 | passed | |/| | | |/' "RC-02 is open" "an open item" \
  submit-check 2
expect_refusal_with "$checklist" 's/| 2 | passed | |/| 2 | failed | |/' "RC-02 failed" \
  "a failed item" submit-check 2
expect_refusal_with "$checklist" 's/| accepted | The simulator stood in for an iPad. |/| accepted | |/' \
  "RC-04 is accepted without a reason" "an item accepted without a reason" submit-check 2
expect_refusal_with "$repo/release/builds.md" 's/| external |/| uploaded |/' "processed" \
  "a build not yet processed" submit-check 2
expect_refusal_with "$repo/release/builds.md" 's/cannot affect RC-01, RC-03/cannot affect RC-03/' \
  "RC-01" "an item from build 1 that build 2 may affect" submit-check 2
expect_refusal_with "$repo/release/builds.md" 's/| external |/| rejected |/' "rejected" \
  "a rejected build" submit-check 2
release submit-check 2
[[ $status -eq 0 ]] || fail "the fixtures should be back as they were; it printed: $output"

exit $((failures > 0))
