# Validation: Saving and Statistics

Results of the quickstart scenarios ([../quickstart.md](../quickstart.md)) and the measurements the
plan relies on. Development Mac: Intel Core i9-9980HK, 2.4 GHz, Xcode 26.3, Swift 6.2.4.

## Baseline (before any slice code)

- 2026-10-22, branch `006-saving-and-statistics` at `3892d41` (code identical to `main`):
  `scripts/test.sh` passes on the iPhone 17 simulator: **221 tests** (106 app unit tests in 26
  suites, 83 engine tests in 14 suites, 32 UI tests in 11 classes), 11 min 11 s.
- Saved size and speed (research, environment facts): the longest of 200 seeded random games
  played without ending it, 220 turns, is 23,317 bytes as JSON; encode 1.6 ms and decode 1.7 ms
  in Release, 1.7 and 2.0 ms in Debug; a `UserDefaults` write takes 5 µs and a read 1.5 µs.
- Launch arguments in the simulator (research R10, T001), checked with a throwaway UI test that
  was not committed:
  - `-lastGameSetup <hex>` of `{"opponent":"computer","difficulty":"hard","side":"dark"}` makes
    setup preselect Computer, Hard and Dark: launch arguments set stored data. **Pass.**
  - With Medium and Dark stored, `-lastGameSetup none` shows the defaults (Computer, Easy,
    Light), and the next launch without the argument shows Medium and Dark again: a text value
    reads as no data, and the stored value is untouched. **Pass.** So `-savedGame none` can show
    Home without a saved game (T023).

## Implementation measurements

- Setup and Foundational (T001–T007), 2026-10-22: engine tests (`swift test`) 89 pass in 22 s,
  with no lint findings, including the three new coding tests. With the validity check turned
  off for a moment, exactly the eight state-level damaged cases (no-progress counts, chains, no
  step, a third repetition) failed; positions, turn records and unknown names are rejected by
  their own decoders. App unit tests: 110 pass.
- US1 (T008–T012), 2026-10-22: `scripts/test.sh` passes on the iPhone 17 simulator: **237
  tests** (117 app unit tests in 28 suites, 86 engine tests in 15 suites, 34 UI tests in 12
  classes), 10 min 46 s. Found while running it: XCUITest reports the app as running in the
  background a moment before SwiftUI's scene phase becomes `.background`, so
  `testUS1_chainSurvivesBackground` waits two seconds before terminating the app; without the
  wait the save had not happened yet. The relaunched game shows the chain exactly as left, which
  only the background save can have written (no turn ended during the chain, and Home was not
  chosen). `GameSession.swift` reached SwiftLint's 400-line file limit, so saving lives in
  `GameSession+Saving.swift`, and every session that starts in the middle of a chain has the
  chain's piece selected.
- US2 (T013–T015), 2026-10-23: before T015 the new tests failed to compile (seen with
  `build-for-testing`); with it, US2's suites and the ones `tapStart()` changed pass
  (`US2AbandonTests`, `US2AbandonUITests`, `US6SetupUITests`, `US7NavigationUITests`), and
  `LocalizationTests` failed only on the alert's three texts until the catalog was synced.
  `scripts/test.sh` passes on the iPhone 17 simulator: **243 tests** (122 app unit tests in 29
  suites, 86 engine tests in 15 suites, 35 UI tests in 13 classes), 12 min 7 s. A finished game
  is never the saved game: the session sends `ended` once, from either side's last step or a
  resignation, and the router clears the save.
- US3 (T016–T019), 2026-10-23: before T018 the new unit tests failed to compile
  (`build-for-testing`: no `GameResult`, `AppRouter.record` or `StatisticsText`). With T018 and
  T019, US3's independent test set passes on the iPhone 17 simulator, with the suites that share
  its helpers: 24 unit tests in 5 suites (`US3RecordTests`, `US7NavigationTests`,
  `LocalizationTests`, `US1ContinueTests`, `US2AbandonTests`) and 8 UI tests
  (`US3StatisticsUITests`, `US7NavigationUITests`, `testUS5_auditStatistics`). The counts' plural
  variations ("1 win", "3 wins") were added to the String Catalog by hand, and
  `scripts/check-string-catalog.sh` confirms a sync keeps them. The full blocking plan was left
  to CI at the session's close-out: CI run 39954174275 (on `68c58c6`, the close-out commit
  after `3bc52eb`) passed with **252 tests** (129 app unit tests in 30 suites, 86 engine tests
  in 15 suites, 37 UI tests in 14 classes); `build-and-test` took 26 minutes and
  `engine-strength` 5.
- US4 (T020–T022), 2026-10-23: before T022 the new unit tests failed to compile
  (`build-for-testing`: no `restoreNotice` or `dismissRestoreNotice`). With T022 the four unit
  tests pass, over seven kinds of unreadable saved game (empty, cut short, bytes that are not
  text, not JSON, version 2, a finished game, a game the rules could not reach) and both kinds of
  unreadable record. Found in the UI tests: XCUITest does not see the identifier
  `home.restoreFailure.ok` on the alert's button (it stays in the code, per contracts/screens.md),
  so the tests find OK by label, taking the first match. A third UI test, `testUS4_bothDamaged`,
  showed that with both values damaged the record's alert never appeared: the first design
  presented it in the same update that closed the save's alert. Home now presents each notice from
  a `.task(id:)`, which runs after that update, and the test passes. `scripts/test.sh` with
  warnings as errors passes on the iPhone 17 simulator: **259 tests** (133 app unit tests in 31
  suites, 86 engine tests in 15 suites, 40 UI tests in 15 classes); its one SwiftLint warning (a
  test variable named `ok`) was fixed and US4's suites rerun; format and catalog checks pass.
  CI run 40023240169 on `216c170` failed at first only on the engine's SC-004 timing check
  (10.5 s against 10 s; the engine suite took 56 s instead of 19.6 s and the UI tests 1,201 s
  instead of 825 s: a slow runner, same image, engine unchanged); its rerun passed with **259
  tests** (133 app unit tests, 86 engine tests, 40 UI tests).
- T030 (#202), 2026-10-23: the SC-004 check failed locally with every core kept busy (16 `yes`
  processes on the Intel Mac's 16 logical cores): the wall-clock count took 10.02 s, against
  5.3 s unloaded. Timed by the counting thread's CPU time instead, the count takes 3.95 s
  unloaded and 6.92 s under that load (hyperthreads share a core), and the suite passes under
  the same load. `swift test`: 89 engine tests pass, no lint findings. CI run 40031135343 on
  `16ecf98` passed with **259 tests** (133 app unit tests, 86 engine tests, 40 UI tests).

## 1. All blocking tests

## 2. Continue after closing the app

## 3. New game with a saved game

## 4. Record

## 5. A damaged saved game or record

## 6. Accessibility

## 7. CI
