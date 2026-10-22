# Feature Specification: Computer Opponent

**Feature Branch**: `005-computer-opponent`

**Created**: 2026-10-22

**Status**: Draft

**Input**: User description: "Computer opponent (epic E4, GitHub issue #95): a single player plays against the computer at three difficulty levels, from FRD.md v1.1 section 11, on top of the rules engine (E2), the game screen (E3) and the VoiceOver board (E7). The computer plays only legal moves (FR-AI-01); Easy, Medium and Hard differ noticeably in strength, Easy beatable by a beginner and Hard a challenge for an experienced casual player (FR-AI-02); a thinking indicator shows during its turn and it moves after a short pause of about 0.5–1 second, even if it chose sooner (FR-AI-03); the app stays responsive while it thinks, with the menu, Undo and Home working (FR-AI-04); its capture chains are shown one jump at a time (FR-AI-05); it makes the first move when it plays Light (FR-AI-06); the board accepts no input during its turn (FR-MOVE-04); undo takes back the player's turn and the computer's reply and is unavailable before the player's first move (FR-UNDO-03), and undo while it thinks cancels its turn (FR-UNDO-04); VoiceOver announces its moves (FR-A11Y-03, #190). Game setup can now start computer games, with the FRD's first-use defaults (FR-SETUP-03). Board tasks: F4.1 AI search (#102: #103, #104, #105), F4.2 Computer turn (#106: #107, #108, #190, #109, #110), F4.3 Undo against the computer (#111: #112, #113). Out of scope, delivered by later epics: saving and resuming a computer game, including the computer moving after a resume (FR-SAVE-04, E5); the record against the computer and the Statistics screen (E5); Settings, sound and the Rules screen (E6). Users are players who play alone against the computer, from beginners to experienced casual players."

## Clarifications

### Session 2026-10-22

- Q: How should we prove that Easy, Medium and Hard differ enough in strength? → A: By automated matches and a playtest: at least 100 seeded games per pairing, each level playing each side in half, where the stronger level scores at least 70% (a win counts 1, a draw 0.5); and a playtest in which a beginner wins at least one of three games against Easy and Hard wins or draws at least one of three against an experienced casual player.
- Q: When the computer makes a multi-jump capture, how long should the board wait between one jump and the next? → A: About 0.5 seconds before each further jump, so a three-jump chain plays out in about 1 second after its first jump.
- Q: If the player opens Rules or Settings from the game menu while the computer is thinking, should the computer's move wait until they come back? → A: Yes: the move is held while Rules or Settings is open and appears after the usual pause once the player returns, so they come back to the position they left and see and hear the move.

## User Scenarios & Testing *(mandatory)*

One player plays against the computer on one device. E3 built Game setup with the Computer
choice, its difficulty and side, the board with the player's pieces at the bottom, and the rule
that only the player resigns; until now a computer game could not start. This feature adds the
opponent: it chooses its moves, takes its turns on the game screen, and works with Undo, the game
menu and VoiceOver. Terms follow the FRD glossary: Light and Dark, man, king, capture chain,
movable piece, turn. "The player" is the human; "the computer" is the opponent.

### User Story 1 - Play a game against the computer (Priority: P1)

