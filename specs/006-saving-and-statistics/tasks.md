---

description: "Task list for the saving and statistics slice (epic E5)"
---

# Tasks: Saving and Statistics

**Input**: Design documents from `/specs/006-saving-and-statistics/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/saved-game.md, contracts/screens.md, quickstart.md

**Tests**: Tests are MANDATORY (Constitution III). Engine logic is tested with Swift Testing in `CheckersEngineTests`; app logic in `checkers/checkersTests/` against in-memory stores (Constitution III.4), the `UserDefaults` stores against a temporary suite; the running app with XCUITest in `checkers/checkersUITests/`, with saved data set through `UserDefaults` launch arguments (research R10). Suites are named `US<n>…Tests`, display names start with the story ID and list the FRD IDs they prove, and UI test methods are named `testUS<n>_…`. Test tasks come before the implementation tasks they cover and must be observed failing (or failing to compile) before implementation begins.

**Organization**: Tasks are grouped by user story. A test task is complete together with the implementation tasks it covers (red, then green): no commit or push is ever red, so every completed task leaves the app building and all tests passing (Constitution workflow gate 3).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US4)
- Shorthands: `Engine/` is `checkers/CheckersEngine/Sources/CheckersEngine/`, `EngineTests/` is `checkers/CheckersEngine/Tests/CheckersEngineTests/`, `App/` is `checkers/checkers/`, `Unit/` is `checkers/checkersTests/`, `UI/` is `checkers/checkersUITests/`.

## Conventions used by every task

- As in E3 to E4: `scripts/test.sh` runs everything with SwiftLint; one suite with `-only-testing`; engine tests alone with `(cd checkers/CheckersEngine && swift test --filter …)`; sync the catalog with `scripts/sync-string-catalog.sh` after string changes and keep `Unit/LocalizationTests.swift`'s list in step with contracts/screens.md; previews in light, dark and `accessibility5`, built with in-memory stores only (workflow gate 4); no force unwraps outside tests; no test-only behavior in the app; commit failing tests with their implementation; push once per story and wait for CI; move board tasks to In Progress before a story and Done after its CI (summaries with `gh issue comment`).
- Formats, validity rules, save points and recording follow [contracts/saved-game.md](contracts/saved-game.md); texts and identifiers follow [contracts/screens.md](contracts/screens.md). Texts are checked as resolved English strings.
- `GameSession`'s class body stays within SwiftLint's 250 lines: new session behavior goes in extensions in `GameSession.swift` (E4 lessons).

---

## Phase 1: Setup (Shared Infrastructure)

- [ ] T001 Create `specs/006-saving-and-statistics/checklists/validation.md` with one section per quickstart scenario (1–7) and a "Baseline" section: `scripts/test.sh` passes before any slice code (record the count), and the measurements from research "Environment facts".
- [ ] T002 [P] Add the `storage` category to `App/Support/Logging.swift` (`Log.storage`) and to `Unit/LoggingTests.swift` (categories `["app", "game", "setup", "computer", "storage"]`), test first.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The engine's coding of a game, the stored values and their stores, used by every story.

- [ ] T003 [P] Write `EngineTests/GameStateCodingTests.swift` (`struct GameStateCodingTests`):
  - `FR-SAVE-03`: encoding then decoding gives an equal `GameState` for the start, for 200 positions reached by seeded random play (`SeededGenerator`), some stopped in the middle of a chain, with kings and non-zero no-progress counts, and for finished games (a win by no moves left, a resignation, a draw by repetition, a draw by no progress).
  - `FR-SAVE-03`: the start state encodes with exactly the keys `position`, `sideToMove`, `chainSquare`, `outcome`, `noProgressCount`, `turns`; a version 1 fixture (inline JSON, as in contracts/saved-game.md, with two turns and a chain) decodes to the expected state.
  - `FR-SAVE-05`: decoding throws `DecodingError.dataCorrupted` for each rule of "Validity": Light and Dark on a common square; a king on an empty square; `noProgressCount` 81, or 80 while in progress; a chain square without a piece of the side to move, without a jump from it, or in a finished game; an in-progress state whose side to move has no step; an in-progress position that occurred three times; a turn record with overlapping sets or a count of 80; and for an unknown side, square or outcome.
  Fails to compile until T004.
- [ ] T004 Create `Engine/GameState+Coding.swift`: `GameState: Codable` per contracts/saved-game.md ("Format", "Validity"), with explicit coding keys, the chain square by name and the outcome as `"inProgress"`, `{"win": {"winner", "reason"}}` or `{"draw": reason}`; make `Side` `Codable` as `"light"`/`"dark"`; add the internal initializer in `Engine/GameState.swift` that decoding needs to set every stored property. No other public API. T003 passes; all engine tests pass.
- [ ] T005 [P] Write `Unit/StorageTests.swift` (`struct StorageTests`), each test on its own `UserDefaults(suiteName:)`, removed afterwards:
  - `FR-SAVE-02 FR-SAVE-05`: `UserDefaultsSavedGameStore` (key `savedGame`): nothing stored → `nil`; save then load → an equal `SavedGame`; a second save replaces the first; clear → `nil`; bad JSON, `"version": 2`, a finished state and a state failing validation → throws `.unreadable`.
  - `FR-STAT-05`: `UserDefaultsRecordStore` (key `record`): nothing stored → an empty record; save then load → equal; bad JSON → an empty record.
  - The in-memory stores give the same answers, including from raw data.
  Fails to compile until T006.
- [ ] T006 Create, per data-model.md, `App/Features/Saving/SavedGame.swift` (`SavedGame`: `version` 1, `setup`, `playerSide`, `state`; `SavedGameError.unreadable`), `App/Features/Saving/SavedGameStore.swift` (protocol; `UserDefaultsSavedGameStore`; `InMemorySavedGameStore`, which can also hold raw data), `App/Features/Statistics/Record.swift` (`Record` with a `Tally` for each difficulty, `version` 1, `adding(_:)`, `isEmpty`; `GameResult`) and `App/Features/Statistics/RecordStore.swift` (protocol; `UserDefaultsRecordStore`; `InMemoryRecordStore`). Read and write failures are logged with `Log.storage`, without game data. T005 passes.
- [ ] T007 Add `games: any SavedGameStore = InMemorySavedGameStore()` and `records: any RecordStore = InMemoryRecordStore()` to `AppRouter.init` in `App/App/AppRouter.swift`, and pass `UserDefaultsSavedGameStore` and `UserDefaultsRecordStore` on `.standard` in `App/CheckersApp.swift`; unused so far.

**Checkpoint**: `scripts/test.sh` passes; nothing user-visible has changed.

---

## Phase 3: User Story 1 - Continue where I left off (Priority: P1) 🎯 MVP

**Goal**: Games are saved after every turn, on leaving and in the background; Home offers Continue, which restores the game exactly, and the computer moves if it is its turn; leaving no longer asks (#122, #123, #124, #125, #189; FR-001 to FR-005, FR-007 to FR-011).

**Independent Test**: `-only-testing:checkersTests/US1ContinueTests -only-testing:checkersTests/US7NavigationTests -only-testing:checkersUITests/US1ContinueUITests`.

### Tests for User Story 1 (MANDATORY - write first) ⚠️

- [ ] T008 [P] [US1] Write `Unit/US1ContinueTests.swift` (`struct US1ContinueTests`), through `AppRouter` with in-memory stores, a scripted opponent and a manual pacer:
  - `US1 FR-SAVE-01`: after each turn of a two-player game, and after the player's turn and the computer's reply in a computer game, the store holds the session's game; after an undo it holds the undone game.
  - `US1 FR-SAVE-01 FR-SAVE-04` (FR-004): `saveNow()` while the computer thinks, and between the jumps of its chain, saves the game as it was at the start of the computer's turn; during the player's own chain it saves the chain unfinished.
  - `US1 FR-NAV-03` (FR-010): `requestHome()` during a game in progress returns to Home at once (empty path, no question), saves the game, cancels the computer's turn, and `hasSavedGame` becomes true.
  - `US1 FR-NAV-02`: a router over an empty store has `hasSavedGame` false; over a store with a saved game, true.
  - `US1 FR-SAVE-03`: `continueGame()` opens the game screen with a state equal to the saved one, the same setup, player's side and board orientation, the chain piece selected when a chain is unfinished, and Undo taking back the same turns; the remembered setup is unchanged (FR-011).
  - `US1 FR-SAVE-04`: continuing a game saved during the computer's turn starts its turn (`computerPhase == .thinking`), and the computer plays exactly one turn.
  Fails to compile until T011–T012.
- [ ] T009 [P] [US1] Write `UI/US1ContinueUITests.swift`: `testUS1_continueAfterRelaunch`: a computer game (Easy, Light); move c3–d4 and wait for "Light to move"; note the labels of the 32 squares; Home: `home.continue` exists; `terminate()` and `launch()`; Continue: every square reads as before and the turn reads "Light to move". Fails until T012.
- [ ] T010 [US1] Rewrite the leave tests for FR-010: `leaveConfirmation` in `Unit/US7NavigationTests.swift` becomes "leaving a game in progress returns Home at once and keeps it saved"; `leaveWhileThinking` in `Unit/US3ComputerControlTests.swift` becomes "leaving while the computer thinks cancels its turn and keeps the game from the start of its turn". Fails until T012.

### Implementation for User Story 1

- [ ] T011 [US1] In `App/Features/Game/GameSession.swift` (extensions in the same file): `GameSessionEvent` (`saved`, `ended`) and `onEvent`; keep the state at the start of the computer's turn while it plays; `snapshot` per contracts/saved-game.md ("Save points"); `init(saved:…)`, selecting the chain piece; send `saved` after each turn of either side and after undo.
- [ ] T012 [US1] In `App/App/AppRouter.swift`: `hasSavedGame` (loaded at creation), save the snapshot on `saved` events and in `requestHome()`, which no longer asks (remove `isConfirmingLeave`, `confirmLeave()`, `cancelLeave()`), `saveNow()`, `continueGame()` per contracts/saved-game.md ("Launch and Continue"); remove the leave alert from `App/Features/Game/GameView.swift`; in `App/CheckersApp.swift` call `router.saveNow()` when the scene phase becomes `.background`; in `App/Features/Home/HomeView.swift` add Continue (`home.continue`, first and prominent, New game bordered then) per contracts/screens.md, with previews with and without a saved game; in `Unit/LocalizationTests.swift` drop "Leave this game?", "It can't be resumed yet." and "Leave" and add "Continue"; sync the catalog. T008–T010 pass; all tests pass.

**Checkpoint**: US1 complete: games survive leaving and relaunching.

---

## Phase 4: User Story 2 - Start a new game without losing one by accident (Priority: P2)

**Goal**: Start asks "Abandon current game?" when a saved game exists; a finished game is never the saved game (#72, #127, #189; FR-006, FR-012 to FR-014).

**Independent Test**: `-only-testing:checkersTests/US2AbandonTests -only-testing:checkersUITests/US2AbandonUITests`.

### Tests for User Story 2 (MANDATORY - write first) ⚠️

- [ ] T013 [P] [US2] Write `Unit/US2AbandonTests.swift` (`struct US2AbandonTests`), through `AppRouter` with in-memory stores:
  - `US2 FR-SETUP-04`: with a saved game, `startGame()` sets `isConfirmingAbandon` and starts nothing; `cancelAbandon()` keeps the setup screen, its choices and the saved game; `startGame()` then `confirmAbandon()` clears the saved game and starts the new game, which is saved after its first turn.
  - `US2 FR-SETUP-04`: without a saved game Start starts at once, and so does Play again after a finished game.
  - `US2 FR-END-08` (FR-006): a game ending by the player's last step, by the computer's last step (scripted) or by resignation clears the saved game; `hasSavedGame` becomes false; the session sends `ended` exactly once.
  - `US2 FR-SETUP-05`: confirming Abandon on a computer game leaves the record unchanged.
  Fails until T015.
- [ ] T014 [P] [US2] Write `UI/US2AbandonUITests.swift`: `testUS2_abandonQuestion`: a two-player game, move c3–d4, Home; New game → Two players → Start: the alert "Abandon current game?" appears; Cancel: setup stays; Start → Abandon: the game starts from the start position; Home: Continue leads to the new game. In `UI/Support/AppScreens.swift`, the start helpers answer Abandon whenever the question appears. Fails until T015.

### Implementation for User Story 2

- [ ] T015 [US2] In `App/Features/Game/GameSession.swift` send `ended` once, from the player's last step, the computer's last step and resignation; in `App/App/AppRouter.swift` clear the saved game on `ended`, and in `startGame()` ask first when a saved game exists (`isConfirmingAbandon`, `confirmAbandon()`, `cancelAbandon()`); show the alert in `App/Features/Setup/SetupView.swift` per contracts/screens.md (`setup.abandon.confirm`, `setup.abandon.cancel`); add its texts to `Unit/LocalizationTests.swift`; sync the catalog. T013–T014 pass; all tests pass.

**Checkpoint**: US2 complete.

---

## Phase 5: User Story 3 - See my record against the computer (Priority: P2)

**Goal**: Every finished computer game counts once at its difficulty; Statistics shows wins, losses and draws per difficulty, or an empty state (#129, #130; FR-016 to FR-023, FR-025).

**Independent Test**: `-only-testing:checkersTests/US3RecordTests -only-testing:checkersUITests/US3StatisticsUITests`.

### Tests for User Story 3 (MANDATORY - write first) ⚠️

- [ ] T016 [P] [US3] Write `Unit/US3RecordTests.swift` (`struct US3RecordTests`), through `AppRouter` and `GameSession` with in-memory stores and scripted positions:
  - `US3 FR-STAT-02`: at each difficulty, the computer's side left without a move records a win, the player's side left without a move a loss, a resignation a loss, a draw by repetition or by no progress a draw: exactly one change, at that difficulty, saved to the record store.
  - `US3 FR-STAT-03 FR-SETUP-05`: a two-player game, an abandoned game and a game left for Home change nothing.
  - `US3 FR-UNDO-08`: a game with undos counts once, by its final result; a game left, continued and finished counts once, at its difficulty.
  - `US3 FR-STAT-01`: `Record.adding(_:)` and `isEmpty`; `GameResult` from each outcome and the player's side; `nil` for two-player games.
  - `US3 FR-STAT-04`: `StatisticsText` gives "3 wins", "1 win", "0 losses", "1 loss", "2 draws", "1 draw", the block label "Easy: 3 wins, 1 loss, 2 draws", and the empty state's two sentences.
  - `US3 FR-STAT-05` (FR-020): an unreadable record (raw data in the in-memory store) loads as an empty record.
  Fails until T018–T019.
- [ ] T017 [P] [US3] Write `UI/US3StatisticsUITests.swift`: `testUS3_finishedGameCounts`: open Statistics and read Easy's losses (0 when the empty state shows); a computer game (Easy, Light), Resign; Home → Statistics: `statistics.easy` reads one more loss in its VoiceOver label. `testUS3_emptyState`: launch with `-record <hex>` holding an empty record: Statistics shows `statistics.empty` with its two sentences. Fails until T019.

### Implementation for User Story 3

- [ ] T018 [US3] In `App/Features/Game/GameSession.swift` add `result` (from the outcome, the player's side and the setup's difficulty, `nil` for two-player games); in `App/App/AppRouter.swift` add `record` (loaded at creation) and, on `ended`, add the session's result and save the record.
- [ ] T019 [US3] Create `App/Features/Statistics/StatisticsText.swift` and `App/Features/Statistics/StatisticsView.swift` per contracts/screens.md and research R9: a block per difficulty with the three counts (plural variants in the String Catalog), one VoiceOver element per block, the empty state, primary text only, no buttons, scrolling at large sizes; previews empty and with a record, in light, dark and `accessibility5`; open it for `.statistics` in `App/App/RootView.swift`; remove the Statistics line from `App/Features/Placeholders/PlaceholderText.swift` and its preview from `PlaceholderView.swift`; update `Unit/LocalizationTests.swift`; sync the catalog and add the plural variations. T016–T017 pass; all tests pass.

**Checkpoint**: US3 complete.

---

## Phase 6: User Story 4 - A saved game that cannot be restored (Priority: P3)

**Goal**: An unreadable save is discarded and reported once on Home (#126; FR-015).

**Independent Test**: `-only-testing:checkersTests/US4RestoreFailureTests -only-testing:checkersUITests/US4RestoreFailureUITests`.

### Tests for User Story 4 (MANDATORY - write first) ⚠️

- [ ] T020 [P] [US4] Write `Unit/US4RestoreFailureTests.swift` (`struct US4RestoreFailureTests`): for bad JSON, `"version": 2`, a finished state and a state failing validation in the in-memory store, a new `AppRouter` clears it, has `hasSavedGame` false and `isShowingRestoreFailure` true; `dismissRestoreFailure()` closes it; a new router over the same store does not show it again; Start does not ask. Display names `US4 FR-SAVE-05`. Fails until T022.
- [ ] T021 [P] [US4] Write `UI/US4RestoreFailureUITests.swift`: `testUS4_damagedSave`: launch with `-savedGame <hex>` of bytes that are not JSON: the alert "Your previous game couldn't be restored." appears; OK (`home.restoreFailure.ok`); no Continue; New game → Two players → Start starts the game without the abandon question. Fails until T022.

### Implementation for User Story 4

- [ ] T022 [US4] In `App/App/AppRouter.swift`, at creation: an unreadable saved game is cleared, logged with `Log.storage` and sets `isShowingRestoreFailure`; add `dismissRestoreFailure()`; show the alert in `App/Features/Home/HomeView.swift` per contracts/screens.md, with a preview; add its text to `Unit/LocalizationTests.swift`; sync the catalog. T020–T021 pass; all tests pass.

**Checkpoint**: US4 complete.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [ ] T023 [P] Update `UI/US5AccessibilityAuditUITests.swift` for FR-026: audit Home with Continue (a game started, then Home), Statistics empty (`-record` with an empty record) and Statistics with a record (`-record` with counts at every level); the Statistics placeholder audit becomes these. Run them and record every reported problem in `validation.md`.
- [ ] T024 Fix every problem T023 reports in `App/Features/`; add a plan "Audit allow-list" entry only for a system component. Run the audits on the iPhone SE (3rd generation) at `accessibility-extra-extra-extra-large` in Dark Mode; reset the simulator, and record the results.
- [ ] T025 Run `scripts/format.sh`, then confirm `scripts/check-format.sh --strict`, `scripts/tests/run.sh`, `scripts/check-string-catalog.sh checkers/checkers/Localizable.xcstrings .build/DerivedData`, `scripts/test.sh` and the strength matches pass with zero warnings and zero SwiftLint errors.
- [ ] T026 [P] Update `checkers/CLAUDE.md` (the Saving and Statistics features, the stores and their keys, saving through `GameSession` events, launch arguments for UI tests, the removed leave alert) and add a pointer to `contracts/saved-game.md` in `specs/002-rules-engine/contracts/engine-api.md` ("How later epics use it", E5).
- [ ] T027 Run the quickstart (1 to 6) and record the results in `validation.md`, including the search for the slice's FRD IDs and the time to save the 220-turn game of research in a Debug build (SC-006); mark anything left for the user.
- [ ] T028 [P] Update `HANDOFF.md` (current state, lessons learned) and `EXECUTION_PLAN.md` (close-out checklist).
- [ ] T029 Final verification: push the branch, confirm `CI gate` is green with both jobs on the last commit, fast-forward `main`, and record the CI run in `validation.md`.

---

## Dependencies & Execution Order

- **Setup (Phase 1)** and **Foundational (Phase 2)** first; Phase 2 blocks all stories (the coding of a game, the stored values and stores).
- **US1** next (P1, the MVP): saving and Continue. **US2** after US1 (it adds `ended` and the question to the same router and session). **US3** after US2 (it records on `ended`). **US4** needs only US1's loading at creation and can come before or after US2–US3.
- **Polish** last; T023 sees every story's screens.
- Within a story: tests first and seen failing; implementation tasks in order.

### Parallel Opportunities

- T001 and T002; T003 and T005 (engine and app files).
- US1: T008, T009 (T010 edits two existing test files and can run beside them).
- US2: T013 and T014. US3: T016 and T017. US4: T020 and T021.
- T023, T026 and T028.

## Implementation Strategy

1. Phases 1–2, then US1: games survive leaving and relaunching, with Continue.
2. US2: the abandon question and finished games cleared.
3. US3: the record and the Statistics screen.
4. US4: a damaged save reported once.
5. Polish: audits, docs, quickstart, CI and the fast-forward of `main`.
6. After each story: `scripts/test.sh` green, push, CI green, update the board and `EXECUTION_PLAN.md`.

## Requirement Coverage

| FRD / spec IDs | Test tasks | Implementation tasks |
|---|---|---|
| FR-SAVE-01 · FR-001 | T008 | T011, T012 |
| FR-SAVE-02 · FR-002 | T005 | T006 |
| FR-SAVE-03 · FR-003, FR-008 | T003, T008, T009 | T004, T006, T011, T012 |
| FR-004 (computer's turn saved at its start) | T008 | T011 |
| FR-005 (survives closing and updates) | T005, T009 | T006, T012 |
| FR-END-08 · FR-006 | T013 | T015 |
| FR-NAV-02 · FR-007 | T008, T009 | T012 |
| FR-SAVE-04 · FR-009 | T008 | T011, T012 |
| FR-NAV-03 · FR-010 | T008, T010 | T012 |
| FR-SETUP-03 · FR-011 | T008 | T012 |
| FR-SETUP-04 · FR-012 | T013, T014 | T015 |
| FR-SETUP-05 · FR-013 | T013, T016 | T015, T018 |
| FR-014 | T013, T021 | T015, T022 |
| FR-SAVE-05 · FR-015 | T003, T005, T020, T021 | T004, T006, T022 |
| FR-STAT-01 to 03, FR-UNDO-08 · FR-016 to FR-019 | T016, T017 | T018 |
| FR-STAT-05 · FR-020, FR-023 | T005, T016 | T006, T019 |
| FR-STAT-01, FR-STAT-04 · FR-021, FR-022 | T016, T017 | T019 |
| FR-PRIV-01, FR-PRIV-02 · FR-024 | existing `PrivacyManifestTests` (unchanged manifest) | — |
| FR-A11Y-04 · FR-025, FR-026 | T016, T017, T023 | T019, T024 |
| SC-001, SC-003 | T003, T008 | T011, T012 |
| SC-002 | T009 | T027 |
| SC-004 | T016 | T018 |
| SC-005 | T020, T021 | T022 |
| SC-006 | — | T027 (measured) |
| SC-007 | T023 | T024 |
| SC-008 | T027 | — |

## Board Mapping

Each board issue lists its task IDs; #120 Reconcile adds a task for the slice's setup and validation (T001, T002, T023–T029), as #200 did for E4:

| Board task | Tasks |
|---|---|
| #122 Codable game snapshot | T003, T004, T006 (`SavedGame`) |
| #123 Saved-game store behind a protocol | T005, T006, T007 |
| #124 Save after every turn and when the app goes to the background | T008, T011, T012 |
| #125 Continue restores the game exactly; computer resumes | T008, T009, T011, T012 |
| #189 Show Continue on Home only when a saved game exists | T008, T009, T010, T012 |
| #126 Unreadable save: discard, hide Continue, tell the player | T020, T021, T022 |
| #127 Clear the saved game on game end and on abandon | T013, T015 |
| #72 "Abandon current game?" confirmation | T013, T014, T015 |
| #129 Record model and recording rules | T006 (`Record`), T016, T018 |
| #130 Statistics screen with empty state | T017, T019 |
| #131 Accessibility pass: Statistics | T023, T024 |
| *(new in #120)* Validate the E5 slice and update project docs | T001, T002, T023–T029 |

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Verify tests fail before implementing
- Each acceptance test names its story ID (for example `US1`) in its display name or tag
- A test task completes together with the implementation tasks it covers; every commit leaves the app building and all tests passing
