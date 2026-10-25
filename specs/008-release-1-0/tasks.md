---

description: "Task list for the Release 1.0 slice (epic E8)"
---

# Tasks: Release 1.0

**Input**: Design documents from `/specs/008-release-1-0/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/diagnostics.md, contracts/release-tooling.md, contracts/store-listing.md, quickstart.md

**Tests**: Tests are MANDATORY (Constitution III). App logic is tested with Swift Testing in `checkers/checkersTests/` (the diagnostics parser and log with JSON fixtures, the Info.plist values); measurements on the phone use XCTest metrics in `checkers/checkersUITests/` (`LaunchPerformanceTests`, `DeviceSessionUITests`); every new script has a script test in `scripts/tests/` that runs in CI. Suites are named `US<n>…Tests`, display names start with the story ID and list the FRD IDs they prove, or this spec's IDs (`FR-0nn`) for requirements that have no FRD ID (`traceability.py` matches only FRD IDs, `FR-<AREA>-<n>`), UI test methods are named `testUS<n>_…`, and each script test's description line (line 2) starts with its story ID. Test tasks come before the implementation tasks they cover and must be observed failing (or failing to compile) first; a guard test that passes at once (nothing to forbid yet) is proven by a mutation: add one violating line, see it fail, remove it.

**Organization**: Tasks are grouped by user story. A test task is complete together with the implementation tasks it covers (red, then green): no commit or push is ever red, so every completed task leaves the app building and all tests passing (Constitution workflow gate 3).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US6)
- Shorthands: `App/` is `checkers/checkers/`, `Unit/` is `checkers/checkersTests/`, `UI/` is `checkers/checkersUITests/`, `Spec/` is `specs/008-release-1-0/`.
- **Who acts**: a task that starts with **Phone:** needs HKH16 connected, unlocked and with Developer Mode on (the owner keeps it so; `scripts/device.sh status` first); **Owner:** needs the owner's hands, eyes, judgment or accounts; **Apple:** waits for Apple (processing, Beta App Review, App Review). These tasks do not block the next story's code.

## Conventions used by every task

- As in E3 to E6: `scripts/test.sh` runs the blocking plan with SwiftLint; one suite with `-only-testing`; `scripts/tests/run.sh` runs the script tests; sync the string catalog with `scripts/sync-string-catalog.sh` after string changes; no force unwraps outside tests; no test-only behavior in the app; commit failing tests with their implementation; push once per story and wait for CI; move board tasks to In Progress before a story and Done after its CI (summaries with `gh issue comment`, then check the issue closed); keep `EXECUTION_PLAN.md` in step.
- **No game behavior, screen or text changes** (FR-031): the app gains only the diagnostics feature, three log lines, the display name, the encryption key and the icon. All existing tests keep passing.
- **Device runs** use the `checkers-device` scheme in Release with `xcodebuild test`, never `test-without-building` (research R1, R3). Scripts find the phone by name (`DEVICE_NAME`, default `HKH16`) and never write its identifiers to a file. Phone traces are read in the Instruments app; `xctrace export` crashes on them (R1).
- **Secrets** (FR-024): the App Store Connect key stays in `../secrets` (`AuthKey_<KEY_ID>.p8`, mode 600, and `appstoreconnect.txt` with `KEY_ID=` and `ISSUER_ID=`); scripts pass it only as `xcodebuild` arguments and never print it; `test-no-secrets.sh` guards every push.
- **Markdown-only commits run no CI**: pages, the listing, checklists and records can land on `main` within a minute; code commits run the full CI (about 30 minutes).
- `App/Features/Game/GameSession.swift` stays at most 400 lines (394 now): the timing helper goes in its own file (T018).
- **The traceability matrix is checked in CI** (T007, T009): after adding or renaming a test whose name lists an FRD ID, regenerate it with `python3 scripts/traceability.py` and commit `Spec/traceability.md` with the test, or `test-traceability.sh` fails.
- Measurements go into `Spec/checklists/validation.md` with every value, the build (configuration, commit, build number when uploaded), the device and its iOS version (data model, "Device measurement").

---

## Phase 1: Setup (Shared Infrastructure)

- [ ] T001 Create `Spec/checklists/validation.md` with one section per quickstart scenario (§1–§8), a "Baseline" section (`scripts/test.sh` and `scripts/tests/run.sh` pass before any slice code: record the test counts and the date), and the research measurements: the environment facts, R1 (what works on iOS 27.0.1 and the two limits), R4 (five cold launches, median 231 ms), R5 (`XCTHitchMetric` on Rules: 0, 0, 0 s), R6 (the console capture), R17 (the iPad window), each with the date, the Mac and the phone.
- [ ] T002 [P] Write `scripts/tests/test-no-secrets.sh` (line 2: "US5 FR-024: no key material is tracked"): it fails if `.gitignore` does not list `*.p8`, if any tracked file (`git ls-files`) ends in `.p8`, or if any tracked file contains a private key's header line (`-----BEGIN`, optional words, then `PRIVATE KEY-----`); the script builds that pattern from two parts at run time, so it never matches itself, and documents that only mention the words do not match. Run it and see it fail on the missing `.gitignore` entry; add `*.p8` under a "# App Store Connect keys (kept in ../secrets)" comment in `.gitignore`; it passes. Prove the header check with a mutation (a probe file holding a fake header line, seen failing, deleted). Then add `scripts/hooks/pre-push` (runs `scripts/tests/test-no-secrets.sh` and blocks the push on failure) and set `git config core.hooksPath scripts/hooks` in this clone, so a key is caught before it reaches the public repository, not after (spec edge case "a check before each push"). Done before the owner creates the key.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Release builds and tests on the phone, used by US1's session and all of US2 (#181, #182; research R3).

- [ ] T003 [P] Write `scripts/tests/test-device.sh` (line 2: "US2 FR-011: device.sh finds the phone and checks Developer Mode") with fixture `devicectl` JSON in `scripts/tests/device-fixtures/` (list and details output for: connected with Developer Mode enabled; Developer Mode disabled; tunnel unavailable; no device named `HKH16`). It runs `scripts/device.sh status` with `DEVICECTL_FIXTURES=<dir>` (the script reads the fixture files instead of calling `devicectl` when it is set) and expects: exit 0 printing the name, model, iOS version, `connected` and `enabled`; otherwise exit 1 with the contract's sentence ("Turn on Developer Mode: Settings › Privacy & Security › Developer Mode" for the disabled case). Fails until T004.
- [ ] T004 Create `scripts/device.sh` (sources `scripts/lib.sh`) with `status` and `launch` per contracts/release-tooling.md: `status` reads `xcrun devicectl list devices --json-output` and `xcrun devicectl device info details --json-output` (or the fixtures), finds the phone by `DEVICE_NAME`, and keeps its CoreDevice identifier and hardware UDID in shell variables only; `launch` runs `status`, then `xcodebuild test -project checkers/checkers.xcodeproj -scheme checkers-device -configuration Release -destination id=<udid> -derivedDataPath .build/DeviceDerivedData -skipPackagePluginValidation -allowProvisioningUpdates -only-testing:checkersUITests/LaunchPerformanceTests -test-iterations 2 -resultBundlePath .build/TestResults/DeviceLaunch.xcresult`, reads the ten `com.apple.dt.XCTMetric_ApplicationLaunch-AppLaunch.duration` values with `xcrun xcresulttool get test-results metrics`, and prints them, their median and "pass" or "miss" against 0.4 s (exit 1 on a miss or fewer than ten values). T003 passes.
- [ ] T005 Add the shared scheme `checkers/checkers.xcodeproj/xcshareddata/xcschemes/checkers-device.xcscheme` (a copy of `checkers.xcscheme` whose build action has no `CheckersEngineTests` entry and whose test action references only `container:Device.xctestplan`, default) and `checkers/Device.xctestplan` (target `checkersUITests`, selected test `LaunchPerformanceTests`). Check: `xcodebuild build-for-testing -scheme checkers-device -configuration Release -destination generic/platform=iOS` succeeds without building the engine's tests; `scripts/test.sh` is unchanged. Record in `validation.md`.

**Checkpoint**: `scripts/tests/run.sh` and `scripts/test.sh` pass; `scripts/device.sh status` reports the phone.

---

## Phase 3: User Story 1 - Every promise verified (Priority: P1) 🎯 MVP

**Goal**: Evidence, requirement by requirement, that the app keeps the FRD's privacy and platform promises, and a traceability matrix that cannot drift (#176: #177, #178, #179; FR-001 to FR-007).

**Independent Test**: `test-no-network.sh`, `traceability.py --check` and `release.sh check` pass; on the phone a fresh Release install used through every screen shows no prompt, stays in portrait and has no network activity in the App Privacy Report; the Organizer's privacy report lists nothing collected.

### Tests for User Story 1 (MANDATORY - write first) ⚠️

- [ ] T006 [P] [US1] Write `scripts/tests/test-no-network.sh` (line 2: "US1 FR-001 FR-003: no networking, web, account, analytics or advertising API"): it greps `checkers/checkers/` and `checkers/CheckersEngine/Sources/` (Swift files and Info.plist build settings in `checkers/checkers.xcodeproj/project.pbxproj`) for `URLSession`, `URLRequest`, `NWConnection`, `NWPathMonitor`, `import Network`, `import WebKit`, `WKWebView`, `CFNetwork`, `CFStream`, `Socket`, `import AuthenticationServices`, `import AppTrackingTransparency`, `import AdSupport`, `import StoreKit`, `import CloudKit`, `import GameKit`, `ASIdentifierManager` and `NSAppTransportSecurity`, and fails naming each file and match. Prove it with a mutation (a probe file containing `URLSession.shared`, seen failing, deleted).
- [ ] T007 [P] [US1] Write `scripts/tests/test-traceability.sh` (line 2: "US1 FR-007: every FRD ID has a test or a manual check") with fixtures in `scripts/tests/traceability-fixtures/` (a small FRD with four IDs, one marked removed in its text; a test folder naming two of them in `@Test("…")` strings and one in a `func testUS1_…` comment; a release checklist naming the fourth): `scripts/traceability.py --frd <f> --tests <dir>… --checklist <f> --out <f>` writes the expected Markdown; `--check` passes on it, fails when an ID is in neither place (naming it), and fails when the output file is stale. It also runs the real `scripts/traceability.py --check`. Fails until T009.
- [ ] T008 [P] [US1] Write `scripts/tests/test-release-check.sh` (line 2: "US1 FR-002 FR-004: the archive declares nothing collected and asks for nothing") with fixture archives in `scripts/tests/release-fixtures/` (`good.xcarchive/Products/Applications/checkers.app/` holding `Info.plist` and `PrivacyInfo.xcprivacy` as the real app's, plus variants: `NSPrivacyTracking` true; one collected data type; a tracking domain; a second accessed-API category; a reason other than CA92.1; an `NSCameraUsageDescription`). `scripts/release.sh check <archive>` must pass on `good` and fail on each variant with a sentence naming the problem. Fails until T010.

### Implementation for User Story 1

- [ ] T009 [US1] Create `scripts/traceability.py` (standard library only) per research R15 and the data model's "Traceability entry": IDs from `FRD.md` in its order (`FR-[A-Z]+-[0-9]+`; FR-PLAT-02 listed as "removed"); tests from `checkers/checkersTests`, `checkers/checkersUITests` and `checkers/CheckersEngine/Tests`, each as file and test name (the `@Test` display name or the `func test…` name of the enclosing test that names the ID); manual checks from `Spec/checklists/release.md` when it exists (its `RC-nn` rows naming the ID, with their results); status covered, removed or missing. Defaults point at the real files. Generate `Spec/traceability.md`; T007 passes; record in `validation.md` §1 the counts (expected: 84 covered by tests, FR-PLAT-02 removed).
- [ ] T010 [US1] Create `scripts/release.sh` (sources `scripts/lib.sh`) with `archive <build>` (`xcodebuild archive -project checkers/checkers.xcodeproj -scheme checkers -configuration Release -destination generic/platform=iOS -archivePath .build/Release/Checkers-1.0-<build>.xcarchive -skipPackagePluginValidation -allowProvisioningUpdates CURRENT_PROJECT_VERSION=<build>`, then `check`; the guards of FR-023 come in T043) and `check <archive>` per research R8 and contracts/release-tooling.md (every `.xcprivacy` under the archived app: no tracking, no tracking domains, no collected data, only `NSPrivacyAccessedAPICategoryUserDefaults` with `CA92.1`; no Info.plist key ending in `UsageDescription`), using `plutil`. T008 passes. Archive the current commit locally (`scripts/release.sh archive 0`; build 0 is never uploaded) and record the check in `validation.md` §2.
- [ ] T011 [US1] Board fit and texts (FR-005, FR-006): confirm `Unit/BoardLayoutTests.swift` covers the smallest supported portrait size (iPhone SE 3rd generation, 375 × 667 pt) and the largest (iPhone 17 Pro Max, 440 × 956 pt) with the whole board on screen; if not, add those cases first (`US1 FR-PLAT-01`), then fix only if they fail. Take a simulator screenshot of a game on each of the two devices and record them in `validation.md` §2. Confirm `Unit/LocalizationTests.swift` and `scripts/check-string-catalog.sh checkers/checkers/Localizable.xcstrings .build/DerivedData` pass (FR-PLAT-03) and record it.
- [ ] T012 [US1] **Phone, Owner:** quickstart §2 steps 1–3 with a fresh Release install (delete the app first; `scripts/device.sh launch` installs the Release build): App Privacy Report on; play a game against the computer and a two-player game; open every screen; turn the phone to both landscape sides and upside down on each. Record: no prompt, portrait throughout, and the App Privacy Report's entry for Checkers (expected: no network activity, no data or sensor access) in `validation.md` §2 (SC-002).
- [ ] T013 [US1] **Owner:** open the archive of T010 in Xcode (`open .build/Release/Checkers-1.0-0.xcarchive`, which adds it to the Organizer; the Organizer lists only archives in Xcode's own folder), then Generate Privacy Report for it and record its result in `validation.md` §2 (FR-004; expected: no collected data, no tracking, no tracking domains, `UserDefaults` with CA92.1 only).
- [ ] T014 [US1] **Owner:** the first iPad compatibility smoke check (FR-005, research R17) on the "iPad (A16) E8" simulator with the app from T010's archive: launch, a few moves against the computer and in a two-player game, every screen, Device › Rotate, and a resized window. Record in `validation.md` §2; later builds repeat it as a release checklist item (T044).

**Checkpoint**: US1 complete: every promise has evidence, and the traceability matrix is generated and checked in CI.

---

## Phase 4: User Story 2 - Fast and smooth on a real iPhone (Priority: P2)

**Goal**: Launch time, hitches, hangs, the computer's timing and the sound delay measured on the phone with Release builds (#180: #181, #182; FR-011 to FR-014).

**Independent Test**: `scripts/device.sh launch` reports ten launches with a median under 0.4 s; `scripts/device.sh session` reports a hitch-time ratio under 5 ms/s, total hitch time under 0.25 s, and passes `device-timings.py`.

### Tests for User Story 2 (MANDATORY - write first) ⚠️

- [ ] T015 [P] [US2] Write `scripts/tests/test-device-timings.sh` (line 2: "US2 FR-013 SC-005: the computer's timing and the sound delay are judged") with fixture console captures in `scripts/tests/timing-fixtures/` in the exact line formats of contracts/release-tooling.md ("Device logs"), mixed with unrelated log lines: all within range (exit 0, and the report lists each difficulty's turns, share within 0.5–1.0 s and slowest turn, and the slowest sound delay, the latency and their sum); one Hard turn at 1,600 ms (exit 1); 6% of Easy turns at 1,100 ms (exit 1); a sound delay plus latency of 120 ms (exit 1); no Medium lines (exit 1, "no computer turns at medium"); no sound lines (exit 1). Fails until T019.
- [ ] T016 [P] [US2] The session's starting position and its UI test, per research R5:
  - `scripts/device-session-game.json`: the JSON text of a version 1 saved two-player game (specs/006-saving-and-statistics/contracts/saved-game.md), Light to move, from which Light has a quiet move to tap and one to drag, Dark replies, and Light then plays a capture and a two-jump chain that ends in a crowning. The opening cannot reach a chain and a crowning in a few moves, and the scripted games in `Unit/Support/ScriptedGames.swift` start from custom positions, so find the position with a throwaway engine search (E4 lessons) and record its steps in the file's companion comment in the test below.
  - In `Unit/StorageTests.swift`, `@Test("US2 FR-012: the device session's saved game is valid and plays its steps")`: read the file through its path from `#filePath`, decode it as the app does (`SavedGameStore`'s decoding of version 1), and apply the session's steps through the engine; it fails until the file exists, and keeps the file from drifting from the engine.
  - `UI/DeviceSessionUITests.swift` (`final class DeviceSessionUITests`, `@MainActor func testUS2_scriptedSession()`): `XCUIApplication().activate()` (never `launch()`); if `home.newGame` does not appear within 10 s, `XCTFail("Start the app with scripts/device.sh session")`. One `measure(metrics: [XCTHitchMetric(application: app)], options:)` with `iterationCount = 1` around a block that starts and ends on Home, so it can repeat: Continue the saved game (the launch argument holds for the whole launch, E5 research R10, so every iteration continues the same position), select by tap, move by tap and by drag, play the capture and the chain with its crowning, undo once, Home; a game against the computer at Easy, Medium and Hard, three player moves each, waiting for each reply (`waitForTurn`), then Home; scrolling Rules to its end and back, Statistics, Settings and the setup form. Use the helpers in `UI/Support/AppScreens.swift` (`tapStart()` answers "Abandon current game?"). It cannot run on CI: T017 keeps it out of the blocking plan.
