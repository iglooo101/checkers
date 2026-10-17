# Feature Specification: Rules Engine

**Feature Branch**: `002-rules-engine`

**Created**: 2026-10-16

**Status**: Draft

**Input**: User description: "Rules engine (epic E2, GitHub issue #29): the complete American checkers rules from FRD.md v1.1 sections 8 (Rules), 9 (Ending a game) and 10 (Undo), plus FR-SETUP-06 and the capture-chain behavior in section 7.3, as tested, UI-free logic in the existing CheckersEngine package. Users are the players, through the screens later epics build on it: E3 (board, two-player play, undo and resign), E4 (computer opponent), E5 (saving and results). Out of scope: any UI, the computer opponent and its undo pairing (FR-UNDO-03, FR-UNDO-04), saving and statistics."

## User Scenarios & Testing *(mandatory)*

The players never see this engine directly; they experience it through the game screens built in
E3–E5. Each story describes the rules as a player meets them, and each is proven by automated
tests against the engine alone. Terms follow the FRD glossary: Light and Dark, man, king, capture
chain, movable piece, turn.

### User Story 1 - Start a game and make simple moves (Priority: P1)

A new game starts from the standard American checkers position with Light to move. On their turn,
a player moves one of their men one square diagonally forward onto an empty dark square, and the
turn passes to the other side. (#36, #37, #38, #40; FR-RULE-01, FR-RULE-02, FR-SETUP-06)

**Why this priority**: Nothing else in the game works without a correct board, starting position
and basic moves; E3's two-player screen can be built on this story alone.

**Independent Test**: Create a new game and check every square's contents and the side to move;
list Light's legal moves (exactly 7); make one and check the board and that Dark is to move.

**Acceptance Scenarios**:

1. **Given** a new game, **When** the board is inspected, **Then** Light men occupy all 12 dark
   squares of rows 1–3, Dark men occupy all 12 dark squares of rows 6–8, all other squares are
   empty, and Light is to move.
2. **Given** a new game, **When** Light's legal moves are listed, **Then** there are exactly 7, each
   a man moving from row 3 one square diagonally forward to row 4.
3. **Given** Light to move, **When** Light moves a man from c3 to d4, **Then** c3 is empty, d4 holds
   a Light man, and Dark is to move.
4. **Given** a man, **When** its legal moves are listed, **Then** none goes backward, sideways,
   more than one square, or onto an occupied square.

---

### User Story 2 - Capture and play with kings (Priority: P1)

A man captures by jumping diagonally forward over an adjacent opposing piece onto the empty square
beyond it. A king moves and captures the same way but in all four diagonal directions, one square
at a time. When any capture is available, the player must capture, but may choose which capture
to make. (#41, #42, #43; FR-RULE-03, FR-RULE-04, FR-RULE-05)

**Why this priority**: Mandatory capture and kings define American checkers; without them the game
is wrong, not just incomplete.

**Independent Test**: Set up positions with captures and kings, list the legal moves, and check
that only captures are offered when one exists and that kings move and capture backward too.

**Acceptance Scenarios**:

1. **Given** a Light man on c3 and a Dark man on d4 with e5 empty, **When** Light's legal moves are
   listed, **Then** the jump c3 over d4 to e5 is legal and no simple move is.
2. **Given** a Dark man behind a Light man (on a lower row), **When** that Light man's moves are
   listed, **Then** it cannot capture backward.
3. **Given** a Light king on d4 with empty diagonal neighbors, **When** its moves are listed,
   **Then** it can move to c3, e3, c5 and e5, and no farther along any diagonal.
4. **Given** a Light king with an adjacent Dark piece behind it and an empty square beyond,
   **When** its moves are listed, **Then** it can capture backward.
5. **Given** two different captures available (one starting a longer chain than the other),
   **When** the legal moves are listed, **Then** both are legal; the player is not forced to take
   the longest chain or to capture with a king.
6. **Given** a capture is available, **When** the player tries a simple move, **Then** it is
   rejected because a capture is required, and nothing changes.

---

### User Story 3 - Capture chains and crowning (Priority: P1)

A multi-jump capture is made one jump at a time. After each jump the jumped piece is removed and,
if the same piece can jump again, the turn continues with only that piece's next jumps allowed.
The turn ends when the piece cannot jump again, or when a man reaches the far row and is crowned
king, even if it could keep jumping as a king. (#44, #45, #46; FR-RULE-06, FR-RULE-07,
FR-CHAIN-01, FR-CHAIN-02, FR-CHAIN-03)

**Why this priority**: E3 shows chains jump by jump and E4 animates the computer's chains the same
way (FR-AI-05); both need the engine to model chains step by step.

**Independent Test**: Set up a double-jump position, make the first jump, check the jumped piece is
gone and only the second jump is legal; make it and check the turn passed. Set up a man that
crowns mid-chain and check the turn ends.

**Acceptance Scenarios**:

1. **Given** a Light man that can jump twice in a row, **When** it makes the first jump, **Then**
   the jumped Dark piece is removed, the man stands on the landing square, Light is still to move,
   and the only legal moves are that man's next jumps.
2. **Given** a chain in progress, **When** the player tries to move a different piece or make a
   simple move, **Then** it is rejected and nothing changes.
3. **Given** a chain in progress, **When** the jumping piece has no further jump, **Then** the turn
   ends and the other side is to move.
4. **Given** a Light man whose jump lands on row 8 with another jump available from there for a
   king, **When** it makes that jump, **Then** it becomes a king and the turn ends.
5. **Given** a Dark man reaching row 1 by a simple move, **When** the move is made, **Then** it
   becomes a king and Light is to move.

---

### User Story 4 - Game endings (Priority: P2)

A game ends when the side to move has no legal move (it loses), when a player resigns (the
opponent wins), when the same position with the same side to move occurs for the third time
(draw), or after 40 consecutive moves by each side with no capture and no man moved (draw). There
are no draw offers. After a game ends, no further moves are accepted. (#47, #48, #49, #50, #51, #52;
FR-END-01 to FR-END-05)

**Why this priority**: E3's result panel and E5's record depend on correct outcomes and reasons, but
play itself (stories 1–3) comes first.

**Independent Test**: Reach each ending from a constructed position or a scripted sequence of moves
and check the outcome, winner and reason, and that further moves are rejected.

**Acceptance Scenarios**:

1. **Given** a turn ends leaving the other side with no pieces, **When** the state is inspected,
   **Then** the game is over and the side that moved has won because the opponent has no moves left.
2. **Given** a turn ends leaving the other side with pieces but no legal move, **When** the state is
   inspected, **Then** the game is over with the same outcome and reason.
3. **Given** a game in progress, **When** either side resigns (whether or not it is that side's
   turn, including during a capture chain), **Then** the game is over and the other side has won by
   resignation.
4. **Given** kings shuffling back and forth, **When** the same position with the same side to move
   occurs for the third time, **Then** the game is over as a draw by repetition.
5. **Given** 80 consecutive turns (40 per side) with no capture and no man moved, **When** the 80th
   such turn ends, **Then** the game is over as a draw by no progress; one capture or man move
   earlier resets the count.
6. **Given** a finished game, **When** any move or resignation is attempted, **Then** it is rejected
   and nothing changes.

---

### User Story 5 - Undo (Priority: P2)

A player can take back turns one at a time, back to the start of the game. Each undo restores the
complete state from before that turn, including whose turn it is and the draw counters. Undo during
an unfinished capture chain takes back the whole partial turn. Undo is not available at the start
of a game or after the game has ended. (#53, #54, #55, #56; FR-UNDO-01, FR-UNDO-02, FR-UNDO-05,
FR-UNDO-06, FR-UNDO-07)

**Why this priority**: The game menu offers undo (E3), and the computer game composes it (E4), but
it builds on the turn model of stories 1–4.

**Independent Test**: Play a sequence of turns, undo them one by one, and check each restored state
equals the state recorded before that turn; undo mid-chain; try undo at the start and after the
end.

**Acceptance Scenarios**:

1. **Given** a game after several turns, **When** undo is used once, **Then** the board, side to
   move, draw counters and repetition record equal the state before the last turn, whichever side
   made it.
2. **Given** a game after several turns, **When** undo is used repeatedly, **Then** each step goes
   back one turn until the starting position, where undo is no longer available.
3. **Given** a capture chain in progress, **When** undo is used, **Then** the position from before
   the chain began is restored, with the same side to move.
4. **Given** a finished game, **When** undo is attempted, **Then** it is unavailable and nothing
   changes.
5. **Given** a position that occurred twice, **When** the turn that led to the second occurrence is
   undone, **Then** that occurrence no longer counts toward a draw by repetition.

### Edge Cases

- **No pieces left**: the side to move with no pieces loses at the start of its turn.
- **Blocked**: the side to move with pieces but no legal move loses.
- **Several capturing pieces**: any piece that can capture may be chosen, man or king.
- **Branching chains**: when the jumping piece has two possible next jumps, the player chooses
  each jump in turn.
- **Revisited squares**: a king's chain may pass over a square it already crossed, but never jumps
  the same piece twice (it is removed when jumped), never jumps its own pieces, and never jumps two
  pieces at once.
- **Crowning mid-chain**: ends the turn even if the new king could jump again.
- **Rejected actions**: moving for the side not to move, moving after the game ended, a simple move
  when a capture is required, an illegal target, or leaving a chain unfinished are rejected and
  change nothing, and the reason is reported.
- **Repetition counting**: positions are compared only at the start of a turn (never mid-chain); the
  starting position counts as its first occurrence.
- **Endings at the same moment**: if the side to move has no legal move, that loss takes precedence
  over a draw reached on the same turn; if both draw rules trigger together, the result is a draw by
  repetition.
- **Resignation during a chain**: allowed; the game ends with the position as it stands.
- **Undo at the start**: unavailable; using undo mid-chain on the first turn restores the starting
  position.

## Requirements *(mandatory)*

### Functional Requirements

**Board and starting position (#36: #37, #38)**

- **FR-001**: The board MUST be 8×8, with play only on the 32 dark squares. Columns are named a–h
  from left to right and rows 1–8 from Light's side, so each square has a name such as "c3"
  (FR-RULE-01, naming as in FR-A11Y-01). a1 is a dark square.
- **FR-002**: Each piece MUST belong to Light or Dark and be either a man or a king.
- **FR-003**: A new game MUST place Light men on the dark squares of rows 1–3 and Dark men on the
  dark squares of rows 6–8 (12 each), with Light to move, no capture chain pending and the game in
  progress (FR-SETUP-06).

**Moves and captures (#39: #40, #41, #42, #43)**

- **FR-004**: A man MUST move one square diagonally forward onto an empty square; forward is toward
  row 8 for Light and toward row 1 for Dark (FR-RULE-02).
- **FR-005**: A man MUST capture by jumping diagonally forward over an adjacent opposing piece onto
  the empty square directly beyond it (FR-RULE-03).
- **FR-006**: A king MUST move and capture like a man but in all four diagonal directions, one
  square at a time; it MUST NOT move or capture across more than one square (FR-RULE-04).
- **FR-007**: When any capture is available to the side to move, only captures MUST be legal. The
  player MAY choose any available capture, regardless of chain length or the kind of capturing
  piece (FR-RULE-05).
- **FR-008**: For the side to move, the engine MUST list every legal move as a single step (a
  simple move or one jump), the pieces that can move, and each piece's legal target squares, and
  MUST report whether a capture is required (needed by FR-GAME-02 and FR-AID-01, FR-AID-02 in E3).

**Capture chains and crowning (#44: #45, #46)**

- **FR-009**: A capture MUST be applied one jump at a time: the jumped piece is removed and the
  jumping piece lands on the empty square beyond it (FR-CHAIN-01).
- **FR-010**: After a jump, if the same piece can jump again, the turn MUST continue with the same
  side to move and only that piece's next jumps legal (FR-RULE-06, FR-CHAIN-02).
- **FR-011**: The turn MUST end when the jumping piece has no further jump (FR-CHAIN-03).
- **FR-012**: A man ending a step on the far row (row 8 for Light, row 1 for Dark) MUST be crowned
  king at once, and crowning MUST end the turn, even in the middle of a chain (FR-RULE-07,
  FR-CHAIN-03).

**Game state and endings (#47: #48, #49, #50, #51, #52)**

- **FR-013**: The game state MUST include the board, the side to move, any capture chain in
  progress, the draw-rule counters, the record of positions for repetition, the undo history and
  the outcome (in progress, a win with winner and reason, or a draw with reason). Nothing that
  affects play may live outside this state, so a later epic can save and restore it exactly
  (FR-SAVE-03).
- **FR-014**: When a turn ends and the side now to move has no legal move (including having no
  pieces), the game MUST end with the other side winning, reason "no moves left" (FR-END-01).
- **FR-015**: Either side MUST be able to resign at any time while the game is in progress,
  including during a capture chain and when it is not that side's turn; the other side wins,
  reason "resignation" (FR-END-02). Which side resigns is decided by the screen (E3, E4).
- **FR-016**: The game MUST end in a draw, reason "repetition", when the same position (same pieces
  of the same kind on the same squares) with the same side to move occurs at the start of a turn
  for the third time (FR-END-03).
- **FR-017**: The game MUST end in a draw, reason "no progress", after 80 consecutive completed
  turns (40 per side) with no capture and no man moved; any capture or man move, including a man's
  crowning move, resets the count (FR-END-04).
- **FR-018**: There MUST be no draw offer or draw by agreement (FR-END-05).
- **FR-019**: When endings coincide, a loss by no legal moves MUST take precedence over a draw, and
  a draw by repetition over a draw by no progress.
- **FR-020**: Any move, resignation or undo that is not allowed in the current state MUST be
  rejected without changing the state, with a reason: game over, not that side's turn, capture
  required, chain must continue with the same piece, or not a legal move.

**Undo (#53: #54, #55, #56)**

- **FR-021**: Undo MUST take back the last completed turn, whichever side made it, restoring the
  complete state from before that turn: board, side to move, draw counters and repetition record
  (FR-UNDO-02, FR-UNDO-07).
- **FR-022**: Undo MUST be repeatable back to the starting position, where it becomes unavailable
  (FR-UNDO-01).
- **FR-023**: Undo during an unfinished capture chain MUST discard the partial turn and restore the
  state from before the chain began (FR-UNDO-05).
- **FR-024**: Undo MUST be unavailable once the game has ended (FR-UNDO-06), and the engine MUST
  report whether undo is currently available.

**Engine qualities**

- **FR-025**: The engine MUST NOT depend on any user interface, and every rule MUST be checkable by
  automated tests that run without the app.
- **FR-026**: Applying the same moves to the same state MUST always produce the same result, and a
  copy of a game state MUST be independent of the original, so the computer opponent (E4) can
  explore hypothetical positions in the background without affecting the game on screen.

### Traceability

| Board task | Requirements | FRD |
|---|---|---|
| #37 Board, square and piece types | FR-001, FR-002 | FR-RULE-01 |
| #38 Starting position | FR-003 | FR-SETUP-06 |
| #40 Man moves | FR-004, FR-008 | FR-RULE-02 |
| #41 Man captures | FR-005 | FR-RULE-03 |
| #42 King moves and captures | FR-006 | FR-RULE-04 |
| #43 Mandatory capture | FR-007, FR-008 | FR-RULE-05 |
| #45 Jump-by-jump chains | FR-009, FR-010, FR-011 | FR-RULE-06, FR-CHAIN-01–03 |
| #46 Crowning ends the turn | FR-012 | FR-RULE-07 |
| #48 Game state | FR-013, FR-020, FR-026 | — |
| #49 No legal moves | FR-014, FR-019 | FR-END-01 |
| #50 Threefold repetition | FR-016, FR-019 | FR-END-03 |
| #51 No progress | FR-017, FR-019 | FR-END-04 |
| #52 Resignation | FR-015, FR-018 | FR-END-02, FR-END-05 |
| #54 Turn history | FR-021, FR-022 | FR-UNDO-01, FR-UNDO-02, FR-UNDO-07 |
| #55 Undo mid-chain | FR-023 | FR-UNDO-05 |
| #56 No undo after the end | FR-024 | FR-UNDO-06 |
| (all) | FR-025 | Constitution II, III |

Covered elsewhere: FR-UNDO-03 and FR-UNDO-04 (undo against the computer) in E4; FR-UNDO-08 and
recording results in E5.

### Key Entities

- **Square**: one of the 32 dark squares, named by column a–h and row 1–8 from Light's side.
- **Piece**: a side (Light or Dark) and a kind (man or king).
- **Position**: which piece, if any, stands on each dark square.
- **Step**: one legal action: a simple move (from, to) or a single jump (from, over, to).
- **Turn**: the steps one side makes before the other side moves: one simple move, or one or more
  jumps by the same piece.
- **Game state**: position, side to move, chain in progress, draw counters, repetition record,
  undo history and outcome.
- **Outcome**: in progress; a win (winner and reason: no moves left or resignation); or a draw
  (reason: repetition or no progress).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Every requirement in FRD sections 8, 9 and 10 within scope (FR-RULE-01 to 07,
  FR-CHAIN-01 to 03, FR-END-01 to 05, FR-UNDO-01, 02, 05, 06, 07) and FR-SETUP-06 has at least one
  automated test, each named with its user story (100% coverage of the list).
- **SC-002**: Counting all complete-turn sequences from the starting position matches the published
  reference counts for American checkers for at least the first 6 turns (an independent check that
  move generation, captures, chains and crowning are all right).
- **SC-003**: In 1,000 games played with random legal moves, every game reaches an outcome, no
  illegal position ever occurs, and undoing every turn of each game returns exactly to the starting
  state, matching the state recorded before each turn along the way.
- **SC-004**: Listing the legal moves of a position is fast enough for a computer opponent to search:
  the 6-turn reference count of SC-002 completes in under 10 seconds on the development Mac.
- **SC-005**: The engine's tests run on the development Mac without building or launching the app,
  and the engine has no user-interface dependency (checked by the existing lint rule).

## Assumptions

- **Board orientation**: Light's side is rows 1–3 and Light moves first and "up" the board (toward
  row 8), as the FRD decides; a1 is a dark square, matching the standard board.
- **Turns and moves**: a "move" in the FRD's draw rules means a completed turn; a full capture chain
  is one turn. The 40-move rule counts completed turns of both sides together (80 in total).
- **Repetition** compares positions at the start of turns only, including the starting position,
  and undo removes undone positions from the record (story 5, scenario 5).
- **Precedence** of simultaneous endings (FR-019) is a reasonable default the FRD does not state;
  `/speckit-clarify` (#32) should confirm it.
- **Resignation** is accepted for either side at any time while the game is in progress; the screens
  decide who may resign (FRD: the human against the computer, the side to move in a two-player
  game).
- **Undo granularity**: the engine undoes one turn per request. Taking back the player's turn and the
  computer's reply together, and cancelling the computer's turn (FR-UNDO-03, FR-UNDO-04), are
  composed by E4 on top of this.
- **Saving**: this slice keeps all state in the game state (FR-013) but adds no saving format; E5
  adds it.
- **Reference counts** for SC-002 come from published checkers move-count tables; the plan records
  the source and the exact numbers.
- **Existing code**: `Side` (light, dark, opponent) from E1 stays and is reused.
