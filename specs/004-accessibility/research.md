# Research: Accessibility

Phase 0 output for `specs/004-accessibility/plan.md`. Each entry records the decision, why, and
what else was considered. Facts marked *measured* were checked on the development Mac on
2026-10-22.

## Environment facts

| Item | Value |
|---|---|
| Game screen | E3: `GameSession` (interaction rules), `BoardView` (dark squares are button-trait accessibility elements with identifier `square.<name>`, label from `GameText.squareLabel`, selected trait, `accessibilityAction` calling `session.tap`), `PieceView` (crown, thick selection ring, thin hint ring), target dots (*measured*) |
| Square labels today | Coordinate and contents only ("c3, Light man", "d4, empty") (*measured*) |
| Announcements today | None |
| Engine | Every applied step returns a `StepResult` (side, piece, from, to, captured, crowned, turn continues, outcome) (`specs/002-rules-engine/contracts/engine-api.md`) |
| UI tests | One class per story in `checkers/checkersUITests/`; helpers in `Support/AppScreens.swift`; largest-text checks via `simctl ui` or the `-UIPreferredContentSizeCategoryName` launch argument (E3) |
| Classic colors, contrast against the dark square `#7a4a24` | Light piece 7.1:1, dark piece 2.3:1, dark-piece outline 1.1:1, selection ring and target dot 1.5:1 (2.6:1 in dark appearance), hint ring 4.4:1; gold crown on a Light king 1.6:1; Light versus Dark pieces 16.1:1 (*measured*, WCAG relative luminance) |

## R1. Square descriptions

- **Decision**: A square's VoiceOver label is one whole sentence chosen by its contents and state,
  with the coordinate as its only argument: "%@, empty", "%@, empty, legal target", and for each of
  the four pieces "%@, Light man", "%@, Light man, can move", "%@, Light man, selected" (and the
  same for Light king, Dark man, Dark king): 14 sentences. `GameSession` decides the state from the
  engine (`movablePieces`, `selection`, `targets`), whatever the hints setting (Clarifications);
  once the game is over no state applies.
- **Rationale**: Whole sentences translate as units (Constitution V.4); one decision point in the
  session keeps labels, visual hints and tap rules consistent and testable without UI.
- **Alternatives considered**: a label plus an accessibility value for the state (rejected: the
  FRD's examples read as one phrase, and VoiceOver reads label and value with a pause and in an
  order the user can change); traits for the state (rejected: only "selected" has a system trait).

## R2. Square-by-square play and focus

- **Decision**: Keep E3's activation: each dark square has the button trait and a default
  accessibility action that calls `session.tap(square)`, so a VoiceOver double-tap follows exactly
  the tap rules (FR-004). After a step, `GameSession` publishes the landing square as
  `focusSquare`; `BoardView` binds it to an `@AccessibilityFocusState`, so VoiceOver focus moves to
  where the piece now stands (FR-005) and the next jump of a chain is one swipe away.
- **Rationale**: One input path for touch and VoiceOver, so FR-A11Y-02 inherits every tested rule
  of E3. A default action replaces VoiceOver's simulated tap, so a double-tap triggers the rule
  once.
- **Alternatives considered**: custom accessibility actions such as "Move to d4" on each piece
  (rejected: the FRD asks for square-by-square play, and actions would duplicate the targets);
  leaving focus where VoiceOver puts it (rejected: after a jump the focus would stay on the empty
  square the piece left).

## R3. Announcements

- **Decision**: `GameSession` announces through an injected `Announcer` protocol (Constitution
  II.3): the live `AccessibilityAnnouncer` posts `AccessibilityNotification.Announcement`, and a
  `RecordingAnnouncer` in tests keeps the list of announcements. The session announces after every
  applied step (from its `StepResult` and the state after it), after an undo, after a resignation,
  and when the "capture required" notice appears (FR-006 to FR-010). Nothing is announced while
  nothing changes (for example selecting a piece, whose new state VoiceOver reads on the square).
- **Rationale**: The session already applies every step and knows the result; a protocol makes the
  exact text and count of announcements unit-testable (SC-003) without VoiceOver running.
