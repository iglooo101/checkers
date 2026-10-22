# Contract: screens, texts and identifiers (E5 changes)

Changes to `specs/003-game-experience/contracts/screens.md` for saving and statistics. Texts are
English, from the String Catalog; identifiers are for UI tests. Behavior is in
[saved-game.md](saved-game.md).

## Home (FR-007, FR-015)

| Element | Text | Identifier |
|---|---|---|
| Button, prominent (only with a saved game) | Continue | `home.continue` |
| Button, prominent without a saved game, bordered with one | New game | `home.newGame` |
| Buttons (unchanged) | Statistics, Rules, Settings | `home.statistics`, `home.rules`, `home.settings` |
| Alert (once, after an unreadable save) | Your previous game couldn't be restored. · OK | `home.restoreFailure.ok` |

Continue comes first when shown.

## Game setup (FR-012 to FR-014)

| Element | Text | Identifier |
|---|---|---|
| Alert after Start, only with a saved game | Abandon current game? · Starting a new game discards the game in progress. · Abandon (destructive) · Cancel | `setup.abandon.confirm`, `setup.abandon.cancel` |

Cancel keeps the setup screen and its choices.

## Game screen (FR-010)

| Element | Change |
|---|---|
| Menu item Home | Returns to Home at once; the game stays saved |
| Leave alert | **Removed**, with its texts ("Leave this game?", "It can't be resumed yet.", "Leave") and identifiers |

## Statistics (FR-021 to FR-023, FR-025)

Replaces the placeholder (its message "Your wins, losses and draws against the computer will appear
here." is removed from the String Catalog).

| Element | Text | Identifier |
|---|---|---|
| Title | Statistics | — |
| Empty state (no game recorded) | No games yet. · Finish a game against the computer to start your record. | `statistics.empty` |
| One block per difficulty, in order | Easy / Medium / Hard, then "%lld wins", "%lld losses", "%lld draws" on three lines (plural variants: "1 win", "1 loss", "1 draw") | `statistics.easy`, `statistics.medium`, `statistics.hard` |
| VoiceOver label of a block (one element) | "Easy: 3 wins, 1 loss, 2 draws" | as above |

No buttons. All text is primary text; blocks stack vertically and scroll at large text sizes.

## Audited states (FR-026, SC-007)

Added to `US5AccessibilityAuditUITests`: Home with Continue; Statistics empty; Statistics with a
record; the restore-failure alert and the abandon alert are system alerts and are checked by their
UI tests. The Statistics placeholder audit becomes the Statistics audits.
