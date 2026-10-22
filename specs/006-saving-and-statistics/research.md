# Research: Saving and Statistics

Phase 0 output for `specs/006-saving-and-statistics/plan.md`. Each entry records the decision, why,
and what else was considered. Facts marked *measured* were checked on the development Mac (Intel
Core i9-9980HK, 2.4 GHz, Swift 6.2.4) on 2026-10-22 with throwaway programs outside the
repository.

## Environment facts

| Item | Value |
|---|---|
| Existing storage | E3 keeps the last setup in `UserDefaults` as one JSON value (`lastGameSetup`, `UserDefaultsSetupStore`, `InMemorySetupStore` for tests and previews); the privacy manifest declares `UserDefaults` with reason CA92.1 |
| Game state | `GameState` holds the position (three 32-bit sets), side to move, chain square, outcome, no-progress count and its turn records (position, side, no-progress count at each turn start), the undo history; all stored properties are internal or `private(set)`. E2's contract foresees "E5 adds `Codable` inside the package" |
| Saved size and speed | The longest of 200 seeded random games played without ending it: 220 turns. Its state as compiler-generated JSON: 23,317 bytes; encode 1.6 ms and decode 1.7 ms (Release), 1.7 and 2.0 ms (Debug); `UserDefaults` write 5 µs and read 1.5 µs per call (*measured*) |
| Launch arguments | A launch argument `-key <hex bytes>` gives `UserDefaults.data(forKey:)` that value for the whole launch (Foundation's argument domain), and writes do not replace it (*measured* with a command-line program) |
| Router | `AppRouter` is built in 20 places: the app, 9 previews and 10 tests |
| Leave confirmation | E3's FR-042 alert ("Leave this game?") lives in `GameView` and `AppRouter` (`isConfirmingLeave`, `confirmLeave`, `cancelLeave`); unit tests in `US7NavigationTests` and `US3ComputerControlTests` use it; no UI test does |
| UI tests | Every UI test starts games through `AppScreens` helpers and leaves unfinished games behind; nothing resets the app's data between tests |
| Session size | `GameSession`'s class body is 154 of SwiftLint's 250 lines; the computer's turn is an extension in the same file (E4) |

## R1. What a saved game holds, and its format

- **Decision**: `GameState` becomes `Codable` inside the engine, with explicit keys instead of the
  compiler's generated ones: the position as the three sets (`light`, `dark`, `kings`), sides as
  `"light"`/`"dark"`, the chain square by name (`"c5"`) or null, the outcome
  (`"inProgress"`, a win with winner and reason, or a draw with its reason), the no-progress count
  and the turn records. Decoding checks that the state is one the rules could reach, and throws a
  `DecodingError` otherwise (contracts/saved-game.md, "Validity"). The app wraps it in a
  `SavedGame` with a format `version` (1), the setup (opponent, difficulty, side choice) and the
  player's resolved side. A JSON fixture of a version 1 save is kept in the tests, so any change to
  the format fails a test instead of silently breaking saved games.
- **Rationale**: The undo history and the draw counters are the engine's own state (FR-003), so the
  engine must encode them; explicit keys keep the format readable and stable (the generated form
  writes a side as `{"light":{}}`); validation turns damaged data into the unreadable-save path
  (FR-015) instead of a game that breaks later.
- **Alternatives considered**: saving the list of steps and replaying them (rejected: undo would
  need its own step bookkeeping in the session, and `GameState` does not keep steps); the
  generated `Codable` (rejected: unstable, verbose, no validation); a public engine API exposing
  the history (rejected: the app has no other use for it).

## R2. Where it is stored

- **Decision**: Two small stores behind protocols, each with a `UserDefaults` conformance for the
  app and an in-memory one for tests and previews, like E3's setup store: `SavedGameStore` (key
  `savedGame`: load, save, clear) and `RecordStore` (key `record`: load, save). Both hold one JSON
  value in `UserDefaults.standard`.
