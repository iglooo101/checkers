# Contract: Square descriptions, announcements and audited screens

What VoiceOver says on the board and after each event, exact English texts (all from the String
Catalog), focus rules, and the screens the accessibility audit checks. Types are in
[../data-model.md](../data-model.md); E3's screens and identifiers in
`specs/003-game-experience/contracts/screens.md`.

## Square descriptions (FR-001, FR-002)

The label of the square at coordinate `c` (named from Light's side), by contents and state:

| Contents | `none` | `canMove` | `selected` | `legalTarget` |
|---|---|---|---|---|
| Empty | "c, empty" | — | — | "c, empty, legal target" |
| Light man | "c, Light man" | "c, Light man, can move" | "c, Light man, selected" | — |
| Light king | "c, Light king" | "c, Light king, can move" | "c, Light king, selected" | — |
| Dark man | "c, Dark man" | "c, Dark man, can move" | "c, Dark man, selected" | — |
| Dark king | "c, Dark king" | "c, Dark king, can move" | "c, Dark king, selected" | — |

The selected square also carries the selected trait. States follow `SquareState` (data model)
whatever the hints setting.

## When to announce (FR-006 to FR-010)

| Event | Announcement |
|---|---|
| A step is applied (tap, VoiceOver double-tap or drop) | "<what happened> <what follows>" (below) |
| The "capture required" notice appears | "A capture is required." |
| Undo | "Move undone. <side> to move." (with ", capture required" when it applies) |
| Resign confirmed | The result sentence |
| A selection changes, a drag starts, a menu or screen opens | Nothing (the squares' labels say it) |

## What happened (FR-007)

| Step | Light | Dark |
|---|---|---|
| Simple move | "Light c3 to d4." | "Dark f6 to e5." |
| Jump | "Light captures d4." | "Dark captures d4." |
| Simple move that crowns | "Light g7 to h8, crowned." | "Dark b2 to a1, crowned." |
| Jump that crowns | "Light captures c7, crowned on d8." | "Dark captures f2, crowned on e1." |

The coordinates are the step result's `from`, `to` and `captured`.

## What follows (FR-008, FR-009)

| After the step | Sentence |
|---|---|
| The chain continues | "Jump again." |
| The turn passes | "Light to move." / "Dark to move." |
| The turn passes and the next side must capture | "Light to move, capture required." / "Dark to move, capture required." |
| The game ended | The result sentence of the result panel ("Dark wins: no moves left", "Draw by repetition", …) |

Example: "Light captures d4. Dark to move, capture required."

## Focus (FR-005)

After a step, VoiceOver focus moves to the step's landing square (`focusSquare`). Undo and Play
again clear it; selecting a piece does not move focus.

## Audited screens (FR-017)

| Screen | State | Reached by |
|---|---|---|
| Home | as launched | launch |
| Game setup | Two players chosen | `home.newGame`, Two players |
| Game setup | Computer chosen (difficulty, side, note) | `home.newGame`, Computer |
| Game | new game | `startTwoPlayerGame()` |
| Game | a piece selected | tap `square.c3` |
| Game | "capture required" notice shown | `c3–d4`, `f6–e5`, tap `square.e3` |
| Game | result panel | menu Resign, confirm |
| Statistics, Rules, Settings | placeholder | from Home |

Each audit runs with all audit types and must report no problem; exceptions follow the plan's
allow-list.
