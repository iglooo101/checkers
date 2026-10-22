---

description: "Task list for the accessibility slice (epic E7)"
---

# Tasks: Accessibility

**Input**: Design documents from `/specs/004-accessibility/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/announcements.md, quickstart.md

**Tests**: Tests are MANDATORY (Constitution III). Every user story has unit tests (Swift Testing, `checkers/checkersTests/`) and, where the running app matters, a UI test (XCUITest, `checkers/checkersUITests/`). Suites are named `US<n>…Tests`, display names start with the story ID and list the FRD IDs they prove, and UI test methods are named `testUS<n>_…`. Test tasks come before the implementation tasks they cover and must be observed failing (or failing to compile) before implementation begins. XCUITest cannot drive VoiceOver, so double-tap play is covered by the shared tap path, unit tests and one VoiceOver session by hand (research R7).

**Organization**: Tasks are grouped by user story. A test task is complete together with the implementation tasks it covers (red, then green): no commit or push is ever red, so every completed task leaves the app building and all tests passing (Constitution workflow gate 3).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US5)
- Shorthands: `App/` is `checkers/checkers/`, `Unit/` is `checkers/checkersTests/`, `UI/` is `checkers/checkersUITests/`.

## Conventions used by every task

- As in E3 (`specs/003-game-experience/tasks.md`): `scripts/test.sh` runs everything with SwiftLint; one suite with `-only-testing`; sync the catalog with `scripts/sync-string-catalog.sh` after string changes; previews in light, dark and `accessibility5`; no force unwraps outside tests; no test-only code in the app; commit failing tests with their implementation; push once per story and wait for CI; move board tasks to In Progress before a story and Done after its CI (summaries with `gh issue comment`).
- Texts follow [contracts/announcements.md](contracts/announcements.md) exactly. Optional strings returned from a `switch` use explicit `return`s (E3 lesson: the compiler extracts only one literal from a `switch` expression with an optional result).
- Announcement texts are checked as resolved English strings (`String(localized:)`) in unit tests.

---

## Phase 1: Setup (Shared Infrastructure)

- [X] T001 Create `specs/004-accessibility/checklists/validation.md` with one section per quickstart scenario (1–5) and a "Baseline" section: `scripts/test.sh` passes before any slice code (record the count), and the Classic contrast ratios measured in research R5.
- [X] T002 [P] Create `Unit/Support/ScriptedGames.swift`: named step lists for scripted games through `GameSession`, each with its starting `GameState`: an opening (`c3–d4, b6–a5`); the capture after `c3–d4, f6–e5` (`d4–f6`, Dark then must capture); E2's double jump (Light men a3, g1; Dark men b4, d6, h8: `a3–c5`, `c5–e7`); a crowning (Light man b6, Dark men c7, e7: `b6–d8`); the king shuffle to a draw by repetition; and a game ending with the last capture (Light man c3, Dark man d4: `c3–e5`). Reuse `US4GameEndTests.play` and the `GamePositions` helpers.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The announcer seam and the square state every story uses.

- [X] T003 [P] Write `Unit/AnnouncerTests.swift`: a `RecordingAnnouncer` keeps announcements in order as resolved strings; a `GameSession` built with it exposes nothing yet (compile-level seam). Fails to compile until T004.
- [X] T004 Create `App/Features/Game/Announcer.swift`: `protocol Announcer: AnyObject { func announce(_ text: LocalizedStringResource) }`, `final class AccessibilityAnnouncer: Announcer` (posts `AccessibilityNotification.Announcement`), `final class RecordingAnnouncer: Announcer` (an `announcements: [String]` list of resolved texts). Add `announcer: any Announcer = AccessibilityAnnouncer()` to `GameSession.init` and keep it in an `@ObservationIgnored` property. Create `App/Features/Game/SquareState.swift`: `enum SquareState: Equatable { case none, canMove, selected, legalTarget }`. T003 passes.

**Checkpoint**: `scripts/test.sh` passes; nothing user-visible has changed.

---

## Phase 3: User Story 1 - Hear what is on each square (Priority: P1) 🎯 MVP

**Goal**: Square labels state coordinate, contents and state (#161; FR-001 to FR-003).

**Independent Test**: `-only-testing:checkersTests/US1SquareDescriptionTests -only-testing:checkersUITests/US1SquareLabelUITests`.

### Tests for User Story 1 (MANDATORY - write first) ⚠️

- [X] T005 [P] [US1] Write `Unit/US1SquareDescriptionTests.swift` (`struct US1SquareDescriptionTests`):
  - `US1 FR-A11Y-01`: in a new game, a3, c3, e3, g3 read "<c>, Light man, can move"; c1 "c1, Light man"; b6 "b6, Dark man"; d4 "d4, empty".
  - `US1 FR-A11Y-01`: after tapping c3, c3 reads "c3, Light man, selected", b4 and d4 "…, empty, legal target", e3 "e3, Light man, can move".
  - `US1 FR-A11Y-01`: in the capture position (`US2CaptureChainTests.capturePosition()`), only c3 reads "can move"; a1 reads "a1, Light man".
  - `US1 FR-A11Y-01`: kings read "Light king" / "Dark king" in every state (a position with both kings).
  - `US1 FR-A11Y-01`: during the double jump's chain only the jumping piece is "selected" and only e7 is a "legal target"; after a resignation no square has a state.
  - `US1 FR-A11Y-01` (SC-002): for every scripted game of T002, after every step every dark square's `squareLabel` equals the description computed from the engine (`movablePieces`, `selection`, `targets`, contents) by the test's own helper.
  - `US1 FR-A11Y-01`: the states do not depend on hints (there is no hints switch yet; the state rule reads only the engine and the selection).
  Fails to compile until T007.
- [X] T006 [P] [US1] Write `UI/US1SquareLabelUITests.swift`: `testUS1_squareDescriptions`: `startTwoPlayerGame()`; `square.c3` reads "c3, Light man, can move", `square.c1` "c1, Light man", `square.d4` "d4, empty"; tap c3: `square.c3` "c3, Light man, selected", `square.d4` "d4, empty, legal target"; `testUS1_readingOrder` (FR-003): the board's square elements, in accessibility order, are b8, d8, f8, h8, a7, c7, e7, g7, … , a1, c1, e1, g1 (light squares absent). Fails until T009.

### Implementation for User Story 1

- [X] T007 [US1] Add to `App/Features/Game/GameText.swift` `squareLabel(_ square: Square, _ piece: Piece?, _ state: SquareState) -> LocalizedStringResource` returning the 14 sentences of the contract with explicit `return`s (replacing the two-argument version); add to `App/Features/Game/GameSession.swift` `state(of:) -> SquareState` and `squareLabel(_:)` per data-model.md. T005 passes.
- [X] T008 [US1] Update the E3 UI tests that read exact square labels to the new descriptions: `UI/US1TwoPlayerMoveUITests.swift` (c3 at the start "c3, Light man, can move"), `UI/US3DragUITests.swift` (after an invalid drop c3 is "c3, Light man, selected"), `UI/US4GameEndUITests.swift` and `UI/US7NavigationUITests.swift` (a fresh board's c3), `UI/US5UndoUITests.swift` (after one undo f6 is "f6, Dark man, can move"; back at the start c3 is "c3, Light man, can move"). Add the 10 new square sentences to `Unit/LocalizationTests.swift`.
- [X] T009 [US1] Use `session.squareLabel(square)` for each square's accessibility label in `App/Features/Game/BoardView.swift`. Sync the catalog. US1 tests and every E3 test pass.

**Checkpoint**: US1 complete: VoiceOver can read the whole board with states.

---

## Phase 4: User Story 2 - Play square by square with VoiceOver (Priority: P1)

**Goal**: Double-tap play follows the tap rules, focus follows each move, and the capture-required notice is spoken (#162; FR-004 to FR-006).

**Independent Test**: `-only-testing:checkersTests/US2VoiceOverPlayTests`, plus the VoiceOver run in quickstart §3.

### Tests for User Story 2 (MANDATORY - write first) ⚠️

- [X] T010 [P] [US2] Write `Unit/US2VoiceOverPlayTests.swift` (`struct US2VoiceOverPlayTests`), with a `RecordingAnnouncer`:
  - `US2 FR-A11Y-02`: after `c3`, `d4` (taps, the path VoiceOver activation uses), `focusSquare == d4`; after the double jump's first jump `focusSquare == c5`, after the second `e7`; selecting a piece does not change `focusSquare`.
  - `US2 FR-A11Y-02`: `undo()` and a new session (Play again) clear `focusSquare`.
  - `US2 FR-A11Y-02`: in the capture position, tapping a1 announces exactly "A capture is required."; beginning a drag on a1 announces it too.
  - `US2 FR-A11Y-02`: selecting and deselecting pieces announces nothing.
  Fails to compile until T011.

### Implementation for User Story 2

- [X] T011 [US2] Extend `App/Features/Game/GameSession.swift`: `private(set) var focusSquare: Square?`, set to the step's landing square in `apply`, cleared by `undo()`; announce `GameText.notice(.captureRequired)` whenever the notice is set (taps and drags). T010 passes.
- [X] T012 [US2] Bind VoiceOver focus in `App/Features/Game/BoardView.swift`: an `@AccessibilityFocusState private var focusedSquare: Square?`, each dark square `.accessibilityFocused($focusedSquare, equals: square)`, and `.onChange(of: session.focusSquare)` moving focus there. Keep the squares' default accessibility action calling `session.tap`. Previews unchanged. All tests pass.

**Checkpoint**: US2 complete; the VoiceOver run by hand is marked for the user in T023.

---

## Phase 5: User Story 3 - Hear what happens in the game (Priority: P1)

**Goal**: One announcement per step, plus undo and result announcements (#164; FR-007 to FR-012).

**Independent Test**: `-only-testing:checkersTests/US3AnnouncementTests`.

### Tests for User Story 3 (MANDATORY - write first) ⚠️

- [ ] T013 [P] [US3] Write `Unit/US3AnnouncementTests.swift` (`struct US3AnnouncementTests`), with a `RecordingAnnouncer`:
  - `US3 FR-A11Y-03`: `c3–d4` announces "Light c3 to d4. Dark to move."; then `f6–e5` "Dark f6 to e5. Light to move, capture required."; then `d4–f6` "Light captures e5. Dark to move, capture required."
  - `US3 FR-A11Y-03`: the double jump's first jump "Light captures b4. Jump again.", the second "Light captures d6. Dark to move."
  - `US3 FR-A11Y-03`: a crowning jump (Light man b6, Dark men c7, e7) "Light captures c7, crowned on d8. Dark to move."; a crowning move (Dark man b2, Light man g3, Dark to move) "Dark b2 to a1, crowned. Light to move."
  - `US3 FR-A11Y-03`: the last capture (Light man c3, Dark man d4) "Light captures d4. Light wins: no moves left"; the king shuffle's eighth turn ends with "Draw by repetition".
  - `US3 FR-A11Y-03`: `undo()` after `c3–d4` announces "Move undone. Light to move."; `resign()` on Light's turn announces "Light resigned".
  - `US3 FR-A11Y-03` (SC-003): over every scripted game of T002, the number of announcements equals the number of steps plus undos and resignations, each step's announcement starting with its "what happened" sentence.
  Fails until T014–T015.

### Implementation for User Story 3

- [ ] T014 [P] [US3] Add to `App/Features/Game/GameText.swift`: `stepSentence(_ result: StepResult) -> LocalizedStringResource` (the 8 sentences of "What happened"), `followUp(after result: StepResult, in state: GameState) -> LocalizedStringResource` ("Jump again.", the four turn sentences with a final period, or the result sentence), `undone(_ side: Side, captureRequired: Bool)` and `joined(_:_:)` (the "%1$@ %2$@" template), all with explicit `return`s.
- [ ] T015 [US3] Announce in `App/Features/Game/GameSession.swift`: after every applied step `joined(stepSentence, followUp)`; after `undo()` the undone sentence; after `resign()` the result sentence (contract: When to announce). Add every new sentence to `Unit/LocalizationTests.swift` and sync the catalog. T013 passes; all tests pass.

**Checkpoint**: US3 complete: a VoiceOver player hears the whole game.

---

## Phase 6: User Story 4 - Tell pieces and marks apart without color (Priority: P2)

**Goal**: Measured contrast for every mark and side-specific crowns (#166; FR-013 to FR-016, FR-020).

**Independent Test**: `-only-testing:checkersTests/US4ContrastTests`, plus the grayscale check in quickstart §4.

### Tests for User Story 4 (MANDATORY - write first) ⚠️

- [ ] T016 [P] [US4] Write `Unit/US4ContrastTests.swift` (`struct US4ContrastTests`): a WCAG contrast helper (relative luminance from `UIColor(named:)` resolved in light and dark trait collections) and, in both appearances, at least 3:1 for: `PieceLight`/`PieceDark` (`US4 FR-A11Y-05`, FR-015), `PieceLight`/`BoardDarkSquare`, `PieceDarkEdge`/`BoardDarkSquare`, `Selection`/`BoardDarkSquare`, `Target`/`BoardDarkSquare`, `Hint`/`BoardDarkSquare`, `CrownOnLight`/`PieceLight`, `CrownOnDark`/`PieceDark` (`US4 FR-A11Y-05`, FR-020). Also `Palette.crown(for: .light) == .crownOnLight` and `.dark == .crownOnDark`. Fails until T017.

### Implementation for User Story 4

- [ ] T017 [US4] Change the color sets in `App/Assets.xcassets` per data-model.md (`PieceDarkEdge` `#d9b48a`; `Selection` and `Target` `#7fd3ff` in both appearances, `Target` at 85% opacity; add `CrownOnLight` `#6b4426` and `CrownOnDark` `#e8c46a`; delete `Crown`), update `App/Support/Palette.swift` (cases `crownOnLight`, `crownOnDark`, `static func crown(for side: Side) -> Palette`) and `App/Features/Game/PieceView.swift` (crown color by side). T016 and `PaletteTests` pass.
- [ ] T018 [US4] Check the board in grayscale on the simulator (quickstart §4) in light and dark appearance, and update the board previews to show a king of each side, a selection, hints and targets together; record the result in `validation.md`.

