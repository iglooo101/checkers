#!/usr/bin/env bash
# Builds, checks, uploads and records release builds (specs/008-release-1-0/contracts/
# release-tooling.md).
# Usage:
#   scripts/release.sh archive <build>   archive HEAD in Release with that build number, then check
#                                        it; only from a clean tree whose CI gate passed, with a
#                                        number higher than every build in release/builds.md
#   scripts/release.sh check <archive>   the archived app declares nothing collected, no tracking,
#                                        only the user-defaults API (CA92.1), asks for nothing, and
#                                        is Checkers 1.0 without non-exempt encryption
#   scripts/release.sh upload <archive>  upload it to App Store Connect with the key in ../secrets,
#                                        then record its build as uploaded
#   scripts/release.sh record <build> <state> [note]
#                                        add the build's row or move its state forward
#   scripts/release.sh submit-check <build>
#                                        the build may be submitted: the latest, processed, and
#                                        every release checklist item passed or accepted on it
# RELEASE_REPO (default: the repository root) is the git repository whose HEAD, tree and
# release/builds.md are used; RELEASE_SECRETS (default: ../secrets) holds the key;
# RELEASE_DRY_RUN=1 prints each xcodebuild command instead of running it. The tests set all three.

source "$(dirname "$0")/lib.sh"

RELEASE_DIR="$REPO_ROOT/.build/Release"
RELEASE_REPO="${RELEASE_REPO:-$REPO_ROOT}"
RELEASE_SECRETS="${RELEASE_SECRETS:-$REPO_ROOT/../secrets}"
BUILDS="$RELEASE_REPO/release/builds.md"
CHECKLIST="$RELEASE_REPO/specs/008-release-1-0/checklists/release.md"

usage() {
  echo "Usage: scripts/release.sh archive <build> | check <archive> | upload <archive> |" \
    "record <build> <state> [note] | submit-check <build>" >&2
  exit 2
}

# Stops with a sentence.
stop() {
  echo "$1" >&2
  exit 1
}

# Runs a command, or only prints it when RELEASE_DRY_RUN is 1.
run() {
  if [[ "${RELEASE_DRY_RUN:-}" == 1 ]]; then
    echo "$*"
  else
    "$@"
  fi
}

# Reads and changes release/builds.md (data model, "Build record"): `highest` prints the highest
# build number (0 for none); `record <build> <state> <commit> <date> [note]` adds the build's row
# or moves its state forward, and stops with a sentence if it cannot.
builds() {
  python3 -I - "$BUILDS" "$@" <<'PY'
import re, sys
from pathlib import Path

STATES = ["uploaded", "processed", "TestFlight internal", "external", "submitted", "approved"]
path, command, arguments = Path(sys.argv[1]), sys.argv[2], sys.argv[3:]
lines = path.read_text().splitlines()
rows = {}
for index, line in enumerate(lines):
    cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
    if line.startswith("|") and len(cells) == 5 and re.fullmatch(r"\d+", cells[0]):
        rows[int(cells[0])] = (index, cells)
highest = max(rows, default=0)

if command == "highest":
    print(highest)
    sys.exit(0)

build, state, commit, date = int(arguments[0]), arguments[1], arguments[2], arguments[3]
note = arguments[4] if len(arguments) > 4 else None
if state not in STATES and state != "rejected":
    sys.exit(f"\"{state}\" is not a state; use one of: {', '.join(STATES)}, rejected.")
if note is not None and "|" in note:
    sys.exit("A note cannot contain \"|\".")
if build in rows:
    index, cells = rows[build]
    current = cells[3]
    if current == "rejected":
        sys.exit(f"Build {build} was rejected; a new build gets a new number.")
    if state != "rejected" and STATES.index(state) < STATES.index(current):
        sys.exit(f"Build {build} is {current}; it cannot move backward to {state}.")
    cells[3] = state
    if note is not None:
        cells[4] = note
    lines[index] = "| " + " | ".join(cells) + " |"
else:
    if build <= highest:
        sys.exit(f"Build {build} is not higher than build {highest} in release/builds.md.")
    lines.append(f"| {build} | {commit} | {date} | {state} | {note or ''} |")
path.write_text("\n".join(lines) + "\n")
print(f"Build {build}: {state}.")
PY
}

# The guards before an archive (FR-023): a clean tree, a passed CI gate for HEAD, a new number.
archive_guards() {
  local build="$1" sha gate
  if [[ -n "$(git -C "$RELEASE_REPO" status --porcelain)" ]]; then
    stop "The working tree has uncommitted changes; archive only a committed, checked commit."
  fi
  sha="$(git -C "$RELEASE_REPO" rev-parse HEAD)"
  export GH_TOKEN="${GH_TOKEN:-$(cat "$REPO_ROOT/../secrets/github.txt" 2>/dev/null || true)}"
  gate="$(gh api "repos/iglooo101/checkers/commits/$sha/check-runs" --jq \
    '[.check_runs[] | select(.name == "CI gate")] | sort_by(.completed_at) | last | .conclusion' \
    2>/dev/null || true)"
  if [[ "$gate" != success ]]; then
    stop "CI gate has not passed for $sha (${gate:-no result}); push it and wait for CI first."
  fi
  local highest
  highest="$(builds highest)"
  if ((build <= highest)); then
    stop "Build $build is not higher than build $highest in release/builds.md."
  fi
}

