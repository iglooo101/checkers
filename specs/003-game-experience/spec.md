# Feature Specification: Game Experience

**Feature Branch**: `003-game-experience`

**Created**: 2026-10-21

**Status**: Draft

**Input**: User description: "Game experience (epic E3, GitHub issue #57): the native SwiftUI app shell, game setup, game screen with board and two-player play on top of the CheckersEngine rules engine from E2, from FRD.md v1.1 sections 4 (screens and navigation), 5 (starting a game), 6 (the game screen), 7 (making moves: tap and drag input, move aids, capture chains), 9 (ending a game: resignation, result panel, play again) and 10 (undo in a two-player game), plus FR-SND-04 (no move animation) and the accessibility pass for each new screen (Dynamic Type, Dark Mode, VoiceOver labels, previews). It replaces the bundled HTML screens and the WKWebView. Board tasks: F3.1 app shell and navigation (#64: #65, #66, #67, #68), F3.2 game setup (#69: #70, #71, #73), F3.3 board view (#74: #75–#78), F3.4 move input (#79: #80–#83), F3.5 move aids and chain interaction (#84: #85–#87), F3.6 game end and result (#88: #89–#92), F3.7 undo in the game (#93: #94). Out of scope, delivered by later epics: the computer opponent's moves and undo against the computer (E4), saving and Continue and "Abandon current game?" and statistics (E5), the Settings, Rules and theme screens, sounds and the hints toggle (E6), the full VoiceOver board and announcements (E7). Users are the players."

## User Scenarios & Testing *(mandatory)*

The players meet this feature as the app itself: a Home screen, a setup screen and a game screen
where two people take turns on one iPhone. The rules come from the engine built in E2; this
feature lets players see the board and make every legal move by touch. Terms follow the FRD
glossary: Light and Dark, man, king, capture chain, movable piece, turn.

### User Story 1 - Start a two-player game and move by tapping (Priority: P1)

A player opens the app on Home, chooses New game, picks Two players and starts. The game screen
shows the board in the starting position with Light at the bottom and a turn indicator reading
"Light to move". The player taps one of Light's movable men and then an empty square it can move
to; the man appears there at once and the indicator reads "Dark to move". Play continues, turn by
turn. (#65, #70, #75, #76, #77, #80, #81; FR-NAV-01, FR-SETUP-01, FR-SETUP-06, FR-GAME-01,
FR-GAME-02, FR-GAME-04, FR-GAME-05, FR-MOVE-01, FR-MOVE-03, FR-MOVE-04, FR-SND-04)

**Why this priority**: This is the smallest version of the app that two people can play, and it
replaces the web-view prototype.

**Independent Test**: Launch the app, start a two-player game, check the board and indicator, and
make several moves by tapping, checking each piece lands where it was tapped and the turn passes.

**Acceptance Scenarios**:

1. **Given** the app is launched, **When** it opens, **Then** Home is shown with New game,
   Statistics, Rules and Settings.
2. **Given** Home, **When** the player chooses New game, picks Two players and starts, **Then** the
   game screen shows the 8×8 board with 12 Light men on the three rows nearest the bottom, 12 Dark
   men on the three rows nearest the top, and the indicator "Light to move".
3. **Given** Light to move, **When** the player taps a movable Light man and then one of its
   target squares, **Then** the man appears on that square with no animation, its old square is
   empty, and the indicator reads "Dark to move".
4. **Given** a selected piece, **When** the player taps another movable piece of the same side,
   **Then** that piece becomes selected instead; **When** the player taps the selected piece again
   or a square that is not a target, **Then** nothing is selected and nothing moves.
5. **Given** Light to move, **When** the player taps a Dark piece, **Then** it is not selected.
6. **Given** a two-player game, **When** turns pass back and forth, **Then** Light stays at the
   bottom; the board never rotates.

---

### User Story 2 - Captures, chains and crowning on the board (Priority: P1)

When a capture is available, the indicator says so ("Light to move · capture required") and only
pieces that can capture can be selected; tapping another piece of the side to move tells the
player a capture is required. A capture is made one jump at a time: after each jump the jumped
piece disappears, and if the same piece can jump again it stays selected and only its next jumps
can be chosen. A man reaching the far row becomes a king, which looks different from a man, and
the turn ends. (#77, #83, #87; FR-GAME-02, FR-MOVE-05, FR-CHAIN-01, FR-CHAIN-02, FR-CHAIN-03,
FR-RULE-07, FR-SND-04)

