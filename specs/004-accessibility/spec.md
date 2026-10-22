# Feature Specification: Accessibility

**Feature Branch**: `004-accessibility`

**Created**: 2026-10-22

**Status**: Draft

**Input**: User description: "Accessibility (epic E7, GitHub issue #153): the board-specific accessibility from FRD.md v1.1 section 17, on top of the native game screen from E3. Every board square is a VoiceOver element whose label states its coordinate, contents and state ("c3, Light man, can move", "d4, empty, legal target") (FR-A11Y-01); a VoiceOver user plays square by square: double-tap a piece to select it, then double-tap a target, with capture chains one jump at a time (FR-A11Y-02); VoiceOver announces each move, capture and crowning, turn changes, mandatory captures and the game result (FR-A11Y-03); light and dark pieces, kings, selection and hints are distinguishable without relying on color alone (FR-A11Y-05); and every screen meets the constitution's accessibility gates, checked by an automated accessibility audit of every screen (FR-A11Y-04). Board tasks: F7.1 VoiceOver board (#160: #161, #162), F7.2 VoiceOver announcements (#163: #164), F7.3 Non-color cues (#165: #166), F7.4 Accessibility audit automation (#167: #168). Out of scope, delivered by later epics: announcing the computer's moves (#190, E4), keeping the non-color cues in the Modern and Playful themes (#144, E6), and adding the Statistics, Settings and Rules screens to the audit when they are built (#131, #142, #152). Users are players who use VoiceOver, players who cannot tell colors apart, and every player."

## User Scenarios & Testing *(mandatory)*

Three kinds of players meet this feature: blind and low-vision players who play with VoiceOver,
players who cannot tell some colors apart, and every player, whose screens must keep passing the
accessibility checks. E3 already gives every square a label with its coordinate and contents and
every control a label; this feature makes the board fully playable and understandable without
sight or color. Terms follow the FRD glossary: Light and Dark, man, king, capture chain, movable
piece, turn.

### User Story 1 - Hear what is on each square (Priority: P1)

