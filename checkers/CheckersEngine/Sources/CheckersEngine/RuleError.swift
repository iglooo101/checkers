/// Why the engine rejected a step, a resignation or an undo. A rejected call changes nothing
/// (FR-020, FR-024).
public enum RuleError: Error, Sendable, Equatable {
    /// The game has ended; no step, resignation or undo is accepted.
    case gameOver
    /// The piece belongs to the side whose turn it is not.
    case notSideToMove
    /// A capture is available, so a simple move is not allowed.
    case captureRequired
    /// A chain is in progress; only the chain's piece may move, and only by jumping.
    case mustContinueChain
    /// There is no piece on the from square, or the step is not one of the legal steps.
    case illegalStep
    /// Undo at the starting position of the game.
    case nothingToUndo
}