**Why this priority**: Without captures and chains the game cannot be played to the end; the
board must show the engine's rules faithfully.

**Independent Test**: Reach (or set up) a position with a double jump and a crowning, play them by
tapping, and check the indicator, the message, the chain lock and the king.

**Acceptance Scenarios**:

1. **Given** Light has a capture available, **When** the board is shown, **Then** the indicator
   reads "Light to move · capture required".
2. **Given** a capture is required, **When** the player taps a Light piece that cannot capture,
   **Then** it is not selected and the app shows that a capture is required.
3. **Given** a Light man that can jump twice, **When** the player makes the first jump, **Then** the
   jumped piece disappears, the man stands on its landing square still selected, the only targets
   are its next jumps, and no other piece can be selected.
4. **Given** a chain in progress, **When** the jumping piece makes its last possible jump, **Then**
   the turn passes to Dark.
5. **Given** a man that reaches the far row, **When** its step ends there (by a move or a jump),
   **Then** it is shown as a king and the turn passes, even if a king could jump again.

---

### User Story 3 - Move hints, selection and dragging (Priority: P2)

With move hints on (the default; the toggle arrives with Settings in E6), the board highlights
every movable piece of the side to move (only capturing pieces when a capture is required), and
once a piece is selected, its legal targets. The selected piece is always marked. Instead of
tapping, a player can drag a piece onto a target; dropping it anywhere else returns it to its
square with no move made. (#82, #85, #86; FR-AID-01, FR-AID-02, FR-AID-03, FR-AID-04, FR-MOVE-02)

**Why this priority**: Hints and dragging make the game easier to play but are not needed to play
it.

**Independent Test**: Start a game and check the highlighted pieces, select one and check the
highlighted targets, then drag a piece to a target and to an illegal square.

**Acceptance Scenarios**:

1. **Given** a new two-player game, **When** the board is shown, **Then** exactly Light's 4 movable
   men are highlighted.
2. **Given** a capture is required, **When** the board is shown, **Then** only the pieces that can
   capture are highlighted.
3. **Given** a selected piece, **When** the board is shown, **Then** the piece is marked as selected
   and exactly its legal targets are highlighted.
4. **Given** Light to move, **When** the player drags a movable man onto one of its targets,
   **Then** the move is made as if tapped.
5. **Given** Light to move, **When** the player drags a piece and drops it on a square that is not
   one of its targets (or off the board), **Then** the piece is back on its square and nothing
   changed.

---

### User Story 4 - Finish a game: resign, result and play again (Priority: P2)

A game ends when a side has no legal move, when the side to move resigns from the game menu after
confirming, or by one of the automatic draws. A result panel then appears over the final position,
which stays visible, stating the outcome and the reason, and offering Play again and Home. Play
again starts a new game with the same choices. (#89, #90, #91, #92; FR-END-01 to FR-END-03,
FR-END-04, FR-END-06, FR-END-07)

**Why this priority**: Players need a clear end to every game, but turns (stories 1–3) come first.

**Independent Test**: Play or set up a game to each kind of ending, check the panel's text and
buttons, and check Play again and Home.

**Acceptance Scenarios**:

1. **Given** a two-player game, **When** the player chooses Resign from the menu, **Then** the app
   asks for confirmation; **When** confirmed, **Then** the side to move has resigned and the panel
   reads, for example, "Light resigned" with Dark the winner; **When** cancelled, **Then** the game
   continues unchanged.
2. **Given** a move that leaves the opponent with no legal move, **When** it is made, **Then** the
   panel names the winner and the reason ("Light wins: no moves left").
3. **Given** a draw by repetition or by no progress, **When** it happens, **Then** the panel states
   the draw and its reason ("Draw by repetition", "Draw by no progress").
4. **Given** the result panel, **When** it is shown, **Then** the final position is still visible
   behind it and the board accepts no moves.
5. **Given** the result panel, **When** the player chooses Play again, **Then** a new game starts
   from the standard position with the same opponent and choices; **When** the player chooses
   Home, **Then** Home is shown.

---

### User Story 5 - Undo in a two-player game (Priority: P2)

The game menu's Undo takes back the last turn, whichever side made it, and can be used repeatedly
back to the start of the game. During an unfinished capture chain it takes back the whole partial
turn. It is unavailable at the start of a game and once the game has ended. (#94; FR-UNDO-01,
FR-UNDO-02, FR-UNDO-05, FR-UNDO-06)

**Why this priority**: Undo is expected in a casual game, but the game is playable without it.

**Independent Test**: Make several moves, undo them one by one back to the start, undo in the
middle of a chain, and check Undo is unavailable at the start and after the end.

**Acceptance Scenarios**:

1. **Given** a game after several turns, **When** the player chooses Undo, **Then** the board and
   indicator show the position and side to move from before the last turn.
2. **Given** a capture chain in progress, **When** the player chooses Undo, **Then** the position
   from before the chain is shown, with the same side to move and nothing selected.
3. **Given** a new game, **When** the menu is opened, **Then** Undo is shown but unavailable.
4. **Given** a finished game, **When** the result panel is shown, **Then** Undo is not available.

---

### User Story 6 - Game setup choices (Priority: P3)

Game setup offers the opponent (Computer or Two players) and, for Computer, a difficulty (Easy,
Medium, Hard) and a side (Light, Dark, Random). It preselects the choices of the previous game,
remembered across launches. Against the computer the player's own pieces are at the bottom of the
board, even when the player is Dark, and only the player resigns. The computer's moves arrive with
E4, so until then a game against the computer cannot be started (see Assumptions). (#70, #71, #73,
#76, #89, #91; FR-SETUP-01, FR-SETUP-02, FR-SETUP-03, FR-GAME-03, FR-END-02, FR-END-07)

**Why this priority**: Only the two-player path is playable in this feature; the computer choices
are built now so E4 only has to add the opponent's moves.

**Independent Test**: Open setup, change every choice, start a two-player game, relaunch the app
and check setup shows the same choices; check the board orientation and resignation rules for a
computer game without playing one.

**Acceptance Scenarios**:

1. **Given** Game setup, **When** Computer is chosen, **Then** difficulty and side can be chosen;
   **When** Two players is chosen, **Then** they are not offered.
2. **Given** a previous game started with some choices, **When** setup is opened again, including
   after relaunching the app, **Then** those choices are preselected.
3. **Given** setup has never been used, **When** it opens, **Then** the defaults are preselected
   (see Assumptions for the defaults until E4).
4. **Given** a game against the computer where the player is Dark, **When** the board is shown,
   **Then** Dark's pieces are at the bottom.
5. **Given** a game against the computer with side Random, **When** Play again is chosen, **Then**
   the new game's side is drawn at random again.

---

### User Story 7 - Navigate the app (Priority: P3)

From the game screen's menu the player can open Rules and Settings and come back to the same game,
or go Home. Home's Statistics, Rules and Settings entries lead to their screens, which later
epics fill in. The old bundled web screens are gone. (#65, #66, #67, #68; FR-NAV-01 to FR-NAV-04,
FR-GAME-06)

**Why this priority**: Navigation frames the game but adds no play; the destination screens
themselves belong to E5 and E6.

**Independent Test**: Open each Home entry and each menu entry, return, and check the game is
unchanged; check no web content remains in the app.

**Acceptance Scenarios**:

1. **Given** the game screen, **When** the menu is opened, **Then** it offers Undo, Resign, Rules,
   Settings and Home.
2. **Given** a game in progress, **When** the player opens Rules or Settings from the menu and
   returns, **Then** the same position and side to move are shown, and a chain in progress is
   still locked to its piece.
3. **Given** the game screen, **When** the player chooses Home, **Then** Home is shown.
4. **Given** Home, **When** the player opens Statistics, Rules or Settings, **Then** a screen with
   that title is shown and the player can return to Home.

### Edge Cases

- **Tapping during a chain**: taps on squares that are not targets, and on other pieces, do
  nothing; the jumping piece stays selected (FR-CHAIN-02 overrides FR-MOVE-03).
- **Capture required, wrong piece**: tapping a piece of the side to move that cannot capture shows
  the message and keeps any current selection; tapping a piece of the other side, or a piece with
  no legal move when no capture is required, behaves as tapping an empty square.
- **Drag of a non-movable piece**: the piece does not move with the finger; nothing changes.
- **Drag cancelled** (finger leaves the board or the system interrupts): the piece returns to its
  square and nothing changes.
- **Drag onto the selected piece's own square**: treated as a drop on a non-target.
- **Both tap and drag**: starting a drag on a piece selects it; releasing on a target moves it.
- **Last legal move ends the game**: the moved piece is shown on its square before the result
  panel appears over the board.
- **Resign confirmation during a chain**: allowed; the position stays as it is when confirmed.
- **Opening the menu during a chain**: Undo is available and takes back the partial turn.
- **Small screens and large text**: the board stays square and fully visible; the indicator and
  menu wrap or scale rather than truncate.
- **Interrupted app** (phone call, app switch): the game in progress is unchanged when the player
  returns while the app is still running.

## Requirements *(mandatory)*

### Functional Requirements

**App shell and navigation (#64: #65, #66, #67, #68)**

- **FR-001**: The app MUST open on Home (FR-NAV-01).
- **FR-002**: Home MUST offer New game, Statistics, Rules and Settings (FR-NAV-02). Continue is not
  part of this feature (E5).
- **FR-003**: Statistics, Rules and Settings MUST each open a screen with that title from which the
  player can return; their content is delivered by E5 and E6 (see Assumptions).
- **FR-004**: The game screen MUST offer a menu with Undo, Resign, Rules, Settings and Home
  (FR-GAME-06), and MUST let the player return Home at any time (FR-NAV-03).
- **FR-005**: Returning from Rules or Settings opened from the game menu MUST show the same game:
  position, side to move and any chain in progress (FR-NAV-04).
- **FR-006**: The app MUST contain no web content: the bundled HTML screens, their sound file
  reference and the web view are removed, and every screen is native (Constitution I.1).

**Game setup (#69: #70, #71, #73)**

- **FR-007**: New game MUST open Game setup, offering the opponent Computer or Two players
  (FR-SETUP-01).
- **FR-008**: With Computer chosen, setup MUST offer a difficulty (Easy, Medium, Hard) and a side
  (Light, Dark, Random); with Two players it MUST NOT (FR-SETUP-02).
- **FR-009**: Setup MUST preselect the opponent, difficulty and side of the previous game, and
  these choices MUST survive relaunching the app (FR-SETUP-03). First-use defaults are in
  Assumptions.
- **FR-010**: Every game MUST start from the standard American checkers position with Light to
  move (FR-SETUP-06).
- **FR-011**: Starting a game against the computer MUST NOT be possible until the computer
  opponent exists (E4); setup MUST say so instead of starting a game without an opponent.

**Board view (#74: #75, #76, #77, #78)**

- **FR-012**: The game screen MUST show the board and a turn indicator and no other game
  information such as piece counts, a move list or timers (FR-GAME-01).
- **FR-013**: The board MUST show 8×8 squares with every man and king of both sides; kings MUST be
  distinguishable from men by shape or mark, not only by color, and the board MUST fit fully on
  the screen of every supported iPhone in portrait (FR-PLAT-01).
- **FR-014**: The turn indicator MUST state whose turn it is ("Light to move", "Dark to move") and,
  when a capture is mandatory, say so ("Light to move · capture required") (FR-GAME-02).
- **FR-015**: In a two-player game Light MUST be at the bottom and the board MUST NOT rotate between
  turns (FR-GAME-04). In a game against the computer the player's pieces MUST be at the bottom,
  even when the player is Dark (FR-GAME-03).
- **FR-016**: The sides MUST be called Light and Dark; there is no name entry (FR-GAME-05).
- **FR-017**: The board MUST be drawn in the Classic theme (FR-GAME-07); choosing a theme arrives
  with Settings in E6.
- **FR-018**: Pieces MUST NOT animate: a moved piece appears directly on its target square, and a
  captured piece disappears when it is jumped (FR-SND-04).

**Move input (#79: #80, #81, #82, #83)**

- **FR-019**: A player MUST be able to move by tapping a piece and then tapping a target square
  (FR-MOVE-01).
- **FR-020**: A player MUST be able to move by dragging a piece onto a target square; dropping it
  anywhere other than a legal target MUST return it to its square with no move made (FR-MOVE-02).
- **FR-021**: Tapping a movable piece of the side to move MUST select it; tapping another movable
  piece MUST switch the selection; tapping the selected piece again, or any square that is not a
  legal target, MUST clear the selection (FR-MOVE-03).
- **FR-022**: Only pieces of the side to move MUST be selectable (FR-MOVE-04).
- **FR-023**: When a capture is mandatory and the player taps a piece of the side to move that
  cannot capture, the app MUST tell the player a capture is required and MUST NOT select it
  (FR-MOVE-05). The message stays until the player's next tap or move.
- **FR-024**: The rules of selection and moving MUST be checkable by automated tests without the
  user interface (Constitution II.2).

**Move aids and chain interaction (#84: #85, #86, #87)**

- **FR-025**: With move hints on, the board MUST highlight every movable piece of the side to move,
  and only the pieces that can capture when a capture is mandatory (FR-AID-01).
- **FR-026**: With move hints on and a piece selected, the board MUST highlight its legal target
  squares (FR-AID-02).
- **FR-027**: The selected piece MUST always be visibly marked, whether hints are on or off
  (FR-AID-03).
- **FR-028**: Move hints MUST be on; the setting that turns them off arrives with Settings in E6
  (FR-AID-04).
- **FR-029**: A capture chain MUST be entered one jump at a time; after each jump the piece stays on
  its landing square and the captured piece disappears (FR-CHAIN-01).
- **FR-030**: While a chain continues, the jumping piece MUST stay selected, only its next jumps
  MUST be targets, and no other piece MUST be selectable (FR-CHAIN-02).
- **FR-031**: The turn MUST end when the jumping piece has no further jump or a man is crowned
  (FR-CHAIN-03).

**Game end and result (#88: #89, #90, #91, #92)**

- **FR-032**: Resign MUST ask for confirmation. In a two-player game the side to move resigns; in a
  game against the computer the player resigns (FR-END-02).
- **FR-033**: When a game ends, a result panel MUST appear over the final position, which stays
  visible, stating the outcome and the reason (for example "Dark wins: no moves left", "Light
  resigned", "Draw by repetition", "Draw by no progress") and offering Play again and Home
  (FR-END-06).
- **FR-034**: Play again MUST start a new game with the same opponent, difficulty and side; a side
  of Random MUST be drawn again (FR-END-07).
- **FR-035**: Once a game has ended, the board MUST NOT accept moves.

**Undo in the game (#93: #94)**

- **FR-036**: Undo MUST take back the last turn, whichever side made it, and be repeatable back to
  the start of the game; during an unfinished chain it MUST take back the partial turn
  (FR-UNDO-01, FR-UNDO-02, FR-UNDO-05).
- **FR-037**: Undo MUST be shown as unavailable at the start of a game and MUST NOT be offered once
  the game has ended (FR-UNDO-06).
- **FR-038**: After an undo, nothing is selected and the indicator shows the restored side to move.

**Accessibility and localization (all screens: #68, #73, #78, #92)**

- **FR-039**: Every screen in this feature MUST support Dynamic Type up to the largest
  accessibility size without truncating or overlapping essential content, MUST render correctly in
  Dark Mode, and every control MUST have a meaningful VoiceOver label (FR-A11Y-04,
  Constitution V.2).
- **FR-040**: Each board square MUST expose its coordinate and contents to VoiceOver (for example
  "c3, Light man"). Selecting and moving square by square with VoiceOver, square states such as
  "can move", and move announcements are delivered by E7.
- **FR-041**: All user-facing text MUST be localizable, and the first release is in English
  (FR-PLAT-03).

### Traceability

| Board task | Requirements | FRD |
|---|---|---|
| #65 Home screen | FR-001, FR-002, FR-003 | FR-NAV-01, FR-NAV-02 |
| #66 Game screen menu | FR-004, FR-005 | FR-GAME-06, FR-NAV-03, FR-NAV-04 |
| #67 Remove the HTML screens | FR-006 | Constitution I.1 |
| #68 Accessibility: Home and navigation | FR-039, FR-041 | FR-A11Y-04, FR-PLAT-03 |
| #70 Setup screen | FR-007, FR-008, FR-010, FR-011 | FR-SETUP-01, FR-SETUP-02, FR-SETUP-06 |
| #71 Remembered choices | FR-009 | FR-SETUP-03 |
| #73 Accessibility: setup | FR-039 | FR-A11Y-04 |
| #75 Board | FR-012, FR-013, FR-016, FR-017, FR-018 | FR-GAME-01, FR-GAME-05, FR-GAME-07, FR-SND-04, FR-PLAT-01 |
| #76 Orientation | FR-015 | FR-GAME-03, FR-GAME-04 |
| #77 Turn indicator | FR-014 | FR-GAME-02 |
| #78 Accessibility: game screen | FR-039, FR-040 | FR-A11Y-04 |
| #80 Selection model | FR-021, FR-022, FR-024 | FR-MOVE-03, FR-MOVE-04 |
| #81 Tap to move | FR-019 | FR-MOVE-01 |
| #82 Drag to move | FR-020 | FR-MOVE-02 |
| #83 Capture required message | FR-023 | FR-MOVE-05 |
| #85 Hints | FR-025, FR-026, FR-028 | FR-AID-01, FR-AID-02, FR-AID-04 |
| #86 Selected piece marked | FR-027 | FR-AID-03 |
| #87 Chain lock | FR-029, FR-030, FR-031 | FR-CHAIN-01, FR-CHAIN-02, FR-CHAIN-03 |
| #89 Resign | FR-032 | FR-END-02 |
| #90 Result panel | FR-033, FR-035 | FR-END-06 |
| #91 Play again | FR-034 | FR-END-07 |
| #92 Accessibility: result and confirmations | FR-039 | FR-A11Y-04 |
| #94 Undo | FR-036, FR-037, FR-038 | FR-UNDO-01, FR-UNDO-02, FR-UNDO-05, FR-UNDO-06 |

Covered elsewhere: FR-SETUP-04, FR-SETUP-05, FR-END-08, FR-NAV-02's Continue and FR-UNDO-08 (E5);
FR-UNDO-03, FR-UNDO-04, the computer's turn and FR-MOVE-04's input lock during it (E4); FR-SET-*,
FR-SND-01 to 03 and FR-HELP-* (E6); FR-A11Y-01 to 03 and 05 in full, and the accessibility audit
(E7).

### Key Entities

- **Game setup**: the opponent (computer or two players), the difficulty and the side (Light, Dark
  or random) for a game against the computer; the last choices are remembered.
- **Game session**: one game being played on the game screen: its rules state (from the engine),
  its setup, which side the player is (against the computer), and what is selected.
- **Selection**: the piece the player has chosen to move, if any, with its legal targets; during a
  chain, the jumping piece.
- **Hints**: the movable pieces and, for the selection, the target squares the board highlights.
- **Result**: how the game ended (winner and reason, or draw and reason), shown in the result panel.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Two players can play a complete game, from launching the app to the result panel,
  using only taps or drags on the board and the game menu; every move takes at most two taps or
  one drag per jump.
- **SC-002**: Every in-scope FRD requirement listed in the traceability table has at least one
  automated test that names its user story (100% of the list).
- **SC-003**: On the smallest and the largest supported iPhone, in portrait and at the largest
  accessibility text size, the whole board is visible without scrolling, and the turn indicator,
  menu, setup choices and result panel show their full text.
- **SC-004**: After a tap or drop on a target square, the moved piece is shown on its new square
  without any delay a player can notice (no animation, within one screen refresh of the input
  being handled).
- **SC-005**: The app contains no web content, and its cold launch is no slower than the current
  recorded baseline.
- **SC-006**: Every screen in the feature has previews in light and dark appearance and at the
  largest accessibility text size, and every control is labelled for VoiceOver.

## Assumptions

- **Computer games before E4**: setup shows and remembers the Computer choice with its difficulty
  and side, but a game against the computer cannot be started until E4 adds the opponent's moves;
  setup explains this. The computer-game rules this feature owns (player at the bottom, only the
  player resigns, Play again draws Random again) are tested without the user interface. To confirm
  in Clarify.
- **First-use setup defaults**: the FRD's defaults (Computer, Easy, Light) apply once E4 exists;
  until then the first-use opponent is Two players so a first game can start. To confirm in
  Clarify.
- **Statistics, Rules and Settings screens**: in this feature they show only their title and a
  short line saying what they will contain; E5 and E6 replace them. To confirm in Clarify.
- **Leaving a game**: without saving (E5), a game left for Home is not kept: the next New game
  starts fresh, and there is no Continue and no "Abandon current game?" yet. To confirm in Clarify.
- **Theme and hints**: the board uses the Classic theme and hints are always on until Settings
  (E6) adds both choices.
- **Sounds**: none in this feature; E6 adds them. FR-SND-04 (no animation) applies now.
- **VoiceOver**: this feature gives every control and square a label; square-by-square play and
  announcements are E7's.
- **Rules engine**: all rules, legal moves, endings and undo come from the E2 engine
  (`specs/002-rules-engine/contracts/engine-api.md`); this feature adds no rules of its own.
- **Remembered choices** are stored on the device only, which the privacy manifest must declare
  (Constitution VI.3; follow-up from E1 for #71).
