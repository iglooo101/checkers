# Validation: Release 1.0

Results of [quickstart.md](../quickstart.md), story by story, with every measurement (data model,
"Device measurement"). The release checklist that gates submission is
[release.md](release.md) (from T042).

- **Mac**: MacBook Pro 15-inch 2019 (Intel Core i9-9980HK), macOS 15.8.1, Xcode 26.3 (17C529),
  iOS 26.2 SDK.
- **Phone**: HKH16, iPhone 16 (iPhone17,3), iOS 27.0.1 (24A446), by cable, Developer Mode on.

## Baseline (T001, 2026-10-25)

Before any app code of the slice, on `008-release-1-0`:

- `scripts/test.sh` (blocking plan on the iPhone 17 simulator, iOS 26.3), at `5e45a6a`, whose
  changes since `5bf6a87` are scripts, the `checkers-device` scheme and `Device.xctestplan` only
  (no app, test or blocking-plan change): **313 tests pass** (168 app unit tests, 59 UI tests,
  86 engine tests; 0 failed, 0 skipped), the same 313 as E6's close-out; no compiler warning; 18.7
  minutes.
- `scripts/tests/run.sh`: 7 script tests pass at `5bf6a87`; 12 at `5e45a6a` (the five added by
  T002, T003, T006, T007 and T008).

## Research measurements (2026-10-25)

| What | Result | Research |
|---|---|---|
| Build, sign, install, launch on iOS 27.0.1 | works (Debug and Release, development signing; profile valid until 2027-10-15) | R1 |
| LLDB attach (`device select`, `device process attach`) | works once Xcode has copied the iOS 27.0.1 symbols (6.6 GB, several minutes the first time) | R1 |
| UI tests on the phone | work through `xcodebuild test` with a scheme; `test-without-building` cannot launch the app ("The process identifier of the launched application could not be determined") | R1, R3 |
| Instruments | `xctrace record` works (App Launch template); `xctrace export` crashes on every table of an iOS 27 trace (a simulator trace exports, 3 MB) | R1 |
| Release test build | the `checkers` scheme fails on the engine's `@testable` tests; a scheme without `CheckersEngineTests` builds | R3 |
| Cold launch, Release, five launches | 0.240, 0.237, 0.230, 0.230, 0.231 s; median 0.231 s (budget 0.4 s) | R4 |
| `XCTHitchMetric`, thirty fast Rules swipes, three iterations, Release | hitch time ratio 0, 0, 0 ms/s; hitches 0, 0, 0; total 0, 0, 0 s | R5 |
| The app's log on the Mac | `devicectl device process launch --console` with `OS_ACTIVITY_DT_MODE=YES` prints the app's `Logger` lines with microsecond times; a UI test using `activate()` drove the same process (ID unchanged) | R6 |
| UI test result bundles | do not contain the app's log | R6 |
| iPad compatibility | the iPhone-only app runs on the "iPad (A16) E8" simulator (iPadOS 26.3) in an iPhone-shaped window with window controls and a resize handle; Home shows normally | R17 |
| Found on the way | Developer Mode was off on the phone mid-session (`devicectl` error 10005; Instruments: "The device is missing the required developer tools"); after reconnecting, the phone showed as unavailable for about 15 s | R1 |

## §1 Automated checks

- **Script tests** (2026-10-25, `5e45a6a`): `scripts/tests/run.sh` passes all 12, among them
  `test-no-secrets`, `test-device`, `test-no-network`, `test-traceability` and
  `test-release-check`.
- **Traceability** (T009, 2026-10-25): `python3 scripts/traceability.py --check` passes;
  [traceability.md](../traceability.md) lists 84 FRD IDs covered by tests, FR-PLAT-02 removed and
  none missing.
- **Release test build** (T005, 2026-10-25, `5e45a6a`): `xcodebuild build-for-testing -scheme
  checkers-device -configuration Release -destination generic/platform=iOS` succeeds ("TEST BUILD
  SUCCEEDED"); it compiles only `checkers`, `CheckersEngine` and `checkersUITests` (the log never
  names `CheckersEngineTests`), and its `.xctestrun` holds the `Device` plan with
  `checkersUITests` alone. `scripts/test.sh` is unchanged since `970b5a9`.
