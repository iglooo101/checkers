# Contract: computer player (CheckersEngine)

What the engine adds for the computer opponent. Declarations are the contract: names, types and
behavior. Everything else in `specs/002-rules-engine/contracts/engine-api.md` is unchanged. Types
are in [../data-model.md](../data-model.md).

## Declarations

```swift
public enum ComputerLevel: Sendable, CaseIterable { case easy, medium, hard }

public struct ComputerTurn: Sendable, Equatable {
    public let steps: [Step]     // never empty
    public let depth: Int        // deepest completed iteration, at least 1
    public let nodes: Int        // positions searched
    public let score: Int        // the chosen turn's score, from the computer's view
}

public enum ComputerPlayer {
    /// The turn the side to move plays at this level. Returns nil when the game is over or a
    /// capture chain is in progress (the computer only starts turns).
    public static func chooseTurn(
        in state: GameState, level: ComputerLevel, seed: UInt64,
        shouldStop: () -> Bool = { false }
    ) -> ComputerTurn?
}
```

## Behavior

| Rule | Requirement |
|---|---|
| Every turn returned is legal: applying its steps in order to `state` with `GameState.apply` succeeds, every step but the last continues the chain, and the last ends the turn. The root turns are enumerated through `GameState` itself. | FR-004, FR-AI-01 |
| The same `state`, `level` and `seed`, with `shouldStop` never true, always give the same turn. | FR-013, R5 |
| Different seeds may give different turns when several are within the level's margin of the best. | FR-013 |
| The search stops an iteration when the level's node limit is reached or `shouldStop()` returns true (checked every 1,024 nodes); it then returns the best turn of the last completed iteration. Depth 1 always completes, so a turn is always returned while the game is in progress. | FR-008, R2 |
| A position that already occurred in the game (the engine's turn records) or on the search path, with the same side to move, scores as a draw; so does a turn that brings the no-progress count to 80. A side with no turn loses. | FR-END-01, FR-END-03, FR-END-04 |
| The call is synchronous and pure apart from `shouldStop`: no I/O, clocks, logging or global state. It may run on any task; the app runs it off the main actor. | Constitution VII.3 |

## Levels

| Level | Strength target |
|---|---|
| `easy` | A beginner can win (SC-004); Medium scores at least 70% against it (SC-003) |
| `medium` | Scores at least 70% against Easy; Hard scores at least 70% against it (SC-003) |
| `hard` | A challenge for an experienced casual player (SC-004); its slowest turn in the matches takes at most 0.5 s on the development Mac in Release (R4) |

Parameters are in research R4.

## Strength matches (SC-002, SC-003)

| Item | Rule |
|---|---|
| Pairings | Medium against Easy; Hard against Medium |
| Games | 50 openings × 2 (sides swapped) = 100 per pairing |
| Opening | Two turns drawn at random with the opening's seed (from `GameState`, any legal turn) |
| Seeds | Opening `i` uses seed `i`; each computer turn uses a seed derived from the game and turn number |
| Play | Every step through `GameState.apply`; the game runs until its outcome is not in progress |
| Score | Win 1, draw 0.5, loss 0, for the stronger level; must be at least 70 of 100 |
| Where | `CheckersEngineStrengthTests`, `swift test -c release`, CI job `engine-strength` |
