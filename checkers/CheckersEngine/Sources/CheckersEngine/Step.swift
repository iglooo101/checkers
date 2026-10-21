/// One action on the board: a simple move to an adjacent square, or a single jump. A step two
/// diagonal squares long is a jump over the square in between (FR-008, FR-009).
public struct Step: Sendable, Hashable {
    public let from: Square
    public let to: Square

    public init(from: Square, to: Square) {
        self.from = from
        self.to = to
    }

    /// Whether the step is two diagonal squares long, which makes it a jump.
    public var isJump: Bool {
        captured != nil
    }

    /// For a jump, the square in between, whose piece the jump captures; otherwise `nil`.
    public var captured: Square? {
        let columnDistance = to.column - from.column
        let rowDistance = to.row - from.row
        guard abs(columnDistance) == 2, abs(rowDistance) == 2 else { return nil }
        return Square(column: from.column + columnDistance / 2, row: from.row + rowDistance / 2)
    }
}

/// What an applied step did, for screens to play sounds, make announcements and show the
/// computer's jumps one by one (FR-027).
public struct StepResult: Sendable, Equatable {
    /// The side that moved.
    public let side: Side
    /// The moving piece as it was before the step.
    public let piece: Piece
    public let from: Square
    public let to: Square
    /// The square of the captured piece, for a jump.
    public let captured: Square?
    /// Whether the man became a king on this step.
    public let crowned: Bool
    /// Whether the same piece must jump again (a chain in progress).
    public let turnContinues: Bool
    /// The outcome after the step: `inProgress` unless this step ended the game.
    public let outcome: Outcome
}