- **Blocking plan with US3** (2026-10-26, US3's code on `4fc7275`, iPhone 17 simulator, iOS
  26.3): 320 of 321 tests pass (176 app unit tests, 8 more than the baseline; 59 UI tests; 85 of
  86 engine tests), no compiler warning, 19.8 minutes. The one failure is the engine's
  `US3 SC-004: the 6-turn count takes under 10 seconds of CPU time` at 10.2 s, with the engine
  unchanged since `16ecf98`: alone the count takes 4.8 s (`swift test --filter
  ReferenceCountTests/sixTurnSpeed`), beside the other engine suites 9.6 s (`swift test`, 89
  tests pass), as the busy cores of this Mac (8 cores, 16 hardware threads) slow the counting
  thread and inflate its own CPU time; CI's last code run (40238654507) measured 14.3 s of wall
  clock and stayed under 10 s of CPU time. Tracked as #206 (T058). The script tests (12), the
  strict format check and `scripts/check-string-catalog.sh` ("String catalog is up to date.")
  pass; `traceability.md` is unchanged (the new tests name spec IDs, no FRD ID).
- **#206 investigation** (T058, 2026-10-26; engine unchanged, a temporary `print` of the CPU
  time in `sixTurnSpeed`, removed afterwards). CPU time of the 6-turn count, first session:

  | Where | Beside it | Mac's `CPU_Speed_Limit` | CPU time (s) |
  |---|---|---|---|
  | `swift test` (Mac, Debug) | nothing | 100 | 3.97 (4.8 earlier) |
  | `swift test` (Mac, Debug) | the whole engine suite | not read | 6.97, 7.50, 7.82 |
  | Simulator, `xcodebuild test` | the engine's tests | not read | 11.6, 14.2 (both fail) |
  | Simulator, `xcodebuild test` | nothing | 62 after the run | 11.1, 11.1 (fail) |
  | Simulator, `xcodebuild test` | nothing | 100 before, 54 after | 9.5 |
  | Simulator, `test-without-building` | nothing | 100 before and after | 9.26, 9.21 |

  Second session: code coverage, the first session's last hypothesis. The built engine test
  binary is instrumented (`otool -l` shows `__llvm_prf_cnts` and the other profile sections),
  so a run with `-enableCodeCoverage NO` alone would still run instrumented code; a second build
  with `build-for-testing -enableCodeCoverage NO` (no profile sections) was timed beside it.
  Every run is `test-without-building` in the simulator, alone unless stated:

  | Simulator | Build | Mac's `CPU_Speed_Limit` | CPU time (s) |
  |---|---|---|---|
  | booted by the run | instrumented | 100 before and after | 7.77 |
  | booted by the run | coverage off | 100 before and after | 9.60, 8.55 |
  | booted by the run, Mac heating | instrumented, coverage off, instrumented | 100 → 82, 82 → 56, 56 → 64 | 8.94, 9.89, 10.83 (fail) |
  | booted and settled first | coverage off, instrumented | 100 before and after | 4.47, 4.47 |
  | booted and settled first, beside the engine's tests in parallel | coverage off, instrumented, instrumented | 100 before and after | 6.76, 7.87, 7.43 |
  | booted and settled first, the engine's tests one at a time (`-parallel-testing-enabled NO`) | instrumented | 100 before and after | 3.79 |

  So **coverage changes nothing** (4.47 s with and without), and the "2.3 times" was **the
  simulator's boot**: `test-without-building` and `xcodebuild test` boot the simulator when it
  is shut down and shut it down afterwards, and a boot drives the load average to about 50 and
  the Mac down to `CPU_Speed_Limit` 68 for about four minutes (`simctl boot`, then the load
  read every 10 s). Booted and settled first, the simulator build of the count takes 4.5 s like
  the Mac build. Beside the other engine suites it takes 6.8–7.9 s, as in `swift test`, and one
  at a time 3.8 s (the engine bundle then takes 55 s of wall clock instead of 28 s).
  In the blocking plan the boot is not the problem: the action log of US3's failed run
  (`xcresulttool get log --type action`) shows the engine bundle starting last, at 1,131 s of
  the 1,193-second run, once the UI tests had finished (1,118 s), so it ran with the other
  engine suites beside it on a Mac heated by 18 minutes of UI tests, and the run ended 62 s
  later (the bundle takes 28 s on a cool Mac). Of the three factors, heat cannot be removed by a test, while running the
  engine's tests one at a time removes the neighbours, the larger of the two others, and
  matches what SC-004 times: the engine's own speed.
