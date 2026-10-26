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
- **#206 investigation** (T058, 2026-10-26, in progress; engine unchanged, a temporary `print`
  of the CPU time in `sixTurnSpeed`, removed afterwards). CPU time of the 6-turn count:

  | Where | Beside it | Mac's `CPU_Speed_Limit` | CPU time (s) |
  |---|---|---|---|
  | `swift test` (Mac, Debug) | nothing | 100 | 3.97 (4.8 earlier) |
  | `swift test` (Mac, Debug) | the whole engine suite | not read | 6.97, 7.50, 7.82 |
  | Simulator, `xcodebuild test` | the engine's tests | not read | 11.6, 14.2 (both fail) |
  | Simulator, `xcodebuild test` | nothing | 62 after the run | 11.1, 11.1 (fail) |
  | Simulator, `xcodebuild test` | nothing | 100 before, 54 after | 9.5 |
  | Simulator, `test-without-building` | nothing | 100 before and after | 9.26, 9.21 |

  So the simulator build of the count takes about 9.2 s alone at full speed, 2.3 times the Mac
  build, leaving 0.8 s of margin; the build that `xcodebuild test` runs first heats the Mac
  until it throttles its clock (`pmset -g therm`), and parallel tests add the rest. The run
  gathers code coverage (`xcrun xccov view --report --only-targets` lists coverage for the
  run), which instruments the code: the next hypothesis for the 2.3 times, not yet tested.

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

## §5 Performance on the phone (US2)

## §6 TestFlight (US5)

## §7 Submission (US6)

## §8 CI

- **US3** (2026-10-26, `f328c30`, run 40272374316): `CI gate` green with both jobs:
  `build-and-test` 27.9 minutes (176 app unit tests, 59 UI tests, 86 engine tests; the engine's
  SC-004 check passed, 14.0 s of wall clock) and `engine-strength` 5.3 minutes. `main`
  fast-forwarded to `f328c30`.
