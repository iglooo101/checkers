---

description: "Task list for the game experience slice (epic E3)"
---

# Tasks: Game Experience

**Input**: Design documents from `/specs/003-game-experience/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/ (game-session.md, screens.md), quickstart.md

**Tests**: Tests are MANDATORY (Constitution III). Every user story has unit tests (Swift Testing, `checkers/checkersTests/`) for its model, navigation and storage rules, and a UI test (XCUITest, `checkers/checkersUITests/`) for its flow. Unit suites are named `US<n>…Tests` with display names that start with the story ID and list the FRD IDs they prove, for example `@Test("US2 FR-MOVE-05: tapping a piece that cannot capture shows the notice")`; UI test methods are named `testUS<n>_…`. Test tasks come before the implementation tasks they cover and must be observed failing (or failing to compile) before implementation begins.

**Organization**: Tasks are grouped by user story so each story can be implemented and verified on its own. A test task is complete together with the implementation tasks it covers (red, then green): no commit or push is ever red, so every completed task leaves the app building and all tests passing (Constitution workflow gate 3).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US7)
- Paths are relative to the repository root. Shorthands: `App/` is `checkers/checkers/`, `Unit/` is `checkers/checkersTests/`, `UI/` is `checkers/checkersUITests/`. All three are file-system synchronized groups: new files join their target without project edits.

## Conventions used by every task

- Run everything with `scripts/test.sh` (unit, UI and engine tests on the iPhone 17 simulator; this build also runs SwiftLint). One suite: `source scripts/lib.sh && xcodebuild test "${XCODEBUILD_FLAGS[@]}" -only-testing:checkersTests/<Suite>` (or `checkersUITests/<Class>`).
- Behavior follows [contracts/game-session.md](contracts/game-session.md); every text, identifier and layout rule follows [contracts/screens.md](contracts/screens.md). Strings are `LocalizedStringResource`s, whole sentences, never concatenated.
- After adding or removing user-facing strings, build, run `scripts/sync-string-catalog.sh` (T001) and commit `App/Localizable.xcstrings`; `scripts/check-string-catalog.sh checkers/checkers/Localizable.xcstrings .build/DerivedData` must pass.
- Every new view has `#Preview`s in light, dark and `accessibility5`, built from in-memory stores and sessions (Constitution workflow 4). Colors come only from `Palette` (T005).
- No force unwraps, `try!` or force casts outside tests; no `print`; logging through `Log` with the `game` and `setup` categories (T006).
- No test-only code paths in the app: UI tests set every setup choice they rely on.
- Commit each story's failing tests with the implementation that makes them pass (or the tests first, without pushing). Push after each story and wait for `CI gate` before pushing again (a push cancels the running CI). Commits are authored by iglooo101 with no AI attribution.
- Before starting a story, move its board tasks to In Progress; when the story is pushed and green, move them to Done (`scripts/project/board_move.py`, which closes the issue; post the summary with `gh issue comment`), then `scripts/project/update_plan.py`. See Board Mapping.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Tools and test helpers every story uses.

