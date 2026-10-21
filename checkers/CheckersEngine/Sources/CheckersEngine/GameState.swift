/// A game of American checkers: the position, whose turn it is, any capture chain in progress,
/// the draw counters, the turn history and the outcome. Nothing that affects play lives outside
/// it (FR-013). It is a value, so a copy is independent of the original and the same steps on
/// equal states give equal results (FR-026).
public struct GameState: Sendable, Equatable {
    public private(set) var position: Position
    public private(set) var sideToMove: Side
    /// The square of the piece that must keep jumping; `nil` between turns.
    public private(set) var chainSquare: Square?
    public private(set) var outcome: Outcome

    /// Completed turns since the last capture or man move (FR-017).
    var noProgressCount = 0
    /// One record per turn started, in order: the undo history and the repetition record
    /// (research R5).
    private(set) var history: [TurnRecord] = []

    /// A new game: the standard starting position with Light to move (FR-003).
    public init() {
        self.init(position: .start, sideToMove: .light)
    }

    /// A game that starts from any position with the given side to move. If that side has no
    /// legal step, the game is already lost (FR-014).
    init(position: Position, sideToMove: Side) {
        self.position = position
        self.sideToMove = sideToMove
        chainSquare = nil
        outcome = .inProgress
        if position.steps(for: sideToMove).isEmpty {
            outcome = .win(winner: sideToMove.opponent, reason: .noMovesLeft)
        }
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

    /// Whether `undo()` would take back a turn: the game is in progress and a turn has been
    /// started (FR-022, FR-024).
    public var canUndo: Bool {
        outcome == .inProgress && !history.isEmpty
    }

    /// How many times the current position with the current side to move has occurred at the
    /// start of a turn, including now (FR-016).
    var repetitionCount: Int {
        1 + history.count { $0.position == position && $0.sideToMove == sideToMove }
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

        if chainSquare == nil {
            history.append(
                TurnRecord(
                    position: position, sideToMove: sideToMove, noProgressCount: noProgressCount))
        }
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
            // Every step of a chain is a jump, so a turn captured if its last step did.
            let progress = step.isJump || piece.kind == .man
            endTurn(progress: progress)
        }
        return StepResult(
            side: piece.side, piece: piece, from: step.from, to: step.to, captured: step.captured,
            crowned: crowned, turnContinues: turnContinues, outcome: outcome)
    }

    /// Ends the game with a win for the other side. Either side may resign at any time while the
    /// game is in progress, including during a chain (FR-015).
    public mutating func resign(_ side: Side) throws(RuleError) {
        guard outcome == .inProgress else { throw .gameOver }
        outcome = .win(winner: side.opponent, reason: .resignation)
        chainSquare = nil
    }

    /// Takes back the last turn, whichever side made it, restoring the state from before it,
    /// including the draw counters; during a chain it discards the partial turn. The undone turn
    /// no longer counts for repetition (FR-021 to FR-024; contract: undo).
    public mutating func undo() throws(RuleError) {
        guard outcome == .inProgress else { throw .gameOver }
        guard let record = history.popLast() else { throw .nothingToUndo }
        position = record.position
        sideToMove = record.sideToMove
        noProgressCount = record.noProgressCount
        chainSquare = nil
    }

    /// Passes the turn and decides whether the game has ended, in the precedence of FR-019: a win
    /// by no moves left, then a draw by repetition, then a draw by no progress (research R6).
    private mutating func endTurn(progress: Bool) {
        noProgressCount = progress ? 0 : noProgressCount + 1
        let mover = sideToMove
        chainSquare = nil
        sideToMove = mover.opponent
        if position.steps(for: sideToMove).isEmpty {
            outcome = .win(winner: mover, reason: .noMovesLeft)
        } else if repetitionCount >= 3 {
            outcome = .draw(reason: .repetition)
        } else if noProgressCount >= 80 {
            outcome = .draw(reason: .noProgress)
        }
    }
}

/// The state at the start of a turn: what undo restores and what the repetition rule compares
/// (research R5).
struct TurnRecord: Sendable, Equatable {
    let position: Position
    let sideToMove: Side
    let noProgressCount: Int
}