# Archives the checked-out commit for any iPhone, with the build number given; the project keeps
# CURRENT_PROJECT_VERSION = 1, so an upload needs no commit (research R14).
archive() {
  local build="${1:-}"
  [[ "$build" =~ ^[0-9]+$ ]] || usage
  archive_guards "$build"
  local path="$RELEASE_DIR/Checkers-1.0-$build.xcarchive"
  [[ "${RELEASE_DRY_RUN:-}" == 1 ]] || rm -rf "$path"
  run xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination generic/platform=iOS \
    -archivePath "$path" \
    -skipPackagePluginValidation \
    -allowProvisioningUpdates \
    CURRENT_PROJECT_VERSION="$build"
  [[ "${RELEASE_DRY_RUN:-}" == 1 ]] || check "$path"
}

# Uploads an archive with the App Store Connect key (FR-024): the key's ID and issuer are passed
# only as xcodebuild arguments and replaced in everything printed; then records the build.
upload() {
  local path="${1:-}"
  [[ -n "$path" ]] || usage
  [[ -d "$path" ]] || stop "No archive at $path."
  local settings="$RELEASE_SECRETS/appstoreconnect.txt"
  [[ -r "$settings" ]] || stop "No $settings: create the App Store Connect key first (T044)."
  local key_id issuer_id
  key_id="$(sed -n 's/^KEY_ID=//p' "$settings")"
  issuer_id="$(sed -n 's/^ISSUER_ID=//p' "$settings")"
  [[ -n "$key_id" && -n "$issuer_id" ]] || stop "$settings needs a KEY_ID= and an ISSUER_ID= line."
  local key="$RELEASE_SECRETS/AuthKey_$key_id.p8"
  [[ -r "$key" ]] || stop "No AuthKey_<KEY_ID>.p8 for that KEY_ID in $RELEASE_SECRETS."
  [[ "$(stat -f %Lp "$key")" == 600 ]] \
    || stop "The AuthKey file must be readable by its owner only: chmod 600 it."
  local build
  build="$(plutil -extract CFBundleVersion raw "$(find "$path/Products/Applications" \
    -maxdepth 1 -name '*.app' | head -1)/Info.plist")"
  run xcodebuild -exportArchive \
    -archivePath "$path" \
    -exportOptionsPlist "$REPO_ROOT/release/ExportOptions.plist" \
    -exportPath "$RELEASE_DIR/export" \
    -allowProvisioningUpdates \
    -authenticationKeyPath "$key" \
    -authenticationKeyID "$key_id" \
    -authenticationKeyIssuerID "$issuer_id" 2>&1 \
    | sed -e "s/$key_id/<key id>/g" -e "s/$issuer_id/<issuer id>/g"
  [[ "${RELEASE_DRY_RUN:-}" == 1 ]] || record "$build" uploaded
}

