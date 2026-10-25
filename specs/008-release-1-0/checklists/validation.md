# Validation: Release 1.0

Results of [quickstart.md](../quickstart.md), story by story, with every measurement (data model,
"Device measurement"). The release checklist that gates submission is
[release.md](release.md) (from T042).

- **Mac**: MacBook Pro 15-inch 2019 (Intel Core i9-9980HK), macOS 15.8.1, Xcode 26.3 (17C529),
  iOS 26.2 SDK.
- **Phone**: HKH16, iPhone 16 (iPhone17,3), iOS 27.0.1 (24A446), by cable, Developer Mode on.

## Baseline (T001, 2026-10-25)

Before any slice code, on `008-release-1-0` at `5bf6a87`:

- `scripts/test.sh` (blocking plan on the iPhone 17 simulator, iOS 26.3): BASELINE_TESTS.
- `scripts/tests/run.sh`: 7 script tests pass.

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

## §2 Promises on the phone (US1)

## §3 Diagnostics on the phone (US3)

## §4 Icon, name, launch screen, screenshots, listing, pages (US4)

## §5 Performance on the phone (US2)

## §6 TestFlight (US5)

## §7 Submission (US6)

## §8 CI