- **#206 fix** (T058, 2026-10-26): `checkers.xctestplan` sets `"parallelizable" : false` on
  `CheckersEngineTests` only (the built `.xctestrun` then holds `InProcessParallelizationEnabled`
  0 for that bundle), so Swift Testing runs the engine's tests one at a time; the test and the
  engine are unchanged, only `sixTurnSpeed`'s comment says why. Alternating runs of the engine
  bundle in a settled simulator, as the Mac heated:

  | Run | Engine tests | Mac's `CPU_Speed_Limit` | Count's CPU time | Bundle (wall) |
  |---|---|---|---|---|
  | forced parallel (`-parallel-testing-enabled YES`, which also runs them on a new simulator clone) | in parallel | 100 → 100 | passed | 66 s |
  | the plan | one at a time | 100 → 100 | 4.15 s | 85 s |
  | forced parallel | in parallel | 100 → 76 | run failed (output not kept) | 106 s |
  | the plan | one at a time | 76 → 100 | 4.38 s | 89 s |
  | forced parallel | in parallel | 100 → 72 | run failed (output not kept) | 105 s |
  | the plan | one at a time | 72 → 100 | 4.32 s | 92 s |
  | forced parallel, output kept | in parallel | 100 → 68 | `sixTurnSpeed` failed (11.0 s) | — |

  (The wall times include starting the simulator's test runner.) `swift test --no-parallel` in
  `checkers/CheckersEngine` gives the same: 4.04 s (89 tests in 54.8 s) against 7.72 s in a
  plain `swift test` (27.3 s). **Blocking plan with the fix** (`scripts/test.sh` with CI's
  warnings-as-errors settings, iPhone 17 simulator, iOS 26.3, with the temporary `print`):
  **321 of 321 tests pass** (176 app unit tests, 59 UI tests, 86 engine tests in 50.3 s), the
  count took 3.86 s of CPU time, 19.8 minutes (Mac at 88 at the start, 100 at the end); after
  removing the `print`, the strict format check and the 12 script tests pass.

## §2 Promises on the phone (US1)

- **Archive check** (T010, 2026-10-25, `5e45a6a`): `scripts/release.sh archive 0` archives
  version 1.0 (0) in Release with Xcode 26.3 and the iOS 26.2 SDK, signed for team 5RH237UKVE
  (build 0 is never uploaded), then `check` passes: "no tracking, no tracking domains, no
  collected data, user defaults with CA92.1 only, no permission asked" (one manifest,
  `PrivacyInfo.xcprivacy`). The archive is `.build/Release/Checkers-1.0-0.xcarchive` for T013 and
  T014.
- **Board fit** (T011, FR-PLAT-01, 2026-10-25, `5e45a6a`): `testUS1_boardFitsAndShowsOnlyTheIndicator`
  passes alone on both ends of the supported sizes (iOS 26.3.1 simulators, Debug), and a
  screenshot of its two-player game on each shows the whole board in portrait under "Light to
  move", with the menu button and nothing else (the plan keeps attachments only on failure, so
  the built test ran from a copy of its `.xctestrun` with `SystemAttachmentLifetime` set to
  `keepAlways` and `PreferredScreenCaptureFormat` to `screenshots`; frames from its UI snapshot):

  | Device | Window (pt) | Board (pt) | Square (pt) |
  |---|---|---|---|
  | iPhone SE (3rd generation) | 375 × 667 | 367 × 367 at (4, 214.5) | 44.9 |
  | iPhone 17 Pro Max | 440 × 956 | 432 × 432 at (4, 330.3) | 53.0 |

  The SE's squares clear the 44-point minimum by 0.9 point: any wider frame or margin on the
  board would fail there first.
- **English and localizable** (T011, FR-PLAT-03, 2026-10-25): `LocalizationTests` passed in the
  baseline run (both tests), and `scripts/check-string-catalog.sh
  checkers/checkers/Localizable.xcstrings .build/DerivedData` reports "String catalog is up to
  date."

## §3 Diagnostics on the phone (US3)

