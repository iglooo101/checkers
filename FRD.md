# Functional Requirements Document: Checkers

Version 1.2 · 2026-10-22

Changes in 1.2: FR-STAT-06 added: an unreadable record starts again from zero and the player is
told once.

Changes in 1.1: the first release is iPhone only (FR-PLAT-01 reworded, FR-PLAT-02 removed,
iPad added to section 19).

## 1. Purpose and scope

This document specifies how a player interacts with the Checkers app for iPhone: what they
see, what they can do, and how the app responds. It describes the target product, not the
current prototype. Implementation decisions (architecture, AI algorithm, storage format) belong in
feature plans and must satisfy the project constitution (`.specify/memory/constitution.md`).

Requirements use **MUST** for mandatory behavior and **SHOULD** for strong recommendations. Each
requirement has an ID (for example `FR-MOVE-03`) so specs, plans and tests can reference it.

## 2. Product summary

- A single player plays American checkers against the computer at one of three difficulty levels,
  or two players take turns on one device.
- The app is fully offline. It has no accounts, no online play and no analytics.
- The first release ships in English on iPhone, in portrait only.

## 3. Glossary

| Term | Meaning |
|---|---|
| Light / Dark | The two sides. Light moves first. |
| Man | An uncrowned piece. It moves and captures diagonally forward only. |
| King | A crowned piece. It moves and captures one square diagonally in any direction. |
| Capture chain | A sequence of one or more jumps made by one piece in one turn. |
| Movable piece | A piece of the side to move that has at least one legal move. |
| Saved game | The single unfinished game the app keeps for resuming. |
| Record | The player's win/loss/draw totals against the computer. |

## 4. Screens and navigation

```
Home
 ├── Continue ───────────────► Game
 ├── New game ─► Game setup ─► Game ─► Result panel ─► Play again / Home
 ├── Statistics
 ├── Rules
 └── Settings
```

- **FR-NAV-01** The app MUST open on the Home screen.
- **FR-NAV-02** Home MUST offer New game, Statistics, Rules and Settings. It MUST also offer
  Continue, but only when a saved game exists.
- **FR-NAV-03** The Game screen MUST let the player return to Home at any time. Leaving does not end
  the game; it stays the saved game.
- **FR-NAV-04** Rules and Settings MUST also be reachable from the Game screen's menu, and returning
  from them MUST bring the player back to the same game position.

## 5. Starting a game

- **FR-SETUP-01** New game MUST open Game setup, where the player chooses the opponent:
  **Computer** or **Two players**.
- **FR-SETUP-02** With Computer, the player MUST choose a difficulty (**Easy**, **Medium**,
  **Hard**) and a side (**Light**, **Dark**, **Random**).
- **FR-SETUP-03** Game setup MUST preselect the opponent, difficulty and side used in the previous
  game. On first use the defaults are Computer, Easy and Light.
- **FR-SETUP-04** If a saved game exists, starting a new game MUST first ask "Abandon current
  game?" Confirming discards the saved game; cancelling returns to setup with the saved game
  intact.
- **FR-SETUP-05** An abandoned game MUST NOT change the record.
- **FR-SETUP-06** Every game MUST start from the standard American checkers position: 12 men per
  side on the dark squares of the three rows nearest each player, with Light to move.

## 6. The game screen

- **FR-GAME-01** The Game screen MUST show the board and a turn indicator. It shows no other game
  information, such as piece counts, a move list or timers.
- **FR-GAME-02** The turn indicator MUST state whose turn it is ("Light to move", "Dark to move").
  When a capture is mandatory it MUST say so ("Light to move · capture required").
- **FR-GAME-03** Against the computer, the player's own pieces MUST be at the bottom of the board,
  even when the player is Dark.
- **FR-GAME-04** In a two-player game, Light MUST be at the bottom, and the board MUST NOT rotate
  between turns.
- **FR-GAME-05** Players MUST be referred to as Light and Dark. Two-player games have no name
  entry.
- **FR-GAME-06** The Game screen menu MUST offer Undo, Resign, Rules, Settings and Home.
- **FR-GAME-07** The board MUST be drawn in the board theme selected in Settings (see
  FR-SET-02).

## 7. Making moves

### 7.1 Selecting and moving

- **FR-MOVE-01** The player MUST be able to move by **tapping** a piece and then tapping a target
  square.
- **FR-MOVE-02** The player MUST also be able to move by **dragging** a piece onto a target square.
  Dropping it anywhere other than a legal target returns the piece to its square with no move
  made.
- **FR-MOVE-03** Tapping one of the player's movable pieces MUST select it. Tapping another movable
  piece switches the selection. Tapping the selected piece again, or any square that is not a legal
  target, clears the selection.
