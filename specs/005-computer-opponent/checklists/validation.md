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
- *(T021: final levels, match scores and Hard's slowest turn.)*

## 1. All blocking tests (SC-001, SC-006 to SC-010)

*(T031, T033)*

## 2. Strength matches and counts (SC-002, SC-003)

*(T017, T021)*

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
