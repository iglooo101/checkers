# Contract: CheckersEngine public API

The interface the rules engine offers to the screens (E3), the computer opponent (E4), saving
(E5) and accessibility (E7). Declarations below are the contract: names, types and behavior.
Bodies are implementation details. Types and fields are described in
[../data-model.md](../data-model.md).

## Declarations

```swift
public enum Side: Sendable, CaseIterable { case light, dark }      // existing
extension Side { public var opponent: Side { get } }                // existing

public enum PieceKind: Sendable, Hashable { case man, king }

public struct Piece: Sendable, Hashable {
    public let side: Side
    public let kind: PieceKind
    public init(side: Side, kind: PieceKind)
}

public struct Square: Sendable, Hashable {
    public init?(column: Int, row: Int)     // 0...7 each; nil for light squares
    public init?(name: String)              // lowercase "a1" ... "h8"; nil for light or invalid squares
    public var column: Int { get }          // 0 = a
    public var row: Int { get }             // 0 = row 1 (Light's side)
    public var name: String { get }         // "c3"
    public static let all: [Square]         // 32 squares: a1, c1, e1, g1, b2, ..., h8
}

public struct Position: Sendable, Hashable {
    public static let start: Position
    public func piece(at square: Square) -> Piece?
}

public struct Step: Sendable, Hashable {
    public let from: Square
    public let to: Square
    public init(from: Square, to: Square)
    public var isJump: Bool { get }         // two diagonal squares apart
    public var captured: Square? { get }    // the square in between, for a jump
}

public struct StepResult: Sendable, Equatable {
    public let side: Side
    public let piece: Piece                 // before the step
    public let from: Square
    public let to: Square
    public let captured: Square?
    public let crowned: Bool
    public let turnContinues: Bool
    public let outcome: Outcome             // after the step
}

public enum WinReason: Sendable, Hashable { case noMovesLeft, resignation }
public enum DrawReason: Sendable, Hashable { case repetition, noProgress }

public enum Outcome: Sendable, Hashable {
    case inProgress
    case win(winner: Side, reason: WinReason)
    case draw(reason: DrawReason)
}

public enum RuleError: Error, Sendable, Equatable {
    case gameOver, notSideToMove, captureRequired, mustContinueChain, illegalStep, nothingToUndo
}

public struct GameState: Sendable, Equatable {
    public init()                                       // standard start, Light to move
    public var position: Position { get }
    public var sideToMove: Side { get }
    public var chainSquare: Square? { get }
    public var outcome: Outcome { get }

    public var legalSteps: [Step] { get }
    public var movablePieces: [Square] { get }
    public func targets(from square: Square) -> [Square]
    public var isCaptureRequired: Bool { get }
    public var canUndo: Bool { get }

    @discardableResult
    public mutating func apply(_ step: Step) throws(RuleError) -> StepResult
    public mutating func resign(_ side: Side) throws(RuleError)
    public mutating func undo() throws(RuleError)
}
```

## Queries (FR-008)

| Query | While in progress | Once the game is over |
|---|---|---|
| `legalSteps` | Every legal single step for the side to move: only jumps if any jump exists (FR-007); only the chain piece's jumps during a chain (FR-010). | Empty |
| `movablePieces` | The distinct from squares of `legalSteps`. | Empty |
| `targets(from:)` | The to squares of the legal steps from that square; empty for any other square. | Empty |
| `isCaptureRequired` | True when the legal steps are jumps (always during a chain). | False |
| `canUndo` | True when at least one turn has been started (FR-022, FR-023). | False (FR-024) |

**Order** (deterministic, FR-026): steps are listed by from square in `Square.all` order, then by
direction: toward row 8 and lower column, toward row 8 and higher column, toward row 1 and lower
column, toward row 1 and higher column. `movablePieces` and `targets(from:)` keep that order.

## apply(_:) (FR-009 to FR-012, FR-014 to FR-017, FR-019, FR-020, FR-027)

