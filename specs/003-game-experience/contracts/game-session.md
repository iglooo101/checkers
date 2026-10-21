# Contract: GameSession and AppRouter

How the game screen turns input into engine steps, and how the app moves between screens. Both
types are `@Observable`, main-actor classes in the app target, tested without the user interface
(FR-024). Fields are in [../data-model.md](../data-model.md); the engine's API is
`specs/002-rules-engine/contracts/engine-api.md`.

## Taps (FR-019, FR-021 to FR-023, FR-030)

Every tap first clears the notice. Then the first matching row applies:

| # | Situation | Result |
|---|---|---|
| 1 | The game is over | Nothing |
| 2 | A chain is in progress and the square is one of the chain piece's targets | Jump there (see Applying a step) |
| 3 | A chain is in progress | Nothing; the chain piece stays selected |
| 4 | A piece is selected and the square is one of its targets | Move there (see Applying a step) |
| 5 | The square holds the selected piece | Clear the selection |
| 6 | The square holds a movable piece of the side to move | Select it |
| 7 | A capture is required and the square holds a piece of the side to move | Show `captureRequired`; selection unchanged |
| 8 | Anything else | Clear the selection |

## Drags (FR-020)

- `beginDrag(at: square) -> Bool`: clears the notice; returns true and selects the piece when a tap
  on that square would select it (row 6), or when it is the chain piece or the selected piece; in
  any other case applies the tap rules as a tap would (so row 7's notice appears) and returns
  false, and the piece does not follow the finger.
- `drop(on: square?)`: when a drag was accepted and the square is one of the selection's targets,
  move there (see Applying a step); otherwise nothing changes and the piece returns to its square.
  A `nil` square (off the board or a cancelled drag) is not a target.

## Applying a step

1. Build `Step(from: selection, to: square)` and call `state.apply`.
2. If the result's `turnContinues`, keep the piece selected at its landing square; otherwise clear
   the selection.
3. Clear the notice.
4. A rejected step (never expected, since only legal targets reach this point) is logged with the
   game logger and leaves everything unchanged.

## Other actions

| Action | Allowed when | Effect |
|---|---|---|
| `undo()` | `canUndo` | `state.undo()`; selection and notice cleared (FR-036, FR-038) |
| `resign()` | not over | `state.resign(resigningSide)` (FR-032); selection and notice cleared |

`resigningSide` is the side to move in a two-player game and `playerSide` in a computer game.

## Derived values

| Value | Rule |
|---|---|
| `layout.bottomSide` | Light in two-player games; `playerSide` in computer games (FR-015) |
| `hintedPieces` | `state.movablePieces` (only capturing pieces when a capture is required, from the engine); empty when over (FR-025) |
| `targets` | `state.targets(from: selection)` (during a chain, the chain piece's jumps) (FR-026, FR-030) |
| `turnText` | "Light to move", "Dark to move", "Light to move · capture required" or "Dark to move · capture required" from `sideToMove` and `isCaptureRequired` (FR-014) |
| `resultText` | `nil` while in progress; otherwise "Light wins: no moves left", "Dark wins: no moves left", "Light resigned", "Dark resigned", "Draw by repetition" or "Draw by no progress" (FR-033) |

A resignation's sentence names the side that resigned (the loser), from the outcome's winner.

## Navigation (AppRouter)

| Action | Effect |
|---|---|
| `newGame()` | Push `setup` with `setup` loaded from the store |
| `setup` changes | Saved to the store immediately (R7) |
| `startGame()` | Only when `setup.canStart`: create a session from `GameState()` and the setup, resolve a Random side with the router's generator, and replace `setup` with `game` in the path |
| `open(.rules / .settings / .statistics)` | Push the placeholder route; Back pops it, leaving the session untouched (FR-005) |
| `requestHome()` | In progress: set `isConfirmingLeave`. Over or no session: pop to Home and drop the session |
| `confirmLeave()` | Pop to Home and drop the session (FR-042) |
| `cancelLeave()` | Clear `isConfirmingLeave`; the session is unchanged |
| `playAgain()` | Replace the session with a new one from the same setup, drawing a Random side again (FR-034) |
