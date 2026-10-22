# Feature Specification: Saving and Statistics

**Feature Branch**: `006-saving-and-statistics`

**Created**: 2026-10-22

**Status**: Draft

**Input**: User description: "E5 Saving and statistics (epic #114; FRD v1.1 §12 Saving and resuming, §13 Statistics). The app saves the unfinished game automatically after every turn and when the app goes to the background; the player never saves manually, and there is at most one saved game. Home offers Continue only when a saved game exists; Continue restores the game exactly (position, side to move, opponent, difficulty, the player's side, undo history and draw-rule counters), and if it was saved during the computer's turn the computer makes its move after the game resumes. A saved game that cannot be read is discarded, Continue is hidden, and the player is told the previous game could not be restored. A finished game is never the saved game, so Continue disappears once a game ends. Leaving a game for Home no longer asks for confirmation: the game stays the saved game (replacing E3's leave confirmation). Starting a new game while a saved game exists first asks "Abandon current game?": confirming discards it, cancelling returns to setup with it intact. Statistics: a new Statistics screen (replacing E3's placeholder) shows wins, losses and draws against the computer for each difficulty; a computer game is recorded when it ends by no legal moves, resignation (a loss for the player) or a draw rule; two-player games and abandoned games are not recorded; undo does not change how a game counts; with no games recorded the screen shows an empty state explaining how to get a record; the record cannot be reset in this release. All data stays on the device. The new and changed screens meet the accessibility gates (VoiceOver, Dynamic Type to the largest size, Dark Mode, the audit). Requirement IDs: FR-SAVE-01 to FR-SAVE-05, FR-STAT-01 to FR-STAT-05, FR-END-08, FR-NAV-02, FR-NAV-03, FR-SETUP-04, FR-SETUP-05, FR-UNDO-08, FR-A11Y-04, FR-PRIV-01. Board features: F5.1 Auto-save and resume (#121), F5.2 Statistics (#128)."

## Clarifications

### Session 2026-10-22

- Q: If the app is interrupted in the middle of a turn, what should Continue bring back? → A: The
  player's unfinished capture chain is kept as it was (the same piece must keep jumping, and Undo
  can take it back); the computer's turn restarts from its beginning, so it thinks again and plays
  its whole turn, possibly a different move of the same strength.
- Q: How should the app tell the player that their previous game could not be restored? → A: One
  alert on Home when the app finds the save unreadable ("Your previous game couldn't be restored."
  with OK), shown once and never again for that save.
- Q: If the record of wins, losses and draws can't be read, what should the app do? → A: The record
  starts again from zero, the failure is logged, and nothing is shown to the player.

## User Scenarios & Testing *(mandatory)*

Users are players of either kind the app already serves: two people sharing the phone, and a
single player against the computer, from beginners to experienced casual players, including
VoiceOver users. This slice builds on the rules engine (E2), the game screen (E3), the VoiceOver
board (E7) and the computer opponent (E4).

### User Story 1 - Continue where I left off (Priority: P1)