- [ ] T017 [US2] Add `DeviceSessionUITests` to `checkers/Device.xctestplan` and to the `skippedTests` of `checkersUITests` in `checkers/checkers.xctestplan` (beside `LaunchPerformanceTests`); confirm `scripts/test.sh` does not run it.

### Implementation for User Story 2

- [ ] T018 [US2] Add the three measurement lines of contracts/release-tooling.md ("Device logs"), notice level, values `privacy: .public`: (1) in `App/Features/Game/GameSession.swift`, `playComputerTurn(from:)` reads `ContinuousClock.now` first and, after the first step is applied (`index == 0`), calls `logFirstComputerStep(since:difficulty:)`, defined in a new `App/Features/Game/GameSession+Timing.swift` that writes `Computer turn at <easy|medium|hard>: first step after <integer> ms` to `Log.computer` (the file stays at most 400 lines); (2) `SoundBank.play(_:requestedAt:)` in `App/Features/Sound/SoundBank.swift` takes `requestedAt: ContinuousClock.Instant? = nil` and, when `player.play()` returns true and an instant was given, logs `Sound <effect> started <decimal, one place> ms after its step` to `Log.sound`; `AudioSoundPlayer.play(_:)` in `App/Features/Sound/SoundPlayer.swift` captures `ContinuousClock.now` on the main actor before its task and passes it; (3) `SoundBank.prepare()` logs `Output latency <decimal, one place> ms` from `AVAudioSession.sharedInstance().outputLatency` after setting the category. No behavior changes (FR-031); existing calls of `play(_:)` compile unchanged; `scripts/test.sh` passes.
- [ ] T019 [US2] Create `scripts/device-timings.py <console.txt>` (standard library only) per contracts/release-tooling.md: parse the three line formats, skip everything else, print the report and exit 1 on any miss of SC-005 (fewer than 95% of a difficulty's first steps within 0.5–1.0 s, any over 1.5 s, the slowest sound start plus the latency over 100 ms, a difficulty or the sounds missing). T015 passes.
- [ ] T020 [US2] Add `session` to `scripts/device.sh` per the contract: `status`; build and install the Release app through `xcodebuild build -scheme checkers-device -configuration Release -destination id=<udid>` (installing with `xcrun devicectl device install app`); launch it with `xcrun devicectl device process launch --console --terminate-existing --environment-variables '{"OS_ACTIVITY_DT_MODE":"YES"}' Hussein-Helmy.checkers -- -savedGame "<$(xxd -p scripts/device-session-game.json | tr -d '\n')>"` in the background, capturing to `.build/DeviceSession/console.txt`; wait until the capture shows the launch; run `xcodebuild test -scheme checkers-device -configuration Release -destination id=<udid> -only-testing:checkersUITests/DeviceSessionUITests -resultBundlePath .build/TestResults/DeviceSession.xcresult`; stop the capture; print the hitch metrics (`com.apple.dt.XCTMetric_Hitch-checkers.time.ratio`, `.number`, `.total.duration`) with pass or miss (ratio < 5 ms/s, total < 0.25 s), then `scripts/device-timings.py`'s report; exit 1 on any miss or if any of the three metrics is absent. **First run check** (research R6: the hitch metric was measured on an app the test launched, and `activate()` with the console without the metric, never both together): confirm the result bundle holds all three hitch metrics when the test attached to the app; if it does not, split `session` into two runs, hitches from a run in which the test launches the app itself with the same `-savedGame` bytes (a Swift copy of the JSON in `UI/Support/AppScreens.swift`'s `StoredValues`, held equal to the file by the T016 unit test) and timings from the console run, and record which way works in `validation.md` §5.
- [ ] T021 [US2] **Phone:** run `scripts/device.sh launch` and `scripts/device.sh session` on HKH16 and record every value in `validation.md` §5 with the commit, the device and iOS 27.0.1 (SC-003 to SC-005). Add a note to `specs/005-computer-opponent/checklists/validation.md` §5 and `specs/007-settings-themes-sound-and-rules/checklists/validation.md` §5 that the iPhone timing and the sound delay are now measured, with the numbers. Best run after US3 and US4's app changes; the release checklist repeats both on each uploaded build (T044).
- [ ] T022 [US2] On a miss only (FR-014, Constitution VII.4): **Phone, Owner:** record the same session in Instruments (Animation Hitches and Hangs, or App Launch) on the phone and read it in the Instruments app; write the finding in `validation.md`; fix through a failing test where one can be written, then the change, CI, and `scripts/device.sh` again; a miss that remains is measured on a newer iPhone (an external tester's), which decides. Without a miss, record "no miss" and close.

**Checkpoint**: US2 complete: every performance target has a number from the phone.

---

## Phase 5: User Story 3 - Crashes and hangs can be diagnosed after release (Priority: P2)

**Goal**: The app logs each diagnostic the system delivers, on the phone only (#176: #192; FR-008 to FR-010).

**Independent Test**: `US3DiagnosticsTests` passes: one entry per diagnostic of every kind, in order, with the payload's times; one failure entry per unreadable payload; on the phone, simulated payloads appear in the console under `[diagnostics]`.

### Tests for User Story 3 (MANDATORY - write first) ⚠️

- [ ] T023 [P] [US3] Write `Unit/Support/DiagnosticFixtures.swift` (JSON payloads as `Data` per contracts/diagnostics.md "Accepted payload JSON": one per kind with `timeStampBegin` "2026-10-25 21:00:00 +0000" and `timeStampEnd` "2026-10-25 21:59:00 +0000"; one with two crashes and a hang; one with no arrays; damaged: non-JSON bytes, a missing `timeStampEnd`, an empty `timeStampBegin`, `crashDiagnostics` holding strings, a top-level array) and `Unit/US3DiagnosticsTests.swift` (`struct US3DiagnosticsTests`), every row of the contract's "Tests" table: `US3 FR-008` each kind gives exactly one entry with that kind and both time stamps; the mixed payload gives three entries in kind order (crash, crash, hang); no arrays gives none; `US3 FR-010` each damaged payload gives one failure entry and no report; two payloads, the first damaged, give the failure then the second's entries; `US3 FR-009` the detail is the `diagnosticMetaData` object re-encoded with sorted keys (the same text on two runs), or nil without one (logged as "none"). Tests use `RecordingDiagnosticsLog` and `DiagnosticsSubscriber.handle(_ payloads: [Data], log:)`. Fails to compile until T025–T026.
- [ ] T024 [P] [US3] Change `Unit/LoggingTests.swift` to the categories `["app", "game", "setup", "computer", "storage", "settings", "sound", "diagnostics"]`; fails until T026.

### Implementation for User Story 3

- [ ] T025 [US3] Create `App/Features/Diagnostics/DiagnosticReport.swift` per data-model.md: `DiagnosticKind` (`crash`, `hang`, `cpuException`, `diskWriteException`, `launch`; `nonisolated`, `Sendable`, `CaseIterable` in that order; each kind's payload array key and log name), `DiagnosticError` (`unreadable`), `Diagnostic` (`kind: DiagnosticKind`, `detail: String?`) and `DiagnosticReport` (`begin: String`, `end: String`, `diagnostics: [Diagnostic]`), all `nonisolated`, `Sendable` and `Equatable`, with `init(json: Data) throws(DiagnosticError)` enforcing exactly: "the bytes must be a JSON object with non-empty string time stamps; each of the five arrays may be missing (none of that kind) but, when present, must be an array of objects. Unknown keys are ignored. Anything else is `DiagnosticError.unreadable`."
- [ ] T026 [US3] Create `App/Features/Diagnostics/DiagnosticsLog.swift`: protocol `DiagnosticsLog` (`record(_:)`, `recordUnreadable()`), `OSLogDiagnosticsLog` writing to `Log.diagnostics` the contract's lines ("<Kind> reported for <begin> to <end>; details: <detail>" with kind and times `privacy: .public` and the detail with the default private redaction; `error` level for crashes, `notice` for the rest; "A diagnostic report could not be read" at `error` level), and `RecordingDiagnosticsLog` (keeps the reports and failures in order in a `Mutex` from Synchronization, so it is `Sendable` without `@unchecked`, Constitution IV.4); all three `nonisolated`; add `diagnostics` to `Log.Category` and `Log.diagnostics` in `App/Support/Logging.swift`. T024 passes.
- [ ] T027 [US3] Create `App/Features/Diagnostics/DiagnosticsSubscriber.swift`: `nonisolated final class DiagnosticsSubscriber: NSObject, MXMetricManagerSubscriber, Sendable` (the app target's default isolation is the main actor, and MetricKit calls on a background queue) holding a `let log: any DiagnosticsLog`; `func didReceive(_ payloads: [MXDiagnosticPayload])` maps each payload's `jsonRepresentation()` to `Data` and calls `static func handle(_ payloads: [Data], log:)`, which parses each on its own and records the report or the failure; `start()` calls `MXMetricManager.shared.add(self)`. In `App/CheckersApp.swift`, keep one subscriber with an `OSLogDiagnosticsLog` for the app's lifetime (`@State`) and start it from a `.task` on the root view, after the first frame, so the first use of `MXMetricManager.shared` never delays launch (Constitution VII.1; diagnostics only need the app running). T023 passes; `PrivacyManifestTests` and the CI launch report are unchanged; T021's launch measurement confirms the budget.
- [ ] T028 [US3] **Phone, Owner:** quickstart §3: run the app from Xcode on HKH16, Debug › Simulate MetricKit Payloads; read the `[diagnostics]` lines in Xcode's console; compare the payload's key names with contracts/diagnostics.md and, if they differ, change the fixtures (T023), the parser and the contract together, test first. Record in `validation.md` §3.

**Checkpoint**: US3 complete: field crashes and hangs leave a trace on the phone, and nothing leaves it.

---

## Phase 6: User Story 4 - A recognizable app with a store page (Priority: P2)

**Goal**: An original icon in three variants, the name "Checkers", the encryption declaration, screenshots, the store texts and the public pages (#183: #184, #185; FR-015 to FR-022).

**Independent Test**: `test-make-icon.sh`, `test-store-listing.sh` and `test-release-check.sh` pass; `PlatformSettingsTests` reads the name, the encryption key and the plain launch screen; `scripts/screenshots.sh` twice reports no change; both public URLs load; the owner approves the icon and the screenshots.

### Tests for User Story 4 (MANDATORY - write first) ⚠️

- [ ] T029 [P] [US4] Write `scripts/tests/test-make-icon.sh` (line 2: "US4 FR-015 SC-007: the icon matches its script"): runs `python3 scripts/make-icon.py --check` and checks with `sips -g pixelWidth -g pixelHeight -g hasAlpha -g space` that `AppIcon.png` is 1024 × 1024 RGB without alpha, `AppIcon-Dark.png` 1024 × 1024 with alpha, `AppIcon-Tinted.png` 1024 × 1024 grayscale, and that `App/Assets.xcassets/AppIcon.appiconset/Contents.json` names the three files in its any, dark and tinted entries. Fails until T033.
- [ ] T030 [P] [US4] Add to `Unit/PlatformSettingsTests.swift`: `US4 FR-016` `Bundle.main.infoDictionary` and `localizedInfoDictionary` give `CFBundleDisplayName` "Checkers"; `US4 FR-022` `ITSAppUsesNonExemptEncryption` is false; `US4 FR-017` `UILaunchScreen` is a dictionary with no `UIImageName` and no `UIColorName` (the system background, as Home's). The first two fail until T035.
- [ ] T031 [P] [US4] Write `scripts/tests/test-store-listing.sh` (line 2: "US4 FR-018: the store texts fit App Store Connect"), which checks a listing file in the format "one `## <Field>` heading per field of contracts/store-listing.md, its text below" against the contract's limits (name 2–30 characters; subtitle ≤ 30; promotional text ≤ 170; description ≤ 4,000 characters; keywords ≤ 100 bytes, comma-separated, each over two characters; support and privacy policy URLs start with `https://`; review notes ≤ 4,000 bytes; What to Test ≤ 4,000 characters; every field present; HTML comments not counted): fixtures in `scripts/tests/listing-fixtures/` (one good, and one each with a 31-character name, 101 bytes of keywords, a two-character keyword, a missing subtitle, an `http://` URL) and the real `release/store-listing.md`. Fails until T039.
- [ ] T032 [P] [US4] Extend `scripts/tests/test-release-check.sh` (T008) with fixture variants whose Info.plist has `CFBundleDisplayName` "checkers", lacks `ITSAppUsesNonExemptEncryption`, or has `CFBundleShortVersionString` 1.1: `release.sh check` must fail on each, naming it (FR-016, FR-022). Fails until T035.

### Implementation for User Story 4

- [ ] T033 [US4] Create `scripts/make-icon.py [--check]` per research R10 and contracts/release-tooling.md: standard library only (`zlib`, `struct`), 1024 × 1024, 4 × 4 supersampling, filled shapes only; one light king (piece `#FFFAF0` with edge `#A88F5F`, crown `#6B4426`) centered on a two-by-two corner of Classic squares (`#F1DFB9`, `#7A4A24`), no text and no thin lines; writes `AppIcon.png` (RGB, opaque), `AppIcon-Dark.png` (RGBA: the piece and its crown only, on a transparent background, per Apple's rule for dark icons) and `AppIcon-Tinted.png` (8-bit grayscale of the default artwork) into `App/Assets.xcassets/AppIcon.appiconset/`, and adds their `filename`s to `Contents.json` without reordering it; `--check` redraws in memory and allows one step per channel. Run it, then T029 passes; add `test-make-icon.sh` runs to CI through `scripts/tests/run.sh` (automatic).
- [ ] T034 [US4] **Owner:** approve the three icon variants (open the PNG files; on the phone after T021's or T035's install: Home Screen › Edit › Customize in light, dark and tinted) at Home Screen and store sizes, or ask for a change to `make-icon.py` (then T033 again). Record the approval in `validation.md` §4 (SC-007, FR-015).
- [ ] T035 [US4] In `checkers/checkers.xcodeproj/project.pbxproj`, app target, Debug and Release: `INFOPLIST_KEY_CFBundleDisplayName = Checkers;` and `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO;`; create `App/InfoPlist.xcstrings` (source language en, key `CFBundleDisplayName`, value "Checkers", state translated, in the catalog's two-space layout). Extend `release.sh check` with the Info.plist checks of the contract (`CFBundleDisplayName` "Checkers", `ITSAppUsesNonExemptEncryption` false, `CFBundleShortVersionString` 1.0). T030 and T032 pass. **Phone, Owner:** after installing, the name under the icon reads "Checkers", and launching in light and in dark shows a plain screen and then Home without a flash; record in `validation.md` §4.
- [ ] T036 [US4] Write `UI/ScreenshotUITests.swift` (`final class ScreenshotUITests`, one `@MainActor func testUS4_<name>()` per screenshot of contracts/store-listing.md "Screenshots", each launching with the needed `-savedGame`/`-record` launch arguments, or playing moves in a two-player game only (the computer draws each turn with a fresh random seed, so every state with the computer comes from `-savedGame`, with the player to move), waiting until the screen is at rest, and adding `XCUIScreen.main.screenshot()` as an `XCTAttachment` named after its file with `lifetime = .keepAlways`); `checkers/Screenshots.xctestplan` (only `ScreenshotUITests`); add the plan to `checkers.xcscheme`'s test plans and `ScreenshotUITests` to the blocking plan's skipped tests; create `scripts/screenshots.sh` per the contract (boot the iPhone 17 simulator on iOS 26.3, light appearance, the status bar override, `xcodebuild test -testPlan Screenshots`, `xcrun xcresulttool export attachments`, write `release/screenshots/01-home.png` … `06-statistics.png` as RGB PNG without alpha at 1206 × 2622, report changed files). Run it twice: the second run reports no change (FR-019); record in `validation.md` §4.
- [ ] T037 [US4] **Owner:** approve the six screenshots in `release/screenshots/` or ask for other states (then T036 again). Record in `validation.md` §4.
- [ ] T038 [US4] Write `docs/index.md` (support) and `docs/privacy.md` (front matter `permalink: /privacy/`) with the content of contracts/store-listing.md "Public pages" (no email address); push them to `main` (Markdown only: no build); enable Pages once with `gh api -X POST repos/iglooo101/checkers/pages -f "source[branch]=main" -f "source[path]=/docs"`; when it has built, the two `curl` checks of quickstart §4 pass. Record the URLs in `validation.md` §4 (FR-021, SC-008).
- [ ] T039 [US4] Write `release/store-listing.md` in the format of T031 with every field of contracts/store-listing.md (a proposed name, subtitle, promotional text, description with an HTML comment of FRD IDs after each paragraph, keywords, the two URLs, category Games › Board, the age rating answers, price free in every country and region, availability iPhone only with Apple silicon Macs and Apple Vision Pro off, copyright with the owner's name as given, App Review notes, privacy label "Data Not Collected", and TestFlight's What to Test). T031 passes. **Owner:** review every statement against the FRD and approve the texts and the name.
- [ ] T040 [US4] **Owner:** in App Store Connect, create the app record (name from T039, bundle ID `Hussein-Helmy.checkers`, SKU of the owner's choice, primary language English (U.S.)); if the name is taken, pick another and update `release/store-listing.md`. Enter every field of `release/store-listing.md`; set the privacy label to "Data Not Collected"; answer the age rating questionnaire (4+); price free in all countries and regions; turn off availability on Apple silicon Macs and Apple Vision Pro. Record in `validation.md` §4 (FR-018, FR-020).

**Checkpoint**: US4 complete: the app has its face, its name and its store page; uploads can begin.

---

## Phase 7: User Story 5 - A beta round on TestFlight (Priority: P3)

**Goal**: Signed builds of CI-passed commits on TestFlight, the release checklist worked through on them, and a small external round (#183: #186; FR-023 to FR-027).

**Independent Test**: `test-release-guards.sh` passes; an upload reaches TestFlight with no export-compliance question; every release checklist item has a result and a build.

### Tests for User Story 5 (MANDATORY - write first) ⚠️

- [ ] T041 [P] [US5] Write `scripts/tests/test-release-guards.sh` (line 2: "US5 FR-023: only checked commits become builds, in order") with fixtures in `scripts/tests/release-fixtures/` and a stub `gh` placed first on `PATH` that answers the `CI gate` conclusion for a commit: `release.sh archive <n>` stops before `xcodebuild` (run with `RELEASE_DRY_RUN=1`, which prints the archive command instead of running it) when the tree is dirty, when `CI gate` is not `success` for `HEAD`, or when `<n>` is not higher than every build in the fixture `builds.md`. The clean and dirty cases run against a temporary git repository the test creates (`RELEASE_REPO=<dir>`, which defaults to the repository root), never the real working tree, which is dirty during development and unknown on CI; `release.sh record <n> <state>` adds a row, moves a state forward along "uploaded → processed → TestFlight internal → external → submitted → approved" (or to "rejected"), and refuses to move one backward. Fails until T043.

### Implementation for User Story 5

- [ ] T042 [US5] Create `Spec/checklists/release.md` per research R16 and the data model's "Release checklist item": one table (`ID`, `Source`, `Check`, `Build`, `Result`, `Reason`), rows `RC-01`… copied with their sources from every open hand check FR-026 lists: E3's hand-played game and largest-text review (`specs/003-game-experience/checklists/validation.md`); E7's VoiceOver game (`specs/004-accessibility/…`); E4's playtest (a beginner against Easy, an experienced casual player against Hard), Home while the computer thinks, and VoiceOver moves against the computer (`specs/005-computer-opponent/…`); E5's closing from the app switcher and Continue, Home while the computer thinks then Continue, finished games at Easy and Medium in Statistics, and VoiceOver reading Statistics (`specs/006-saving-and-statistics/…`); E6's sound delay, silent mode, volume buttons, other apps' music, a sound over another, and VoiceOver through Rules and Settings (`specs/007-…/…`); and E8's: the App Privacy Report session with rotation and no prompts (T012), the Organizer privacy report (T013), the iPad smoke check (T014), `scripts/device.sh launch` and `session` on the build's commit (T021), the diagnostics simulation (T028), the icon in the three Home Screen styles, the name and the launch screen (T034, T035), the TestFlight install behaving as the local Release build, and the external testers' feedback window. Each row names the FRD IDs it checks. In each earlier slice's `validation.md`, mark its open checks "moved to E8 release checklist RC-nn". Regenerate `Spec/traceability.md` (manual checks column).
- [ ] T043 [US5] Create `release/ExportOptions.plist` (contract values) and `release/builds.md` (the contract's table header only); extend `scripts/release.sh`: `archive <n>` refuses a dirty tree, a `HEAD` whose `CI gate` is not `success` (`gh api repos/iglooo101/checkers/commits/<sha>/check-runs`), and a build number not higher than every row; `upload <archive>` reads `../secrets/appstoreconnect.txt` and the matching `AuthKey_<KEY_ID>.p8` (stops if missing or not mode 600), runs `xcodebuild -exportArchive -archivePath <archive> -exportOptionsPlist release/ExportOptions.plist -exportPath .build/Release/export -allowProvisioningUpdates -authenticationKeyPath … -authenticationKeyID … -authenticationKeyIssuerID …` without echoing them, then `record <n> uploaded`; `record <n> <state> [note]` per T041. T041 and `test-no-secrets.sh` pass.
- [ ] T044 [US5] **Owner:** create the App Store Connect API key (role App Manager) and save it as the contract says (`../secrets/AuthKey_<KEY_ID>.p8`, `chmod 600`, and `../secrets/appstoreconnect.txt` with `KEY_ID=` and `ISSUER_ID=`); recruit two to five external testers, at least one new to checkers. Record "key in place" (never its values) in `validation.md` §6.
- [ ] T045 [US5] **Apple:** the first upload (quickstart §6): on a commit whose `CI gate` passed, `scripts/release.sh archive <n>` then `upload`; confirm App Store Connect asks no export-compliance question and the build processes; `record <n> processed`. If the key cannot create the App Store profile, sign in Xcode's account path (research R14) and record which worked. Note in `validation.md` §6.
- [ ] T046 [US5] **Phone, Owner:** install the build from TestFlight on HKH16 and work through `Spec/checklists/release.md` on it (the agent runs the `scripts/device.sh` items on the same commit with the phone connected); record each result and the build; `record <n> "TestFlight internal"`.
- [ ] T047 [US5] **Owner, Apple:** enter the What to Test text from `release/store-listing.md` for the external group; submit the build for Beta App Review; once approved, invite the testers with at least one week for feedback; `record <n> external`. Record the playtest result and the feedback in `validation.md` §6 and the checklist.
- [ ] T048 [US5] For each problem the beta finds (FR-027): a behavior change goes into `FRD.md` first; then a failing test, the fix, CI, and a new build (`archive`/`upload` with the next number, with a note naming the checklist items it can affect); run those items again on it. Without problems, record "none" and close.

**Checkpoint**: US5 complete: a checked build has been through the owner's and the testers' hands.

---

## Phase 8: User Story 6 - Submitted and approved (Priority: P3)

**Goal**: The checked build submitted for review and approved, waiting for the owner to release it (#183: #187; FR-028 to FR-030).

**Independent Test**: `release.sh submit-check <n>` passes only when every checklist item is passed or accepted on that build; App Store Connect shows "Pending Developer Release"; the commit is tagged `v1.0`.

### Tests for User Story 6 (MANDATORY - write first) ⚠️

- [ ] T049 [P] [US6] Extend `scripts/tests/test-release-guards.sh` (a second description in its header: "US6 FR-028: only a fully checked build is submitted") with fixture `builds.md` and `release.md` pairs: `release.sh submit-check <n>` passes when every item is passed or accepted on `<n>`; fails on an open item, a failed item, an item accepted without a reason, `<n>` not the latest row, or `<n>` not yet processed; passes for an item passed on an earlier build when every later build's note says it cannot affect that item's ID, and fails when one does not. Fails until T050.

### Implementation for User Story 6

- [ ] T050 [US6] Add `submit-check <n>` to `scripts/release.sh` per the contract and research R16 (notes name unaffected items as "cannot affect RC-nn, …"). T049 passes.
- [ ] T051 [US6] **Owner, Apple:** when `scripts/release.sh submit-check <n>` passes, submit build `<n>` as version 1.0 with the App Review notes from `release/store-listing.md`, release set to manual; `record <n> submitted`. On a rejection (FR-029): record the round (reason and answer) in `Spec/checklists/release.md`; fix the listing, or the app through T048; `submit-check` again; resubmit.
- [ ] T052 [US6] **Apple:** on approval, confirm "Pending Developer Release" in App Store Connect, `record <n> approved`, tag the build's commit `git tag -a v1.0 <sha> -m "Version 1.0 (build <n>)"` and push the tag (FR-030; tags run no CI). Record in `validation.md` §7 (SC-010).

**Checkpoint**: US6 complete: version 1.0 is approved and waits for the owner; E8 is done.

---

## Phase 9: Polish & Cross-Cutting Concerns

- [ ] T053 [P] Update `checkers/CLAUDE.md`: the Diagnostics feature and its category; the three device log lines; the `checkers-device` scheme and the `Device` and `Screenshots` plans (and why device runs use `xcodebuild test`); the new scripts (`device.sh`, `device-timings.py`, `make-icon.py`, `screenshots.sh`, `traceability.py`, `release.sh`) and their tests; the `release/` and `docs/` folders; the display name catalog; the pre-push hook (`core.hooksPath`, T002); and the rule that a test naming an FRD ID needs `python3 scripts/traceability.py` run before committing. Before the first upload (T045).
- [ ] T054 Run `scripts/format.sh`, then confirm `scripts/check-format.sh --strict`, `scripts/tests/run.sh`, `scripts/check-string-catalog.sh checkers/checkers/Localizable.xcstrings .build/DerivedData`, `python3 scripts/traceability.py --check` and `scripts/test.sh` pass with zero warnings and zero SwiftLint errors. Before the first upload, and again before submission.
- [ ] T055 Run the quickstart (§1–§8) and record the results in `validation.md`; list what stays with the owner.
- [ ] T056 [P] Update `HANDOFF.md` (current state, lessons learned) and `EXECUTION_PLAN.md` (close-out checklist), at each story's close and at the end.
- [ ] T057 Final verification: push the branch, confirm `CI gate` is green with both jobs on the last code commit, fast-forward `main`, and record the CI run in `validation.md`.

---

## Dependencies & Execution Order

- **Setup (Phase 1)** first; T002 before the owner creates the key (T044).
- **Foundational (Phase 2)** before US1's phone session (T012) and all of US2.
- **US1** (P1, the MVP) next. **US2, US3 and US4** follow in any order: US3 and US4 change the app; US2's measurement (T021) is best taken after them, and the release checklist repeats it on every uploaded build anyway.
- **US5** needs US1 to US4: the icon is required to upload (T033), the listing and the record must exist (T039, T040), and the checklist (T042) gathers every story's checks. T053 and T054 come before its first upload (T045).
- **US6** after US5.
- **Polish**: T053 and T054 before T045; T055 to T057 at the end; T056 at every close-out.
- Tasks marked **Owner:**, **Apple:** or **Phone:** wait for those; the next story's code does not wait for them.

### Parallel Opportunities

- T001 and T002; T003 alone (T004, T005 follow).
- US1: T006, T007 and T008; then T009 and T010 (different files).
- US2: T015 and T016. US3: T023 and T024. US4: T029, T030, T031 and T032; T038 and T039 beside T036.
- US3 and US4 code beside US2's device tasks.
- T053 and T056.

## Implementation Strategy

1. Phases 1–2: validation log, the secrets guard, the device scheme and `device.sh`.
2. US1: the network guard, the traceability matrix, the archive check; the owner's session on the phone.
3. US3: diagnostics (the slice's only new feature).
4. US4: icon, name, encryption key, screenshots, pages, listing; the owner's approvals and the App Store Connect record.
5. US2: the timing lines, then launch and session measurements on the phone.
6. T053, T054, then US5: the key, the first upload, the release checklist, the external round.
7. US6: the submission gate, review, approval and the `v1.0` tag.
8. Polish: quickstart, docs, final CI and the fast-forward of `main`.
9. After each story: `scripts/test.sh` green, push, CI green, update the board and `EXECUTION_PLAN.md`.

## Requirement Coverage

| Spec / FRD IDs | Test tasks | Implementation and check tasks |
|---|---|---|
| FR-001, FR-003 · FR-PRIV-01 (no network, account, analytics, SDK) | T006 | T012 (App Privacy Report), T042 (RC) |
| FR-002 · FR-PRIV-02 (no permission) | T008, `PrivacyManifestTests` | T010, T012 |
| FR-004 · VI (privacy report of the signed build) | T008, T032 | T010, T013, T035 |
| FR-005 · FR-PLAT-01 (portrait, board fits, iPad window) | T011, `PlatformSettingsTests` | T011, T012, T014, T042 |
| FR-006 · FR-PLAT-03 (English, localizable) | T011 (`LocalizationTests`, catalog check), T030 (display name) | T035 |
| FR-007 (traceability) | T007 | T009, T042 |
| FR-008 · IX.1, IX.2 (diagnostics logged) | T023, T024 | T025–T027, T028 |
| FR-009 · IX.3 (redacted, on the phone only) | T023 (detail), `PrivacyManifestTests` | T026, T027 |
| FR-010 (unreadable report) | T023 | T025, T027 |
| FR-011 · VII.1 (cold launch) | T003, `LaunchPerformanceTests` | T004, T005, T021 |
| FR-012 · VII.2, VII.3 (hitches, hangs) | T016 | T017, T020, T021 |
| FR-013 (computer timing, sound delay) | T015 | T018, T019, T020, T021 |
| FR-014 · VII.4 (a miss is profiled) | — | T022 |
| FR-015 (icon) | T029 | T033, T034 |
| FR-016 (name "Checkers") | T030, T032 | T035 |
| FR-017 (launch screen) | T030 | T035 |
| FR-018 (listing complete, in the repository) | T031 | T039, T040 |
| FR-019 (screenshots) | T036 (the run is its own check: two identical runs) | T036, T037 |
| FR-020 (privacy label) | T031 (field present) | T039, T040 |
| FR-021 (public pages) | quickstart §4 `curl` checks | T038 |
| FR-022 (encryption) | T030, T032 | T035 |
| FR-023 (signed builds of checked commits, recorded) | T041 | T043, T045 |
| FR-024 (key outside the repository) | T002 (CI and the pre-push hook) | T043, T044 |
| FR-025 (TestFlight, internal and external) | — | T046, T047 |
| FR-026 (one release checklist) | T007 (manual checks in the matrix) | T042, T046 |
| FR-027 (beta fixes) | — | T048 |
| FR-028 (submit only the checked build, manual release) | T049 | T050, T051 |
| FR-029 (rejections) | — | T051 |
| FR-030 (tag v1.0) | — | T052 |
| FR-031 (no behavior change) | the whole blocking plan | T054 |
| FR-032 (Xcode 26.3) | — | constitution v1.2.0; CI pin unchanged |
| SC-001 | T007 | T009 |
| SC-002 | T006, T008 | T012, T013 |
| SC-003, SC-004, SC-005 | T015, T016 | T021 |
| SC-006 | T023 | T027, T028 |
| SC-007 | T029 | T034 |
| SC-008 | T031 | T038, T040 |
| SC-009 | T049 | T046, T047 |
| SC-010 | — | T052 |

## Board Mapping

Each board issue lists its task IDs and the requirements of the spec's traceability table (#175, 2026-10-25). #175 added #205 for the slice's setup and validation (T001, T053–T057) under F8.3 (#183), as #201 and #203 did for E5 and E6:

| Board task | Tasks |
|---|---|
| #177 No network, permissions, account or analytics; privacy report | T006, T008, T010, T012, T013 |
| #178 iPhone portrait-only on devices | T011, T014 |
| #179 FRD traceability check | T007, T009 |
| #192 MetricKit diagnostics subscriber | T023–T028 |
| #181 Cold launch under 400 ms | T003–T005, T021 (launch) |
| #182 Hitch-ratio check | T015–T020, T021 (session), T022 |
| #184 App icon and launch screen | T029, T030, T033–T035 |
| #185 Store metadata, screenshots, privacy label | T031, T032, T036–T040 |
| #186 TestFlight build and beta round | T002, T041–T048 |
| #187 Submit for App Store review | T049–T052 |
| #205 Validate the E8 slice and update project docs | T001, T053–T057 |

## Notes

- [P] tasks = different files, no dependencies.
- Each acceptance test names its story ID in its display name, method name or script description line.
- Each completed task leaves the app building and all tests passing; commit after each task or logical group, push once per story.
- Tasks for the owner and Apple are listed where they belong in the story, so the story's checkpoint is honest about what is still open.