**Checks**, in this order; the first that fails throws and leaves the state unchanged:

| # | Check | Error |
|---|---|---|
| 1 | The game is in progress | `gameOver` |
| 2 | A piece stands on `from` | `illegalStep` |
| 3 | That piece belongs to the side to move | `notSideToMove` |
| 4 | No chain is in progress, or `from` is the chain square and the step is a jump | `mustContinueChain` |
| 5 | No capture is required, or the step is a jump | `captureRequired` |
| 6 | The step is in `legalSteps` | `illegalStep` |

**Effects** of an accepted step:

1. If no chain is in progress, a turn record (position, side to move, no-progress count) is
   pushed onto the history.
2. The piece moves from `from` to `to`; for a jump, the piece on `captured` is removed.
3. A man that lands on its far row becomes a king (`crowned`), and the turn ends (FR-012).
4. Otherwise, after a jump, if the same piece has another jump, the turn continues
   (`turnContinues`, `chainSquare = to`); otherwise the turn ends.
5. When the turn ends, the outcome is evaluated as in research R6: no-progress count, turn
   passes, then no legal step → `win(winner: side that moved, reason: .noMovesLeft)`, else third
   occurrence → `draw(reason: .repetition)`, else 80 turns without progress →
   `draw(reason: .noProgress)`.
6. The returned `StepResult` describes the step and carries the outcome after it.

## resign(_:) (FR-015, FR-018)

- Either side may resign at any time while the game is in progress, including during a chain and
  when it is not that side's turn. Which side resigns is the screen's decision.
- Effect: `outcome = .win(winner: side.opponent, reason: .resignation)`; the chain is cleared;
  the position and history are unchanged. Throws `gameOver` if the game has already ended.

## undo() (FR-021 to FR-024)

| Check | Error |
|---|---|
| The game is in progress | `gameOver` |
| The history is not empty | `nothingToUndo` |

- Effect: the last turn record is removed and its position, side to move and no-progress count
  are restored; the chain is cleared. The restored state is equal (`==`) to the state before
  that turn started, and the turn's occurrence no longer counts for repetition.
- Mid-chain this discards the partial turn (FR-023); between turns it takes back the last
  completed turn, whichever side made it (FR-021). One call undoes one turn; E4 composes two
  calls for undo against the computer.

## Guarantees

- **Value semantics** (FR-026): every type is a value; a copy of a `GameState` is independent of
  the original, and the same calls on equal states give equal results and equal errors.
- **Concurrency**: every type is `Sendable` and nonisolated; all calls are synchronous and pure
  (no I/O, logging, clocks or randomness), so they may run on any task, including off the main
  actor for the computer's search.
- **No UI** (FR-025): the package imports no UI framework (enforced by the
  `engine_no_ui_imports` lint rule) and contains no user-facing text.

## How later epics use it

- **E3 (game screen)**: build the board from `Square.all` and `position.piece(at:)`; highlight
  `movablePieces` and `targets(from:)` (FR-AID-01, FR-AID-02); `isCaptureRequired` drives the
  turn indicator and the "capture required" message (FR-MOVE-05); a tap pair or drag becomes
  `Step(from:to:)` for `apply`; `chainSquare` marks the locked piece (FR-CHAIN-02); `outcome`
  drives the result panel; `canUndo` enables the menu item.
- **E4 (computer opponent)**: copy the `GameState` into a background task, search with
  `legalSteps` and `apply` (a turn is complete when `turnContinues` is false), and replay the
  chosen steps one by one on screen (FR-AI-05). Undo against the computer calls `undo()` until it
  is the player's turn again.
- **E5 (saving)**: everything that affects play is in `GameState` (FR-013); E5 adds `Codable`
  inside the package.
- **E7 (accessibility)**: `StepResult` and `Square.name` give announcements and square labels
  their facts; the text itself comes from the app's String Catalog.
