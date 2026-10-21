# Data Model: Game Experience

Phase 1 output for `specs/003-game-experience/plan.md`. App-side types live in
`checkers/checkers/`; rules types (`GameState`, `Square`, `Step`, `Outcome`, `Side`, `Piece`) come
from the engine (`specs/002-rules-engine/contracts/engine-api.md`). Decisions are in
[research.md](research.md); exact behavior is in [contracts/](contracts/).

## Value types

### GameSetup (R7)

| Field | Type | Values | Default (until E4) |
|---|---|---|---|
| `opponent` | `Opponent` | `computer`, `twoPlayers` | `twoPlayers` |
| `difficulty` | `Difficulty` | `easy`, `medium`, `hard` | `easy` |
| `side` | `SideChoice` | `light`, `dark`, `random` | `light` |

- `Codable`, `Equatable`, `Sendable`. Difficulty and side apply only when the opponent is the
  computer; they are kept (and remembered) while Two players is chosen.
- `canStart`: true only for `twoPlayers` in this slice (FR-011).

### BoardLayout (R6)

| Field | Type | Notes |
|---|---|---|
| `bottomSide` | `Side` | `light` in two-player games; the player's side against the computer |

- `square(row:column:) -> Square?`: the square shown in a display cell (row 0 at the top, column 0
  at the left), or `nil` for a light square. Light at the bottom: (column c, row 7 − r). Dark at the
  bottom: (column 7 − c, row r).
- `cell(of:) -> (row, column)`: the inverse, for drawing a square in place.

### Notice

| Case | Shown as |
|---|---|
| `captureRequired` | "A capture is required." near the turn indicator (FR-023) |

Cleared at the start of the next tap or drag, and when a step is applied.

### Route (R2)

`setup`, `game`, `statistics`, `rules`, `settings`; `Hashable`. Home is the root, not a route.

## Observable models (main actor)

### GameSession (R1, R3, R4)

| Field | Type | Public to views | Notes |
|---|---|---|---|
| `state` | `GameState` | read | The engine's game (FR-010: starts from `GameState()`) |
| `setup` | `GameSetup` | read | The setup the game was started with |
| `playerSide` | `Side?` | read | The player's side in a computer game; `nil` in two-player games |
| `selection` | `Square?` | read | The selected piece's square |
| `notice` | `Notice?` | read | The current notice, if any |
| `layout` | `BoardLayout` | read (derived) | From `playerSide` (FR-015) |
| `hintedPieces` | `Set<Square>` | read (derived) | `state.movablePieces` while hints are on (always on in this slice); empty when over |
| `targets` | `Set<Square>` | read (derived) | `state.targets(from: selection)`; empty without a selection |
| `turnText` | `LocalizedStringResource` | read (derived) | One of four sentences (FR-014) |
| `resultText` | `LocalizedStringResource?` | read (derived) | One of six sentences once over (FR-033) |
| `canUndo` | `Bool` | read (derived) | `state.canUndo` (FR-037) |
| `resigningSide` | `Side` | read (derived) | Side to move in two-player games; `playerSide` against the computer (FR-032) |
| `isOver` | `Bool` | read (derived) | `state.outcome != .inProgress` |

Actions: `tap(_ square:)`, `beginDrag(at:) -> Bool`, `drop(on: Square?)`, `undo()`, `resign()`.
Rules: [contracts/game-session.md](contracts/game-session.md).

**Invariants**

- `selection` is `nil` or a square in `state.movablePieces`; during a chain it equals
  `state.chainSquare`.
- `targets` are always the engine's legal targets for the selection, and only a step to one of
  them reaches `state.apply`.
- Once `isOver`, `selection` and `notice` are `nil`, and input does nothing.

### AppRouter (R2, R8)

| Field | Type | Notes |
|---|---|---|
| `path` | `[Route]` | The navigation stack above Home |
| `session` | `GameSession?` | The game shown by `Route.game`; `nil` when no game is open |
| `setup` | `GameSetup` | Current setup choices; every change is saved to the store (R7) |
| `isConfirmingLeave` | `Bool` | Drives the leave confirmation (FR-042) |

Actions: `newGame()`, `startGame()`, `requestHome()`, `confirmLeave()`, `cancelLeave()`,
`playAgain()`, `open(_ route:)`. Rules: [contracts/game-session.md](contracts/game-session.md),
section "Navigation".

## Services

### SetupStore (R7)

| Member | Notes |
|---|---|
| `load() -> GameSetup` | The stored setup, or the defaults when nothing usable is stored (an undecodable value is logged) |
| `save(_ setup: GameSetup)` | Replaces the stored setup |

Conformances: `UserDefaultsSetupStore` (live, one JSON value under one key, `UserDefaults`
injected so tests can use a private suite) and `InMemorySetupStore` (tests and previews).

## State transitions

| From | Event | To |
|---|---|---|
| Home | New game | Setup (choices loaded from the store) |
| Setup | Change a choice | Setup (choice saved) |
| Setup | Start (two players) | Game: new session from `GameState()` |
| Setup | Start (computer) | Not possible in this slice (FR-011) |
| Game | Rules or Settings from the menu | Placeholder screen above the game; Back returns to the same session |
| Game (in progress) | Home | Leave confirmation → Home (session discarded) or back to the game |
| Game (over) | Home (menu or result panel) | Home |
| Game (over) | Play again | Game: new session with the same setup (Random drawn again) |
| Home | Statistics, Rules, Settings | Placeholder screen; Back returns Home |
