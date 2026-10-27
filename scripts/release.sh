#!/usr/bin/env bash
# Builds and checks release archives (specs/008-release-1-0/contracts/release-tooling.md).
# Usage:
#   scripts/release.sh archive <build>   archive HEAD in Release with that build number, then check it
#   scripts/release.sh check <archive>   the archived app declares nothing collected, no tracking,
#                                        only the user-defaults API (CA92.1), asks for nothing, and
#                                        is Checkers 1.0 without non-exempt encryption

source "$(dirname "$0")/lib.sh"

RELEASE_DIR="$REPO_ROOT/.build/Release"

usage() {
  echo "Usage: scripts/release.sh archive <build> | check <archive>" >&2
  exit 2
}

# Archives the checked-out commit for any iPhone, with the build number given; the project keeps
# CURRENT_PROJECT_VERSION = 1, so an upload needs no commit (research R14).
archive() {
  local build="${1:-}"
  [[ "$build" =~ ^[0-9]+$ ]] || usage
  local path="$RELEASE_DIR/Checkers-1.0-$build.xcarchive"
  rm -rf "$path"
  xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination generic/platform=iOS \
    -archivePath "$path" \
    -skipPackagePluginValidation \
    -allowProvisioningUpdates \
    CURRENT_PROJECT_VERSION="$build"
  check "$path"
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

case "${1:-}" in
  archive) archive "${2:-}" ;;
  check) check "${2:-}" ;;
  *) usage ;;
esac
