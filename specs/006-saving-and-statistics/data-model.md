# Data Model: Saving and Statistics

Types this feature adds or changes. Engine types are `Sendable` values in `CheckersEngine`; app
types follow E3 to E4 (`specs/005-computer-opponent/data-model.md`). Formats and rules are in
[contracts/saved-game.md](contracts/saved-game.md); screens in [contracts/screens.md](contracts/screens.md).

## Engine

### GameState (changed: `Codable`, R1)

| Encoded field | From | Notes |
|---|---|---|
| `position` | `light`, `dark`, `kings` as numbers | The three 32-bit sets |
| `sideToMove` | `"light"` or `"dark"` | |
| `chainSquare` | a square name such as `"c5"`, or null | The piece in an unfinished chain |
| `outcome` | `"inProgress"`, a win (winner, reason) or a draw (reason) | |
| `noProgressCount` | number | Turns since the last capture or man move |
| `turns` | the turn records: position, side to move and no-progress count at each turn start | The undo history and the repetition count |

Decoding validates the state (contract, "Validity") and throws `DecodingError.dataCorrupted`
otherwise. `Side` is `Codable` as `"light"`/`"dark"`. No other public API changes.

## App

### SavedGame (new, R1)

| Field | Type | Meaning |
|---|---|---|
| `version` | `Int` | Format version, 1 |
| `setup` | `GameSetup` | Opponent, difficulty and side choice of the game (E3's type, already `Codable`) |
| `playerSide` | `Side?` | The player's side against the computer; `nil` in a two-player game |
| `state` | `GameState` | The game, always in progress |

### SavedGameStore (new protocol, R2)

| Member | Meaning |
|---|---|
| `func load() throws(SavedGameError) -> SavedGame?` | The saved game, `nil` if none, `.unreadable` if it cannot be used |
| `func save(_ game: SavedGame)` | Replaces the saved game |
| `func clear()` | Removes it |

Conformances: `UserDefaultsSavedGameStore` (key `savedGame`) and `InMemorySavedGameStore` (tests,
previews; can be given raw data to test unreadable saves). `SavedGameError`: `unreadable`.

### GameResult (new, R8)

| Field | Type | Meaning |
|---|---|---|
| `difficulty` | `Difficulty` | The level the game was played at |
| `kind` | `win`, `loss`, `draw` | From the player's view |

Made from a finished game's outcome and the player's side; `nil` for two-player games.

### Record (new, R8)

| Field | Type | Meaning |
|---|---|---|
| `version` | `Int` | Format version, 1 |
| `easy`, `medium`, `hard` | `Tally` (`wins`, `losses`, `draws`: `Int`) | The player's results at each level |

`adding(_ result:)` returns the record with one more in the right place; `isEmpty` is true when
every count is zero.

### RecordStore (new protocol, R2)

| Member | Meaning |
|---|---|
| `func load() -> Record` | The record, or an empty one if none is stored or it cannot be read (logged) |
| `func save(_ record: Record)` | Replaces it |

Conformances: `UserDefaultsRecordStore` (key `record`) and `InMemoryRecordStore`.

### GameSession (changed, R3)

| Addition | Type | Meaning |
|---|---|---|
| `init(saved:…)` | initializer | Rebuilds a session from a saved game; the chain piece is selected again |
| `snapshot` | `SavedGame?` | The game to save: the current state, or the state at the start of the computer's turn while it plays; `nil` once the game is over |
| `result` | `GameResult?` | The finished computer game's result; `nil` otherwise |
| `onEvent` | `(GameSessionEvent) -> Void` | Set by the router: `saved` after every turn and undo, `ended` once when the game ends |

### GameSessionEvent (new)

`saved`, `ended`. The router saves the snapshot on `saved`; on `ended` it clears the saved game and
records the session's result, if any.

### AppRouter (changed, R4 to R7, R11)

| Change | Meaning |
|---|---|
| `init(…, games:, records:)` | Two stores, in-memory by default; the app passes the `UserDefaults` ones |
| `hasSavedGame: Bool` | Observable; Home shows Continue while true |
| `record: Record` | Observable; what Statistics shows |
| `isConfirmingAbandon: Bool` | The abandon question is showing |
| `isShowingRestoreFailure: Bool` | The unreadable-save alert is showing |
| `continueGame()` | Opens the saved game and starts the computer's turn if it is its turn |
| `startGame()` | Asks first when a saved game exists |
| `confirmAbandon()`, `cancelAbandon()` | Answer the question |
| `dismissRestoreFailure()` | Closes the alert |
| `saveNow()` | Saves the session's snapshot; called when the app moves to the background |
| `requestHome()` | Saves and returns Home at once (no question) |
| Removed | `isConfirmingLeave`, `confirmLeave()`, `cancelLeave()` (E3's leave confirmation) |

### Log (changed, R12)

New category `storage`.

## State transitions: the saved game

```text
none ──(a turn ends, undo, leave, background)──► saved ──(same)──► saved (replaced)
  ▲                                                 │
  └──(the game ends · Abandon confirmed · unreadable at launch, then the alert)◄┘
```
