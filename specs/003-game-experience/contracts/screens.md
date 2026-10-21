# Contract: Screens, texts and identifiers

What each screen shows, its exact English texts (all from the String Catalog) and the
accessibility identifiers UI tests use. Identifiers are not shown to players and are not
localized. Behavior behind the controls is in [game-session.md](game-session.md).

## Home (FR-001, FR-002)

| Element | Text | Identifier |
|---|---|---|
| Title | Checkers | — |
| Button | New game | `home.newGame` |
| Button | Statistics | `home.statistics` |
| Button | Rules | `home.rules` |
| Button | Settings | `home.settings` |

## Game setup (FR-007 to FR-011)

| Element | Text | Identifier |
|---|---|---|
| Title | New game | — |
| Choice | Opponent: Computer, Two players | `setup.opponent` |
| Choice (Computer only) | Difficulty: Easy, Medium, Hard | `setup.difficulty` |
| Choice (Computer only) | Side: Light, Dark, Random | `setup.side` |
| Note (Computer only) | Games against the computer arrive in a later update. | `setup.computerNote` |
| Button | Start (disabled for Computer) | `setup.start` |

## Game screen (FR-004, FR-012 to FR-018, FR-032, FR-033, FR-042)

| Element | Text | Identifier |
|---|---|---|
| Turn indicator (header) | One of the four `turnText` sentences | `game.turn` |
| Notice | A capture is required. | `game.notice` |
| Board | — (contains the squares) | `board` |
| Square (button) | VoiceOver label "c3, Light man", "c3, Light king", "c3, Dark man", "c3, Dark king" or "c3, empty"; selected trait when selected | `square.c3` (one per dark square) |
| Menu button | Game menu | `game.menu` |
| Menu items (in progress) | Undo (disabled when unavailable), Resign, Rules, Settings, Home | `game.menu.undo`, `game.menu.resign`, `game.menu.rules`, `game.menu.settings`, `game.menu.home` |
| Menu items (over) | Rules, Settings, Home | as above |
| Resign alert | Resign as Light? / Resign as Dark? · Resign (destructive) · Cancel | `game.resign.confirm`, `game.resign.cancel` |
| Leave alert | Leave this game? · It can't be resumed yet. · Leave (destructive) · Cancel | `game.leave.confirm`, `game.leave.cancel` |
| Result panel | One of the six `resultText` sentences · Play again · Home | `result.panel`, `result.text`, `result.playAgain`, `result.home` |

Light squares are drawn but are not accessibility elements and accept no input.

## Placeholder screens (FR-003)

| Screen | Title | Message (`placeholder.message`) |
|---|---|---|
| Statistics | Statistics | Your wins, losses and draws against the computer will appear here. |
| Rules | Rules | How to play American checkers will be explained here. |
| Settings | Settings | Board theme, sound effects and move hints will be set here. |

## Layout rules (FR-039, SC-003)

- The board is square, inset 8 points, and as large as the space left by the turn indicator and
  notice allows; it never scrolls or clips.
- At accessibility text sizes, texts wrap instead of truncating; Home, setup, the result panel and
  placeholder screens scroll when their content is taller than the screen.
- Every color is an asset-catalog color with light and dark variants (Constitution V.1); the board
  uses the Classic colors from `Classic.html` (research, Environment facts).
