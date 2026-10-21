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

    /// Every legal single step for the side to move: during a chain only the chain piece's jumps
    /// (FR-010); empty once the game is over (FR-008).
    public var legalSteps: [Step] {
        guard outcome == .inProgress else { return [] }
        if let chainSquare {
            return position.jumps(from: chainSquare)
        }
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
        if let chainSquare, step.from != chainSquare || !step.isJump { throw .mustContinueChain }
        let legal = legalSteps
        if legal.first?.isJump == true, !step.isJump { throw .captureRequired }
        guard legal.contains(step) else { throw .illegalStep }

        position.remove(at: step.from)
        if let captured = step.captured {
            position.remove(at: captured)
        }
        // A man ending a step on its far row is crowned at once, and crowning ends the turn,
        // even in the middle of a chain (FR-012).
        let crowned = piece.kind == .man && step.to.row == piece.side.farRow
        position.place(crowned ? Piece(side: piece.side, kind: .king) : piece, at: step.to)
        let turnContinues = step.isJump && !crowned && !position.jumps(from: step.to).isEmpty
        if turnContinues {
            chainSquare = step.to
        } else {
            chainSquare = nil
            sideToMove = sideToMove.opponent
        }
        return StepResult(
            side: piece.side, piece: piece, from: step.from, to: step.to, captured: step.captured,
            crowned: crowned, turnContinues: turnContinues, outcome: outcome)
    }
}
