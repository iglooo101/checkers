# Research: Game Experience

Phase 0 output for `specs/003-game-experience/plan.md`. Each entry records the decision, why, and
what else was considered. Facts marked *measured* were checked on the development Mac on
2026-10-21.

## Environment facts

| Item | Value |
|---|---|
| App target | `checkers/checkers/`, file-system synchronized group (new files join the target), `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, iOS 26.2, iPhone only, portrait (*measured*) |
| Current UI | `ContentView` with a segmented picker over four bundled HTML screens in a `WKWebView` (`WebView: UIViewRepresentable`), plus `move.wav` (*measured*) |
| Tests tied to the web UI | `ScreenCatalogTests` (bundled HTML files), `LocalizationTests` (the picker's strings), `AppSmokeUITests` (tabs and a move in `Play.html`) (*measured*) |
| String catalog | Keys `Classic`, `Modern`, `Play`, `Playful`, `Screen`; CI fails on missing or stale keys (`scripts/check-string-catalog.sh`), and command-line builds never update the catalog (E1 lesson) (*measured*) |
| Privacy manifest | No tracking, no collected data, no required-reason APIs; `PrivacyManifestTests` asserts the API list is empty (*measured*) |
| Engine | `CheckersEngine` (E2): `GameState` with `apply`, `resign`, `undo`, `legalSteps`, `movablePieces`, `targets(from:)`, `isCaptureRequired`, `chainSquare`, `canUndo`, `outcome` (`specs/002-rules-engine/contracts/engine-api.md`) |
| Simulators | iOS 26.3 runtime; iPhone 17 (tests), 16e, Air, 17 Pro, 17 Pro Max installed; iPhone SE (3rd generation) and iPhone 13 mini device types run on iOS 26.3 (*measured*: created and deleted a probe of each) |
| Classic look | `Classic.html`: light squares `#f1dfb9`, dark squares `#7a4a24`, frame `#3b2415`, light pieces `#fffaf0`/`#d9c39a`, dark pieces `#2a1a0e`/`#1a0f07`, gold accent `#e8c46a` (*measured*) |
| Launch baseline | 3.635 s, local Intel simulator, Debug (`checkers/launch-baselines.json`) |

## R1. Where the game logic lives

- **Decision**: An `@Observable` class `GameSession` in the app target
  (`checkers/checkers/Features/Game/`) owns one game: the engine's `GameState`, the game's setup,
  the player's side against the computer, the selection and the "capture required" notice. It
  turns taps and drags into engine steps and exposes what the board shows (highlights, targets,
  turn text, result). Views only read it and forward input.
- **Rationale**: Constitution II.2 keeps views thin and rules testable without UI; the rules
  themselves are already in the engine, so the session is the small layer of interaction rules
  (FR-021 to FR-023, FR-030) that FR-024 requires to be testable without the interface. It is
  shared mutable state for one game, which is what Constitution II.4 allows a class for. The app
  target defaults to the main actor, which suits a UI model; the engine's calls are synchronous
  and fast.
- **Alternatives considered**: a separate Swift package for the session (rejected: only the game
  screen uses it, Constitution II.1's "SHOULD" applies to logic used by two or more features or
  needing package-level tests, and app-target tests suffice); putting selection rules in the views
  (rejected: Constitution II.2, FR-024).

## R2. Navigation

- **Decision**: One `NavigationStack` at the root, driven by an `@Observable` `AppRouter` that holds
  the path of `Route` values (`setup`, `game`, `statistics`, `rules`, `settings`) and the current
  `GameSession`. Home is the root. Rules and Settings opened from the game menu are pushed on top
  of the game, so going back returns to the same session (FR-005). Home from the game pops to the
  root after the leave confirmation (FR-042). Play again replaces the session in place.
- **Rationale**: A value path makes every navigation rule a plain state change that unit tests can
  check (start game, leave, play again, return from Rules). Keeping the session in the router, not
  in a view's `@State`, means it survives the pushed screens.