The player chooses Computer in Game setup, picks a difficulty and a side, and starts. Whenever it is
the computer's turn, the game screen shows that the computer is thinking, the board stops
accepting input, and after a short pause the computer makes a legal move. A capture chain appears
one jump at a time. When the computer plays Light, it makes the first move without the player
doing anything. The game goes on turn by turn until it ends and the result panel appears. (#107,
#108, #109, #103, #104; FR-AI-01, FR-AI-03, FR-AI-05, FR-AI-06, FR-MOVE-04, FR-SETUP-03)

**Why this priority**: Playing the computer is the app's main use (FRD section 2); without it only
two-player games exist.

**Independent Test**: Start a game against the computer at any difficulty, as Light and as Dark,
and play it to the result panel.

**Acceptance Scenarios**:

1. **Given** Game setup with Computer chosen, **When** the player chooses Start, **Then** a game
   against the computer begins with the chosen difficulty and the player's side at the bottom.
2. **Given** the player is Light, **When** they make a move, **Then** the screen shows that the
   computer is thinking, the board accepts no taps or drags, and after a pause of about 0.5–1
   second the computer's move appears and it is the player's turn again.
3. **Given** the player is Dark, **When** the game starts, **Then** the computer, playing Light,
   makes the first move without any input from the player.
4. **Given** the computer has a capture chain, **When** it plays it, **Then** each jump appears in
   order, with a pause between jumps, and each captured piece disappears as it is jumped.
5. **Given** a capture is available to the computer, **When** it moves, **Then** it captures, as the
   rules require.
6. **Given** the computer's move leaves the player with no legal move, **When** it is shown,
   **Then** the result panel appears with the computer's side as the winner.
7. **Given** setup has never been used, **When** it opens, **Then** Computer, Easy and Light are
   preselected.

---

### User Story 2 - Choose how strong the computer is (Priority: P2)

The three difficulty levels play noticeably differently: a beginner can beat Easy, Medium is a
fair game for a player who knows the rules, and Hard is a challenge for an experienced casual
player. Replaying the same moves against the computer does not always produce the same game.
(#103, #104, #105; FR-AI-01, FR-AI-02)

**Why this priority**: One working opponent already makes the game playable (User Story 1); three
distinct levels make it worth coming back to.

**Independent Test**: Let the levels play each other over a fixed set of games and compare their
scores, then play a few games by hand at each level.

**Acceptance Scenarios**:

1. **Given** a fixed set of games between Medium and Easy, with each level playing both sides,
   **When** they are played, **Then** Medium scores clearly better than Easy.
2. **Given** the same between Hard and Medium, **When** they are played, **Then** Hard scores
   clearly better than Medium.
3. **Given** a beginner plays Easy, **When** they play a few games, **Then** they can win.
4. **Given** an experienced casual player plays Hard, **When** they play a few games, **Then** the
   games are a challenge: the computer wins or draws some of them.
5. **Given** the player makes the same opening moves in two games at the same level, **When** the
   computer replies, **Then** its replies are not always the same.

---

### User Story 3 - Stay in control while the computer thinks (Priority: P2)

While the computer thinks or plays out a chain, the player can still open the game menu and use
Undo, Resign, Rules, Settings and Home, and the app responds at once. The computer never moves
after the player has left the game or resigned. (#110; FR-AI-04, FR-NAV-04, FR-END-02)

**Why this priority**: The thinking time is short, but a frozen screen or a move made after the
player resigned would break trust in the app.

**Independent Test**: Start a computer game, and during the computer's turn open the menu and use
each entry in turn.

**Acceptance Scenarios**:

1. **Given** the computer is thinking, **When** the player opens the game menu, **Then** it opens
   at once and each entry works.
2. **Given** the computer is thinking, **When** the player resigns and confirms, **Then** the
   result panel shows the player's resignation and the computer makes no move.
3. **Given** the computer is thinking, **When** the player chooses Home and confirms leaving,
   **Then** Home appears and the abandoned game makes no further move.
4. **Given** the computer is thinking, **When** the player opens Rules or Settings and comes back,
   **Then** the game is in the position they left, and the computer then makes its move.

---

### User Story 4 - Undo against the computer (Priority: P2)

Undo takes the player back to their own previous turn: it removes their last turn and the
computer's reply together. It is not available until the player has made a move. Using Undo while
the computer is still thinking cancels the computer's turn and takes back the player's move.
(#112, #113; FR-UNDO-03, FR-UNDO-04)

**Why this priority**: Undo already works in two-player games (E3); against the computer it must
skip the computer's reply, or the player would undo into the computer's turn.

**Independent Test**: Play several turns against the computer, then undo repeatedly, including
once while the computer is thinking.

**Acceptance Scenarios**:

1. **Given** the player and the computer have each made a move, **When** the player chooses Undo,
   **Then** both moves are taken back and it is the player's turn in the position before their
   move.
2. **Given** a new game where the player has not moved yet, including one where the computer made
   the first move as Light, **When** the menu is opened, **Then** Undo is unavailable.
3. **Given** the computer is thinking after the player's move, **When** the player chooses Undo,
   **Then** the computer's turn is cancelled, the player's move is taken back, and it is the
   player's turn; the computer makes no move afterwards.
4. **Given** several turns played, **When** the player undoes repeatedly, **Then** each undo goes
   back one of the player's turns, until the player's first turn of the game.
5. **Given** the player is in the middle of their own capture chain, **When** they choose Undo,
   **Then** the position from before the chain is restored and it is still the player's turn.
6. **Given** the game has ended, **When** the result panel is shown, **Then** Undo is unavailable.

---

### User Story 5 - Hear the computer's moves with VoiceOver (Priority: P2)

A VoiceOver player hears each of the computer's moves as it appears, in the same words as their
own: "Dark c5 to d4. Light to move.", "Dark captures d4", "Dark crowned on a1". VoiceOver focus
stays where the player left it, so they can go straight back to the board. (#190; FR-A11Y-03)

**Why this priority**: Without it, a VoiceOver player cannot follow a game against the computer;
E7 already announces the player's own moves.

**Independent Test**: Replay scripted computer games with the announcer recorded and check each
computer step's announcement; play one game by hand with VoiceOver.

**Acceptance Scenarios**:

1. **Given** the computer makes a simple move, **When** it appears, **Then** VoiceOver announces it
   with the turn that follows, for example "Dark c5 to d4. Light to move."
2. **Given** the computer plays a two-jump chain, **When** each jump appears, **Then** each jump is
   announced once ("Dark captures e5", then "Dark captures c3. Light to move.").
3. **Given** the computer's move crowns a man or ends the game, **When** it appears, **Then** the
   announcement includes the crowning or the result.
4. **Given** VoiceOver focus is on a square during the computer's turn, **When** the computer
   moves, **Then** focus stays on that square.
5. **Given** it is the computer's turn, **When** VoiceOver reads the screen, **Then** it reads that
   the computer is thinking, and no square reads "can move".

### Edge Cases

- **Only one legal move**: the computer still waits the pause before playing it (FR-AI-03).
- **The player's move ends the game**: the computer does not think; the result panel appears at
  once.
- **The computer's move ends the game** (no moves left, repetition, no progress): the move appears,
  then the result panel; the announcement ends with the result.
- **Undo at the moment the computer's move appears**: either the move is taken back with the
  player's turn, or the turn is cancelled before it appears; the board is never left with the
  computer's move after a cancel, and the player is never left without a turn.
- **Undo during the computer's chain** (some jumps already shown): the chain stops, and the position
  from before the player's last turn is restored.
- **Play again**: the new game keeps the opponent, difficulty and side; with Random the side is
  drawn again, and if the computer gets Light it moves first.
- **The computer plays Light and the player has not moved**: Undo is unavailable; Resign and Home
  work.
- **Leave confirmation during the computer's turn**: the computer's turn continues while the
  confirmation is shown; cancelling returns to the game, which may now show the computer's move.
- **Background and back during the computer's turn**: the turn completes or carries on; no move is
  lost or made twice. Saving the game for a later resume is E5.
- **Rapid input during the computer's turn**: taps, drags and VoiceOver activations on the board are
  ignored and leave nothing selected or hinted when the player's turn begins.
- **Two-player games**: unchanged; no thinking, no pauses.

## Requirements *(mandatory)*

### Functional Requirements

**Computer games in Game setup** (no board task yet; #101 Reconcile assigns them)

- **FR-001**: Game setup MUST start a game against the computer with the chosen difficulty and side
  (FR-SETUP-01, FR-SETUP-02). The note that computer games arrive later MUST go. This replaces E3's
  FR-011.
- **FR-002**: On first use, setup MUST preselect Computer, Easy and Light (FR-SETUP-03). Choices
  already remembered from earlier games stay.
- **FR-003**: Setup MUST remember the opponent, difficulty and side when a game starts, and
  preselect them next time (FR-SETUP-03, "used in the previous game"). This replaces E3's rule of
  remembering choices as soon as they are made.

**The computer's turn (#106: #107, #108, #109)**

- **FR-004**: The computer MUST play only legal steps under the rules of FRD section 8, including
  mandatory captures and every jump of a capture chain (FR-AI-01).
- **FR-005**: When it becomes the computer's turn, including the first turn of a game in which the
  computer plays Light (FR-AI-06) and after Play again, the computer MUST take its turn without any
  action by the player.
- **FR-006**: During the computer's turn, the game screen MUST show that the computer is thinking
  (FR-AI-03), in place of the usual turn sentence.
- **FR-007**: During the computer's turn, the board MUST NOT accept input: taps, drags and VoiceOver
  activations do nothing, nothing is selected or hinted, and no square has a "can move" or "legal
  target" state (FR-MOVE-04).
- **FR-008**: The computer's first step MUST appear no sooner than 0.5 seconds after its turn
  starts, even if it chose sooner, and no later than about 1 second after (FR-AI-03).
- **FR-009**: The computer's capture chain MUST be shown one jump at a time, in order, with a pause
  of about 0.5 seconds before each further jump, each captured piece disappearing as it is jumped
  (FR-AI-05, FR-SND-04).
- **FR-010**: When the computer's turn ends, the thinking indicator MUST go and the player's turn
  begins as usual; if the computer's step ended the game, the result panel MUST appear (FR-END-06).

**Difficulty (#102: #103, #104, #105)**

- **FR-011**: Easy, Medium and Hard MUST differ noticeably in strength (FR-AI-02): over a fixed set
  of games, each level MUST beat the level below it by the margin in SC-003.
- **FR-012**: Easy MUST be beatable by a beginner, and Hard MUST be a challenge for an experienced
  casual player (FR-AI-02), checked by a playtest (SC-004).
- **FR-013**: The computer MUST NOT play the same game every time: when several moves are equally
  good for its level, it MUST choose among them at random. For tests, its choices MUST be
  repeatable from a fixed starting value.

**Staying in control (#106: #110)**

- **FR-014**: While the computer thinks or plays out a chain, the game menu MUST open and Undo,
  Resign, Rules, Settings and Home MUST work, with no delay a player can notice (FR-AI-04).
- **FR-015**: Resigning during the computer's turn MUST stop that turn: the computer MUST NOT move
  afterwards, and the result is the player's resignation (FR-END-02).
- **FR-016**: Leaving the game for Home MUST work during the computer's turn, with E3's leave
  confirmation; once the game is left, the computer MUST NOT move in it.
- **FR-017**: While Rules or Settings is open from the game menu, the computer's move MUST NOT
  appear and nothing about it is announced; once the player returns, it appears after the pause of
  FR-008, so they come back to the position they left (FR-NAV-04) and see and hear the move
  (Clarifications).

**Undo against the computer (#111: #112, #113)**

- **FR-018**: In a game against the computer, each undo MUST take back the player's last turn and
  the computer's reply, returning to the player's turn (FR-UNDO-03), and MUST be repeatable back to
  the player's first turn (FR-UNDO-01). When the computer played Light, its first move is never
  taken back.
- **FR-019**: Undo MUST be unavailable until the player has made at least one move (FR-UNDO-03),
  and after the game has ended (FR-UNDO-06).
- **FR-020**: Undo during the computer's turn, while it thinks or while its chain is being shown,
  MUST cancel that turn and take back the player's last turn (FR-UNDO-04). A cancelled turn MUST
  NOT change the board afterwards.
- **FR-021**: Undo during the player's own unfinished capture chain MUST restore the position from
  before the chain began, leaving it the player's turn (FR-UNDO-05).
- **FR-022**: Every undo MUST restore the full game state, including the side to move and the
  draw-rule counters (FR-UNDO-07).

**VoiceOver (#106: #190)**

- **FR-023**: Each of the computer's steps MUST be announced as it appears, with the sentences E7
  uses for the player's steps: "<Side> <from> to <to>", "<Side> captures <square>", "<Side>
  crowned on <square>" (FR-A11Y-03). Each step MUST produce exactly one announcement.
- **FR-024**: A computer step that continues its chain MUST be announced without "Jump again"; the
  computer's last step MUST end with the turn that follows ("Light to move", or "Light to move,
  capture required") or with the result.
- **FR-025**: VoiceOver focus MUST NOT move during the computer's turn.
- **FR-026**: The thinking indicator MUST be read by VoiceOver, and an undo during the computer's
  turn MUST be announced like any other undo ("Move undone. Light to move.").

**Accessibility**

- **FR-027**: The automated accessibility audit MUST cover Game setup with Computer chosen and Start
  available, and the game screen during the computer's turn; the allow-list entry for the disabled
  Start goes (FR-A11Y-04).
- **FR-028**: The thinking indicator MUST support Dynamic Type up to the largest accessibility size
  and Dark Mode, and any motion in it MUST respect Reduce Motion (Constitution V.2).

### Traceability

| Board task | Requirements | FRD |
|---|---|---|
| #103 Position evaluation | FR-011, FR-012 | FR-AI-02 |
| #104 Cancellable search | FR-004, FR-008, FR-013, FR-014, FR-020 | FR-AI-01, FR-AI-04, FR-UNDO-04 |
| #105 Difficulty levels | FR-011, FR-012, FR-013 | FR-AI-02 |
| #107 Computer turn controller | FR-005 to FR-008, FR-010, FR-017 | FR-AI-03, FR-MOVE-04, FR-NAV-04 |
| #108 Chains one jump at a time | FR-009 | FR-AI-05 |
| #190 VoiceOver for the computer's moves | FR-023 to FR-026 | FR-A11Y-03 |
| #109 Computer moves first as Light | FR-005 | FR-AI-06 |
| #110 Responsive while thinking | FR-014, FR-015, FR-016 | FR-AI-04, FR-END-02 |
| #112 Undo takes back a pair | FR-018, FR-019, FR-021, FR-022 | FR-UNDO-01, FR-UNDO-03, FR-UNDO-05 to 07 |
| #113 Undo while thinking | FR-020 | FR-UNDO-04 |
| *(none yet)* Computer games in setup | FR-001, FR-002, FR-003 | FR-SETUP-01 to 03 |
| *(none yet)* Accessibility of new states | FR-027, FR-028 | FR-A11Y-04 |

Covered elsewhere: saving a computer game and the computer moving after a resume (FR-SAVE-01 to
05, E5); the record against the computer, which counts each difficulty separately and ignores undo
(FR-STAT-*, FR-UNDO-08, E5); the hints switch, sounds for the computer's moves and the Rules and
Settings screens (E6).

### Key Entities

- **Difficulty level**: Easy, Medium or Hard; sets how strongly the computer plays.
- **Computer player**: chooses a whole turn, every jump of a chain included, for a position, the
  side to move and a difficulty level.
- **Computer turn**: one turn of the computer on the game screen: thinking, then its steps shown
  one by one; it ends when its last step is shown, or is cancelled by Undo, Resign or leaving.
- **Game setup**: as in E3; now remembered when a game starts.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A player can play a complete game against the computer at each difficulty, as Light
  and as Dark, from Home to the result panel, using only taps or drags.
- **SC-002**: In at least 100 seeded games per difficulty, in which the computer plays both sides,
  every computer step is legal and every game ends (100%).
- **SC-003**: Over a fixed set of at least 100 seeded games per pairing, each level playing each
  side in half of them, Medium scores at least 70% against Easy and Hard at least 70% against
  Medium (a win counts 1, a draw 0.5).
- **SC-004**: In a recorded playtest, a beginner wins at least one of three games against Easy, and
  Hard wins or draws at least one of three games against an experienced casual player.
- **SC-005**: On a recent iPhone in a release build, at every difficulty, the computer's first step
  appears 0.5–1 second after its turn starts in at least 95% of turns, and never later than 1.5
  seconds.
- **SC-006**: While the computer thinks, the game menu opens and Undo, Resign and Home respond as
  quickly as when it is the player's turn; no freeze a player can notice (under 100 ms).
- **SC-007**: In scripted games, every undo against the computer, including during its thinking and
  during its chain, returns to the player's turn with exactly the position, side to move and
  draw-rule counters from before the player's last turn (100%), and no cancelled turn changes the
  board afterwards.
- **SC-008**: In scripted computer games, each computer step produces exactly one announcement whose
  text matches it, and VoiceOver focus does not move during the computer's turn (100%).
- **SC-009**: The accessibility audit reports zero problems on every screen and state in FR-027.
- **SC-010**: FR-AI-01 to FR-AI-06, FR-MOVE-04, FR-UNDO-03, FR-UNDO-04 and the computer part of
  FR-A11Y-03 each have at least one automated test that names its user story.

## Assumptions

- **Measuring strength** (confirmed in Clarifications): FR-AI-02 is judged by automated matches
  between the levels (SC-003: at least 70% score over at least 100 games per pairing) plus a short
  playtest (SC-004). The FRD gives no number.
- **Pace of a computer chain** (confirmed in Clarifications): about 0.5 seconds before each
  further jump (FR-009), so a three-jump chain takes about 1 second after the first jump. The FRD
  says only that the player can follow it.
- **Rules or Settings during the computer's turn** (confirmed in Clarifications): the computer's
  move waits until the player returns (FR-017), so they come back to the position they left
  (FR-NAV-04) and see and hear the move, rather than the computer moving while they are away.
- **Variety**: the computer chooses at random among equally good moves, so games do not repeat;
  tests fix the random choices so they do. How a weaker level picks its moves is decided in the
  plan.
- **Thinking indicator**: during the computer's turn the turn sentence becomes a "thinking"
  sentence for the computer's side (for example "Dark is thinking…"), with a system activity
  indicator; the exact wording is set in the plan's contracts. No sound or haptic (FR-SND-03).
- **Setup memory**: choices are remembered when a game starts (FR-003), as the FRD says ("used in
  the previous game"); E3 remembered them as they were made because computer games could not
  start.
- **Leaving a computer game**: until E5 adds saving, leaving an unfinished game asks first and
  discards it, as in E3 (E3's FR-042); E5 adds saving, Continue and the computer moving after a
  resume (FR-SAVE-04).
- **Speed**: thinking time is bounded (FR-008), not a fixed search depth; the plan profiles the
  engine's move generation before choosing how deep each level searches (Constitution VII.4,
  `specs/002-rules-engine/checklists/validation.md`).
- **No rule changes**: the computer uses the rules engine of E2 (`specs/002-rules-engine/contracts/
  engine-api.md`) for every move it considers and plays, and the game screen of E3 and E7.