# Adds a build's row to release/builds.md (HEAD's commit, today) or moves its state forward.
record() {
  local build="${1:-}" state="${2:-}"
  [[ "$build" =~ ^[0-9]+$ && -n "$state" ]] || usage
  local commit
  commit="$(git -C "$RELEASE_REPO" rev-parse HEAD)"
  if [[ $# -ge 3 ]]; then
    builds record "$build" "$state" "$commit" "$(date +%F)" "$3"
  else
    builds record "$build" "$state" "$commit" "$(date +%F)"
  fi
}

# What Xcode's privacy report summarizes, checked on the archived app (research R8).
check() {
  local path="${1:-}"
  [[ -n "$path" ]] || usage
  python3 -I - "$path" <<'PY'
import plistlib, sys
from pathlib import Path

archive = Path(sys.argv[1])
apps = sorted((archive / "Products" / "Applications").glob("*.app"))
if not apps:
    print(f"No app in {archive}.")
    sys.exit(1)
app = apps[0]
problems = []

manifests = sorted(app.rglob("*.xcprivacy"))
if not manifests:
    problems.append("The app has no privacy manifest.")
for manifest in manifests:
    name = manifest.relative_to(app).as_posix()
    values = plistlib.loads(manifest.read_bytes())
    if values.get("NSPrivacyTracking", False):
        problems.append(f"{name} declares tracking.")
    if values.get("NSPrivacyTrackingDomains"):
        problems.append(f"{name} declares tracking domains.")
    if values.get("NSPrivacyCollectedDataTypes"):
        problems.append(f"{name} declares collected data.")
    for api in values.get("NSPrivacyAccessedAPITypes", []):
        category = api.get("NSPrivacyAccessedAPIType")
        reasons = api.get("NSPrivacyAccessedAPITypeReasons", [])
        if category != "NSPrivacyAccessedAPICategoryUserDefaults":
            problems.append(f"{name} declares the required-reason API {category}.")
        elif reasons != ["CA92.1"]:
            problems.append(f"{name} gives the reasons {', '.join(reasons)} for user defaults; "
                            "only CA92.1 is expected.")

info = plistlib.loads((app / "Info.plist").read_bytes())
for key in sorted(info):
    if key.endswith("UsageDescription"):
        problems.append(f"Info.plist asks for a permission: {key}.")
if info.get("CFBundleDisplayName") != "Checkers":
    problems.append(f"Info.plist's CFBundleDisplayName is {info.get('CFBundleDisplayName')!r}; "
                    "the name under the icon must be 'Checkers'.")
if info.get("ITSAppUsesNonExemptEncryption") is not False:
    problems.append(f"Info.plist's ITSAppUsesNonExemptEncryption is "
                    f"{info.get('ITSAppUsesNonExemptEncryption')!r}; it must be false.")
if info.get("CFBundleShortVersionString") != "1.0":
    problems.append(f"Info.plist's CFBundleShortVersionString is "
                    f"{info.get('CFBundleShortVersionString')!r}; this release is 1.0.")

if problems:
    print(f"Archive check failed for {app.name}:")
    for problem in problems:
        print(f"- {problem}")
    sys.exit(1)
print(f"Archive check passed for {app.name}: no tracking, no tracking domains, no collected "
      "data, user defaults with CA92.1 only, no permission asked, Checkers 1.0 without "
      "non-exempt encryption.")
PY
}

# The submission gate (FR-028, research R16): the build is the latest row and processed, and
# every release checklist item is passed or accepted (with a reason) on it, or on an earlier
# build when each later build's notes say "cannot affect" that item.
submit_check() {
  local build="${1:-}"
  [[ "$build" =~ ^[0-9]+$ ]] || usage
  python3 -I - "$BUILDS" "$CHECKLIST" "$build" <<'PY'
import re, sys
from pathlib import Path

builds_path, checklist_path, build = Path(sys.argv[1]), Path(sys.argv[2]), int(sys.argv[3])


def rows(path, first):
    """The table rows whose first cell matches `first`, as lists of stripped cells."""
    found = []
    for line in path.read_text().splitlines():
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if line.startswith("|") and re.fullmatch(first, cells[0]):
            found.append(cells)
    return found


builds = {int(cells[0]): cells for cells in rows(builds_path, r"\d+")}
problems = []
if build not in builds:
    sys.exit(f"Build {build} is not in release/builds.md.")
if build != max(builds):
    problems.append(f"Build {build} is not the latest build; build {max(builds)} is.")
state = builds[build][3]
if state == "rejected":
    problems.append(f"Build {build} was rejected; submit a new build.")
elif state == "uploaded":
    problems.append(f"Build {build} is only uploaded; it must be processed first.")


def unaffected(notes):
    """The checklist IDs a build's notes say it cannot affect."""
    named = set()
    for phrase in re.findall(r"cannot affect ([^.;]*)", notes):
        named.update(re.findall(r"RC-\d+", phrase))
    return named


items = rows(checklist_path, r"RC-\d+")
if not items:
    problems.append("The release checklist has no items.")
for cells in items:
    item, run_on, result, reason = cells[0], cells[3], cells[4], cells[5]
    if not result:
        problems.append(f"{item} is open.")
        continue
    if result == "failed":
        problems.append(f"{item} failed on build {run_on}.")
        continue
    if result not in ("passed", "accepted"):
        problems.append(f"{item} has the result \"{result}\"; use passed, failed or accepted.")
        continue
    if result == "accepted" and not reason:
        problems.append(f"{item} is accepted without a reason.")
    if not re.fullmatch(r"\d+", run_on) or int(run_on) not in builds or int(run_on) > build:
        problems.append(f"{item} names no recorded build up to {build}.")
        continue
    for later in sorted(number for number in builds if int(run_on) < number <= build):
        if item not in unaffected(builds[later][4]):
            problems.append(f"{item} was run on build {run_on}, and build {later}'s notes do not "
                            f"say it cannot affect {item}.")
            break

if problems:
    print(f"Build {build} cannot be submitted:")
    for problem in problems:
        print(f"- {problem}")
    sys.exit(1)
print(f"Build {build} can be submitted: it is the latest, {state}, and every one of the "
      f"{len(items)} release checklist items is passed or accepted for it.")
PY
}

case "${1:-}" in
  archive) archive "${2:-}" ;;
  check) check "${2:-}" ;;
  upload) upload "${2:-}" ;;
  record) shift && record "$@" ;;
  submit-check) submit_check "${2:-}" ;;
  *) usage ;;
esac