- **Alternatives considered**: posting from the views on state changes (rejected: views would need
  to diff states to know what happened, and tests would need the UI); announcing selections
  (rejected: the square's own label already says "selected").

## R4. Announcement sentences

- **Decision**: One announcement per step (Clarifications) made of two whole sentences from the
  String Catalog joined by a localizable template "%1$@ %2$@", so translators can reorder or
  re-punctuate:
  - **What happened** (per side, coordinates as arguments): "Light %1$@ to %2$@.", "Light captures
    %@.", "Light %1$@ to %2$@, crowned.", "Light captures %1$@, crowned on %2$@." and the four Dark
    versions.
  - **What follows**: "Dark to move.", "Dark to move, capture required.", the Light versions, "Jump
    again." during a chain, or the result sentence of the result panel when the game ends.
  - **Other events**: an undo says "Move undone." followed by the turn ("Move undone. Light to
    move." through the same template); a resignation says the result; the notice says "A capture
    is required."
- **Rationale**: Side-specific sentences avoid inserting "Light"/"Dark" into a sentence, which many
  languages inflect; joining two complete sentences with a template is not string concatenation
  in code, and the template itself is localizable.
- **Alternatives considered**: one catalog entry for every combination of step and follow-up
  (rejected: about 80 near-duplicate entries); separate announcements (rejected in Clarifications).

## R5. Non-color cues and contrast

- **Decision**:
  - **Sides**: Light and Dark pieces keep their pale and dark fills, 16.1:1 apart (*measured*;
    FR-015 asks 3:1). No extra mark (Clarifications).
  - **Visibility** (spec FR-020, added here): every mark gets at least 3:1 against what it is drawn
    on (WCAG 1.4.11, non-text contrast). Changes to the Classic palette, *measured*:
    - dark-piece outline `PieceDarkEdge` `#6b4426` → `#d9b48a` (3.8:1 against the square);
    - selection ring and target dot `Selection`, `Target` `#1f6fd1`/`#4c9bff` → `#7fd3ff` in both
      appearances (4.5:1 against the square);
    - the crown splits into `CrownOnLight` `#6b4426` (8.1:1 on a Light king) and `CrownOnDark`
      `#e8c46a` (10.0:1 on a Dark king), replacing `Crown`;
    - the hint ring stays `#e8c46a` (4.4:1).
  - **Shapes**: crown for kings, thick ring for the selection, thin ring for hints, a dot for
    targets (E3). Hint and selection rings are equally light (1.0:1 apart) and are told apart by
    thickness, which is the shape cue FR-014 asks for.
  - **Test**: a unit test computes WCAG contrast from the asset colors in light and dark appearance
    and checks every pair above, so a future palette change (E6 themes, #144) cannot drop below
    3:1 unnoticed.
- **Rationale**: E3's shapes already distinguish every mark; measurement showed several marks were
  hard to see at all on the dark squares, which a color-independent design must also fix.
- **Alternatives considered**: a mark on Dark pieces (rejected in Clarifications); a
  Differentiate-Without-Color-only variant (rejected in Clarifications); raising the dark square's
  lightness instead (rejected: it would lower the 5.6:1 contrast between the two square colors and
  change the Classic look).

## R6. Accessibility audit

- **Decision**: A UI test class runs `XCUIApplication.performAccessibilityAudit()` (all audit types)
  on each screen and state of FR-017, reached by the existing helpers: Home, setup with Two players
  and with Computer, the game screen as a new game, with a selected piece, with the "capture
  required" notice (after `c3–d4, f6–e5`, tap e3) and with the result panel, and the three
  placeholder screens. Problems are fixed in the app. An exception goes through the audit's issue
  handler only for a system element the app cannot change, matched by element and issue type, and
  is listed with its reason in the plan's allow-list table.
- **Rationale**: The audit checks labels, contrast of text, hit regions, Dynamic Type support,
  clipped text and traits on real screens, which is what Constitution V's verification names.
- **Alternatives considered**: auditing only Home and the game screen (rejected: FR-017 lists
  every screen); one test per audit type (rejected: one audit per state reports every problem at
  once).
- **Findings (implementation)**: The first run reported 20 problems on 9 of the 10 states, all
  contrast but two. Fixes in the app: an `AccentColor` dark enough for white text in light
  appearance and light enough for dark backgrounds in dark appearance, with an `OnAccent` label
  color for prominent buttons; primary instead of secondary text for the notice, the placeholder
  messages, the setup headers and the computer note; an opaque result panel (the material let
  the board behind lower its text's contrast; the board stays visible around the panel); and the
  computer note moved under the opponent choice it explains. Two issues remain on system
  components and are allow-listed in the plan: the disabled Start button, and the Dynamic Type
  report on whichever setup line the scrolling form cuts at the screen's edge when the audit
  enlarges the text. Evidence for the second: the report moved from the note to the "Side" header
  when the note moved, disappeared when a row was added above, and both scale at the largest
  size on screen. On CI a system notification banner on the fresh simulator was read as
  inaccessible text with no element; a screen with problems is therefore audited again after
  8 s, and only problems found both times fail.

## R7. Tests

- **Decision**:
  - **Unit** (Swift Testing, `checkers/checkersTests/`): square descriptions for every content and
    state (US1); scripted games through `GameSession` with a `RecordingAnnouncer` checking, after
    every step, every square's description against the board and the exact announcement list
    (SC-002, SC-003); focus square after each step (US2); contrast pairs (US4).
  - **UI** (XCUITest): square labels read through the accessibility tree after taps (US1, US2),
    and the audit (US5). XCUITest cannot drive VoiceOver, so double-tap activation is covered by
    the shared tap path, its unit tests, and one VoiceOver run by hand recorded in
    `checklists/validation.md` (SC-001).
  - Suites and test names carry story and FRD IDs as before.

## R8. Order of reading

- **Decision**: Keep SwiftUI's default order, which follows the on-screen layout: the board's rows
  from the top, left to right (FR-003). The board container keeps `children: .contain` so its
  squares stay individual elements; light squares stay hidden.
- **Rationale**: Matches the board as drawn in either orientation without a custom sort.