A player can leave a game at any moment, go to Home, switch to another app or close the app, and
later pick the same game up from Home with Continue, exactly as it was: the same position, whose
turn it is, the same opponent and difficulty, and the same undo history. Against the computer, if
it was the computer's turn, the computer then makes its move. The player never saves by hand.
(#121: #122, #123, #124, #125, #189; FR-SAVE-01 to FR-SAVE-04, FR-NAV-02, FR-NAV-03)

**Why this priority**: Checkers games are interrupted all the time on a phone. Without saving,
every interruption loses the game, and E3 had to warn the player before leaving.

**Independent Test**: Play a few turns, choose Home, close the app from the app switcher, reopen it
and choose Continue: the game is identical, and undo still goes back through the earlier turns.

**Acceptance Scenarios**:

1. **Given** a game in progress, **When** a turn ends, **Then** the game is saved without any
   action from the player.
2. **Given** a game in progress, **When** the player chooses Home from the game menu, **Then** Home
   appears at once, without a confirmation, and offers Continue.
3. **Given** a saved game, **When** the app is closed by the player or the system and opened again,
   **Then** it opens on Home, which offers Continue.
4. **Given** a saved game, **When** the player chooses Continue, **Then** the game screen shows the
   same position, side to move, opponent, difficulty and orientation as when it was saved, and Undo
   takes back the same turns it would have taken back then.
5. **Given** a game against the computer saved while it was the computer's turn, **When** the player
   chooses Continue, **Then** the computer thinks and makes its move as usual.
6. **Given** a game in progress, **When** the app goes to the background in the middle of a turn,
   **Then** the game is saved, and Continue later returns to it.
7. **Given** no saved game, **When** Home appears, **Then** it offers New game, Statistics, Rules and
   Settings, and no Continue.

---

### User Story 2 - Start a new game without losing one by accident (Priority: P2)

Starting a new game while a saved game exists asks first, so the player never throws away a game
by mistake; a finished game is never kept as the saved game, so Continue only ever leads to a game
that can still be played. (#121: #72, #127, #189; FR-SETUP-04, FR-SETUP-05, FR-END-08)

**Why this priority**: Once games are saved, a new game replaces the saved one, so the player must
confirm; after a game ends, Continue would lead nowhere useful.

**Independent Test**: With a saved game, start a new game from setup, cancel, and check the saved
game is intact; start again and confirm, and check the old game is gone and not in the record.
Finish a game and check Continue is gone.

**Acceptance Scenarios**:

1. **Given** a saved game, **When** the player chooses Start in Game setup, **Then** the app asks
   "Abandon current game?" before starting.
2. **Given** that question, **When** the player cancels, **Then** they stay in Game setup with their
   choices, and the saved game is still there to Continue.
3. **Given** that question, **When** the player confirms, **Then** the new game starts, the old game
   can no longer be continued, and the record is unchanged.
4. **Given** no saved game, **When** the player chooses Start, **Then** the game starts at once.
5. **Given** a game that has just ended, **When** the player returns to Home, **Then** Continue is not
   offered, and Play again starts the next game without asking.

---

### User Story 3 - See my record against the computer (Priority: P2)

A player who plays the computer can see how they are doing: the Statistics screen shows their
wins, losses and draws at each difficulty. Every finished game against the computer counts once;
games between two players, abandoned games and taken-back moves do not change it. Before the first
finished game, the screen explains how the record starts. (#128: #129, #130, #131; FR-STAT-01 to
FR-STAT-05, FR-UNDO-08)

**Why this priority**: The record gives a reason to keep playing and to try a harder level; the
game itself works without it.

**Independent Test**: Finish computer games at each difficulty with each kind of ending, plus a
two-player game and an abandoned game, and compare the Statistics screen with the expected counts.

**Acceptance Scenarios**:

1. **Given** no finished game against the computer, **When** the player opens Statistics, **Then** it
   shows an empty state explaining that finishing a game against the computer starts the record.
2. **Given** the player wins a game against the computer at Medium, **When** they open Statistics,
   **Then** Medium shows one more win.
3. **Given** the player resigns, or has no legal move, in a game against the computer, **When** they
   open Statistics, **Then** that difficulty shows one more loss.
4. **Given** a game against the computer ends in a draw by repetition or by the no-progress rule,
   **When** the player opens Statistics, **Then** that difficulty shows one more draw.
5. **Given** a two-player game ends, or a game is abandoned, **When** the player opens Statistics,
   **Then** nothing has changed.
6. **Given** a game against the computer in which the player used Undo, **When** it ends, **Then** it
   counts once, by how it ended.
7. **Given** a game against the computer that was left and continued later, **When** it ends,
   **Then** it counts once, at the difficulty it was played at.

---

### User Story 4 - A saved game that cannot be restored (Priority: P3)

If the saved game cannot be read, for example because it was damaged, the app does not fail: it
discards it, does not offer Continue, and tells the player once that the previous game could not
be restored. Everything else works as usual. (#121: #126; FR-SAVE-05)

**Why this priority**: Rare, but without it a damaged save could crash the app or leave a Continue
that does nothing.

**Independent Test**: Replace the saved game with damaged data, open the app, and check that Home
shows the alert once, offers no Continue, and that new games and Statistics work.

**Acceptance Scenarios**:

1. **Given** a saved game that cannot be read, **When** the app opens, **Then** Home shows an alert
   that the previous game could not be restored, and no Continue.
2. **Given** that alert was dismissed, **When** the player returns to Home later, **Then** it does
   not appear again.
3. **Given** a saved game that cannot be read, **When** the player starts a new game, **Then** it
   starts without asking "Abandon current game?".

---

### Edge Cases

- **The system ends the app in the background**: the game saved when it went to the background is
  the one Continue restores.
- **The app goes to the background while the computer thinks or plays out its chain**: the game is
  saved as it was at the start of the computer's turn; after Continue the computer plays that turn
  again from the start, and may choose a different move of the same strength.
- **The app goes to the background in the middle of the player's own capture chain**: the game is
  saved with the chain unfinished; after Continue the same piece must go on jumping, and Undo takes
  the partial chain back, as before the interruption.
- **The computer's turn ends the game while the app is in the background**: the game counts in the
  record, and Continue is not offered.
- **The app is ended while the result panel shows**: the game was recorded when it ended; the app
  reopens on Home without Continue.
- **Continue, then Home at once**: the game stays saved, unchanged.
- **Rules or Settings open over the game when the app goes to the background**: the game is saved;
  Continue opens the game screen.
- **A two-player game is saved and continued**: it works the same way and is never recorded.
- **Saving fails** (for example, the device is full): play goes on; the next save tries again; the
  failure is logged. The player is not interrupted.
- **The record cannot be read**: the record starts again from zero; the failure is logged, and the
  player is not told (FR-020, Clarifications).
- **Undo after the game ends**: unavailable (FR-UNDO-06), so the record cannot change.

## Requirements *(mandatory)*

### Functional Requirements

**Saving (#121: #122, #123, #124)**

- **FR-001**: The app MUST save the game in progress automatically whenever a turn ends and when the
  app leaves the foreground, in two-player games and games against the computer. The player never
  saves by hand (FR-SAVE-01).
- **FR-002**: The app MUST keep at most one saved game; each save replaces the previous one
  (FR-SAVE-02).
- **FR-003**: The saved game MUST hold everything needed to continue it exactly: the position, the
  side to move, the player's unfinished capture chain if any, the opponent, the difficulty, the
  player's side against the computer, the full undo history and the draw-rule counters
  (FR-SAVE-03).
- **FR-004**: A game saved during the computer's turn MUST be saved as it was at the start of that
  turn, so that none of the computer's turn is kept half-played.
- **FR-005**: The saved game MUST survive the app being closed, ended by the system or updated, and
  the device restarting.
- **FR-006**: When a game ends, it MUST stop being the saved game (FR-END-08).

**Continue (#121: #125, #189)**

- **FR-007**: Home MUST offer Continue when, and only when, a saved game exists (FR-NAV-02). The app
  still opens on Home (FR-NAV-01).
- **FR-008**: Continue MUST open the game screen with the saved game exactly as it was saved: board,
  side to move, any unfinished chain, opponent, difficulty, the player's side at the bottom, and the
  same undo history and draw-rule counters (FR-SAVE-03).
- **FR-009**: If it is the computer's turn in the continued game, the computer MUST start its turn
  when the game screen appears, with the usual thinking pause, and play it (FR-SAVE-04).
- **FR-010**: Choosing Home during an unfinished game MUST return to Home at once, without the
  confirmation E3 added (E3's FR-042); the game stays the saved game (FR-NAV-03).
- **FR-011**: Continuing a game MUST NOT change the setup choices Game setup remembers
  (FR-SETUP-03).

**Starting a new game (#121: #72, #127)**

- **FR-012**: When a saved game exists, Start in Game setup MUST first ask "Abandon current game?"
  Confirming discards the saved game and starts the new one; cancelling stays in Game setup with the
  saved game intact (FR-SETUP-04).
- **FR-013**: An abandoned game MUST NOT change the record (FR-SETUP-05).
- **FR-014**: Without a saved game, Start and Play again MUST start the game at once, as before.

**A saved game that cannot be read (#121: #126)**

- **FR-015**: If the saved game cannot be read, or does not describe a valid game, the app MUST
  discard it, MUST NOT offer Continue, and MUST tell the player once, with an alert on Home, that
  the previous game could not be restored (FR-SAVE-05). The alert has a single OK button and does
  not appear again for that save. The app otherwise works as usual.

**The record (#128: #129)**

- **FR-016**: The app MUST keep a record of games against the computer: the player's wins, losses
  and draws, separately for Easy, Medium and Hard (FR-STAT-01).
- **FR-017**: A game against the computer MUST be recorded once, when it ends: a win when the
  computer is left without a legal move; a loss when the player is left without a legal move or
  resigns; a draw when a draw rule ends it (FR-STAT-02). It counts at the difficulty it was played
  at, also after being continued.
- **FR-018**: Two-player games, abandoned games and games still in progress MUST NOT be recorded
  (FR-STAT-03).
- **FR-019**: Undo MUST NOT change how a game counts: only its final result is recorded
  (FR-UNDO-08).
- **FR-020**: The record MUST persist on the device and MUST NOT be resettable in this release
  (FR-STAT-05). If the record cannot be read, it MUST start again from zero, with the failure logged
  and no message to the player.

**The Statistics screen (#128: #130)**

- **FR-021**: Statistics, opened from Home, MUST replace E3's placeholder and show wins, losses and
  draws for each of Easy, Medium and Hard (FR-STAT-01). Once any game is recorded, a difficulty
  without games shows zeros.
- **FR-022**: With no game recorded, Statistics MUST show an empty state that explains how to get a
  record: finish a game against the computer (FR-STAT-04).
- **FR-023**: Statistics MUST NOT offer a way to reset or edit the record (FR-STAT-05).

**Privacy**

- **FR-024**: The saved game and the record MUST stay on the device: no network requests, no
  account, no analytics (FR-PRIV-01). The app MUST NOT ask for any permission (FR-PRIV-02).

**Accessibility (#128: #131)**

- **FR-025**: VoiceOver MUST read each difficulty's results on Statistics as one element (for
  example "Easy: 3 wins, 1 loss, 2 draws"), the empty state as text, and Continue, the abandon
  question and the unreadable-save alert like any other button or alert (FR-A11Y-04).
- **FR-026**: Statistics (empty and with a record), Home with Continue, the abandon question and the
  unreadable-save alert MUST support Dynamic Type up to the largest accessibility size, render
  correctly in Dark Mode, and pass the automated accessibility audit (FR-A11Y-04).

### Traceability

| Board task | Requirements | FRD |
|---|---|---|
| #122 Game snapshot | FR-003, FR-004 | FR-SAVE-03 |
| #123 Saved-game store | FR-002, FR-005, FR-024 | FR-SAVE-02, FR-PRIV-01 |
| #124 Save after every turn and on background | FR-001, FR-004 | FR-SAVE-01 |
| #125 Continue restores exactly; computer resumes | FR-008, FR-009, FR-011 | FR-SAVE-03, FR-SAVE-04 |
| #126 Unreadable save | FR-015 | FR-SAVE-05 |
| #127 Clear the saved game on end and abandon | FR-006, FR-012 | FR-END-08, FR-SETUP-04 |
| #189 Continue on Home only with a saved game | FR-007, FR-010 | FR-NAV-02, FR-NAV-03 |
| #72 "Abandon current game?" | FR-012, FR-013, FR-014 | FR-SETUP-04, FR-SETUP-05 |
| #129 Record model and recording rules | FR-016 to FR-020 | FR-STAT-01 to 03, FR-STAT-05, FR-UNDO-08 |
| #130 Statistics screen with empty state | FR-021, FR-022, FR-023 | FR-STAT-01, FR-STAT-04, FR-STAT-05 |
| #131 Accessibility pass: Statistics | FR-025, FR-026 | FR-A11Y-04 |

Covered elsewhere: Settings, sound, themes and the Rules screen (E6); measuring launch time on a
real iPhone (E8, #181).

### Key Entities

- **Saved game**: the one unfinished game the app keeps: the game state (position, side to move,
  any unfinished chain of the player, undo history, draw-rule counters) plus the opponent, the
  difficulty and the player's side.
- **Record**: for each difficulty, how many games against the computer the player has won, lost and
  drawn.
- **Game result**: how a finished game against the computer counts: win, loss or draw, from the
  player's view, at its difficulty.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In scripted games of both kinds, a game saved after any turn, and while the app goes to
  the background at any point of a turn, continues identically in 100% of cases: position, side to
  move, chain, opponent, difficulty, the player's side, undo history and draw-rule counters.
- **SC-002**: After the app was closed, a player gets back to their game in two taps or fewer from
  opening the app (Continue on Home), and the game screen appears within 1 second.
- **SC-003**: In every tested game saved during the computer's turn, the computer makes exactly one
  turn after Continue, and the game is otherwise unchanged.
- **SC-004**: For every way a game against the computer can end, at each difficulty, the record
  changes by exactly one in the right place; two-player games, abandoned games, undos and leaving
  and continuing change it by nothing else (100% of scripted cases).
- **SC-005**: With an unreadable saved game (empty, cut short, random data, or from an unknown
  version), the app opens on Home in 100% of cases, never offers Continue, and shows the alert
  exactly once.
- **SC-006**: Saving never slows the game down: moves appear at the same pace as without saving, with
  no pause a player can notice (under 100 ms).
- **SC-007**: The automated accessibility audit passes on Home with Continue and on Statistics with
  and without a record, and the new screens stay usable at the largest accessibility text size in
  Dark Mode.
- **SC-008**: Every FRD requirement ID of this slice is named by at least one automated test.

## Assumptions

- **Where a game is saved during a turn** (confirmed in Clarifications): during the computer's turn
  the game is saved as it was at the start of that turn (FR-004), so the computer plays its whole
  turn again after Continue (it may choose a different move of the same strength, since it picks at
  random among equally good ones). During the player's own capture chain the game is saved with the
  chain unfinished, because that is the exact state and Undo can take it back (FR-003).
- **The unreadable-save alert** (confirmed in Clarifications): a one-time alert on Home, "Your
  previous game couldn't be restored." with OK; the plan's contracts fix the exact text.
- **The abandon question**: the title is the FRD's "Abandon current game?"; it is asked when the
  player chooses Start in Game setup (as the FRD says), not when they choose New game on Home, so
  they can still look at the setup without losing anything. Its buttons are a destructive
  confirmation and Cancel.
- **Statistics content**: exactly what the FRD names: wins, losses and draws per difficulty; no
  totals, percentages, streaks or game history.
- **An unreadable record** (confirmed in Clarifications): the FRD gives no rule; the record starts
  again from zero and the failure is logged, without a message, since nothing can be done about it
  and the record cannot be reset anyway.
- **Leaving a game**: E3's leave confirmation (FR-042) was a stopgap until saving existed; with
  saving, leaving keeps the game, as FR-NAV-03 says.
- **What counts as "abandoned"**: a game the player discards by confirming "Abandon current game?".
  A game left for Home is not abandoned: it stays saved and counts when it ends.
- **First release only**: the record counts games finished from this release on; the app keeps no
  older history. Data lives only in the app's own storage, which the system may include in the
  user's device backups; the app itself sends nothing anywhere.