A VoiceOver player moves over the board square by square and hears, for each dark square, its
coordinate, what stands on it and what it can do: "c3, Light man, can move", "d4, empty, legal
target", "e5, Dark king". Coordinates are always named from Light's side, whichever side is at the
bottom. (#161; FR-A11Y-01)

**Why this priority**: Without square states, a VoiceOver player cannot find a piece to move or a
square to move to.

**Independent Test**: Start a game and read the labels of every dark square, then select a piece
and read them again.

**Acceptance Scenarios**:

1. **Given** a new two-player game, **When** VoiceOver reads the squares, **Then** each of Light's
   four movable men reads "<coordinate>, Light man, can move", every other Light man and every
   Dark man reads only its coordinate and contents, and every empty dark square reads
   "<coordinate>, empty".
2. **Given** Light's man on c3 is selected, **When** VoiceOver reads c3, b4 and d4, **Then** they
   read "c3, Light man, selected", "b4, empty, legal target" and "d4, empty, legal target".
3. **Given** a capture is required, **When** VoiceOver reads the side to move's pieces, **Then**
   only the pieces that can capture read "can move".
4. **Given** a king, **When** VoiceOver reads its square, **Then** it says "Light king" or "Dark
   king".
5. **Given** a finished game, **When** VoiceOver reads the squares, **Then** they state only their
   coordinate and contents.
6. **Given** VoiceOver moves through the board, **When** it goes from square to square, **Then** it
   visits the dark squares in the order they appear on screen, row by row from the top, left to
   right, and skips the light squares.

---

### User Story 2 - Play square by square with VoiceOver (Priority: P1)

A VoiceOver player double-taps one of their movable pieces to select it, then double-taps a legal
target to move. In a capture chain, the piece stays selected and the player double-taps each next
landing square in turn. Double-tapping a piece that cannot capture while a capture is required
speaks the "capture required" notice. (#162; FR-A11Y-02)

**Why this priority**: This is how a VoiceOver player makes every move; it completes the board
for them.

**Independent Test**: With VoiceOver, play a few moves including a capture chain, by double-taps
only.

**Acceptance Scenarios**:

1. **Given** a new game with VoiceOver, **When** the player double-taps c3 and then d4, **Then** the
   man moves to d4 and it is Dark's turn, exactly as with taps.
2. **Given** a double jump is available, **When** the player double-taps the jumping man, its first
   landing square and then its second, **Then** both jumps are made one at a time and the turn
   passes.
3. **Given** a capture is required, **When** the player double-taps a piece that cannot capture,
   **Then** VoiceOver speaks "A capture is required." and nothing is selected.
4. **Given** a move was just made by double-tap, **When** it is done, **Then** VoiceOver focus is on
   the square the piece moved to.

---

### User Story 3 - Hear what happens in the game (Priority: P1)

After every step VoiceOver says what happened: "Light c3 to d4", "Light captures d4", "Light
crowned on b8", then whose turn it is now ("Dark to move", "Dark to move, capture required"). In
a capture chain it says the piece must jump again. When the game ends it says the result, and an
undo says the move was taken back. (#164; FR-A11Y-03)

**Why this priority**: A VoiceOver player otherwise cannot follow the game, least of all the other
player's moves on the same device.

**Independent Test**: Play a scripted game with a move, a double jump, a crowning, an undo and a
resignation, and check each announcement.

**Acceptance Scenarios**:

1. **Given** Light moves c3 to d4, **When** the step is applied, **Then** VoiceOver announces "Light
   c3 to d4. Dark to move."
2. **Given** Light jumps from c3 over d4 and the turn ends, **When** the step is applied, **Then**
   VoiceOver announces "Light captures d4" followed by the next turn.
3. **Given** a chain continues after a jump, **When** the jump is applied, **Then** VoiceOver
   announces the capture and that the piece must jump again.
4. **Given** a man reaches the far row, **When** the step is applied, **Then** the announcement
   includes "Light crowned on b8" (or the square it reached).
5. **Given** a turn ends and the next side must capture, **When** the turn passes, **Then** the
   announcement says "Dark to move, capture required".
6. **Given** a step, a resignation or a draw ends the game, **When** it happens, **Then** VoiceOver
   announces the result sentence shown in the result panel.
7. **Given** the player chooses Undo, **When** the turn is taken back, **Then** VoiceOver announces
   that the move was undone and whose turn it is.

---

### User Story 4 - Tell pieces and marks apart without color (Priority: P2)

A player who cannot tell some colors apart can still see which pieces are Light and which are
Dark, which are kings, which piece is selected, which pieces are hinted and which squares are
targets. (#166; FR-A11Y-05)

**Why this priority**: Most cues already differ in shape (E3); this story proves it and closes the
gaps, but the board is already playable.

**Independent Test**: View the board in grayscale (or with a color-blindness filter) in light and
dark appearance and identify every piece, king, selection, hint and target.

**Acceptance Scenarios**:

1. **Given** the board in grayscale, **When** the player looks at it, **Then** Light and Dark
   pieces are clearly different.
2. **Given** a king and a man of the same side, **When** compared, **Then** the king has a mark the
   man does not.
3. **Given** a selected piece, hinted pieces and target squares, **When** shown together, **Then**
   each kind looks different by shape, not only by color.
4. **Given** light and dark appearance, **When** the board is shown, **Then** all of the above
   holds in both.

---

### User Story 5 - Every screen passes the accessibility checks (Priority: P2)

Every screen and its main states are checked automatically for accessibility problems, such as
missing labels, text too small or clipped at large sizes, low contrast and touch targets too
small, so regressions are caught on every change. (#168; FR-A11Y-04)

**Why this priority**: E3 checked screens by hand and with targeted tests; an automated audit keeps
them accessible as later epics change them.

**Independent Test**: Run the audit on every screen and state and check it reports no problems.

**Acceptance Scenarios**:

1. **Given** Home, Game setup (Two players and Computer), the game screen (new game, a selected
   piece, the "capture required" notice, the result panel) and the placeholder screens, **When**
   the audit runs on each, **Then** it reports no problems.
2. **Given** a change that introduces an accessibility problem on one of these screens, **When**
   the tests run, **Then** the audit fails and names the problem.

### Edge Cases

- **Orientation**: with Dark at the bottom (a computer game, E4), coordinates still name squares
  from Light's side, and VoiceOver reads the board in on-screen order.
- **Chain in progress**: only the jumping piece reads "can move" (or "selected"), and only its next
  landing squares read "legal target".
- **Moves in quick succession**: each step's announcement is spoken; a newer announcement may cut
  short an older one that is still being spoken, but none is skipped before it starts.
- **VoiceOver off**: announcements and states cost nothing visible; the board looks and behaves as
  in E3.
- **Rules and Settings opened from the menu**: returning makes no announcement; the board's states
  are unchanged.
- **Large text**: square labels are spoken, not shown, so text size does not affect them.
- **Leave and resign alerts**: system alerts, read by VoiceOver as usual.

## Requirements *(mandatory)*

### Functional Requirements

**VoiceOver board (#160: #161, #162)**

- **FR-001**: Each dark square MUST be one VoiceOver element whose label states its coordinate
  (named from Light's side, a–h and 1–8), its contents ("empty", "Light man", "Light king", "Dark
  man", "Dark king") and its state, in that order (FR-A11Y-01). Light squares MUST NOT be VoiceOver
  elements.
- **FR-002**: The states MUST be "can move" for a movable piece of the side to move, "selected"
  for the selected piece and "legal target" for a target of the selected piece; a finished game
  shows no states. Whether states follow the move hints setting is in Assumptions.
- **FR-003**: VoiceOver MUST visit the dark squares in on-screen order, row by row from the top,
  left to right.
- **FR-004**: Activating a square with VoiceOver MUST have exactly the effect of tapping it: select,
  switch, clear, move, jump, chain lock and the "capture required" notice (FR-A11Y-02).
- **FR-005**: After a step made with VoiceOver, focus MUST be on the square the piece moved to.
- **FR-006**: The "capture required" notice MUST be announced when it appears.

**Announcements (#163: #164)**

- **FR-007**: Every applied step MUST be announced: a simple move as "<Side> <from> to <to>", a
  capture as "<Side> captures <square>", and a crowning as "<Side> crowned on <square>" (FR-A11Y-03).
- **FR-008**: When a step ends the turn, the announcement MUST also state the turn that follows
  ("Dark to move", "Dark to move, capture required"); when a chain continues it MUST say the piece
  must jump again.
- **FR-009**: When the game ends, by a step, a resignation or a draw, the result sentence of the
  result panel MUST be announced.
- **FR-010**: An undo MUST be announced, with the turn it returns to.
- **FR-011**: Announcements MUST cover the moves of both sides made on this device; the computer's
  moves (E4, #190) use the same sentences.
- **FR-012**: Every announcement MUST be a whole sentence from the String Catalog, built from the
  step's facts, never assembled from fragments (Constitution V.4).

**Non-color cues (#165: #166)**

- **FR-013**: Kings MUST differ from men by a shape mark (the crown).
- **FR-014**: The selected piece, hinted pieces and target squares MUST each have a distinct shape
  cue, so they can be told apart without color.
- **FR-015**: Light and Dark pieces MUST be distinguishable without relying on hue (how, in
  Assumptions).
- **FR-016**: FR-013 to FR-015 MUST hold in light and dark appearance in the Classic theme; E6 keeps
  them in its themes (#144).

**Accessibility audit (#167: #168)**

- **FR-017**: An automated accessibility audit MUST run on Home, Game setup (Two players and
  Computer), the game screen (a new game, a selected piece, the "capture required" notice and the
  result panel) and the placeholder screens, and MUST fail the test run on any problem it finds
  (FR-A11Y-04).
- **FR-018**: Every problem the audit finds MUST be fixed; an exception is allowed only for a system
  component the app cannot change, recorded with its reason.
- **FR-019**: Every screen MUST keep supporting Dynamic Type up to the largest accessibility size and
  Dark Mode, as in E3 (FR-A11Y-04).

### Traceability

| Board task | Requirements | FRD |
|---|---|---|
| #161 Square elements with states | FR-001, FR-002, FR-003 | FR-A11Y-01 |
| #162 Double-tap play, including chains | FR-004, FR-005, FR-006 | FR-A11Y-02 |
| #164 Announcements | FR-007 to FR-012 | FR-A11Y-03 |
| #166 Non-color cues | FR-013 to FR-016 | FR-A11Y-05 |
| #168 Accessibility audit | FR-017, FR-018, FR-019 | FR-A11Y-04 |

Covered elsewhere: the computer's moves announced (#190, E4); the cues in the Modern and Playful
themes (#144, E6); Statistics, Settings and Rules added to the audit (#131, #142, #152).

### Key Entities

- **Square description**: what VoiceOver says for a square: coordinate, contents and state.
- **Announcement**: what VoiceOver says after a step, an undo, a notice or the end of a game.
- **Visual cue**: the shape that marks a king, a selection, a hint or a target, or tells the two
  sides apart.
- **Audited screen**: a screen in a given state that the automated audit checks.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A VoiceOver user can play a two-player game from Home to the result panel using only
  VoiceOver gestures (checked once by hand with VoiceOver, and by automated tests of every
  activation).
- **SC-002**: In scripted games covering moves, captures, a chain, a crowning, an undo and each
  ending, every square's description matches the board after every step (100% of squares and
  steps).
- **SC-003**: In the same games every step, undo and ending produces exactly one announcement,
  whose text matches what happened (100%).
- **SC-004**: The accessibility audit reports zero problems on every screen and state listed in
  FR-017.
- **SC-005**: Viewed in grayscale, Light and Dark pieces have a lightness contrast of at least 3:1
  against each other, and kings, selection, hints and targets are each identifiable by shape.
- **SC-006**: FR-A11Y-01 to FR-A11Y-05 each have at least one automated test that names its user
  story.

## Assumptions

- **States and the hints setting** (to confirm in Clarify): VoiceOver states ("can move", "legal
  target") are always given, even after E6 adds a switch to hide the visual hints, because a
  VoiceOver player cannot look the board over.
- **Light and Dark without color** (to confirm in Clarify): the sides differ by lightness (pale
  versus dark pieces, at least 3:1 contrast), which survives color blindness and grayscale; no
  extra mark is added.
- **One announcement per step** (to confirm in Clarify): a step's announcement includes the turn
  that follows, so a player hears one sentence per step rather than several in a row.
- **Focus after a move**: focus stays on the square that was activated, where the piece now stands,
  so the next jump of a chain is one swipe away.
- **Undo announcement**: "Move undone. Light to move." (or Dark); the FRD does not word it.
- **Scope**: the computer's moves (E4), the other themes (E6) and the screens of E5 and E6 add
  themselves to this feature's announcements, cues and audit when they are built.
- **No rule changes**: everything announced comes from the engine's step results
  (`specs/002-rules-engine/contracts/engine-api.md`) and the game screen of E3.
