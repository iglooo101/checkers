# Contract: Release tooling

Implements the measuring, building and recording side of spec US1, US2, US4 to US6 (research R3
to R8, R10, R12, R14 to R16). Every script runs from the repository root, sources
`scripts/lib.sh` where it builds, never prints a secret, and exits non-zero with one plain
sentence when a precondition fails.

## Schemes and test plans

| Item | Contents | Runs where |
|---|---|---|
| `checkers` scheme (changed) | adds `Screenshots.xctestplan` beside `checkers.xctestplan` and `Performance.xctestplan` | Mac and CI, as today |
| `checkers-device` scheme (new, shared) | build action: the app and `checkersUITests` only (no `CheckersEngineTests`); test action: `Device.xctestplan` | the phone, Release |
| `Device.xctestplan` (new) | `LaunchPerformanceTests`, `DeviceSessionUITests` | the phone |
| `Screenshots.xctestplan` (new) | `ScreenshotUITests` | iPhone 17 simulator |
| `checkers.xctestplan` (changed) | also skips `DeviceSessionUITests` and `ScreenshotUITests` | Mac and CI |

`DeviceSessionUITests` attaches to the running app with `XCUIApplication().activate()` and never
launches it (R6); run on its own it fails at once with "Start the app with scripts/device.sh
session". `ScreenshotUITests` launches the app with launch arguments for each state.

## `scripts/device.sh <status|launch|session>` (R1, R3 to R6)

The phone is found by name (`DEVICE_NAME`, default `HKH16`) in `xcrun devicectl list devices
--json-output`; its CoreDevice identifier and hardware UDID are read there and never written to a
file.

| Command | Does | Prints | Fails when |
|---|---|---|---|
| `status` | reads `devicectl device info details` | name, model, iOS version, `tunnelState`, `developerModeStatus` | the phone is missing, not connected, or Developer Mode is off ("Turn on Developer Mode: Settings › Privacy & Security › Developer Mode") |
| `launch` | `status`, then `xcodebuild test -scheme checkers-device -configuration Release -destination id=<udid> -only-testing:checkersUITests/LaunchPerformanceTests -test-iterations 2` | the ten launch times, their median, and pass or miss against 0.4 s | `status` fails, the test fails, or fewer than ten values |
| `session` | `status`; launches the installed Release app with `devicectl device process launch --console --terminate-existing --environment-variables '{"OS_ACTIVITY_DT_MODE":"YES"}'` and the session's launch arguments, capturing its output to `.build/DeviceSession/console.txt`; runs `DeviceSessionUITests`; stops the capture | the three hitch metrics, then `device-timings.py`'s report | `status` fails, the test fails, or a target misses |

