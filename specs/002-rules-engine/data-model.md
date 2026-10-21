# Data Model: Rules Engine

Phase 1 output for `specs/002-rules-engine/plan.md`. Every type lives in
`checkers/CheckersEngine/Sources/CheckersEngine/`, is a struct or enum, declares `Sendable`, and
is `Equatable` (most also `Hashable`). The public API with its exact behavior is in
[contracts/engine-api.md](contracts/engine-api.md); the decisions behind this model are in
[research.md](research.md).

## Entities

### Side (existing, E1)

| Field | Type | Notes |
|---|---|---|
| case | `light`, `dark` | Light moves first (FR-003). |
| `opponent` | `Side` | The other side. |

Added in this slice (internal): the forward direction (toward row 8 for Light, toward row 1 for
Dark, FR-004) and the far row (row 8 for Light, row 1 for Dark, FR-012).

### PieceKind and Piece (FR-002)

| Type | Fields | Notes |
|---|---|---|
| `PieceKind` | `man`, `king` | |
| `Piece` | `side: Side`, `kind: PieceKind` | `Hashable`. |

### Square (FR-001)

| Field | Type | Notes |
|---|---|---|
| index (internal) | 0–31 | `row * 4 + column / 2`; a1 = 0, h8 = 31. |
| `column` | `Int`, 0–7 | a–h, left to right from Light's side. |
| `row` | `Int`, 0–7 | Rows 1–8 from Light's side. |
| `name` | `String` | Notation such as "c3"; not localized (screens build their own text). |

- **Validation**: created from a column and row, or a name (a lowercase column letter a–h
  followed by a row 1–8); returns `nil` unless both are in range and `column + row` is even (a
  dark square). a1 is dark.
- `Square.all`: the 32 squares in index order (a1, c1, e1, g1, b2, …, h8).
- `Hashable`; no other ordering is public.

### Position (FR-001, FR-003)

| Field | Type | Notes |
|---|---|---|
| Light pieces (internal) | 32-bit set | One bit per square index. |
| Dark pieces (internal) | 32-bit set | |
| Kings (internal) | 32-bit set | A subset of the occupied squares. |
| `piece(at:)` | `Piece?` | The piece on a square, if any. |
| `Position.start` | `Position` | Light men on the 12 dark squares of rows 1–3, Dark men on those of rows 6–8. |

- **Invariants**: no square holds both a Light and a Dark piece; every king square is occupied;
  each side has at most 12 pieces; no Light man stands on row 8 and no Dark man on row 1 (it
  would have been crowned).
- Internal for tests: building a position from a map of squares to pieces, placing and removing
  pieces, and generating the legal steps of a bare position for a side.
