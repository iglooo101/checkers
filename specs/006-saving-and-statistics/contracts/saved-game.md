# Contract: saved game and record

What is stored, when, and how it is read back. Types are in [../data-model.md](../data-model.md).
Everything stays on the device (FR-024).

## Format (version 1)

Two JSON values in `UserDefaults.standard`, beside E3's `lastGameSetup`:

| Key | Value |
|---|---|
| `savedGame` | `{"version": 1, "setup": {…E3's GameSetup…}, "playerSide": "light" \| "dark" \| null, "state": {…GameState…}}` |
| `record` | `{"version": 1, "easy": {"wins": n, "losses": n, "draws": n}, "medium": {…}, "hard": {…}}` |

`GameState` (encoded by the engine):

```json
{
  "position": {"light": 4095, "dark": 4293918720, "kings": 0},
  "sideToMove": "light",
  "chainSquare": null,
  "outcome": "inProgress",
  "noProgressCount": 0,
  "turns": [{"position": {…}, "sideToMove": "dark", "noProgressCount": 0}]
}
```

`outcome` is `"inProgress"`, `{"win": {"winner": "light", "reason": "noMovesLeft" | "resignation"}}`
or `{"draw": "repetition" | "noProgress"}`. A test keeps a version 1 fixture of each value, so any
change to the format fails a test; a new format means a new version.

## Validity

Decoding a `GameState` fails unless all of these hold:

| Rule | Why |
|---|---|
| Light and Dark occupy no common square; every king is on an occupied square | A position the board can show |
| `noProgressCount` is 0–80, and below 80 while in progress | FR-END-04 |
| A chain square holds a piece of the side to move, which has a jump from there, and the game is in progress | Only a chain in progress can be resumed |
| In progress: the side to move has a legal step, and the position has not occurred three times with the same side to move | Otherwise the game would already be over |
| Every turn record is a valid position with a no-progress count of 0–79 | Undo restores them |

A saved game is also unreadable when its JSON does not decode, its `version` is not 1, or its
state is not in progress.

## Stores

| Store | Rule |
|---|---|
| `SavedGameStore.load()` | No value → `nil`; a value that is unreadable by the rules above → throws `.unreadable` |
| `SavedGameStore.save(_:)` | Replaces the value; an encoding failure is logged and leaves the old value |
| `SavedGameStore.clear()` | Removes the value |
| `RecordStore.load()` | No value → an empty record; a value that does not decode or whose `version` is not 1 → throws `.unreadable`, logged |
| `RecordStore.save(_:)` | Replaces the value; a failure is logged |

## Save points

| When | What the router does |
|---|---|
| A turn ends, of either side, the game going on (session event `saved`) | Saves the session's snapshot |
| Undo (event `saved`) | Saves the snapshot |
| The game ends: a last step or a resignation (event `ended`, once) | Clears the saved game; records the result of a computer game |
| Home from the game menu | Saves the snapshot, then cancels the computer's turn (in that order, so a computer's chain is never saved half-played), and returns to Home |
| The app moves to the background | Saves the snapshot if a game is open |
| Abandon confirmed | Clears the saved game; records nothing |

The snapshot is the current state, except while the computer's turn is under way, when it is the
state at the start of that turn (FR-004). A player's unfinished chain is saved as it is.

## Launch and Continue

| Moment | Rule |
|---|---|
| The router is created | Loads the saved game: if unreadable, clears it, logs and adds the `savedGame` notice; `hasSavedGame` tells whether one exists. Loads the record: if unreadable, starts an empty record, saves it, logs and adds the `record` notice. Home shows the notices one at a time, the saved game's first; neither comes back for the same data |
| Continue | Loads the saved game, builds the session (the chain piece selected), opens the game screen, then `startComputerTurnIfNeeded()`; the remembered setup is unchanged |

## Recording

| Ending (computer games) | Recorded at the game's difficulty |
|---|---|
| The computer's side has no legal move | A win |
| The player's side has no legal move | A loss |
| The player resigns | A loss |
| Draw by repetition or by no progress | A draw |

Not recorded: two-player games, abandoned games, games still in progress (left, continued or
undone). Each game is recorded once, when it ends.