**Checkpoint**: US4 complete.

---

## Phase 7: User Story 5 - Every screen passes the accessibility checks (Priority: P2)

**Goal**: An automated audit of every screen and state (#168; FR-017 to FR-019).

**Independent Test**: `-only-testing:checkersUITests/US5AccessibilityAuditUITests`.

### Tests for User Story 5 (MANDATORY - write first) ⚠️

- [ ] T019 [P] [US5] Write `UI/US5AccessibilityAuditUITests.swift`: one `testUS5_audit…` method per screen and state of the contract's "Audited screens" table, each reaching the state with `AppScreens` helpers and calling `try app.performAccessibilityAudit()` (all types), named with `FR-A11Y-04` in a comment. Run it and record every reported problem in `validation.md`.

### Implementation for User Story 5

- [ ] T020 [US5] Fix every problem T019 reports in the app's views under `App/Features/` (labels, traits, contrast, hit regions, Dynamic Type, clipped text). Only for a system element the app cannot change, handle the issue in the audit's issue handler by element and issue type, and add it with its reason to the plan's "Audit allow-list" table. All audits pass.
- [ ] T021 [US5] Run the audit tests on the iPhone SE (3rd generation) at `accessibility-extra-extra-extra-large` in Dark Mode (`simctl ui`), fix anything new, reset the simulator, and record the result in `validation.md`.

**Checkpoint**: US5 complete.

---

## Phase 8: Polish & Cross-Cutting Concerns

- [ ] T022 Run `scripts/format.sh`, then confirm `scripts/check-format.sh --strict`, `scripts/tests/run.sh`, `scripts/check-string-catalog.sh checkers/checkers/Localizable.xcstrings .build/DerivedData` and `scripts/test.sh` pass with zero warnings and zero SwiftLint errors.
- [ ] T023 Run the quickstart (1, 2, 4, 5) and record the results in `validation.md`, including the SC-006 search for FR-A11Y-01 to FR-A11Y-05; mark §3 (a full game with VoiceOver) for the user.
- [ ] T024 [P] Update `checkers/CLAUDE.md`: square states, the `Announcer` seam, announcements, the palette contrast rule and test, and the audit tests.
- [ ] T025 [P] Update `HANDOFF.md` (current state, lessons learned) and `EXECUTION_PLAN.md` (close-out checklist).
- [ ] T026 Final verification: push the branch, confirm `CI gate` is green on the last commit, fast-forward `main`, and record the CI run in `validation.md`.

---

## Dependencies & Execution Order

- **Setup (Phase 1)** and **Foundational (Phase 2)** first; Phase 2 blocks all stories.
- **US1** then **US2** and **US3** (all P1; US2 and US3 both extend `GameSession` and run in order); **US4** and **US5** after (US5's audit sees US1–US4's changes).
- **Polish** last.
- Within a story: tests first and seen failing; implementation tasks in order.

### Parallel Opportunities

- T001 and T002; T003 alongside T002.
- Each story's `[P]` test task can be written while the previous story's implementation finishes, in a different file.
- T024 and T025.

## Implementation Strategy

1. Phases 1–2, then US1 (labels with states): the board is readable with VoiceOver.
2. US2 and US3: playable and followable with VoiceOver.
3. US4 (contrast and crowns), US5 (audit), then Polish.
4. After each story: `scripts/test.sh` green, push, CI green, update the board and `EXECUTION_PLAN.md`.

## Requirement Coverage

| FRD / spec IDs | Test tasks | Implementation tasks |
|---|---|---|
| FR-A11Y-01 · FR-001, FR-002, FR-003 | T005, T006 (order) | T007, T008, T009 |
| FR-A11Y-02 · FR-004, FR-005, FR-006 | T010 (and the E3 tap tests) | T011, T012 |
| FR-A11Y-03 · FR-007 to FR-012 | T013 | T014, T015 |
| FR-A11Y-05 · FR-013 to FR-016, FR-020 | T016 | T017, T018 |
| FR-A11Y-04 · FR-017, FR-018, FR-019 | T019 | T020, T021 |
| SC-001 | — | T023 (for the user) |
| SC-002 | T005 | — |
| SC-003 | T013 | — |
| SC-004 | T019 | T020 |
| SC-005 | T016 | T018 |
| SC-006 | T023 | — |

## Board Mapping

Reconciled with the board in #159 (2026-10-22). Each board issue lists its task IDs:

| Board task | Tasks |
|---|---|
| #161 Square elements with states | T005–T009 |
| #162 Double-tap play, including chains | T010–T012 |
| #164 Announcements | T013–T015 |
| #166 Non-color cues | T016–T018 |
| #168 Accessibility audit | T019–T021 |
| #197 Validate the E7 slice and update docs | T001–T004, T022–T026 |

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Verify tests fail before implementing
- Each acceptance test names its story ID (for example `US1`) in its display name or tag
- A test task completes together with the implementation tasks it covers; every commit leaves the app building and all tests passing