- [X] T001 Create `scripts/sync-string-catalog.sh` (sources `scripts/lib.sh`; usage `sync-string-catalog.sh [catalog] [derived-data]`, defaulting to `checkers/checkers/Localizable.xcstrings` and `.build/DerivedData`): finds the extracted `*.stringsdata` files exactly as `scripts/check-string-catalog.sh` does, runs `xcrun xcstringstool sync <catalog> --stringsdata …` in place, and prints the keys added and marked stale. Verify: after a `scripts/test.sh` build it leaves the current catalog unchanged and `check-string-catalog.sh` passes.
- [X] T002 Make the engine's custom-position initializers public, test-first: write `Unit/GamePositionsTests.swift` with a plain `import CheckersEngine` (no `@testable`) that builds `GameState(position: Position([Square(name: "c3")!: Piece(side: .light, kind: .man), Square(name: "d4")!: Piece(side: .dark, kind: .man)]), sideToMove: .light)` and expects `legalSteps == [Step(from: c3, to: e5)]`; it fails to compile until `Position.init(_ pieces: [Square: Piece])` in `checkers/CheckersEngine/Sources/CheckersEngine/Position.swift` and `GameState.init(position:sideToMove:)` in `GameState.swift` are made `public` (behavior unchanged; engine tests still pass). Record the change in `specs/002-rules-engine/contracts/engine-api.md` (declarations, with "made public in E3 for app previews and tests"). Then create `Unit/Support/GamePositions.swift` with helpers on the public API: `Square(_ name:)`, `Step(_ from:, _ to:)`, `Piece.lightMan/lightKing/darkMan/darkKing`, `GameState(_ layout: [String: Piece], toMove: Side)`. Previews in the app target use the same public initializers (research R12).
- [X] T003 [P] Create `specs/003-game-experience/checklists/validation.md` with one section per quickstart scenario (1–7) and a "Baseline" section recording that `scripts/test.sh` passes before any slice code and the current launch time.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Colors and logging the screens share.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T004 [P] Update `Unit/LoggingTests.swift` first: expect `Log.Category` cases `app`, `game`, `setup` with matching raw values and loggers `Log.game`, `Log.setup`. Write `Unit/PaletteTests.swift` (`US1 FR-GAME-07`): every `Palette` color resolves from the asset catalog (`UIColor(named:)` is not `nil`) in both the light and dark trait collections. Both fail to compile until T005–T006.
- [X] T005 [P] Add the Classic board colors to `App/Assets.xcassets` as color sets with light and dark appearances: `BoardLightSquare` (#f1dfb9), `BoardDarkSquare` (#7a4a24), `BoardFrame` (#3b2415), `PieceLight` (#fffaf0) and `PieceLightEdge` (#a88f5f), `PieceDark` (#2a1a0e) and `PieceDarkEdge` (#6b4426), `Crown` (#e8c46a), `Selection`, `Hint` and `Target` (accent tones readable on both square colors); dark appearances may repeat the light values for the board itself. Create `App/Support/Palette.swift`: an enum with a static `Color` per set (`Color("BoardLightSquare")`…), the only place views get colors from.
- [X] T006 Add `game` and `setup` to `Log.Category` and the matching static loggers in `App/Support/Logging.swift`. T004 passes.

**Checkpoint**: `scripts/test.sh` passes; the app still shows the web prototype.

---

## Phase 3: User Story 1 - Start a two-player game and move by tapping (Priority: P1) 🎯 MVP

**Goal**: Home, a setup screen with the opponent choice, and a game screen where two players move by tapping; the web prototype is no longer the app's root (#65, #70, #75, #76, #77, #80, #81; FR-001, FR-002, FR-007, FR-010, FR-012 to FR-016, FR-018, FR-019, FR-021, FR-022, FR-024).

**Independent Test**: `-only-testing:checkersTests/US1TwoPlayerMoveTests -only-testing:checkersTests/BoardLayoutTests -only-testing:checkersUITests/US1TwoPlayerMoveUITests` (quickstart §2).

### Tests for User Story 1 (MANDATORY - write first) ⚠️

- [X] T007 [P] [US1] Write `Unit/BoardLayoutTests.swift` (`struct BoardLayoutTests`): with Light at the bottom, display cell (row 7, column 0) is a1 and (0, 7) is h8; with Dark at the bottom, (row 7, column 0) is h8 and (0, 7) is a1; cells where `(row + column)` is even are light squares (`nil`) in both orientations; `cell(of:)` inverts `square(row:column:)` for all 32 squares in both orientations. Display names start `US1 FR-GAME-04` / `US6 FR-GAME-03` as appropriate.
- [X] T008 [P] [US1] Write `Unit/US1TwoPlayerMoveTests.swift` (`struct US1TwoPlayerMoveTests`) covering:
  - `US1 FR-SETUP-01`: `GameSetup.defaults.opponent == .twoPlayers`; `canStart` is true for `.twoPlayers` and false for `.computer`.
  - `US1 FR-SETUP-06`: a session for a two-player setup has `state == GameState()`, `layout.bottomSide == .light`, `playerSide == nil`, no selection, `turnText` "Light to move".
  - `US1 FR-MOVE-01 FR-MOVE-03`: tap c3 selects it; tap e3 switches to e3; tap e3 again clears; tap c3 then c5 (empty, not a target) clears; tap c3 then d4 moves the man (d4 holds a Light man, c3 empty), clears the selection and `turnText` becomes "Dark to move".
  - `US1 FR-MOVE-04`: on Light's turn tapping b6 (a Dark man) selects nothing; tapping c1 (a Light man with no move) selects nothing.
  - `US1 FR-NAV-01 FR-SETUP-01`: `AppRouter` starts with an empty path and no session; `newGame()` makes the path `[.setup]`; `startGame()` with Two players makes the path `[.game]` and creates a session from `GameState()`; `startGame()` with Computer changes nothing.
  Use an `InMemorySetupStore`. Fails to compile until T011–T014.
- [X] T009 [P] [US1] Create `UI/Support/AppScreens.swift` (helpers on `XCUIApplication`: `element(_ identifier:)` via `descendants(matching: .any)`, `square(_ name:)`, `startTwoPlayerGame()` that taps `home.newGame`, chooses Two players in `setup.opponent` and taps `setup.start`) and write `UI/US1TwoPlayerMoveUITests.swift` (`final class US1TwoPlayerMoveUITests: XCTestCase`, methods `@MainActor`):
  - `testUS1_homeOffersFourEntries`: after launch, `home.newGame`, `home.statistics`, `home.rules`, `home.settings` exist; tapping `home.statistics` shows a screen titled "Statistics" and Back returns Home (likewise Rules and Settings).
  - `testUS1_tapToMove`: `startTwoPlayerGame()`; `game.turn` reads "Light to move"; `square.c3` is labelled "c3, Light man"; tap `square.c3` then `square.d4`; read the labels at once, without waiting: `square.d4` is "d4, Light man", `square.c3` "c3, empty" (FR-SND-04, no animation), and `game.turn` reads "Dark to move".
  - `testUS1_boardFitsAndShowsOnlyTheIndicator`: in a new game, the `board` frame lies inside the window and is square (FR-PLAT-01), and the only text on the game screen apart from the menu is `game.turn` (FR-GAME-01).
  Delete `UI/AppSmokeUITests.swift` in this task: it tests the web prototype, which T019 removes from the app's root. Fails until T019.

### Implementation for User Story 1

- [X] T010 [P] [US1] Create `App/Features/Setup/GameSetup.swift`: `enum Opponent { case computer, twoPlayers }`, `enum Difficulty { case easy, medium, hard }`, `enum SideChoice { case light, dark, random }` (all `String`-backed, `Codable`, `CaseIterable`, `Sendable`), and `struct GameSetup: Codable, Equatable, Sendable` with `opponent`, `difficulty`, `side`, `static let defaults` (Two players, Easy, Light) and `canStart` (`opponent == .twoPlayers`, FR-011).
- [X] T011 [P] [US1] Create `App/Features/Setup/SetupStore.swift`: `protocol SetupStore { func load() -> GameSetup; func save(_ setup: GameSetup) }` and `final class InMemorySetupStore: SetupStore` (holds a value, starts at `.defaults`). The `UserDefaults` store comes in US6.
- [X] T012 [P] [US1] Create `App/Features/Game/BoardLayout.swift`: `struct BoardLayout: Equatable, Sendable { let bottomSide: Side }` with `square(row:column:) -> Square?` and `cell(of:) -> (row: Int, column: Int)` per research R6. T007 passes.
- [X] T013 [P] [US1] Create `App/Features/Game/GameText.swift`: `enum GameText` with `static func turn(_ side: Side) -> LocalizedStringResource` ("Light to move", "Dark to move") and `static func squareLabel(_ square: Square, _ piece: Piece?) -> LocalizedStringResource` (`"\(square.name), Light man"` and the other four cases from contracts/screens.md).
- [X] T014 [US1] Create `App/Features/Game/GameSession.swift`: `@Observable final class GameSession` with `init(setup: GameSetup, playerSide: Side? = nil, state: GameState = GameState())`, stored `state`, `setup`, `playerSide`, `selection`; derived `layout`, `turnText`; `tap(_:)` implementing rows 1, 4, 5, 6 and 8 of the taps table and "Applying a step" (logging an unexpected `RuleError` with `Log.game`). Create `App/App/Route.swift` (`enum Route: Hashable { case setup, game, statistics, rules, settings }`) and `App/App/AppRouter.swift` (`@Observable final class AppRouter` with `path`, `session`, `setup`, `init(store: SetupStore)`, `newGame()`, `startGame()`, `open(_:)`). T008 passes.
- [X] T015 [P] [US1] Create `App/Features/Game/PieceView.swift`: a man is a filled circle in `PieceLight`/`PieceDark` with an edge ring; a king adds a `crown.fill` symbol in `Crown` (FR-013); takes an `isSelected` flag drawing a thick `Selection` ring (FR-027 groundwork). Previews for all four pieces, selected and not.
- [X] T016 [US1] Create `App/Features/Game/BoardView.swift`: a square board sized to the smaller of the available width and height, inset 8 points, framed in `BoardFrame`, 8 rows of 8 cells from `session.layout`; dark cells are buttons with identifier `square.<name>`, label `GameText.squareLabel`, the selected trait when selected, and `onTapGesture` → `session.tap`; light cells are not accessibility elements; all changes without animation (`.transaction { $0.animation = nil }`, FR-018).
- [X] T017 [US1] Create `App/Features/Game/GameView.swift`: the turn indicator (`game.turn`, header trait, wraps at large sizes) above `BoardView`, no other game information (FR-012); previews from a session at the start and after one move.
- [X] T018 [P] [US1] Create `App/Features/Home/HomeView.swift` (title "Checkers"; buttons New game, Statistics, Rules, Settings with the identifiers of contracts/screens.md; scrolls at large text sizes), `App/Features/Setup/SetupView.swift` (title "New game"; `setup.opponent` picker with Computer and Two players bound to `router.setup.opponent`; `setup.start` button calling `router.startGame()`, disabled unless `canStart`) and `App/Features/Placeholders/PlaceholderView.swift` (a screen with a title only, for now).
- [X] T019 [US1] Create `App/App/RootView.swift` (`NavigationStack(path: $router.path)` over `HomeView`, with destinations: `.setup` → `SetupView`, `.game` → `GameView` for `router.session`, `.statistics`/`.rules`/`.settings` → `PlaceholderView` with the screen's title) and change `App/CheckersApp.swift` to show `RootView` with an `AppRouter(store: InMemorySetupStore())` held in `@State`. `ContentView.swift` stays unused until T055. Run `scripts/sync-string-catalog.sh` and commit the catalog. US1 unit and UI tests pass; `ScreenCatalogTests` and `LocalizationTests` still pass.

**Checkpoint**: US1 complete: two players can start a game from Home and play simple moves by tapping.

---

## Phase 4: User Story 2 - Captures, chains and crowning on the board (Priority: P1)

**Goal**: The indicator and notice for mandatory captures, jump-by-jump chains locked to the jumping piece, and kings shown with a crown (#77, #83, #87; FR-014, FR-023, FR-029 to FR-031).

**Independent Test**: `-only-testing:checkersTests/US2CaptureChainTests -only-testing:checkersUITests/US2CaptureUITests`.

### Tests for User Story 2 (MANDATORY - write first) ⚠️

- [X] T020 [P] [US2] Write `Unit/US2CaptureChainTests.swift` (`struct US2CaptureChainTests`), building positions with `GamePositions`:
  - `US2 FR-GAME-02`: with Light men c3 and a1 and Dark men d4 and h8, Light to move, `turnText` is "Light to move · capture required"; the Dark version reads "Dark to move · capture required".
  - `US2 FR-MOVE-05`: in that position, tapping a1 shows `captureRequired`, selects nothing; with c3 selected, tapping a1 keeps c3 selected; the next tap (any square) clears the notice; applying a step clears it.
  - `US2 FR-CHAIN-01 FR-CHAIN-02`: Light men a3 and g1, Dark men b4, d6, h8: tap a3, tap c5: b4 is empty, `selection == c5`, `targets == [e7]`; tapping g1, b6 or an empty square changes nothing (rows 2–3).
  - `US2 FR-CHAIN-03`: then tap e7: d6 empty, selection cleared, `turnText` "Dark to move".
  - `US2 FR-RULE-07 FR-CHAIN-03`: Light man b6, Dark men c7 and e7: tap b6, tap d8: d8 holds a Light king, selection cleared, Dark to move.
  Fails until T022–T023.
- [X] T021 [P] [US2] Write `UI/US2CaptureUITests.swift`: `testUS2_captureRequired`: `startTwoPlayerGame()`; play `c3`→`d4`, `f6`→`e5` by taps; `game.turn` reads "Light to move · capture required"; tap `square.e3`: `game.notice` reads "A capture is required."; tap `square.d4` then `square.f6`: `square.e5` is labelled "e5, empty", `square.f6` "f6, Light man", and `game.turn` reads "Dark to move". Fails until T024.

### Implementation for User Story 2

- [X] T022 [P] [US2] Extend `App/Features/Game/GameText.swift`: `turn(_:captureRequired:)` with the two "· capture required" sentences, and `notice(_ notice: Notice) -> LocalizedStringResource` ("A capture is required."). Add `enum Notice { case captureRequired }` to `App/Features/Game/GameSession.swift`.
- [X] T023 [US2] Extend `App/Features/Game/GameSession.swift`: stored `notice`; rows 2, 3 and 7 of the taps table; clear the notice at the start of every tap and when a step is applied; `turnText` uses `state.isCaptureRequired`. T020 passes.
- [X] T024 [US2] Extend `App/Features/Game/GameView.swift`: show `game.notice` below the indicator while `session.notice` is set (wrapping, not truncated); previews with a capture-required position and the notice. Sync and commit the catalog. US1 and US2 tests pass.

**Checkpoint**: US2 complete: every rule of a turn is playable and visible on the board.

---

## Phase 5: User Story 3 - Move hints, selection and dragging (Priority: P2)

**Goal**: Highlighted movable pieces and targets, a marked selection, and drag and drop; the game screen's accessibility pass (#78, #82, #85, #86; FR-020, FR-025 to FR-028, FR-039, FR-040).

**Independent Test**: `-only-testing:checkersTests/US3HintsDragTests -only-testing:checkersUITests/US3DragUITests`.

### Tests for User Story 3 (MANDATORY - write first) ⚠️

- [X] T025 [P] [US3] Write `Unit/US3HintsDragTests.swift` (`struct US3HintsDragTests`):
  - `US3 FR-AID-01 FR-AID-04`: a new game's `hintedPieces` are exactly a3, c3, e3, g3; in the US2 capture position only c3 is hinted; once over, none.
  - `US3 FR-AID-02`: with c3 selected in a new game, `targets == [b4, d4]`; with nothing selected, empty.
  - `US3 FR-AID-03`: `selection` is set whatever the hints; the view model exposes it for marking (tested via the session).
  - `US3 FR-MOVE-02`: `beginDrag(at: c3)` returns true and selects c3; `drop(on: d4)` moves; `beginDrag(at: c1)` returns false and selects nothing; after `beginDrag(at: c3)`, `drop(on: c5)`, `drop(on: c3)` and `drop(on: nil)` each leave the state unchanged; in the US2 chain after the first jump, `beginDrag(at: g1)` returns false and `beginDrag(at: c5)` true; in the capture position, `beginDrag(at: a1)` returns false and shows `captureRequired`.
  Fails until T027.
- [X] T026 [P] [US3] Write `UI/US3DragUITests.swift`: `testUS3_dragToMove`: `startTwoPlayerGame()`; press `square.c3` and drag to `square.d4` (`press(forDuration:thenDragTo:)`): `square.d4` is "d4, Light man" and `game.turn` "Dark to move"; `testUS3_invalidDropReturns`: drag `square.c3` to `square.c5`: `square.c3` is still "c3, Light man" and `game.turn` "Light to move"; `testUS3_selectionIsMarked` (FR-AID-03): after tapping `square.c3` it reports as selected, and after tapping it again it does not. Fails until T028.

### Implementation for User Story 3

- [X] T027 [US3] Extend `App/Features/Game/GameSession.swift`: derived `hintedPieces` and `targets`, `beginDrag(at:) -> Bool` and `drop(on:)` per the contract's Drags section. T025 passes.
- [X] T028 [US3] Extend `App/Features/Game/BoardView.swift` and `PieceView.swift`: a thin `Hint` ring on hinted pieces, a `Target` dot on target squares, the thick `Selection` ring on the selected piece; a `DragGesture(minimumDistance: 8)` on pieces of the side to move that calls `beginDrag` on start, offsets the piece while dragging when accepted, converts the end location in the board's named coordinate space to a square through `BoardLayout` (or `nil` off the board) and calls `drop(on:)`; offsets reset without animation. US3 tests pass.
- [X] T029 [US3] Accessibility pass for the game screen (#78): check `GameView` at `accessibility5` and in Dark Mode on iPhone SE (3rd generation) and 17 Pro Max (board fully visible, squares at least 44 points, indicator and notice fully shown); every square labelled per contracts/screens.md (FR-040); previews in light, dark and `accessibility5` with hints, a selection and a king. Record the results in `validation.md`.

**Checkpoint**: US3 complete: the board shows hints and supports dragging.

---

## Phase 6: User Story 4 - Finish a game: resign, result and play again (Priority: P2)

**Goal**: Resign with confirmation, the result panel over the final board, Play again and Home from the result (#89, #90, #91, #92; FR-032 to FR-035, FR-039).

**Independent Test**: `-only-testing:checkersTests/US4GameEndTests -only-testing:checkersUITests/US4GameEndUITests`.

### Tests for User Story 4 (MANDATORY - write first) ⚠️

- [ ] T030 [P] [US4] Write `Unit/US4GameEndTests.swift` (`struct US4GameEndTests`):
  - `US4 FR-END-02`: in a two-player game `resigningSide` is the side to move; `resign()` on Light's turn gives `resultText` "Light resigned" and `isOver`; on Dark's turn "Dark resigned".
  - `US4 FR-END-01 FR-END-06`: capturing the last Dark piece (Light man c3, Dark man d4: tap c3, tap e5) gives "Light wins: no moves left"; the Dark version reads "Dark wins: no moves left".
  - `US4 FR-END-03 FR-END-04 FR-END-06`: the engine's king shuffle (`h2` and `a7` kings, eight turns tapped through the session) gives "Draw by repetition"; replaying E2's 80-turn king tour through the session's taps (Light king b2 cycling c1, d2, e3, d4, c5, b4, c3, b2; Dark king e7 cycling f8, g7, h6, g5, f6, e7; `specs/002-rules-engine/tasks.md` T025) gives "Draw by no progress".
  - `US4 FR-END-06`: once over, taps, drags, `undo()` and `resign()` change nothing, and `selection`, `notice`, `hintedPieces` are empty.
  - `US4 FR-END-07`: `AppRouter.playAgain()` replaces the session with one from `GameState()` and the same setup; `requestHome()` on a finished game empties the path without asking.
  Fails until T032–T033.
- [ ] T031 [P] [US4] Write `UI/US4GameEndUITests.swift`: `testUS4_resignAndPlayAgain`: `startTwoPlayerGame()`; play `c3`→`d4`; open `game.menu`, tap `game.menu.resign`, tap `game.resign.cancel`: the game continues ("Dark to move"); resign again and confirm (`game.resign.confirm`): `result.text` reads "Dark resigned", `square.d4` is still "d4, Light man"; tap `result.playAgain`: `game.turn` "Light to move" and `square.c3` "c3, Light man"; resign and confirm, then `result.home`: `home.newGame` exists. Fails until T035.

### Implementation for User Story 4

- [ ] T032 [P] [US4] Extend `App/Features/Game/GameText.swift`: `result(_ outcome: Outcome) -> LocalizedStringResource?` with the six sentences (a resignation names the side that resigned, the winner's opponent) and `resignTitle(_ side: Side)` ("Resign as Light?", "Resign as Dark?").
- [ ] T033 [US4] Extend `App/Features/Game/GameSession.swift` (`resigningSide`, `resign()`, `isOver`, `resultText`; rule 1 for taps and drags; clear selection and notice when over) and `App/App/AppRouter.swift` (`playAgain()`, `requestHome()` for a finished game or no session). T030 passes.
- [ ] T034 [P] [US4] Create `App/Features/Game/ResultPanel.swift`: an overlay with a material background holding `result.text` and the `result.playAgain` and `result.home` buttons, scrolling at large text sizes; previews for all six results in light, dark and `accessibility5`.
- [ ] T035 [US4] Extend `App/Features/Game/GameView.swift`: a toolbar menu (`game.menu`) with Resign (`game.menu.resign`) while in progress; a confirmation dialog titled `resignTitle(resigningSide)` with Resign (destructive, `game.resign.confirm`) and Cancel (`game.resign.cancel`); `ResultPanel` over the board when over, wired to `router.playAgain()` and `router.requestHome()`. Sync the catalog. Accessibility pass for the result panel and the dialog (#92): `accessibility5`, Dark Mode and labels; record in `validation.md`. US4 tests pass.

**Checkpoint**: US4 complete: every game ends with a clear result.

---

## Phase 7: User Story 5 - Undo in a two-player game (Priority: P2)

**Goal**: Undo from the game menu, one turn at a time, unavailable at the start and after the end (#94; FR-036 to FR-038).

**Independent Test**: `-only-testing:checkersTests/US5GameUndoTests -only-testing:checkersUITests/US5UndoUITests`.

### Tests for User Story 5 (MANDATORY - write first) ⚠️

- [ ] T036 [P] [US5] Write `Unit/US5GameUndoTests.swift` (`struct US5GameUndoTests`):
  - `US5 FR-UNDO-01 FR-UNDO-02`: after `c3–d4`, `b6–a5` (tapped), `undo()` restores the state before Dark's turn and `turnText` "Dark to move"; a second `undo()` restores `GameState()`; `canUndo` is then false.
  - `US5 FR-UNDO-05`: in the US2 chain after the first jump, `undo()` restores the position before the chain with Light to move and nothing selected.
  - `US5 FR-UNDO-06`: `canUndo` is false at the start and after resigning; true after one move.
  - `US5`: after `undo()`, `selection` and `notice` are cleared (FR-038).
  Fails until T038.
- [ ] T037 [P] [US5] Write `UI/US5UndoUITests.swift`: `testUS5_undoBackToStart`: `startTwoPlayerGame()`; `game.menu.undo` is disabled; play `c3`→`d4` and `f6`→`e5`; Undo twice: `square.c3` is "c3, Light man", `square.f6` "f6, Dark man", `game.turn` "Light to move", and `game.menu.undo` is disabled again. Fails until T039.

### Implementation for User Story 5

- [ ] T038 [US5] Extend `App/Features/Game/GameSession.swift`: `canUndo` and `undo()` per the contract. T036 passes.
- [ ] T039 [US5] Add Undo (`game.menu.undo`, disabled when `!session.canUndo`, not shown once over) to the game menu in `App/Features/Game/GameView.swift`. Sync the catalog. US5 tests pass.

**Checkpoint**: US5 complete.

---

## Phase 8: User Story 6 - Game setup choices (Priority: P3)

**Goal**: Computer choices with difficulty and side, remembered across launches; computer games described and blocked until E4; the computer-game rules for orientation, resignation and Random (#70, #71, #73, #76, #89, #91; FR-008, FR-009, FR-011, FR-015, FR-032, FR-034).

**Independent Test**: `-only-testing:checkersTests/US6SetupTests -only-testing:checkersTests/PrivacyManifestTests -only-testing:checkersUITests/US6SetupUITests`.

### Tests for User Story 6 (MANDATORY - write first) ⚠️

- [ ] T040 [P] [US6] Write `Unit/US6SetupTests.swift` (`struct US6SetupTests`):
  - `US6 FR-SETUP-03`: `GameSetup.defaults` is Two players, Easy, Light; a `GameSetup` round-trips through `JSONEncoder`/`JSONDecoder`.
  - `US6 FR-SETUP-03`: `UserDefaultsSetupStore` on a private suite (`UserDefaults(suiteName: "US6SetupTests-<UUID>")`, removed after the test) returns the defaults when empty, returns what was saved, and returns the defaults for an undecodable stored value.
  - `US6 FR-SETUP-02 FR-SETUP-03`: changing `router.setup` (opponent, difficulty, side) saves each change to the store.
  - `US6 FR-GAME-03`: a session with `playerSide: .dark` has `layout.bottomSide == .dark`; with `.light`, `.light`.
  - `US6 FR-END-02`: in a computer session `resigningSide == playerSide` whoever is to move.
  - `US6 FR-END-07`: with a Random side and a seeded generator injected into `AppRouter`, `playAgain()` draws the player's side again from the generator (two successive Play agains follow the generator's sequence); with a fixed side it is kept.
  Fails to compile until T043–T045.
- [ ] T041 [P] [US6] Update `Unit/PrivacyManifestTests.swift` first: `NSPrivacyAccessedAPITypes` holds exactly one entry, category `NSPrivacyAccessedAPICategoryUserDefaults` with reasons `["CA92.1"]`; tracking and collected data stay empty. Fails until T044.
- [ ] T042 [P] [US6] Write `UI/US6SetupUITests.swift`: `testUS6_computerChoicesRemembered`: open setup; choose Computer: `setup.difficulty`, `setup.side` and `setup.computerNote` appear and `setup.start` is disabled; choose Hard and Dark; terminate and relaunch; open setup: Computer, Hard and Dark are selected; choose Two players: difficulty, side and the note disappear and `setup.start` is enabled. Fails until T046.

### Implementation for User Story 6

- [ ] T043 [US6] Add `UserDefaultsSetupStore` to `App/Features/Setup/SetupStore.swift`: `init(defaults: UserDefaults, key: String = "lastGameSetup")`; `load()` decodes the JSON value, returning `.defaults` when missing and logging with `Log.setup` (private redaction) and returning `.defaults` when undecodable; `save(_:)` encodes and stores.
- [ ] T044 [US6] Declare the user-defaults required-reason API in `App/PrivacyInfo.xcprivacy` (`NSPrivacyAccessedAPICategoryUserDefaults`, reason `CA92.1`) and switch `App/CheckersApp.swift` to `AppRouter(store: UserDefaultsSetupStore(defaults: .standard))` in the same change (Constitution VI.3). T041 passes.
- [ ] T045 [US6] Extend `App/App/AppRouter.swift`: save `setup` to the store on every change; inject a random-number generator (`init(store:random:)`, the system generator by default) used to resolve a Random side in `startGame()` (for when E4 enables computer games) and `playAgain()`; pass the resolved `playerSide` to new sessions. Extend `GameSession` so `layout` and `resigningSide` use `playerSide`. T040 passes.
- [ ] T046 [US6] Extend `App/Features/Setup/SetupView.swift`: `setup.difficulty` (Easy, Medium, Hard) and `setup.side` (Light, Dark, Random) pickers and the `setup.computerNote` text, shown only for Computer; `setup.start` disabled for Computer. Sync the catalog. Accessibility pass for setup (#73): `accessibility5`, Dark Mode, labels, previews for both opponents; record in `validation.md`. US6 tests pass.

**Checkpoint**: US6 complete: setup is final except for enabling computer games in E4.

---

## Phase 9: User Story 7 - Navigate the app (Priority: P3)

**Goal**: The full game menu, returning to the same game, the leave confirmation, placeholder messages, and no web content left (#65, #66, #67, #68; FR-003 to FR-006, FR-042).

**Independent Test**: `-only-testing:checkersTests/US7NavigationTests -only-testing:checkersTests/NoWebContentTests -only-testing:checkersUITests/US7NavigationUITests`.

### Tests for User Story 7 (MANDATORY - write first) ⚠️

- [ ] T047 [P] [US7] Write `Unit/US7NavigationTests.swift` (`struct US7NavigationTests`):
  - `US7 FR-NAV-04`: with a game open and a chain in progress (US2 chain position), `open(.rules)` makes the path `[.game, .rules]`; removing the last path element leaves the same session object with an equal state and the chain still selected; likewise `.settings`.
  - `US7 FR-NAV-03`: `requestHome()` during a game in progress sets `isConfirmingLeave` and leaves the path and session unchanged; `cancelLeave()` clears it with nothing else changed; `confirmLeave()` empties the path and drops the session.
  - `US7 FR-NAV-02`: `PlaceholderText.message(for:)` gives the three one-line messages of contracts/screens.md for `.statistics`, `.rules` and `.settings`.
  Fails to compile until T050–T051.
- [ ] T048 [P] [US7] Write `Unit/NoWebContentTests.swift` (`struct NoWebContentTests`, `US7`): the app bundle contains no `.html` and no `.wav` resources (FR-006). Fails until T055.
- [ ] T049 [P] [US7] Write `UI/US7NavigationUITests.swift`:
  - `testUS7_menuOffersEverything`: in a game, `game.menu` offers `game.menu.undo`, `game.menu.resign`, `game.menu.rules`, `game.menu.settings` and `game.menu.home`.
  - `testUS7_rulesAndSettingsReturnToTheGame`: play `c3`→`d4`; open Rules from the menu, check `placeholder.message`, go Back: `square.d4` is "d4, Light man" and `game.turn` "Dark to move"; the same for Settings.
  - `testUS7_leaveConfirmation`: play a move; menu → Home: `game.leave.cancel` keeps the game; menu → Home → `game.leave.confirm` shows Home; New game → Two players → Start shows a fresh board.
  - `testUS7_placeholdersFromHome`: Home → Statistics shows its `placeholder.message`; Back → Home.
  - `testUS7_largestTextSize` (FR-A11Y-04, in part): launched with the system argument `-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityXXXL`, Home's four buttons, setup's `setup.start`, the game's `game.turn` and `game.menu`, and the result panel's buttons are all hittable, and the `board` lies inside the window.
  Fails until T052–T053.

### Implementation for User Story 7

- [ ] T050 [P] [US7] Create `App/Features/Placeholders/PlaceholderText.swift` (`message(for: Route) -> LocalizedStringResource?` with the three lines) and show the message (`placeholder.message`) in `PlaceholderView`, scrolling at large text sizes.
- [ ] T051 [US7] Extend `App/App/AppRouter.swift`: `requestHome()` sets `isConfirmingLeave` while the game is in progress; `confirmLeave()` and `cancelLeave()` per the contract. T047 passes.
- [ ] T052 [US7] Extend the game menu in `App/Features/Game/GameView.swift` with Rules, Settings (pushing `.rules`, `.settings`) and Home (`router.requestHome()`), shown in progress and after the end, and the leave confirmation dialog ("Leave this game?", "It can't be resumed yet.", Leave destructive `game.leave.confirm`, Cancel `game.leave.cancel`) bound to `isConfirmingLeave`. Sync the catalog.
- [ ] T053 [US7] Accessibility pass for Home, setup navigation and placeholders (#68): `accessibility5`, Dark Mode, labels, previews; record in `validation.md`. US7 unit and UI tests pass except `NoWebContentTests`.
- [ ] T054 [US7] Update `Unit/LocalizationTests.swift` first: expect every string of contracts/screens.md in the catalog (titles, buttons, choices, the note, the four turn sentences, the notice, the six results, the dialog texts, the five square-label formats, the three placeholder messages) and none of `Classic`, `Modern`, `Play`, `Playful`, `Screen`. Fails until T055.
- [ ] T055 [US7] Remove the web prototype (#67): delete `App/ContentView.swift`, `App/Classic.html`, `App/Modern.html`, `App/Playful.html`, `App/Play.html`, `App/move.wav` and `Unit/ScreenCatalogTests.swift`; build, run `scripts/sync-string-catalog.sh` so the picker strings are removed, and commit the catalog. Confirm `grep -rn 'WebKit\|WKWebView\|UIViewRepresentable' checkers/checkers` finds nothing. T048 and T054 pass; all tests pass.

**Checkpoint**: US7 complete: the app is fully native.

---

## Phase 10: Polish & Cross-Cutting Concerns

- [ ] T056 Run `scripts/format.sh`, then confirm `scripts/check-format.sh --strict`, `scripts/tests/run.sh`, `scripts/check-string-catalog.sh checkers/checkers/Localizable.xcstrings .build/DerivedData` and `scripts/test.sh` pass with zero warnings and zero SwiftLint errors.
- [ ] T057 Run every scenario in `specs/003-game-experience/quickstart.md` (1–7), including the hand-played game (§3), the iPhone SE (3rd generation) and 17 Pro Max checks at the largest text size in Dark Mode (§4), the launch timing against the baseline (§5) and the SC-002 search, and record each result in `specs/003-game-experience/checklists/validation.md`.
- [ ] T058 [P] Update `checkers/CLAUDE.md`: the native app layout (`App/`, `Features/`), `GameSession` and `AppRouter`, the setup store and privacy entry, `scripts/sync-string-catalog.sh`, and the removal of the web screens.
- [ ] T059 [P] Update `HANDOFF.md` (current state, lessons learned) and `EXECUTION_PLAN.md` (close-out checklist).
- [ ] T060 Final verification: push the branch, confirm `CI gate` is green on the last commit, fast-forward `main`, and confirm SC-005 (no web content; launch no slower than the baseline in `checkers/launch-baselines.json`); record the CI run in `specs/003-game-experience/checklists/validation.md`.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: no dependencies. T002 decides how unit tests build positions for all later stories.
- **Foundational (Phase 2)**: depends on Setup; blocks all stories.
- **US1 (Phase 3)**: depends on Phase 2. It changes the app's root, so it comes first.
- **US2 (Phase 4)**, **US3 (Phase 5)**: depend on US1 (session and board); US3 also uses US2's chain and notice rules in its drag tests.
- **US4 (Phase 6)**: depends on US1; creates the game menu.
- **US5 (Phase 7)**: depends on US4's menu.
- **US6 (Phase 8)**: depends on US1 (setup screen and router) and US4 (Play again, resign).
- **US7 (Phase 9)**: depends on US4's menu and US1's routes; T055 removes the web prototype last.
- **Polish (Phase 10)**: depends on all stories.

The stories run in order (US1 → US7): they share `GameSession`, `GameView` and `AppRouter`.

### Within Each User Story

- The story's test tasks first; observe them fail (or fail to compile) before implementing.
- Model and text tasks before the views that use them.
- Story complete, with `scripts/test.sh` green, before the next one; push and wait for CI.

### Parallel Opportunities

- T003 alongside T001–T002; T004 and T005 together.
- Within each story, the `[P]` test tasks (different files) can be written together, and the `[P]` model, text and view tasks can be written together before the task that wires them.

## Parallel Example: User Story 1

```bash
Task: "T007 Unit/BoardLayoutTests.swift"
Task: "T008 Unit/US1TwoPlayerMoveTests.swift"
Task: "T009 UI/Support/AppScreens.swift and UI/US1TwoPlayerMoveUITests.swift"
# then
Task: "T010 GameSetup.swift"   Task: "T011 SetupStore.swift"   Task: "T012 BoardLayout.swift"   Task: "T013 GameText.swift"
```

## Implementation Strategy

### MVP First (User Story 1)

1. Phases 1–2, then US1: Home, setup and tapped moves in a native two-player game.
2. **Stop and validate** with the US1 suites.

### Incremental Delivery

1. US1 → US2 (both P1: a complete game by tapping) → US3 → US4 → US5 → US6 → US7 (web prototype removed) → Polish.
2. After each story: `scripts/test.sh` green, push, CI green, update the board and `EXECUTION_PLAN.md`.

## Requirement Coverage

FRD requirements in scope, by the test tasks that name them:

| FRD IDs | Test tasks |
|---|---|
| FR-NAV-01, FR-NAV-02 | T008, T009, T047, T049 |
| FR-NAV-03, FR-NAV-04, FR-GAME-06 | T047, T049 |
| FR-SETUP-01, FR-SETUP-06 | T008, T009 |
| FR-SETUP-02, FR-SETUP-03 | T040, T042 |
| FR-GAME-01, FR-GAME-02, FR-GAME-05 | T008, T009, T020, T021 |
| FR-GAME-03, FR-GAME-04 | T007, T040 |
| FR-GAME-07 | T004 (palette colors resolve) |
| FR-SND-04, FR-PLAT-01 | T009 (labels read without waiting; board inside the window), T049 (largest text size) |
| FR-MOVE-01, FR-MOVE-03, FR-MOVE-04 | T008, T009 |
| FR-MOVE-02 | T025, T026 |
| FR-MOVE-05 | T020, T021 |
| FR-AID-01 to FR-AID-04 | T025, T026 (selected state) |
| FR-CHAIN-01 to FR-CHAIN-03, FR-RULE-07 | T020 |
| FR-END-01 to FR-END-04, FR-END-06, FR-END-07 | T030, T031, T040 |
| FR-UNDO-01, FR-UNDO-02, FR-UNDO-05, FR-UNDO-06 | T036, T037 |
| FR-A11Y-04 (in part), FR-PLAT-03 | T049 (largest text size), T054 (catalog); manual passes T029, T035, T046, T053 |

Spec requirements and success criteria:

| Spec ID | Tasks |
|---|---|
| FR-001, FR-002 | T008, T009, T018, T019 |
| FR-003 | T009, T047, T049, T050 |
| FR-004, FR-005 | T047, T049, T052 |
| FR-006 | T048, T055 |
| FR-007, FR-010 | T008, T009, T010, T014, T018 |
| FR-008, FR-009, FR-011 | T040, T042, T043, T045, T046 |
| FR-012 to FR-018 | T007, T008, T009, T012, T015–T017, T020, T040 |
| FR-019, FR-021, FR-022, FR-024 | T008, T009, T014 |
| FR-020 | T025, T026, T027, T028 |
| FR-023 | T020, T021, T023, T024 |
| FR-025 to FR-028 | T025, T027, T028 |
| FR-029 to FR-031 | T020, T023 |
| FR-032 to FR-035 | T030, T031, T033–T035, T040 |
| FR-036 to FR-038 | T036, T037, T038, T039 |
| FR-039, FR-040 | T029, T035, T046, T053 |
| FR-041 | T054, T055 (and the catalog check in every story) |
| FR-042 | T047, T049, T051, T052 |
| SC-001 | T057 (§3) |
| SC-002 | T057 (§1 search) |
| SC-003 | T029, T057 (§4) |
| SC-004 | T016, T028 (no animation), T057 (§3) |
| SC-005 | T055, T057 (§5), T060 |
| SC-006 | Every view task's previews, T029, T035, T046, T053 |

## Board Mapping

Reconciled with the board in #63 (2026-10-21). Each board task maps to these tasks, and each board issue lists its task IDs:

| Board task | Tasks |
|---|---|
| #65 Home screen | T009, T018, T019 |
| #66 Game screen menu | T047, T049, T051, T052 (leave confirmation, FR-042) |
| #67 Remove the HTML screens | T048, T054, T055 |
| #68 Accessibility: Home and navigation | T053 |
| #70 Setup screen | T008, T010, T018 (opponent), T042, T046 (difficulty, side, note) |
| #71 Remembered choices | T040, T041, T043, T044, T045 |
| #73 Accessibility: setup | T046 |
| #75 Board | T009, T015, T016, T017 |
| #76 Orientation | T007, T012, T040 |
| #77 Turn indicator | T008, T013, T020, T022 |
| #78 Accessibility: game screen | T029 |
| #80 Selection model | T008, T014, T020, T023 |
| #81 Tap to move | T009, T014, T016 |
| #82 Drag to move | T025, T026, T027, T028 |
| #83 Capture required message | T020, T021, T022, T023, T024 |
| #85 Hints | T025, T027, T028 |
| #86 Selected piece marked | T015, T025, T026, T028 |
| #87 Chain lock | T020, T023 |
| #89 Resign | T030, T031, T032, T033, T035, T040 (computer side) |
| #90 Result panel | T030, T031, T032, T034, T035 |
| #91 Play again | T030, T031, T033, T040 (Random), T045 |
| #92 Accessibility: result and confirmations | T035 |
| #94 Undo | T036, T037, T038, T039 |
| #196 Validate the E3 slice and update docs | T001–T006, T056–T060 |

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Each acceptance test names its story ID (for example `US1`) in its display name or tag
- A test task completes together with the implementation tasks it covers; every commit leaves the app building and all tests passing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
