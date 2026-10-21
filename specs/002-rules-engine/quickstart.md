# Quickstart: validating the rules engine

Run these scenarios to prove the slice works. Each names the user story or success criterion it
validates. Commands run from the repository root unless noted. The API under test is in
[contracts/engine-api.md](contracts/engine-api.md); the reference numbers are in
[research.md](research.md) (R1).

## Prerequisites

- Xcode 26.3 selected, as for E1 (see `specs/001-project-foundation/quickstart.md`).
- Nothing else: the engine tests need neither the app nor a simulator.

## 1. The whole engine suite on the Mac (SC-005)

```sh
(cd checkers/CheckersEngine && swift test)
```

Expected: every test passes without building the app, with zero compiler warnings. Record the
total time in `checklists/validation.md`; the target is under 60 s on the development Mac
(research R12). `swift test` does not run SwiftLint; the Xcode build in §6 does.

## 2. One story at a time (US1–US5)

```sh
cd checkers/CheckersEngine
swift test --filter US1   # start and simple moves: start position, 7 opening moves, c3–d4, men only forward
swift test --filter US2   # captures and kings: forward-only man captures, king in four directions, mandatory capture, free choice
swift test --filter US3   # chains and crowning: jump by jump, chain lock, crowning ends the turn, step results
swift test --filter US4   # endings: no pieces, blocked, resignation, threefold repetition, 80 turns without progress, no moves after the end
swift test --filter US5   # undo: one turn at a time, back to the start, mid-chain, unavailable after the end, repetition uncounted
```

Expected: each command runs that story's suite, and every acceptance scenario in the spec has a
passing test whose name starts with the story ID.

## 3. Reference move counts and speed (SC-002, SC-004)

```sh
(cd checkers/CheckersEngine && swift test --filter ReferenceCount)
```

Expected: the counts of complete-turn sequences from the starting position are 7, 49, 302, 1,469,
7,361, 36,768 and 179,740 for 1 to 7 turns, and the 6-turn count finishes in under 10 s.

## 4. Random games (SC-003)

```sh
(cd checkers/CheckersEngine && swift test --filter RandomGame)
```

Expected: 1,000 seeded games of random legal steps all reach an outcome within the turn bound;
the invariants in `data-model.md` hold after every step; and from the start of each game's
final turn, undoing every turn returns the exact state recorded before it, back to the starting
state. A failure names the seed and game number, so it can be replayed.

## 5. Requirement coverage (SC-001)

```sh
grep -rhoE 'FR-(RULE|CHAIN|END|UNDO|SETUP)-[0-9]+' checkers/CheckersEngine/Tests | sort -u
```

Expected: exactly these 21 IDs, each named by at least one test: FR-RULE-01 to FR-RULE-07,
FR-CHAIN-01 to FR-CHAIN-03, FR-END-01 to FR-END-05, FR-UNDO-01, FR-UNDO-02, FR-UNDO-05,
FR-UNDO-06, FR-UNDO-07 and FR-SETUP-06.

## 6. In the app's test plan and CI

```sh
scripts/test.sh
xcrun xcresulttool get test-results tests --path .build/TestResults/checkers.xcresult | grep -c CheckersEngineTests
```

Expected: the blocking test plan passes with zero SwiftLint errors (this Xcode build is what
lints the engine) and its results include `CheckersEngineTests` (E1 lesson: check that package
tests actually ran). After pushing the branch, the `CI gate` check is green.

## 7. Engine stays UI-free (SC-005, FR-025)

Add `import SwiftUI` to any file under `checkers/CheckersEngine/Sources/` and build with Xcode:

```sh
(source scripts/lib.sh && xcodebuild build-for-testing "${XCODEBUILD_FLAGS[@]}")
```

Expected: the build fails with the `engine_no_ui_imports` lint error. Revert the change.