Result bundles go to `.build/TestResults/Device*.xcresult`; numbers are copied by hand into
`checklists/validation.md` with the build, device and iOS version (data model, "Device
measurement").

## Device logs (R6)

Exact texts, at notice level, all values `privacy: .public` (they cannot identify anyone):

```text
[computer] Computer turn at <easy|medium|hard>: first step after <integer> ms
[sound] Sound <move|capture|crowning|gameEnd> started <decimal, one place> ms after its step
[sound] Output latency <decimal, one place> ms
```

- The computer's line is written when the first step of its turn is applied, measured from the
  moment its turn started (`computerPhase` became thinking) with `ContinuousClock`.
- The sound line is written by `SoundBank` when `play()` returns true, measured from the moment
  the session asked for the sound; the latency line once each time the audio session becomes
  active, from `AVAudioSession.outputLatency`.
- Nothing else in the app's behavior changes (FR-031). The lines are checked on the phone by
  `device.sh session`, whose report fails when a difficulty has no computer lines or no sound
  line appears; they add no behavior for unit tests to check.

## `scripts/device-timings.py <console.txt>` (SC-005)

Reads the capture and prints, per difficulty: turns, the share of first steps within 0.5–1.0 s,
and the slowest; for sound: the slowest start delay, the latency, and their sum. Exit 1 if a
difficulty has fewer than 95% within range or any turn over 1.5 s, or the slowest sound plus the
latency exceeds 100 ms. Lines it does not recognize are skipped. Tested by
`scripts/tests/test-device-timings.sh` with three fixture captures (all pass, a slow turn, a slow
sound).

## `scripts/make-icon.py [--check]` (R10)

Writes `AppIcon.png` (RGB, opaque), `AppIcon-Dark.png` (RGBA, transparent background) and
`AppIcon-Tinted.png` (grayscale) at 1024 × 1024 into
`checkers/checkers/Assets.xcassets/AppIcon.appiconset/` and sets their file names in its
`Contents.json`. Same output on every run on one machine; `--check` redraws in memory and allows a
difference of one per channel. `scripts/tests/test-make-icon.sh` runs `--check` (CI).

## `scripts/screenshots.sh` (R12)

Boots the iPhone 17 simulator (iOS 26.3), sets light appearance and the status bar
(`xcrun simctl status_bar <udid> override --time 9:41 --batteryState charged --batteryLevel 100
--cellularMode active --cellularBars 4 --wifiBars 3`), runs `Screenshots.xctestplan`, exports
the attachments, and writes `release/screenshots/01-home.png` … `06-statistics.png` as RGB PNG
files of 1206 × 2622 px. It prints which files changed; a second run on the same commit must
print none (FR-019). The states and their launch arguments are in
[store-listing.md](store-listing.md).

## `scripts/traceability.py [--check]` (R15)

Writes `specs/008-release-1-0/traceability.md` from `FRD.md`, the test sources and
`checklists/release.md`. `--check` exits 1 if an ID other than FR-PLAT-02 has neither a test nor
a manual check, or if the committed file differs from a fresh one. Tested by
`scripts/tests/test-traceability.sh` with a small fixture FRD and test folder; the real check runs
there too (CI).

## `scripts/release.sh <command>` (R8, R14, R16)

| Command | Does | Fails when |
|---|---|---|
| `archive <build>` | `xcodebuild archive -scheme checkers -configuration Release -destination generic/platform=iOS CURRENT_PROJECT_VERSION=<build>` to `.build/Release/Checkers-1.0-<build>.xcarchive`, then `check` | the tree is not clean; `CI gate` did not pass for `HEAD`; `<build>` is not higher than every build in `release/builds.md` |
| `check <archive>` | R8: every `.xcprivacy` in the app declares no tracking, no tracking domains and no collected data, and only `NSPrivacyAccessedAPICategoryUserDefaults` with CA92.1; Info.plist has no `NS…UsageDescription`, `ITSAppUsesNonExemptEncryption` is false, `CFBundleDisplayName` is "Checkers", `CFBundleShortVersionString` is 1.0 | any of these differs |
| `upload <archive>` | `xcodebuild -exportArchive -exportOptionsPlist release/ExportOptions.plist -allowProvisioningUpdates` with the key (below); then `record <build> uploaded` | the key is missing; the export fails |
| `record <build> <state> [note]` | adds or updates the build's row in `release/builds.md` | the state would move backwards |
| `submit-check <build>` | R16: `<build>` is the latest row and is processed; every row of `checklists/release.md` is passed or accepted on `<build>`, or on an earlier build whose later builds' notes say they cannot affect it | any item is open or failed |

`release/ExportOptions.plist`: `method` app-store-connect, `destination` upload, `teamID`
5RH237UKVE, `signingStyle` automatic, `uploadSymbols` true, `manageAppVersionAndBuildNumber`
false.

The App Store Connect key (FR-024) is read from outside the repository:
`../secrets/AuthKey_<KEY_ID>.p8` and `../secrets/appstoreconnect.txt` with the lines
`KEY_ID=<id>` and `ISSUER_ID=<id>`. The script checks the `.p8` file is readable only by its
owner, passes the three values only as `xcodebuild` arguments, and never echoes them. If the key
cannot create the App Store profile, the profile comes from the Xcode account already signed in
(R14), and the upload still uses the key.

The guards are tested by `scripts/tests/test-release-guards.sh` with fixture `builds.md` and
`release.md` files (build order, backward states, an open checklist item, an accepted item
without a reason).

## `release/builds.md`

```markdown
| Build | Commit | Uploaded | State | Notes |
|---|---|---|---|---|
| 1 | <full SHA> | 2026-11-02 | TestFlight internal | First beta. Affects every item. |
```

Build numbers start at 1 and each upload takes the next. The approved build's commit gets the tag
`v1.0` (FR-030); tags run no CI.

## Script tests added to `scripts/tests/run.sh`

| Test | Requirement |
|---|---|
| `test-make-icon.sh` | FR-015, SC-007 (same images) |
| `test-traceability.sh` | FR-007, SC-001 |
| `test-device-timings.sh` | FR-013, SC-005 (the check itself) |
| `test-no-network.sh` | FR-001, FR-003: no networking, web, account, analytics or advertising API in `checkers/checkers` or `checkers/CheckersEngine/Sources` |
| `test-no-secrets.sh` | FR-024: no tracked file contains `PRIVATE KEY` or ends in `.p8`; `.gitignore` lists `*.p8` |
| `test-store-listing.sh` | FR-018: the limits in [store-listing.md](store-listing.md) |
| `test-release-guards.sh` | FR-023, FR-028 |