- **Rationale**: The data is small (at most about 25 KB for a long game, a few dozen bytes for the
  record) and written after every turn; a `UserDefaults` write takes microseconds on the calling
  thread and is persisted by the system even if the app is suspended or ended right after, so
  saving on the way to the background needs no extra background-task handling. The privacy
  manifest already declares `UserDefaults` (CA92.1: the app's own data). The same pattern is
  already in the app and its tests.
- **Alternatives considered**: a JSON file in Application Support (rejected: file I/O must stay off
  the main actor (Constitution VII.3), which needs an actor and a background task to finish a
  write when the app leaves the foreground, for no gain at this size); SwiftData (rejected: a model
  container, schema and migrations for one value and three tallies; Principle VIII.3); the
  Keychain (rejected: for secrets, Principle VI.2).

## R3. When the game is saved

- **Decision**: `GameSession` reports save points to its owner through one callback with two
  events: `saved` after every turn of either side, after an undo and when the router asks; `ended`
  once, when the game ends. The router then saves the session's snapshot, or clears the saved game
  and records the result. The snapshot is the current state, except during the computer's turn,
  when it is the state at the start of that turn (FR-004); during the player's own chain it keeps
  the chain unfinished (Clarifications). The router also saves when the player leaves for Home and
  when the app moves to the background (scene phase `.background`, observed in `CheckersApp`).
  A finished game has no snapshot, so saving it clears the saved game (FR-006).
- **Rationale**: The session knows when turns end and what state is safe to save; the router owns
  the stores and the record, as it owns the setup store. Saving after undo keeps the saved game
  equal to what is on screen.
- **Alternatives considered**: observing `session.state` from the router (rejected: every step of a
  chain would save, and the router would have to rediscover what the session knows); saving only
  on leave and background (rejected: FR-SAVE-01 says after every turn, and a crash would lose the
  game).

## R4. Continue

- **Decision**: Home shows Continue, above a no-longer-prominent New game, while the router reports
  a saved game. Continue loads the saved game from the store, builds a session from it (the
  player's chain piece selected again, as when the chain was played), opens the game screen and
  calls `startComputerTurnIfNeeded()`, so the computer plays if it is its turn (FR-009). The setup
  choices are not touched (FR-011). The router keeps the saved game's existence in an observable
  property, set at launch and on every save or clear.
- **Rationale**: Loading from the store, the same path as after a relaunch, means the in-app test
  of Continue also proves the stored format.
- **Alternatives considered**: keeping the left session in memory for Continue (rejected: two
  sources of truth, and a relaunch would take a different path).

## R5. Leaving a game

- **Decision**: Home from the game menu saves the game and returns to Home at once; the computer's
  turn is cancelled (it restarts after Continue, FR-004). E3's leave alert, its texts and the
  router's leave-confirmation state are removed; the unit tests that used them are rewritten for
  FR-010 first.
- **Rationale**: FR-NAV-03; the alert only existed because games could not be kept (E3's FR-042).

## R6. "Abandon current game?"

- **Decision**: `startGame()` asks when a saved game exists: the router sets `isConfirmingAbandon`
  and Game setup shows an alert, "Abandon current game?", with the message "Starting a new game
  discards the game in progress.", a destructive Abandon and Cancel. Abandon clears the saved game
  and starts the new one; Cancel leaves setup and the saved game as they are. Play again never
  asks, since a finished game is not saved.
- **Rationale**: FR-SETUP-04 as the FRD words it ("starting a new game … cancelling returns to
  setup"); an alert, as for E3's other confirmations (an iOS 26 confirmation dialog from a button
  becomes a popover without Cancel, E3 lessons).

## R7. A saved game that cannot be read

- **Decision**: The router loads the saved game when it is created. If the store reports it
  unreadable (bad JSON, an unknown version, a state that fails validation, or a finished game), the
  router clears it, logs the error and sets `isShowingRestoreFailure`; Home shows one alert, "Your
  previous game couldn't be restored.", with OK (Clarifications). Clearing it means the alert
  cannot come back for that save.
- **Rationale**: FR-015; checking at launch means Home is right the first time it appears.

## R8. The record

- **Decision**: A `Record` value holds wins, losses and draws for each `Difficulty`, stored as one
  JSON value with a version. When a computer game ends, the session's `ended` event carries its
  `GameResult` (win when the computer's side is left without a move, loss when the player's side
  is or when the player resigns, draw for repetition or no progress) and the router adds it and
  saves the record. Two-player games carry no result. The event comes once per game, from the step
  or resignation that ends it, so undo, leaving and Continue cannot count a game twice
  (FR-017 to FR-019). An unreadable record starts again at zero and is logged (Clarifications).
- **Rationale**: Counting at the end is the only point where the result is final, and undo is
  unavailable after it (FR-UNDO-06).

## R9. The Statistics screen

- **Decision**: A new `StatisticsView` replaces the placeholder. With a record: one block per
  difficulty (Easy, Medium, Hard), with its name and three lines, wins, losses and draws, each a
  number and a word ("3 wins", "1 loss", from String Catalog plural variations); VoiceOver reads
  each block as one element, "Easy: 3 wins, 1 loss, 2 draws". With no game recorded: a title and a
  sentence, "No games yet." and "Finish a game against the computer to start your record.". All
  text is primary, in the app's own layout rather than `List`, `LabeledContent` or
  `ContentUnavailableView`, whose secondary text styles fail the audit's contrast check (E7
  lessons). It has no buttons.
- **Rationale**: FR-021 to FR-023 and FR-025; stacked lines fit the iPhone SE at the largest text
  size, where a four-column grid would not.
- **Alternatives considered**: a table with columns (rejected: does not fit at accessibility
  sizes); totals or win rates (out of scope, spec Assumptions).

## R10. UI tests and data that persists

- **Decision**: The app gets no test-only switches. UI tests that need a known saved game or record
  launch the app with `UserDefaults` launch arguments, `-savedGame <hex>` or `-record <hex>`, which
  Foundation reads before the stored values; this sets up a damaged save (the alert), a saved game
  (Continue) and an empty record (the empty state for the audit). The start helpers in `AppScreens`
  answer "Abandon current game?" when it appears, since earlier tests leave games saved. The
  Continue test relaunches the app (`terminate()`, `launch()`), and the Statistics test compares
  counts before and after a game instead of assuming an empty record.
- **Rationale**: Keeps the shipped app free of test behavior while making each UI test independent
  of the ones before it.
- **Alternatives considered**: a launch argument that switches the app to in-memory stores
  (rejected: test-only behavior in the app); resetting the simulator between tests (not available
  from inside a UI test).

## R11. Building the router

- **Decision**: `AppRouter.init` gains `games: any SavedGameStore` and `records: any RecordStore`,
  both defaulting to in-memory stores; `CheckersApp` passes the `UserDefaults` ones. Previews and
  existing tests keep compiling unchanged and never touch storage (workflow gate 4).
- **Rationale**: The 20 call sites stay as they are; a missing live store in the app would show at
  once in the relaunch UI test.
- **Alternatives considered**: required parameters (rejected: 20 edits for no behavior); live
  defaults (rejected: previews would write to the device's storage).

## R12. Logging

- **Decision**: A new `Log.storage` category: an error when a saved game or the record cannot be
  read or written, with the error, and no game data (Principle IX.3).

## R13. Privacy

- **Decision**: No change to `PrivacyInfo.xcprivacy`: the saved game and the record are the app's
  own data in `UserDefaults`, covered by the declared reason CA92.1; nothing leaves the device
  (FR-024).

## R14. Tests

- **Decision**: Engine (`CheckersEngineTests`): `GameState` coding round trips for seeded random
  games (chains, kings, counters, every outcome), the version 1 fixture, and rejection of damaged
  states. App (`checkersTests`), with in-memory stores, a scripted opponent and a manual pacer:
  save points and snapshots (including the computer's turn and the player's chain), Continue,
  leaving without a question, the abandon question, the unreadable save, recording every ending
  once at its difficulty, and the `UserDefaults` stores against a temporary suite. UI
  (`checkersUITests`): Continue after a relaunch, the abandon question, the unreadable-save alert,
  Statistics counting a finished game, and the audit of Home with Continue and of Statistics, empty
  and with a record. Acceptance tests name US1–US4.
- **Rationale**: Every rule is tested without UI and without the device's storage; the UI tests
  prove the wiring, the relaunch and the screens.