- `Hashable`: two positions are equal when the same pieces of the same kind stand on the same
  squares (the repetition rule's definition, FR-016).

### Step (FR-008, FR-009)

| Field | Type | Notes |
|---|---|---|
| `from` | `Square` | Square of the moving piece. |
| `to` | `Square` | Landing square. |
| `isJump` | `Bool` (computed) | True when `to` is two diagonal squares from `from`. |
| `captured` | `Square?` (computed) | For a jump, the square in between; otherwise `nil`. |

- Any two squares form a `Step` value; whether it is legal is decided by the game state.
- `Hashable`, so screens and tests can compare and look up steps.

### StepResult (FR-027)

| Field | Type | Notes |
|---|---|---|
| `side` | `Side` | The side that moved. |
| `piece` | `Piece` | The moving piece as it was before the step. |
| `from`, `to` | `Square` | As in the applied step. |
| `captured` | `Square?` | The removed piece's square, for a jump. |
| `crowned` | `Bool` | The man became a king on this step. |
| `turnContinues` | `Bool` | The same piece must jump again (chain in progress). |
| `outcome` | `Outcome` | The outcome after the step: `inProgress` unless this step ended the game. |

### Outcome (FR-013 to FR-017)

| Case | Associated values |
|---|---|
| `inProgress` | |
| `win` | `winner: Side`, `reason: WinReason` (`noMovesLeft`, `resignation`) |
| `draw` | `reason: DrawReason` (`repetition`, `noProgress`) |

There is no draw by agreement (FR-018).

### RuleError (FR-020, FR-024)

| Case | Meaning |
|---|---|
| `gameOver` | The game has ended; no step, resignation or undo is accepted. |
| `notSideToMove` | The piece belongs to the side whose turn it is not. |
| `captureRequired` | A capture is available, so a simple move is not allowed. |
| `mustContinueChain` | A chain is in progress; only the chain's piece may move, and only by jumping. |
| `illegalStep` | No piece on the from square, or not one of the legal steps. |
| `nothingToUndo` | Undo at the starting position of the game. |

### TurnRecord (internal; FR-021, FR-016)

| Field | Type | Notes |
|---|---|---|
| `position` | `Position` | Position at the start of the turn. |
| `sideToMove` | `Side` | Side whose turn it was. |
| `noProgressCount` | `Int` | The count before the turn. |

One record per turn started, pushed when the turn's first step is applied. The records are both
the undo history and the repetition record.

### GameState (FR-013)

| Field | Type | Public | Notes |
|---|---|---|---|
| `position` | `Position` | read | |
| `sideToMove` | `Side` | read | |
| `chainSquare` | `Square?` | read | Square of the piece that must keep jumping; `nil` between turns. |
| `outcome` | `Outcome` | read | |
| `noProgressCount` | `Int` | internal | Completed turns since the last capture or man move (FR-017). |
| `history` | `[TurnRecord]` | internal | Undo history and repetition record. |

Derived (public): `legalSteps`, `movablePieces`, `targets(from:)`, `isCaptureRequired`,
`canUndo`. Derived (internal): the repetition count of the current position.

- **Validation and invariants**:
  - While in progress, the side to move has at least one legal step; once the game is over, the
    legal step list is empty.
  - If `chainSquare` is set, it holds a piece of the side to move, that piece has at least one
    jump, and the legal steps are exactly its jumps.
  - While in progress, `noProgressCount` is between 0 and 79.
  - The history has one record per turn started and not undone; `canUndo` is true exactly when
    the game is in progress and the history is not empty.
  - Copies are independent values; the same steps on equal states give equal results (FR-026).
- `Equatable`, comparing every stored field, so tests can check that undo restores a recorded
  state exactly (SC-003).

## Relationships

- A `GameState` has one current `Position` and an ordered list of `TurnRecord`s, each holding a
  `Position`.
- A `Position` maps `Square`s to `Piece`s; a `Piece` has a `Side` and a `PieceKind`.
- A `Step` names two `Square`s; applying it to a `GameState` yields a `StepResult` that carries
  an `Outcome`.

## State transitions

A game is always in one of three phases. Every transition below is atomic: it happens completely
or, if rejected, not at all (FR-020).

| From | Action | Condition | To |
|---|---|---|---|
| Between turns | apply a legal simple move | | Turn ends (below) |
| Between turns | apply a legal jump | the piece can jump again and was not crowned | Chain in progress |
| Between turns | apply a legal jump | no further jump, or the man was crowned | Turn ends |
| Chain in progress | apply the chain piece's next jump | it can jump again and was not crowned | Chain in progress |
| Chain in progress | apply the chain piece's next jump | no further jump, or crowned | Turn ends |
| Between turns or chain in progress | resign (either side) | | Game over: win for the other side, reason resignation |
| Between turns (history not empty) or chain in progress | undo | | Between turns, restored from the last turn record |
| Game over | any action | | Rejected: `gameOver` |

**Turn ends**: update the no-progress count, pass the turn and clear the chain, then evaluate the
outcome in precedence order (FR-019): no legal step for the side now to move → win for the side
that moved (no moves left); otherwise the position with that side to move has occurred three
times at turn starts → draw (repetition); otherwise the no-progress count is 80 → draw (no
progress); otherwise the game continues between turns. Details: research R6.

The first step of every turn pushes a turn record before the step is applied, so undo during a
chain and undo after a completed turn both restore the state from before that turn.