- **Alternatives considered**: sheets for Rules and Settings (rejected: the FRD treats them as
  screens reachable from Home too, and one push style is simpler); a `TabView` like the prototype
  (rejected: the FRD's Home is a menu, not tabs).

## R3. Selection and moving rules

- **Decision**: `GameSession` handles input with these rules, in order (contract:
  `contracts/game-session.md`):
  1. The game is over: input does nothing.
  2. A chain is in progress: a tap on one of the chain piece's targets jumps; anything else does
     nothing (FR-030 overrides FR-021).
  3. A piece is selected and the tap is on one of its targets: the step is applied; after a jump
     that continues, the piece stays selected, otherwise nothing is selected.
  4. The tap is on a movable piece of the side to move: it becomes selected, or the selection is
     cleared if it was already selected.
  5. The tap is on a piece of the side to move that cannot move while a capture is required: the
     "capture required" notice appears; the selection is unchanged (FR-023).
  6. Anything else clears the selection.

  The notice is cleared at the start of every tap or drag and when a step is applied.
- **Rationale**: This orders the FRD's rules so every tap has exactly one outcome, including the
  edge cases in the spec. Only legal targets ever reach the engine, so it never rejects a step in
  normal play; an unexpected rejection is logged and leaves the state unchanged (Constitution
  IV.2).
- **Alternatives considered**: letting the engine reject and translating every `RuleError`
  (rejected: the UI already knows the legal targets, and FR-023's message is the only rejection a
  player sees).

## R4. Dragging

- **Decision**: Each piece has a `DragGesture` with a small minimum distance so taps still register
  as taps. Starting a drag on a movable piece selects it (`GameSession.beginDrag`); the piece
  follows the finger with an offset; on release the location in the board's coordinate space is
  converted to a square and passed to `GameSession.drop(on:)`, which applies the step only if the
  square is a target. Otherwise the offset resets without animation. Drags on pieces that cannot
  move do not move the piece.
- **Rationale**: FR-020 and its edge cases (cancelled drag, drop off the board, drop on its own
  square) all reduce to "drop on a square that is or is not a target"; the session decides, so
  drop rules are unit-tested.
- **Alternatives considered**: SwiftUI's transferable drag and drop (`draggable`/`dropDestination`)
  (rejected: built for moving data between views and apps, with system previews and animations
  that FR-018 forbids).

## R5. Drawing the board

- **Decision**: The board is a square sized to the smaller of the available width and height
  (minus the turn indicator), with an 8-point inset, laid out as 8 rows of 8 squares. Pieces are
  drawn with SwiftUI shapes; a king carries a crown symbol (`crown.fill`), so kings differ from men
  by shape, not color (FR-013). The selected piece has a thick ring; hinted pieces have a thin
  ring; target squares show a dot (shape cues, not only color). No animations: every board change
  is applied in a transaction with animation disabled (FR-018).
- **Rationale**: On the narrowest supported iPhone (375 points, iPhone SE) an 8-point inset gives
  44.9-point squares, above the 44-point minimum touch target in Apple's guidelines. Shape cues
  now make E7's non-color work (#166) an audit rather than a redesign.
- **Alternatives considered**: `Grid` or `LazyVGrid` (rejected: they size to content; the board
  must size to the screen); images for pieces (rejected: shapes scale to every size and adapt to
  Dark Mode without assets per size).

## R6. Orientation

- **Decision**: A `BoardLayout` value maps each display cell (row 0 at the top, column 0 at the
  left) to a square. With Light at the bottom, display row r and column c show square
  (column c, row 7 − r); with Dark at the bottom the board is turned 180°: (column 7 − c, row r).
  Two-player games always use Light at the bottom; a computer game uses the player's side
  (FR-015).
- **Rationale**: One pure mapping, unit-tested for both orientations, serves drawing, tapping and
  drop location, so the three can never disagree.
- **Alternatives considered**: rotating the rendered board with a transform (rejected: rotates the
  crowns and text labels, and hit testing would need the inverse transform anyway).

## R7. Remembering setup choices

- **Decision**: `GameSetup` (opponent, difficulty, side choice) is `Codable` and stored as one JSON
  value in `UserDefaults` behind a `SetupStore` protocol, with a live `UserDefaultsSetupStore` and
  an `InMemorySetupStore` for tests and previews (Constitution II.3). Choices are saved whenever the
  player changes them in setup. With no stored value, or one that cannot be decoded (logged), the
  defaults apply: Two players, with Easy and Light preselected for Computer (Clarifications).
  The privacy manifest declares the user-defaults required-reason API with reason `CA92.1` in the
  same change (Constitution VI.3, E1 follow-up for #71), and `PrivacyManifestTests` asserts exactly
  that entry.
- **Rationale**: Computer games cannot start in this slice, so saving only when a game starts would
  never remember a computer choice, which the clarification requires. Saving on change also keeps
  the player's last choice if they back out of setup. E4 keeps this behavior unless its spec says
  otherwise.
- **Alternatives considered**: `@AppStorage` in the setup view (rejected: puts persistence in a view
  and bypasses the injected protocol, Constitution II.2–3); three separate keys (rejected: one
  value is decoded or defaulted as a whole, so a partial write cannot mix old and new choices).

## R8. Random side

- **Decision**: Resolving a side of Random to Light or Dark happens when a game starts and again on
  Play again (FR-034), through a random-number generator injected into the router (the system
  generator in the app, a seeded one in tests).
- **Rationale**: Makes FR-034's "drawn again" testable deterministically. Only computer games use
  it, which start in E4, but the rule belongs to Play again in this slice.

## R9. Text and localization

- **Decision**: Every user-facing string is a `LocalizedStringResource` in the String Catalog. Text
  that varies by side or outcome uses one complete sentence per case ("Light to move · capture
  required", "Dark wins: no moves left"), never assembled from parts (Constitution V.4). Square
  labels for VoiceOver use a format with the coordinate as its only argument ("%@, Light king").
  Because command-line builds do not update the catalog, `scripts/sync-string-catalog.sh` updates
  it in place from the last build's extracted strings, using the same `xcstringstool sync` as
  `scripts/check-string-catalog.sh`; the old picker strings are removed with the web screens.
- **Rationale**: Whole sentences translate correctly; the sync script makes the E1 lesson a
  command instead of a manual step.
- **Alternatives considered**: building text from a side name and a phrase (rejected: Constitution
  V.4 and word order in other languages).

## R10. Dialogs and the result panel

- **Decision**: Resign and leave use system confirmation dialogs with a destructive confirm button
  and Cancel (FR-032, FR-042). The result panel is an overlay on the board with a material
  background, so the final position stays visible (FR-033), holding the result sentence and the
  Play again and Home buttons; its content scrolls if the text size requires it. After the end, the
  game menu offers only Rules, Settings and Home (FR-037: Undo and Resign are not offered).
- **Rationale**: System dialogs bring VoiceOver, Dynamic Type and Dark Mode support for free; an
  overlay keeps the board visible as the FRD asks.
- **Alternatives considered**: a sheet for the result (rejected: covers most of the board).

## R11. Accessibility in this slice

- **Decision**: Every control has a label from the String Catalog; every square is one
  accessibility element labelled with its coordinate and contents ("c3, Light man", "d4, empty")
  and the button trait, and the selected square adds the selected trait (FR-040). The turn
  indicator is a header-trait label. All text uses system text styles and wraps; layouts that
  could overflow at `accessibility5` switch from horizontal to vertical stacks or scroll. Every view
  has `#Preview`s in light, dark and `accessibility5`, using in-memory stores and a session built
  from a fixed position.
- **Rationale**: Meets Constitution V.2 for the screens this slice adds; E7 adds square states
  ("can move", "legal target"), square-by-square play, announcements and the audit test (#168).

## R12. Testing

- **Decision**:
  - **Unit tests** (Swift Testing, `checkers/checkersTests/`): `GameSession` (every rule of R3 and
    R4, hints, turn text, undo, resign, result text, Play again), `BoardLayout` (both
    orientations), `AppRouter` (start, leave with and without confirmation, return from Rules and
    Settings, Play again), `GameSetup` and the stores (defaults, round trip, undecodable value).
    Suites and display names carry the story ID and FRD IDs, as in E2. Positions for chains,
    crowning and endings are built with the engine's internal initializer through
    `@testable import CheckersEngine`; if Xcode does not build the package with testability in the
    app's test configuration, the tests reach the same positions with scripted move sequences.
  - **UI tests** (XCUITest, `checkers/checkersUITests/`): one flow per story where the UI matters:
    launch to Home and a tapped move (US1), the "capture required" indicator after
    `c3–d4, f6–e5` (US2), a drag and an invalid drop (US3), resign with confirm and cancel and the
    result panel with Play again (US4), undo back to the start (US5), setup choices remembered
    across a relaunch (US6), and every navigation path including the leave confirmation (US7).
    Elements are found by accessibility identifiers listed in `contracts/screens.md`.
  - **No test hooks in the app**: UI tests set every setup choice they rely on instead of resetting
    stored state, so the app has no test-only launch arguments.
  - The tests tied to the web UI (`ScreenCatalogTests`, `AppSmokeUITests`, the picker strings in
    `LocalizationTests`) are replaced, and a unit test asserts the bundle contains no HTML files
    (FR-006).
- **Rationale**: Interaction rules are fastest and most thorough at the session level; UI tests
  prove the wiring once per story (Constitution III.2: XCTest only for UI flows).

## R13. Removing the web screens

- **Decision**: Delete `ContentView.swift` (with `WebView` and `Screen`), the four HTML files and
  `move.wav`, after the native board and menu work (#67 last, as the sequencing notes say). The root
  view becomes the navigation root of R2. This removes E1's only Complexity Tracking entry
  (web content, Constitution I.1). `move.wav` is not reused: E6 brings its own sounds.
- **Rationale**: FR-006; the synchronized group drops deleted files from the target without project
  edits.

## R14. Performance

- **Decision**: No background work in this slice: every engine call on a tap is a few microseconds
  of work for one position (E2 measured whole 6-turn searches in seconds). SC-004 is met by drawing
  without animation; cold launch is measured with the existing launch test against the baseline
  (SC-005).
- **Rationale**: Constitution VII.4: no optimization without a measurement showing a need.
