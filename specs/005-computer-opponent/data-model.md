# Data Model: Computer Opponent

Types this feature adds or changes. Engine types are `Sendable` values in `CheckersEngine`; app
types follow E3 and E7 (`specs/003-game-experience/data-model.md`,
`specs/004-accessibility/data-model.md`). Behavior is in
[contracts/computer-player.md](contracts/computer-player.md) and
[contracts/computer-turn.md](contracts/computer-turn.md).

## Engine (public)

### ComputerLevel (R4)

| Case | Maximum depth | Node limit | Random margin |
|---|---|---|---|
| `easy` | 2 | none | 40 |
| `medium` | 4 | none | 8 |
| `hard` | 16 | measured (R4) | 0 |

Starting values; the tuned values are recorded in research R4. Depth counts complete turns;
margins are in evaluation points (a man is 100). Each level's values are an internal
`SearchLimits` (`maxDepth`, `nodeLimit: Int?`, `margin`), exposed as `ComputerLevel.limits`.

### ComputerTurn

| Field | Type | Meaning |
|---|---|---|
| `steps` | `[Step]` | The turn, in order: one step, or every jump of a chain. Never empty. |
| `depth` | `Int` | The deepest completed iteration (at least 1). |
| `nodes` | `Int` | Positions searched, for logging. |
| `score` | `Int` | The chosen turn's score from the computer's view, for logging and tests. |

### ComputerPlayer

A namespace with one public function, `chooseTurn(in:level:seed:shouldStop:)` (contract), which
calls the internal `chooseTurn(in:limits:seed:shouldStop:)` with `level.limits`. Tests in the
Debug run use the internal form with small limits, so they never search at Hard's full node
limit. No stored state; each call is independent.

## Engine (internal)

### Board (R1)

`light`, `dark`, `kings`: `UInt32`, indexed `row * 4 + column / 2` like `Position`; built from a
`Position` at no cost. Neighbor and landing tables per square and direction are computed once.

### TurnGenerator (R1)

Writes every complete turn of a side into a reusable buffer: the board after the turn, whether it
captured, how many pieces it captured, and whether it was progress (a capture or a man moving) for
the no-progress count. Only jumps when any jump exists; a chain ends when no jump is left or a man
is crowned.

### Search (R2)

Per call: the level's limits, the `shouldStop` closure, a node counter, the seeded generator
(SplitMix64), the positions already seen (from the game's turn records plus the search path, with
the side to move), the no-progress count, per-ply turn buffers, and the best turn of the last
completed iteration.

### Evaluation (R3)

A pure function of a board and the side to move, returning points.

## App

### GameSetup (changed, R11)

| Change | Before (E3) | After |
|---|---|---|
| `defaults` | Two players, Easy, Light | Computer, Easy, Light (FR-002) |
| `canStart` | false for Computer | removed: every setup can start (FR-001) |
| When remembered | on every change | when a game starts (FR-003) |

`Difficulty.computerLevel` maps easy, medium, hard to `ComputerLevel` (one switch).

### ComputerOpponent (protocol, R7, R8)

| Member | Meaning |
|---|---|
| `func chooseTurn(in state: GameState, level: ComputerLevel) async -> ComputerTurn?` | The turn to play, or `nil` if cancelled. Never blocks the main actor. |

Conformances: `EngineComputerOpponent` (live: draws a seed, runs `ComputerPlayer` in a
`@concurrent` function with a 0.8 s limit, logs the turn) and `ScriptedComputerOpponent` (tests
and previews: returns the next scripted turn, or waits until cancelled).

### TurnPacer (protocol, R8)

| Member | Meaning |
|---|---|
| `func pause(_ duration: Duration) async throws` | Waits; throws `CancellationError` if the task is cancelled. |

Conformances: `SleepingPacer` (live: `Task.sleep(for:)`); in tests, `ManualPacer` records every
requested pause and resumes when the test says so.

### GameSession (changed)

| Addition | Type | Meaning |
|---|---|---|
| `computerSide` | `Side?` | `playerSide?.opponent`; `nil` in a two-player game |
| `computerPhase` | `ComputerPhase` | `idle`, `thinking` (choosing or before its first step), `playing` (between jumps of its chain) |
| `isComputerTurn` | `Bool` | `computerPhase != .idle` |
| `isCovered` | `Bool` | Rules or Settings is open over the game (set by the router, FR-017) |
| `startComputerTurnIfNeeded()` | method | Starts the turn when the computer is to move and the game is in progress |
| `setCovered(_:)` | method | Holds or releases the computer's next step |
| `cancelComputerTurn()` | method | Cancels the task; the phase returns to `idle` |

Changed rules while `isComputerTurn` (contract): taps, drags and activations do nothing;
`hintedPieces` and `targets` are empty; `state(of:)` is `none`; `turnText` is the thinking
sentence; `canUndo` and `undo()` follow research R9; `resign()` cancels the turn first.

Injected through the initializer with defaults for the app: `opponent: any ComputerOpponent`,
`pacer: any TurnPacer`.

### ComputerPhase

```text
idle ──(computer to move)──► thinking ──(first step applied, chain continues)──► playing
  ▲                            │  │                                               │
  │                            │  └──(first step ends the turn)──────────────────┤
  └──(turn ends, or cancelled: undo, resign, leave, new session)◄─────────────────┘
```

### AppRouter (changed)

| Change | Rule |
|---|---|
| `startGame()` | Saves the setup, opens the game and calls `startComputerTurnIfNeeded()` |
| `playAgain()` | As before, then `startComputerTurnIfNeeded()` on the new session |
| `path` changes | `session.setCovered(path.last != .game)` while a session exists |
| Leaving or replacing a session | `cancelComputerTurn()` on the old session first |

### GameText (changed)

| Addition | Text |
|---|---|
| `thinking(_ side:)` | "Light is thinking…", "Dark is thinking…" |
| `computerFollowUp(after:in:)` | `nil` while the chain continues; otherwise the result or the spoken turn, as `followUp` |

### Log (changed, R14)

New category `computer`.