- **Tests** (T023–T027, 2026-10-26): the fixtures (`Support/DiagnosticFixtures.swift`, key
  names written out, not taken from the app) and `US3DiagnosticsTests` (8 tests, 12 cases: one
  per kind, the contract's order and names, two crashes and a hang in kind order, no arrays,
  eight damaged payloads, a damaged payload before a good one, the detail's sorted keys, "none")
  failed to compile before `DiagnosticReport` existed, and `LoggingTests` lists the
  `diagnostics` category; with T025–T027 both suites pass alone and in the blocking plan.
- **Mutations** (2026-10-26): a wrong key for launch diagnostics failed only the launch case;
  skipping items that are not objects failed only the "crashDiagnostics holding strings" case
  of the two FR-010 tests; writing the detail without sorted keys failed every case that checks
  a detail, the reordered metadata among them. The parser was restored after each.
- **Start**: `CheckersApp` keeps one `DiagnosticsSubscriber` with an `OSLogDiagnosticsLog` and
  starts it from a `.task` on the root view; `PrivacyManifestTests` pass unchanged and the
  privacy manifest is untouched.
- **On the phone** (T028, 2026-10-26, owner): a Debug build from Xcode 26.3 at `a4a05f3` on
  HKH16 (iOS 27.0.1); after Home appeared, Debug › Simulate MetricKit Payloads gave five lines
  in Xcode's console, one per kind in the contract's order: "Crash reported for 2026-10-26
  01:45:41 to 2026-10-26 01:45:41; details: {…}", then Hang, CPU exception, Disk-write exception
  and Launch, each with its metadata as JSON with sorted keys (for example `"hangDuration":"20
  sec"`, `"totalCPUTime":"20 sec"`, `"writesCaused":"2000 byte"`, `"launchDuration":"20000
  ms"`, and for the crash `"signal":11` with an Objective-C exception reason). No "could not be
  read" line. Apple's key names match contracts/diagnostics.md; the time stamps have no zone
  (the contract's example now shows that form; the parser keeps them as written). The details
  were readable because Xcode's debugger was attached; without it they are redacted as private.
  The sample payloads report `"lowPowerModeEnabled":true`, most likely sample data (`pid` 123,
  "testEventName"), but Low Power Mode is checked off before US2's measurements (T021). SC-006
  met.

## §4 Icon, name, launch screen, screenshots, listing, pages (US4)

- **Icon** (T029, T033, 2026-10-26): `scripts/make-icon.py` draws the three 1024 × 1024 files in
  1.4 s on the development Mac: `AppIcon.png` (8-bit RGB, 19,105 bytes), `AppIcon-Dark.png`
  (8-bit RGBA, the piece and its crown only, 19,428 bytes) and `AppIcon-Tinted.png` (8-bit
  grayscale, Rec. 709 weights, 12,296 bytes), each with an `sRGB` chunk, and names them in
  `Contents.json` (Xcode's layout kept: the file round-trips byte for byte). The artwork: a disc
  of radius 320 with a 40-pixel `#A88F5F` edge (6.25% of the diameter; the app's is 6.6%) and a
  `#FFFAF0` face, a drawn crown (`#6B4426`, a polygon 376 pixels wide at its points with three
  balls of radius 28: 59% of the piece's width at its points, where the app's crown is 55%; the app's `crown.fill` is an SF Symbol, which Apple does not allow
  in app icons), on a two-by-two corner with dark squares at the bottom left and top right.
  `test-make-icon.sh` failed on the missing script and files before, and passes. **Mutation**:
  one channel of `AppIcon-Dark.png` raised by two steps made `--check` fail, naming the file;
  restored from a backup (the files were untracked). `--check` also reads a `sips` re-encode of
  `AppIcon.png` (row filters 1–4) as the same pixels.
- **Name, encryption, launch screen** (T030, T032, T035, 2026-10-26): the app target's Debug and
  Release settings have `INFOPLIST_KEY_CFBundleDisplayName = Checkers` and
  `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO`, and `App/InfoPlist.xcstrings` holds the
  name (en, translated). `PlatformSettingsTests`: the FR-016 (also through
  `localizedInfoDictionary`) and FR-022 tests failed with both keys nil, and pass; the FR-017
  test passed at once and was proven by a mutation (a temporary `INFOPLIST_FILE` adding
  `UILaunchScreen` › `UIColorName` AccentColor to the Debug build failed only that test;
  removed). `release.sh check` now names a display name other than "Checkers", a missing
  encryption key and a version other than 1.0; the three fixture variants of
  `test-release-check.sh` passed the old check. The owner's phone check of the name and the
  launch screen in light and dark is part of T034.
- **Full checks** (2026-10-26, the batch before its push): the blocking plan with CI's
  warnings-as-errors settings passes 324 of 324 in 20 minutes (179 app unit tests, 59 UI tests,
  86 engine tests; the 6-turn count passed after 5.0 s); the strict format check and the 13
  script tests pass; `traceability.py --check` is unchanged (no new FRD IDs).
- **Store listing** (T031, T039, 2026-10-28): `release/store-listing.md` holds the 15 fields of
  the contract, each paragraph and list item on one line (App Store Connect keeps line breaks).
  Lengths with comments removed: name 29 characters ("Checkers – Classic Board Game", a proposal),
  subtitle 29, promotional text 149, description 1,641 in seven paragraphs (each followed by its
  FRD IDs), keywords 94 bytes, App Review notes 744 bytes, What to Test 636. Every description
  sentence was read against FRD v1.3 and the review notes' labels against the string catalog
  (New game, Two players, Computer, Start, Continue, Statistics; the game menu at the top
  right). `test-store-listing.sh` failed on the missing listing, then passes; it is the 14th
  script test. Open for the owner: the texts, the name and the copyright holder's name.
- **Public pages** (T038, 2026-10-28): `docs/index.md` and `docs/privacy.md` landed on `main` in
  `74541c2` (docs-only CI); the owner enabled Pages from `main` and `/docs` (the auto-mode safety
  check blocks that call); the first build took 36 s. `https://iglooo101.github.io/checkers/`
  and `https://iglooo101.github.io/checkers/privacy/` answer 200, the support page contains
  "GitHub" and links to `privacy/`, and the privacy page contains "collects no data"
  (quickstart §4). The privacy page also says the data is part of the iPhone's own backups.
- **Screenshots** (T036, 2026-10-28): `ScreenshotUITests` (six tests, skipped by the blocking
  plan) through `Screenshots.xctestplan` (English, US, no coverage) on the iPhone 17 simulator,
  iOS 26.3, by `scripts/screenshots.sh`. States: Home with a saved game; a Medium game against
  the computer ten turns in, Light to move, six pieces hinted; a two-player game where c3 has
  jumped to e5 and must go on to c7 ("capture required", e5 selected, c7 marked); a two-player
  game after e7–d8 crowns a Light king, Dark to move; the top of Rules; Statistics with
  7/1/1, 4/3/2 and 1/4/1. The three game positions come from seeded random games played by the
  engine in a scratch package (20,000 seeds in 0.2 s), checked as boards, and are saved with an
  empty history. Each test redraws `XCUIScreen.main.screenshot()` on an opaque
  `UIGraphicsImageRenderer` (standard range), so every file is 1206 × 2622, 8-bit RGB, no alpha,
  sRGB IEC61966-2.1 (`sips`), 104–275 KB. First run: all six written, 3.3 minutes with the
  build, the tests 75 s. Second run: "No screenshot changed.", 1.2 minutes, every file
  byte-identical (`shasum`) (FR-019). The status bar shows 9:41, full signal and a charging
  battery (`--batteryState charged`, as the contract says). The owner's approval is T037.

## §5 Performance on the phone (US2)

## §6 TestFlight (US5)

## §7 Submission (US6)

## §8 CI

- **US3** (2026-10-26, `f328c30`, run 40272374316): `CI gate` green with both jobs:
  `build-and-test` 27.9 minutes (176 app unit tests, 59 UI tests, 86 engine tests; the engine's
  SC-004 check passed, 14.0 s of wall clock) and `engine-strength` 5.3 minutes. `main`
  fast-forwarded to `f328c30`.
- **US4, first batch** (2026-10-27, `325b4b3`, run 40432329029): `CI gate` green with both jobs:
  `build-and-test` 31.9 minutes (179 app unit tests, 59 UI tests, 86 engine tests in 42.9 s one
  at a time; the SC-004 count passed after 4.6 s; the launch timing test reported) and
  `engine-strength` 6.1 minutes. `main` fast-forwarded to `325b4b3` on 2026-10-28.
