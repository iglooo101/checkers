---

description: "Task list for the computer opponent slice (epic E4)"
---

# Tasks: Computer Opponent

**Input**: Design documents from `/specs/005-computer-opponent/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/computer-player.md, contracts/computer-turn.md, quickstart.md

**Tests**: Tests are MANDATORY (Constitution III). Engine logic is tested with Swift Testing in `CheckersEngineTests` (Debug, blocking) and `CheckersEngineStrengthTests` (Release, CI job `engine-strength`); app logic in `checkers/checkersTests/`; the running app with XCUITest in `checkers/checkersUITests/`. Suites are named `US<n>…Tests`, display names start with the story ID and list the FRD IDs they prove, and UI test methods are named `testUS<n>_…`. Test tasks come before the implementation tasks they cover and must be observed failing (or failing to compile) before implementation begins. The computer's timing is tested without waiting, through `ManualPacer` and `ScriptedComputerOpponent` (research R8, R13).

**Organization**: Tasks are grouped by user story. A test task is complete together with the implementation tasks it covers (red, then green): no commit or push is ever red, so every completed task leaves the app building and all tests passing (Constitution workflow gate 3).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US5)
- Shorthands: `Engine/` is `checkers/CheckersEngine/Sources/CheckersEngine/`, `EngineTests/` is `checkers/CheckersEngine/Tests/CheckersEngineTests/`, `StrengthTests/` is `checkers/CheckersEngine/Tests/CheckersEngineStrengthTests/`, `App/` is `checkers/checkers/`, `Unit/` is `checkers/checkersTests/`, `UI/` is `checkers/checkersUITests/`.

## Conventions used by every task

- As in E3 and E7: `scripts/test.sh` runs everything with SwiftLint; one suite with `-only-testing`; engine tests alone with `(cd checkers/CheckersEngine && swift test --filter …)` (no lint); sync the catalog with `scripts/sync-string-catalog.sh` after string changes; previews in light, dark and `accessibility5`; no force unwraps outside tests; no test-only behavior in the app; commit failing tests with their implementation; push once per story and wait for CI; move board tasks to In Progress before a story and Done after its CI (summaries with `gh issue comment`).
- Texts and timings follow [contracts/computer-turn.md](contracts/computer-turn.md); the engine API follows [contracts/computer-player.md](contracts/computer-player.md). Announcement texts are checked as resolved English strings.
- Engine tests in the blocking plan run in Debug on the simulator: keep their searches shallow (depth 4 or less, or a node limit) and their game counts small; anything heavier goes in `StrengthTests/`.

---

## Phase 1: Setup (Shared Infrastructure)

- [X] T001 Create `specs/005-computer-opponent/checklists/validation.md` with one section per quickstart scenario (1–7) and a "Baseline" section: `scripts/test.sh` passes before any slice code (record the count), and the engine speed and profile figures from research "Environment facts".
- [X] T002 [P] Add the `computer` category to `App/Support/Logging.swift` (`Log.computer`) and to `Unit/LoggingTests.swift` (categories `["app", "game", "setup", "computer"]`), test first.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The search's turn generator and the app's two seams, used by every story.

- [X] T003 [P] Write `EngineTests/TurnGeneratorTests.swift` (`struct TurnGeneratorTests`):
  - `FR-AI-01`: complete-turn counts from the start through `TurnGenerator` equal the published counts for 1–7 turns (the values in `ReferenceCountTests`).
  - `FR-AI-01`: for 1,000 positions reached by seeded random play through `GameState` (`SeededGenerator`, seed per position), the set of boards after each complete turn equals the set reached by enumerating complete turns with `GameState.legalSteps` and `apply`, and each turn's capture count and progress flag match.
  - `FR-AI-01`: a chain that crowns ends there; a king may continue jumping; only jumps when any jump exists.
  Fails to compile until T004.
- [X] T004 Create `Engine/TurnGenerator.swift` per research R1 and data-model.md: internal `Board` (Light, Dark and kings as `UInt32`, `init(_ position: Position)`), neighbor and landing tables built once, and `TurnGenerator` writing complete turns (board after, captures, progress) into a caller-owned reusable buffer without allocating per node. T003 passes.
- [X] T005 [P] Write `Unit/ComputerSeamTests.swift` (`struct ComputerSeamTests`): `ScriptedComputerOpponent` returns its scripted turns in order and, when it has none left, waits until its task is cancelled and returns `nil`; `ManualPacer` records each requested `Duration` in order and resumes a pause only when `resumeNext()` is called; `SleepingPacer.pause` throws `CancellationError` when its task is cancelled. Fails to compile until T006.
- [X] T006 Create `App/Features/Game/TurnPacer.swift` (`protocol TurnPacer`, `struct SleepingPacer`), `App/Features/Game/ComputerOpponent.swift` (`protocol ComputerOpponent`, `final class ScriptedComputerOpponent`) and `Unit/Support/ManualPacer.swift`, per data-model.md. Add `opponent: any ComputerOpponent` and `pacer: any TurnPacer` to `GameSession.init` with app defaults (the live opponent arrives in T012; until then default to `ScriptedComputerOpponent()`), unused so far. T005 passes.

**Checkpoint**: `scripts/test.sh` passes; nothing user-visible has changed.

---

## Phase 3: User Story 1 - Play a game against the computer (Priority: P1) 🎯 MVP

**Goal**: Setup starts computer games; the computer thinks, pauses, plays legal turns, shows chains jump by jump and opens as Light (#107, #108, #109, #103, #104; FR-001 to FR-010).

**Independent Test**: `-only-testing:checkersTests/US1ComputerGameTests -only-testing:checkersTests/US6SetupTests -only-testing:checkersUITests/US1ComputerGameUITests`, and `swift test --filter US1ComputerPlayerTests` in the engine.

### Tests for User Story 1 (MANDATORY - write first) ⚠️

- [X] T007 [P] [US1] Write `EngineTests/US1ComputerPlayerTests.swift` (`struct US1ComputerPlayerTests`). Every search here uses Easy, Medium or explicit `SearchLimits` of depth 4 or less through the internal `chooseTurn(in:limits:seed:shouldStop:)`, never Hard's full limits (Debug run; Hard at full strength is exercised only in `StrengthTests/`):
  - `US1 FR-AI-01`: from the start, and from 50 seeded random positions, at Easy, at Medium and with depth-4 limits, the returned turn's steps apply with `GameState.apply`, every step but the last continues the chain and the last ends the turn.
  - `US1 FR-AI-01`: with a capture available the turn captures; with a double jump available it contains both jumps; a chain that reaches the far row stops there.
  - `US1 FR-AI-01`: `nil` once the game is over and during a chain in progress.
  - `US1 FR-AI-01`: takes a free piece; does not move a man where it is captured for nothing; with a two-for-one shot available, plays it; prefers a win in one turn to a win in three.
  - `US1 FR-AI-01`: a turn that repeats a position of the game (third occurrence) scores 0; a position won on material but at 79 no-progress turns scores 0 after a non-progress turn.
  - `US1 FR-AI-01`: `shouldStop` returning true at once still returns a legal depth-1 turn; the same state, limits and seed give the same turn; `nodes` and `depth` are reported.
  Fails to compile until T011.
- [X] T008 [P] [US1] Write `Unit/US1ComputerGameTests.swift` (`struct US1ComputerGameTests`), with `ScriptedComputerOpponent`, `ManualPacer` and `RecordingAnnouncer`, the player as Light unless stated:
  - `US1 FR-AI-03 FR-MOVE-04`: after `c3–d4`, `computerPhase == .thinking`, `turnText` is "Dark is thinking…", `hintedPieces` and `targets` are empty, every square's `state(of:)` is `none`, a tap on a Light man selects nothing and `beginDrag` returns false; after taps and a drag during the computer's turn, once its turn ends nothing is selected, no notice shows and the hints are the player's usual movable pieces.
  - `US1 FR-AI-03`: the pacer was asked for 0.5 s; the scripted turn (`f6–e5`) is not applied until both the opponent has answered and the pause is resumed, in either order; then `computerPhase == .idle` and `turnText` is "Light to move · capture required".
  - `US1 FR-AI-05`: a scripted two-jump turn: after the first jump `computerPhase == .playing`, the captured piece is gone and the pacer was asked for another 0.5 s; after resuming, the second jump is applied and the turn ends.
  - `US1 FR-AI-06`: with the player as Dark, `startComputerTurnIfNeeded()` starts thinking at once in a new game; with the player as Light it does nothing.
  - `US1 FR-END-06`: a scripted computer turn that ends the game leaves `resultText` set and `computerPhase == .idle`.
  - `US1 FR-004`: when the opponent returns `nil` while the game is in progress (not cancelled), the session plays the first legal turn.
  - `US1 FR-AI-01`: `EngineComputerOpponent` at Easy returns a legal turn for the start position and for Dark after `c3–d4`.
  - `US1 FR-AI-06`: through `AppRouter`, `startGame()` with Computer and side Dark starts the computer's turn; `playAgain()` with side Random draws again and the computer moves first when it gets Light.
  Fails to compile until T012–T014.
- [X] T009 [P] [US1] Rewrite the setup tests for FR-001 to FR-003, test first: in `Unit/US6SetupTests.swift`, first use is Computer, Easy, Light; changing choices does not save them; `startGame()` saves them and opens the game for every opponent (computer included); in `Unit/US1TwoPlayerMoveTests.swift`, replace the `canStart` test with "a two-player game starts from setup". Fails to compile until T014.
- [X] T010 [P] [US1] Write `UI/US1ComputerGameUITests.swift`: `testUS1_computerReplies`: New game → Computer → Easy → Light → Start; move c3–d4; `game.turn` reads "Dark is thinking…"; within 3 s it reads "Light to move" (or "… · capture required") and the set of squares reading "…, Dark man" differs from the start. `testUS1_computerOpensAsLight`: side Dark → Start; within 3 s a Light man has left row 3 and `game.turn` reads "Dark to move" (or "… · capture required"). Update `UI/US6SetupUITests.swift`: Computer shows difficulty and side and Start is enabled (no `setup.computerNote`); after starting a game with Computer, Hard, Dark and relaunching, setup preselects them. Fails until T015.

### Implementation for User Story 1

- [X] T011 [US1] Create in `Engine/`: `ComputerLevel.swift` (public enum with internal `limits: SearchLimits`; for now every level uses depth 4, no node limit, margin 0), `Evaluation.swift` (research R3 starting weights), `Search.swift` (research R2: negamax alpha-beta over `TurnGenerator` turns, iterative deepening, captures at the horizon, endings and draws from the game's turn records and the path, node counting with `shouldStop` every 1,024 nodes, last completed iteration kept), and `ComputerPlayer.swift` (`ComputerTurn`, public `chooseTurn(in:level:seed:shouldStop:)` calling the internal `chooseTurn(in:limits:seed:shouldStop:)`, root turns enumerated through `GameState`, ties broken by root order). T007 passes; record Release search speed (nodes per second at depth 8 from the start) in `validation.md`.
- [X] T012 [US1] Add `EngineComputerOpponent` to `App/Features/Game/ComputerOpponent.swift` (a `@concurrent` function running `ComputerPlayer.chooseTurn` with a seed from the system generator and `shouldStop` = cancelled or 0.8 s since thinking began; returns `nil` when cancelled; one `Log.computer` debug line per turn) and `Difficulty.computerLevel` to `App/Features/Setup/GameSetup.swift`; make it `GameSession`'s default opponent and `SleepingPacer` its default pacer. This is the app's first use of `ContinuousClock`: confirm against Apple's required-reason API list that it needs no new `PrivacyInfo.xcprivacy` entry (the list names `systemUptime` and `mach_absolute_time`, not Swift clocks) and record the finding in `validation.md`.
- [X] T013 [US1] Extend `App/Features/Game/GameSession.swift` per data-model.md and the contract's Timeline and Input tables: `computerSide`, `computerPhase`, `isComputerTurn`, `startComputerTurnIfNeeded()`, the turn task (thinking and the 0.5 s pause together, then each step with 0.5 s before each further jump, a cancellation check after every wait, the first-legal-turn fallback), `cancelComputerTurn()`, the input lock, empty hints and targets, `none` square states, and the thinking `turnText`; start the computer's turn after a player's step ends the turn. Add `GameText.thinking(_:)` ("Light is thinking…", "Dark is thinking…") with explicit `return`s. T008 passes.
- [X] T014 [US1] Setup and router: in `App/Features/Setup/GameSetup.swift` make `defaults` Computer, Easy, Light and remove `canStart`; in `App/Features/Setup/SetupView.swift` remove the computer note and the Start condition; in `App/App/AppRouter.swift` stop saving on every change, save in `startGame()`, call `startComputerTurnIfNeeded()` after `startGame()` and `playAgain()`, and cancel the old session's turn when leaving or replacing it. Remove the note from the catalog and `Unit/LocalizationTests.swift`, add the thinking sentences, sync the catalog. T009 passes.
- [X] T015 [US1] Show the thinking header in `App/Features/Game/GameView.swift`: while `isComputerTurn`, a `ProgressView` (`game.thinking`, hidden from VoiceOver) beside the turn text; add previews of a computer game while it thinks (a `ScriptedComputerOpponent` with no turns) in light, dark and `accessibility5`. T010 passes; all tests pass.

**Checkpoint**: US1 complete: a full game against the computer can be played (at one strength).

---

## Phase 4: User Story 2 - Choose how strong the computer is (Priority: P2)

**Goal**: Three levels that differ by depth, node limit and randomness, proven by matches in a blocking Release job (#103, #104, #105; FR-011 to FR-013, SC-002, SC-003).

**Independent Test**: `swift test --filter US2ComputerLevelTests` and `swift test -c release --filter CheckersEngineStrengthTests` in the engine.

### Tests for User Story 2 (MANDATORY - write first) ⚠️

- [X] T016 [P] [US2] Write `EngineTests/US2ComputerLevelTests.swift` (`struct US2ComputerLevelTests`). It runs in Debug, so Hard is checked through its `limits` (values and their order against Medium) and through searches with Hard's margin and a node cap of 20,000, never at its full node limit; Hard at full strength is exercised in `StrengthTests/`:
  - `US2 FR-AI-02`: the levels' limits are ordered: Easy's depth < Medium's < Hard's, margins Easy > Medium > Hard = 0, and only Hard has a node limit.
  - `US2 FR-AI-02`: a position where the only safe turn needs a 4-turn lookahead: Medium finds it and Easy does not.
  - `US2 FR-AI-02`: with a node cap of 20,000, the search stops within one check interval (1,024 nodes) of the cap and returns the best turn of its last completed iteration.
  - `US2 FR-AI-02` (FR-013): from the start, 20 seeds give at least two different turns at Easy and at Medium; the same seed always gives the same turn at Easy, at Medium and with Hard's margin under the cap; with Hard's margin only turns with the best score are ever chosen.
  - `US2 FR-AI-02`: `SeededGenerator` (now in the engine) produces the SplitMix64 reference values for seed 0.
  Fails until T019.
- [X] T017 [P] [US2] Add the test target `CheckersEngineStrengthTests` (depends on `CheckersEngine`, SwiftLint plugin) to `checkers/CheckersEngine/Package.swift`, not to the Xcode test plan, and write `StrengthTests/US2StrengthMatchTests.swift` per the contract's "Strength matches": `US2 FR-AI-02 SC-003` Medium against Easy and Hard against Medium, 100 games each, at least 70 points; `US2 FR-AI-01 SC-002` every step applies and every game ends; `FR-AI-01` `TurnGenerator` counts for 1–9 turns; `US2 FR-AI-02`: a position with a 6-turn shot that Hard finds at its full limits and Medium does not. Print each match's score, draws and Hard's slowest turn, and turns per second for 9 turns. Run with `swift test -c release`; fails until T019 and T021 (every level plays alike).
- [X] T018 [P] [US2] Extend `scripts/tests/test-ci-gate.sh` for a fourth argument, the `engine-strength` result: a code push passes only when build-and-test and engine-strength both succeed; a docs-only push passes when both are skipped; any failure, cancellation or skip on a code push fails. Fails until T020.

### Implementation for User Story 2

- [X] T019 [US2] Move `SeededGenerator` from `EngineTests/Support/SeededGenerator.swift` to `Engine/SeededGenerator.swift` (internal, unchanged algorithm, so `RandomGameTests` replay the same games); give `ComputerLevel.limits` the research R4 parameters (depth, node limit, margin) and make the root choose at random, with the seed, among turns within the level's margin of the best (root window per research R2). T016 passes; all engine tests pass.
- [X] T020 [US2] Add the `engine-strength` job to `.github/workflows/ci.yml` (macOS 26, Xcode 26.3, `needs: changes`, runs on code pushes, `cd checkers/CheckersEngine && swift test -c release --filter CheckersEngineStrengthTests`, 20-minute timeout), pass its result to `scripts/ci/gate.sh` as a fourth argument, and update `specs/001-project-foundation/contracts/ci-gate.md` ("Outcomes" and the job list). T018 passes; `scripts/tests/run.sh` passes.
- [X] T021 [US2] Tune: run the strength matches in Release and adjust the level parameters and evaluation weights until both matches reach at least 70 points and Hard's slowest turn is at most 0.5 s on the development Mac; record the final values in research R3 and R4 (and data-model.md) and the scores, draws and timings in `validation.md`. T017 passes locally; push and confirm `engine-strength` passes in CI within 15 minutes.

**Checkpoint**: US2 complete: the playtest (quickstart §4) is marked for the user in T033.

---

## Phase 5: User Story 3 - Stay in control while the computer thinks (Priority: P2)

**Goal**: Menu, Undo, Resign, Rules, Settings and Home work during the computer's turn; no move after resigning or leaving; moves wait while Rules or Settings is open (#110; FR-014 to FR-017).

**Independent Test**: `-only-testing:checkersTests/US3ComputerControlTests`.

### Tests for User Story 3 (MANDATORY - write first) ⚠️

- [X] T022 [P] [US3] Write `Unit/US3ComputerControlTests.swift` (`struct US3ComputerControlTests`), through `AppRouter` with a scripted opponent and a manual pacer:
  - `US3 FR-AI-04 FR-END-02`: resigning while the computer thinks shows "Light resigned"; after the opponent answers and the pause resumes, no step is applied.
  - `US3 FR-AI-04`: confirming Leave while it thinks drops the session and cancels its task; cancelling the leave alert lets the turn finish.
  - `US3 FR-NAV-04`: `open(.rules)` while it thinks: the opponent answers and the pause resumes, but nothing is applied; popping back asks the pacer for a fresh 0.5 s, after which the step is applied; the same for Settings and in the middle of a chain.
  - `US3 FR-AI-04`: while it thinks, `canUndo` reflects the rule of US4 and Rules, Settings and Home are reachable.
  - `US3 FR-AI-04`: with `EngineComputerOpponent` at Hard on a middlegame position, a main-actor task scheduled while the search runs completes within 100 ms.
  Fails until T023.

### Implementation for User Story 3

- [X] T023 [US3] Add `isCovered` and `setCovered(_:)` to `App/Features/Game/GameSession.swift` (each step waits while covered, then a fresh 0.5 s pause); in `App/App/AppRouter.swift` call `setCovered(path.last != .game)` when the path changes and `cancelComputerTurn()` on confirmed leave; make `resign()` cancel the computer's turn first. T022 passes; all tests pass.

**Checkpoint**: US3 complete.

---

## Phase 6: User Story 4 - Undo against the computer (Priority: P2)

**Goal**: Undo returns to the player's turn, is unavailable before the player's first move, and cancels the computer's turn (#112, #113; FR-018 to FR-022).

**Independent Test**: `-only-testing:checkersTests/US4ComputerUndoTests -only-testing:checkersUITests/US4ComputerUndoUITests`.

### Tests for User Story 4 (MANDATORY - write first) ⚠️

- [ ] T024 [P] [US4] Write `Unit/US4ComputerUndoTests.swift` (`struct US4ComputerUndoTests`), with a scripted opponent and a manual pacer:
  - `US4 FR-UNDO-03`: after the player's move and the computer's reply, `undo()` restores a state equal to the one before the player's move (position, side to move, draw counters) and announces "Move undone. Light to move."
  - `US4 FR-UNDO-03`: `canUndo` is false in a new game, also when the computer has opened as Light and the player has not moved; true after the player's first move; false once the game is over.
  - `US4 FR-UNDO-04`: undo while the computer thinks takes back the player's move only, and no step is applied after the opponent answers; undo between the jumps of the computer's chain takes back the partial chain and the player's move.
  - `US4 FR-UNDO-05`: undo during the player's own chain restores the position before the chain and it is still the player's turn.
  - `US4 FR-UNDO-01`: three turn pairs, then three undos, reach the start; the computer's opening move as Light is never taken back.
  - Two-player undo is unchanged (the E3 `US5GameUndoTests` still pass).
  Fails until T026.
- [ ] T025 [P] [US4] Write `UI/US4ComputerUndoUITests.swift`: `testUS4_undoTakesBackBothMoves`: a computer game (Easy, Light); Undo is disabled in the menu; move c3–d4, wait for "Light to move"; Undo: `square.c3` reads "c3, Light man, can move", `square.d4` "d4, empty", every Dark man is on its starting square, and Undo is disabled again. Fails until T026.

### Implementation for User Story 4

- [ ] T026 [US4] Implement research R9 in `App/Features/Game/GameSession.swift`: in a computer game `undo()` cancels the computer's turn, then calls `state.undo()` at least once and until `sideToMove == playerSide`; `canUndo` applies the same rule to a copy of the state. Two-player games keep E3's rule. T024 and T025 pass; all tests pass.

**Checkpoint**: US4 complete.

---

## Phase 7: User Story 5 - Hear the computer's moves with VoiceOver (Priority: P2)

**Goal**: Each computer step is announced once, chains without "Jump again", and focus stays put (#190; FR-023 to FR-026).

**Independent Test**: `-only-testing:checkersTests/US5ComputerAnnouncementTests`, plus quickstart §6 by hand.

### Tests for User Story 5 (MANDATORY - write first) ⚠️

- [ ] T027 [P] [US5] Write `Unit/US5ComputerAnnouncementTests.swift` (`struct US5ComputerAnnouncementTests`), with a `RecordingAnnouncer`, a scripted opponent and a manual pacer:
  - `US5 FR-A11Y-03`: after the player's `c3–d4` ("Light c3 to d4. Dark to move."), the computer's `f6–e5` announces "Dark f6 to e5. Light to move, capture required."
  - `US5 FR-A11Y-03`: a computer double jump announces "Dark captures e5." then "Dark captures c3. Light to move." (no "Jump again.").
  - `US5 FR-A11Y-03`: a crowning computer step "Dark b2 to a1, crowned. Light to move."; a game-ending one ends with the result sentence.
  - `US5 FR-A11Y-03`: exactly one announcement per computer step; nothing is announced while it thinks or while Rules is open.
  - `US5 FR-A11Y-03`: `focusSquare` is the player's landing square (d4) before, during and after the computer's turn.
  - `US5 FR-A11Y-03`: undo while it thinks announces "Move undone. Light to move."
  Fails until T028.

### Implementation for User Story 5

- [ ] T028 [US5] Add `GameText.computerFollowUp(after:in:)` (`nil` while the chain continues, otherwise as `followUp`) in `App/Features/Game/GameText.swift`, and in `App/Features/Game/GameSession.swift` announce each computer step with it and leave `focusSquare` unchanged. T027 passes; all tests pass.

**Checkpoint**: US5 complete; the VoiceOver game by hand is marked for the user in T033.

---

## Phase 8: Polish & Cross-Cutting Concerns

- [ ] T029 [P] Update `UI/US5AccessibilityAuditUITests.swift` for FR-027 and FR-028: remove the disabled-Start exception from `isAllowed` (done in US1, where the edge-cut exception was widened to Start); audit Game setup with Computer chosen (Start enabled), a computer game on the player's turn (after the computer's reply) and a computer game with the result panel (after resigning); the thinking header is not audited or UI-tested (it lasts about half a second, less than XCUITest needs after a tap; found in US1, research R12) and is covered by `US1ComputerGameTests` and the previews. Run them and record every reported problem in `validation.md`.
- [ ] T030 Fix every problem T029 reports in `App/Features/`; update the plan's "Audit allow-list" table if a system-component exception is needed. Run the audits on the iPhone SE (3rd generation) at `accessibility-extra-extra-extra-large` in Dark Mode; with Reduce Motion on, check the thinking indicator during a computer turn (FR-028); reset the simulator, and record the results.
- [ ] T031 Run `scripts/format.sh`, then confirm `scripts/check-format.sh --strict`, `scripts/tests/run.sh`, `scripts/check-string-catalog.sh checkers/checkers/Localizable.xcstrings .build/DerivedData`, `scripts/test.sh` and the strength matches pass with zero warnings and zero SwiftLint errors.
- [ ] T032 [P] Update `checkers/CLAUDE.md` (the computer player in the engine and its turn generator, the two seams, the computer turn in `GameSession`, the strength target and CI job) and add a pointer to `contracts/computer-player.md` in `specs/002-rules-engine/contracts/engine-api.md` ("How later epics use it", E4).
- [ ] T033 Run the quickstart (1, 2, 3, 7) and record the results in `validation.md`, including the SC-010 search for the slice's FRD IDs and §3's background-and-return check; mark §4 (playtest), §5 (iPhone timing, or the Mac measurement as the closest proxy) and §6 (VoiceOver by hand) for the user.
- [ ] T034 [P] Update `HANDOFF.md` (current state, lessons learned) and `EXECUTION_PLAN.md` (close-out checklist).
- [ ] T035 Final verification: push the branch, confirm `CI gate` is green with both jobs on the last commit, fast-forward `main`, and record the CI run in `validation.md`.

---

## Dependencies & Execution Order

- **Setup (Phase 1)** and **Foundational (Phase 2)** first; Phase 2 blocks all stories (the generator for the search, the seams for the session).
- **US1** next (P1, the MVP). **US2** after US1 (it tunes US1's search); **US3**, **US4** and **US5** after US1, in that order, since each extends `GameSession`'s computer turn. US2 is independent of US3–US5 and can be interleaved, but its CI job (T020) should land before the last story's push.
- **Polish** last; T029 sees every story's screens.
- Within a story: tests first and seen failing; implementation tasks in order.

### Parallel Opportunities

- T001 and T002; T003 and T005 (engine and app files).
- US1: T007, T008, T009 and T010 are separate files; T011 (engine) can proceed alongside T012–T015 (app) once the seams exist.
- US2: T016, T017 and T018.
- T029, T032 and T034.

## Implementation Strategy

1. Phases 1–2, then US1: a computer game is playable end to end at one strength.
2. US2: three levels, proven by the Release matches in their own CI job.
3. US3, US4, US5: control while thinking, undo, VoiceOver.
4. Polish: audits, docs, quickstart, CI and the fast-forward of `main`.
5. After each story: `scripts/test.sh` green, push, CI green, update the board and `EXECUTION_PLAN.md`.

## Requirement Coverage

| FRD / spec IDs | Test tasks | Implementation tasks |
|---|---|---|
| FR-SETUP-01 to 03 · FR-001, FR-002, FR-003 | T009, T010 | T014 |
| FR-AI-01 · FR-004 | T003, T007, T008, T017 | T004, T011, T012, T013 |
| FR-AI-06 · FR-005 | T008, T009, T010 | T013, T014 |
| FR-AI-03 · FR-006, FR-008, FR-010 | T008, T010, T029 | T012, T013, T015 |
| FR-MOVE-04 · FR-007 | T008 | T013 |
| FR-AI-05 · FR-009 | T008 | T013 |
| FR-AI-02 · FR-011, FR-012, FR-013 | T016, T017 | T019, T021 (FR-012 also T033, playtest) |
| FR-AI-04 · FR-014, FR-015, FR-016 | T022 | T023 |
| FR-NAV-04 · FR-017 | T022 | T023 |
| FR-UNDO-01, 03 to 07 · FR-018 to FR-022 | T024, T025 | T026 |
| FR-A11Y-03 · FR-023 to FR-026 | T027 | T028 |
| FR-A11Y-04 · FR-027, FR-028 | T029 | T015, T030 |
| SC-001 | T010 | T033 |
| SC-002, SC-003 | T017 | T021 |
| SC-004 | — | T033 (for the user) |
| SC-005 | — | T012, T033 (for the user on an iPhone) |
| SC-006 | T022 | T023 |
| SC-007 | T024 | T026 |
| SC-008 | T027 | T028 |
| SC-009 | T029 | T030 |
| SC-010 | T033 | — |

## Board Mapping

Reconciled with the board in #101 (2026-10-22). Each board issue lists its task IDs:

| Board task | Tasks |
|---|---|
| #103 Position evaluation function | T011 (evaluation), T021 (tuning) |
| #104 Cancellable alpha-beta search off the main actor | T003, T004, T007, T011, T012 |
| #105 Difficulty levels with measurable strength gaps | T016, T017, T019, T021 |
| #107 Computer turn controller | T005, T006, T008, T013, T015 |
| #108 Capture chains one jump at a time | T008 (chain cases), T013 |
| #190 Announce the computer's moves with VoiceOver | T027, T028 |
| #109 Computer makes the first move as Light | T008 (first-move cases), T013, T014 |
| #110 UI responsive while thinking | T022, T023 |
| #112 Undo takes back a pair | T024, T025, T026 |
| #113 Undo while the computer thinks | T024 (cancel cases), T026 |
| #198 Start computer games from Game setup (F4.2) | T009, T010, T014 |
| #199 Strength matches in a Release CI job (F4.1) | T018, T020 |
| #200 Validate the E4 slice and update project docs (F4.3, after #113) | T001, T002, T029–T035 |

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Verify tests fail before implementing
- Each acceptance test names its story ID (for example `US1`) in its display name or tag
- A test task completes together with the implementation tasks it covers; every commit leaves the app building and all tests passing
