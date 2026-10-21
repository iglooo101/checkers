/// A game of American checkers: the position, whose turn it is, any capture chain in progress
/// and the outcome (FR-013). It is a value, so a copy is independent of the original and the
/// same steps on equal states give equal results (FR-026).
public struct GameState: Sendable, Equatable {
    public private(set) var position: Position
    public private(set) var sideToMove: Side
    /// The square of the piece that must keep jumping; `nil` between turns.
    public private(set) var chainSquare: Square?
    public private(set) var outcome: Outcome

    /// A new game: the standard starting position with Light to move (FR-003).
    public init() {
        self.init(position: .start, sideToMove: .light)
    }

    /// A game that starts from any position with the given side to move.
    init(position: Position, sideToMove: Side) {
        self.position = position
        self.sideToMove = sideToMove
        chainSquare = nil
        outcome = .inProgress
    }

    /// Every legal single step for the side to move; empty once the game is over (FR-008).
    public var legalSteps: [Step] {
        guard outcome == .inProgress else { return [] }
        return position.steps(for: sideToMove)
    }

    /// The squares of the pieces that have a legal step, in board order.
    public var movablePieces: [Square] {
        var squares: [Square] = []
        for step in legalSteps where squares.last != step.from {
            squares.append(step.from)
        }
        return squares
    }

    /// The landing squares of the legal steps from a square; empty for any other square.
    public func targets(from square: Square) -> [Square] {
        legalSteps.filter { $0.from == square }.map(\.to)
    }

    /// Whether the side to move must capture: the legal steps are jumps.
    public var isCaptureRequired: Bool {
        legalSteps.first?.isJump ?? false
    }

    /// Applies one step for the side to move and reports what it did. A rejected step throws
    /// and changes nothing (FR-020; contract: apply).
    @discardableResult
    public mutating func apply(_ step: Step) throws(RuleError) -> StepResult {
        guard outcome == .inProgress else { throw .gameOver }
        guard let piece = position.piece(at: step.from) else { throw .illegalStep }
        guard piece.side == sideToMove else { throw .notSideToMove }
        let legal = legalSteps
        if legal.first?.isJump == true, !step.isJump { throw .captureRequired }
        guard legal.contains(step) else { throw .illegalStep }

        position.remove(at: step.from)
        if let captured = step.captured {
            position.remove(at: captured)
        }
        position.place(piece, at: step.to)
        sideToMove = sideToMove.opponent
        return StepResult(
            side: piece.side, piece: piece, from: step.from, to: step.to, captured: step.captured,
            crowned: false, turnContinues: false, outcome: outcome)
    }
}
