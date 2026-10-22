# Validation: Computer Opponent

Results of the quickstart scenarios ([../quickstart.md](../quickstart.md)) and the measurements the
plan relies on. Development Mac: Intel Core i9-9980HK, 2.4 GHz, Xcode 26.3, Swift 6.2.4.

## Baseline (before any slice code)

- 2026-10-22, branch `005-computer-opponent` at `b7e5ed3` (code identical to `main`):
  `scripts/test.sh` passes on the iPhone 17 simulator: **163 tests** (73 app unit tests in 21
  suites, 63 engine tests in 11 suites, 27 UI tests), 9 min 27 s.
- Engine speed through the public API, from the start (research, environment facts): Release
  175,000–182,000 steps applied per second (6 turns 0.26 s, 7 turns 1.28 s, 9 turns 30.9 s);
  Debug 10,600–11,000 per second (6 turns 4.4 s, 7 turns 20.7 s).
- Time Profiler, Release, 8-turn count: 55% of samples in array growth; `malloc`, `free` and
  object allocation 33% of self time; `GameState.legalSteps` 48% and `endTurn` 39% inclusive.
- Allocation-free prototype: published counts for 1–10 turns reproduced; Release about 25 million
  turns per second, unoptimized about 400,000.

## Implementation measurements

- T011, search speed from the start, Release (`swift test -c release`), margin 0: depth 6 10,701
  nodes in 0.003 s; depth 8 103,801 nodes in 0.027 s; depth 10 683,574 nodes in 0.150 s, that is
  3.3–4.6 million nodes per second. Engine tests in Debug (`swift test`): all 76 pass in 21.5 s,
  the 1,000-position cross-check of the turn generator 4.7 s of that.
- US1 (T001–T015), 2026-10-22: `scripts/test.sh` passes on the iPhone 17 simulator: **192 tests**
  (87 app unit tests in 23 suites, 76 engine tests in 13 suites, 29 UI tests), 9 min 48 s plus
  the audit rerun. Found while running it: with Computer chosen, Start is the setup row the
  audit's enlarged text cuts at the screen's edge, so E7's edge-cut exception now covers Start
  as well (plan, audit allow-list); and a UI test cannot see the half-second thinking sentence
  after a tap (research R12), so it is covered by unit tests and previews.
- T012, privacy manifest: `EngineComputerOpponent` is the app's first use of `ContinuousClock`
  (for the 0.8 s limit and the logged thinking time). Apple's required-reason list names, for
  system boot time, `systemUptime` and `mach_absolute_time()`, not Swift's clocks, so
  `PrivacyInfo.xcprivacy` is unchanged; the Xcode privacy report of the first release archive
  confirms it (#177).
- US2 tests first (T016–T018), 2026-10-22: `US2ComputerLevelTests` failed 5 of 7 tests while every
  level searched to depth 4 and played its first best turn (limits, the four-turn position, the
  node cap, opening variety, ties at Hard's margin); the strength suite did not compile until
  `SeededGenerator` moved into the engine, then failed both matches at 50 of 100 points and the
  six-turn position; `test-ci-gate.sh` failed 5 cases until `gate.sh` took the
  `engine-strength` result. Two deviations from the task text: the matches' score (SC-003) and
  their legality (SC-002) are checked on the same 100 games in one parameterized test, and
  "only turns with the best score" is checked on a position with an exact tie by construction
  (a king's two four-man chains ending on the same board), since scores from the start depend on
  the evaluation weights.
- US2 (T016–T020), 2026-10-22: engine tests in Debug (`swift test`): 86 pass in 22.7 s, and
  the strength suite's 3 tests are skipped there ("Run with swift test -c release").
  `scripts/test.sh` with warnings as errors passes on the iPhone 17 simulator: **199 tests**
  (87 app unit tests, 83 engine tests, 29 UI tests), 9 min 31 s. Script tests, the strict format
  check, SwiftLint over the engine and its tests, and the string catalog check pass.
- T021, final levels: the starting values of research R4 (Easy depth 2, margin 40; Medium depth
  4, margin 8; Hard depth 16, 1,500,000 nodes, margin 0) and the starting evaluation weights
  (R3). Hard's turns in 12 match games played one at a time (scratch harness, the same openings
  and seeds as the test): 522 turns, mean 262 ms, slowest 419 ms (1,500,160 nodes, depth 10),
  492 stopped by the node limit after completing depth 9 to 12, 3.6–7.4 million nodes per
  second. Goal: at most 0.5 s.
- Turn generator in Release (9-turn count from the start, 5,035,307 turns generated): 201–223 ms,
  22.5–25.0 million turns per second, above the plan's 10 million.

## 1. All blocking tests (SC-001, SC-006 to SC-010)

*(T031, T033)*

## 2. Strength matches and counts (SC-002, SC-003)

- 2026-10-22, development Mac, `swift test -c release --filter CheckersEngineStrengthTests`: 3
  tests pass in 192 s (3 min 28 s with the build).
  - Medium against Easy: **90.0 of 100** (83 wins, 14 draws, 3 losses).
  - Hard against Medium: **99.0 of 100** (98 wins, 2 draws), 188 s with the 100 games in
    parallel; Hard's slowest turn replayed alone 376 ms (depth 12, 1,500,160 nodes).
  - Every step of all 200 games applied through `GameState.apply`, and every game ended (SC-002).
  - Turn generator counts for 1–9 turns match the published counts.
  - In the six-turn position Hard plays e5–f4 for every seed and Medium never does.
- CI, 2026-10-22, run 39841996479 on `59ab67b` (the first with the `engine-strength` job): `CI
  gate` passed. `engine-strength` took 4 min 31 s (build 28 s, the 3 tests 226 s), within the
  15-minute budget, and gave the same results as the Mac: Medium 90.0 and Hard 99.0 of 100 with
  the same wins and draws, Hard's slowest turn replayed alone 283 ms (depth 10), the turn
  generator 25.3 million turns per second. `build-and-test` took 19 min.

## 3. Play the computer (SC-001, US1, US3, US4)

*(T033)*

## 4. Playtest (SC-004, US2)

*(For the user.)*

## 5. Timing on an iPhone (SC-005)

*(For the user, or the Mac measurement as the closest proxy.)*

## 6. VoiceOver (US5)

*(For the user.)*

## 7. CI

*(T035)*