- **FR-MOVE-04** Only pieces of the side to move can be selected. During the computer's turn the
  board MUST NOT accept input.
- **FR-MOVE-05** If a capture is mandatory and the player taps a piece that cannot capture, the app
  MUST tell them a capture is required and MUST NOT select that piece.

### 7.2 Move aids

- **FR-AID-01** When the move hints setting is on, the board MUST highlight every movable piece of
  the side to move. When a capture is mandatory, only pieces that can capture are highlighted.
- **FR-AID-02** When the move hints setting is on and a piece is selected, the board MUST highlight
  its legal target squares.
- **FR-AID-03** The selected piece MUST always be visibly marked, whether hints are on or off.
- **FR-AID-04** Move hints MUST be on by default.

### 7.3 Capture chains

- **FR-CHAIN-01** A multi-jump capture MUST be entered **one jump at a time**. After each jump the
  piece stays on its landing square, and the captured piece is removed.
- **FR-CHAIN-02** After a jump, if the same piece can jump again, the turn MUST continue with that
  piece selected. Only its next legal jumps are shown as targets (when hints are on), and no other
  piece can be selected.
- **FR-CHAIN-03** The turn MUST end when the moving piece has no further jump or when a man reaches
  the far row and is crowned.

## 8. Rules (American checkers)

- **FR-RULE-01** The board MUST be 8×8, and play MUST use only the dark squares.
- **FR-RULE-02** A man MUST move one square diagonally forward onto an empty square.
- **FR-RULE-03** A man MUST capture by jumping diagonally forward over an adjacent opposing piece
  onto the empty square beyond it.
- **FR-RULE-04** A king MUST move and capture like a man, but in all four diagonal directions,
  one square at a time (no flying kings).
- **FR-RULE-05** Capturing MUST be mandatory. If any capture is available, the player MUST make a
  capture, but may choose which one. They do not have to choose the longest chain.
- **FR-RULE-06** A capture chain MUST continue while the moving piece can keep jumping
  (see FR-CHAIN-02).
- **FR-RULE-07** A man reaching the far row MUST be crowned king, and crowning MUST end the turn.

## 9. Ending a game

- **FR-END-01** **No legal moves:** A side to move that has no legal move (including having no
  pieces) MUST lose.
- **FR-END-02** **Resignation:** The player MUST be able to resign from the game menu after
  confirming. Against the computer, the human player resigns. In a two-player game, the side whose
  turn it is resigns.
- **FR-END-03** **Draw by repetition:** The game MUST end in a draw when the same position with the
  same side to move occurs for the third time.
- **FR-END-04** **Draw by no progress:** The game MUST end in a draw after 40 consecutive moves by
  each side (80 turns in total) with no capture and no man moved.
- **FR-END-05** There MUST be no draw offers and no draw by agreement.
- **FR-END-06** When a game ends, a result panel MUST appear over the board. It states the outcome
  and reason (for example "Dark wins: no moves left", "Light resigned", "Draw by repetition") and
  offers **Play again** and **Home**. The final position MUST stay visible behind it.
- **FR-END-07** Play again MUST start a new game with the same opponent, difficulty and side
  settings. For a side of Random, it assigns a new random side.
- **FR-END-08** A finished game MUST NOT be the saved game. After it ends, Continue is no longer
  offered.

## 10. Undo

- **FR-UNDO-01** The player MUST be able to undo moves repeatedly, back to the start of the game.
- **FR-UNDO-02** In a two-player game, each undo MUST take back the last turn, whichever side made
  it.
- **FR-UNDO-03** Against the computer, each undo MUST take back the player's last turn and the
  computer's reply, returning to the player's turn. Undo MUST be unavailable until the player has
  made at least one move.
- **FR-UNDO-04** If undo is used while the computer is thinking, the app MUST cancel the computer's
  turn and take back the player's last turn.
- **FR-UNDO-05** Undo during an unfinished capture chain MUST restore the position from before the
  chain began.
- **FR-UNDO-06** Undo MUST be unavailable after a game has ended.
- **FR-UNDO-07** Undo MUST restore the full game state, including the turn and the draw-rule
  counters.
- **FR-UNDO-08** Using undo MUST NOT change how the game counts in the record.

## 11. Computer opponent

- **FR-AI-01** The computer MUST play only legal moves under section 8.
- **FR-AI-02** The three difficulty levels MUST differ noticeably in strength. Easy is beatable by a
  beginner, and Hard is a challenge for an experienced casual player.
- **FR-AI-03** The computer MUST show a "thinking" indicator during its turn and MUST make its move
  after a short pause of about 0.5–1 second, even if it chose sooner.
- **FR-AI-04** The app MUST stay responsive while the computer thinks. The menu, Undo and Home MUST
  keep working.
