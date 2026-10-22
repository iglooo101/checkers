# Contract: the computer's turn on the game screen

How `GameSession` and `AppRouter` play the computer's turns, extending
`specs/003-game-experience/contracts/game-session.md` and `screens.md`, and
`specs/004-accessibility/contracts/announcements.md`. Two-player games are unchanged.

## Timeline (FR-005 to FR-010, FR-017)

| # | When | What happens |
|---|---|---|
| 1 | The player's turn ends and the game is in progress; or a game starts (Start, Play again) with the computer to move | `computerPhase = .thinking`; selection, notice and hints cleared; the turn indicator shows the thinking sentence |
| 2 | Thinking | `opponent.chooseTurn` and `pacer.pause(0.5 s)` run together; the first step waits for both (FR-008) |
| 3 | Before every step | If `isCovered`, wait until the game screen is visible again, then `pacer.pause(0.5 s)` (FR-017) |
| 4 | First step | `state.apply`; announced (below); if the chain continues, `computerPhase = .playing` |
| 5 | Each further jump | `pacer.pause(0.5 s)`, step 3, then `state.apply` and its announcement (FR-009) |
| 6 | Last step applied | `computerPhase = .idle`; the player's turn begins, or the result panel shows (FR-010) |

After every wait the task checks for cancellation before touching the state. If the opponent
returns no turn while the game is in progress, the error is logged and the first legal turn is
played (R14).

## Cancelling (FR-015, FR-016, FR-020)

| Event | Effect on the computer's turn |
|---|---|
| Undo | Cancelled, then undo as below |
| Resign confirmed | Cancelled, then the player resigns |
| Leave confirmed, or a new session replaces this one | Cancelled; the session is dropped |
| Rules or Settings opened | Not cancelled: thinking continues, steps wait (timeline step 3) |
| Resign or leave alert shown, then cancelled | Not affected: the turn continues while the alert is up |

A cancelled turn never applies another step.

## Input during the computer's turn (FR-007)

| Input | Effect |
|---|---|
| Tap, VoiceOver activation | Nothing; no notice |
| Drag | Not accepted; the piece stays |
| `hintedPieces`, `targets` | Empty |
| `state(of:)` | `none` for every square |
| Menu | Opens; Undo, Resign, Rules, Settings, Home work (FR-014) |

## Undo in a computer game (FR-018 to FR-022, research R9)

| Action | Rule |
|---|---|
| `undo()` | Cancel the computer's turn; then `state.undo()` at least once and until `sideToMove == playerSide`; selection, notice and focus cleared; announce "Move undone." with the player's turn |
| `canUndo` | The same rule on a copy of the state reaches the player's turn: false before the player's first move (also when the computer opened as Light) and once the game is over |

| Situation | Turns taken back |
|---|---|
| Player's turn, after the computer's reply | The computer's reply and the player's last turn |
| Computer thinking | The player's last turn |
| Computer between jumps of its chain | The partial chain and the player's last turn |
| Player in the middle of their own chain | The partial chain only |

## Announcements and focus (FR-023 to FR-026)

| Computer step | Announcement |
|---|---|
| Continues the chain | The step sentence only: "Dark captures e5." |
| Ends the turn | The step sentence and the player's turn: "Dark c5 to d4. Light to move." / "… Light to move, capture required." |
| Ends the game | The step sentence and the result: "Dark captures c3. Dark wins: no moves left" |
| Crowns (ends the turn) | E7's crowning sentence and the player's turn: "Dark b2 to a1, crowned. Light to move." / "Dark captures b2, crowned on a1. Light to move." |

`focusSquare` does not change during the computer's turn.

## Screen texts and identifiers (additions to screens.md)

| Element | Text | Identifier |
|---|---|---|
| Turn indicator while the computer's turn lasts | "Light is thinking…" / "Dark is thinking…" | `game.turn` |
| Activity indicator beside it (hidden from VoiceOver) | — | `game.thinking` |
| Game setup, Computer chosen | No note; Start available | `setup.start` |

The setup note "Games against the computer arrive in a later update." (`setup.computerNote`) is
removed from the screen and the String Catalog.

## Router (FR-001 to FR-003, FR-016, FR-017)

| Action | Effect |
|---|---|
| `startGame()` | Save the setup (FR-003); open the game; `startComputerTurnIfNeeded()` |
| `playAgain()` | Cancel the old session's turn; new session; `startComputerTurnIfNeeded()` |
| `path` changes | `session.setCovered(path.last != .game)` |
| `confirmLeave()` | `cancelComputerTurn()`, then pop to Home and drop the session |
| Setup changes | Not saved until a game starts |

## Audited states (FR-027, R12)

Game setup with Computer chosen (Start available); a computer game on the player's turn; a
computer game with the result panel. The thinking header is checked by a UI test while the
computer thinks and by previews at the largest text size and in Dark Mode.