- **FR-AI-05** When the computer plays a capture chain, the board MUST show each jump in order so
  the player can follow it.
- **FR-AI-06** If the computer plays Light, it MUST make the first move when the game starts.

## 12. Saving and resuming

- **FR-SAVE-01** The app MUST save the unfinished game automatically after every turn and when the
  app goes to the background. The player never saves manually.
- **FR-SAVE-02** The app MUST keep at most one saved game.
- **FR-SAVE-03** Continue MUST restore the saved game exactly: the position, side to move, opponent
  and difficulty, undo history and draw-rule counters.
- **FR-SAVE-04** If the game was saved during the computer's turn, the computer MUST make its move
  after the game resumes.
- **FR-SAVE-05** If a saved game cannot be read, the app MUST discard it, hide Continue and tell the
  player that the previous game could not be restored.

## 13. Statistics

- **FR-STAT-01** The Statistics screen MUST show wins, losses and draws against the computer for
  each difficulty level.
- **FR-STAT-02** A game against the computer MUST be recorded when it ends by no legal moves,
  resignation (a loss for the player) or a draw rule.
- **FR-STAT-03** Two-player games and abandoned games MUST NOT be recorded.
- **FR-STAT-04** When no game has been recorded, Statistics MUST show an empty state that explains
  how to get a record.
- **FR-STAT-05** The record cannot be reset in this release.
- **FR-STAT-06** If the record cannot be read, the app MUST start it again from zero and tell the
  player once that it could not be restored.

## 14. Settings

- **FR-SET-01** Settings MUST contain: board theme, sound effects on/off and move hints on/off.
- **FR-SET-02** Board theme MUST offer **Classic**, **Modern** and **Playful**. The default is
  Classic. Each theme option MUST show a small preview of the board.
- **FR-SET-03** Setting changes MUST take effect immediately, including in a game in progress, and
  MUST persist across launches.
- **FR-SET-04** Sound effects MUST be on by default.

## 15. Sound

- **FR-SND-01** When sound effects are on, the app MUST play distinct sounds for a move, a capture,
  a crowning and the end of a game.
- **FR-SND-02** Sounds MUST respect the device's silent mode and volume.
- **FR-SND-03** The app has no haptic feedback and no music in this release.
- **FR-SND-04** Pieces move without animation. A moved piece appears directly on its target square,
  and captured pieces disappear when they are jumped.

## 16. Rules screen

- **FR-HELP-01** A Rules screen MUST explain, briefly and with illustrations, the setup, moving,
  mandatory capture, capture chains, crowning, how a game is won and drawn, and the app's undo and
  resign options.
- **FR-HELP-02** The Rules screen MUST be reachable from Home and from the Game screen menu.

## 17. Accessibility

- **FR-A11Y-01** Every square MUST be a VoiceOver element whose label states its coordinate and
  contents. Columns are a–h from left to right and rows 1–8 from Light's side, for example
  "c3, Light man, can move" or "d4, empty, legal target".
- **FR-A11Y-02** A VoiceOver user MUST be able to move square by square: double-tap a piece to
  select it, then double-tap a target square. Capture chains continue one jump at a time.
- **FR-A11Y-03** VoiceOver MUST announce each move, including the opponent's (for example "Dark
  c5 to d4", "Light captures d4", "Light crowned on b8"), plus turn changes, mandatory captures and
  the game result.
- **FR-A11Y-04** Every screen MUST support Dynamic Type up to the largest accessibility size
  without losing essential content, MUST render correctly in Dark Mode, and MUST meet the
  constitution's accessibility gates (Principle V).
- **FR-A11Y-05** Light and dark pieces, kings, selection and hints MUST be distinguishable without
  relying on color alone in every theme.

## 18. Devices, language and privacy

- **FR-PLAT-01** The app MUST run on iPhone only, in portrait orientation, and size the board to
  fit every supported iPhone screen.
- **FR-PLAT-02** *Removed in v1.1: iPad is out of scope for the first release (see section 19).*
- **FR-PLAT-03** The first release MUST ship in English. All user-facing text MUST be localizable.
- **FR-PRIV-01** All data (saved game, record, settings) MUST stay on the device. The app MUST NOT
  make network requests, require an account or collect analytics.
- **FR-PRIV-02** The app MUST NOT request any system permission.

## 19. Out of scope

These are excluded from this release by decision:

- Online or Game Center play, achievements and leaderboards
- Rule variants other than American checkers, and rule options
- Draw offers or draw by agreement
- Game clocks and timers
- Haptics, music and move animation
- Piece counts, a move list or notation, game history and replays
- Hints that suggest moves, and an interactive tutorial
- Player names, multiple saved games and resetting statistics
- Languages other than English, iPad, and iPhone landscape
