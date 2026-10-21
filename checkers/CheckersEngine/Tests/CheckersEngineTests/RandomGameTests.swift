import Testing

@testable import CheckersEngine

struct RandomGameTests {
    /// The longest a game can last: 168 man moves and 23 captures, each preceded by at most 79
    /// other turns, plus 79 more at the end (research R11).
    static let turnBound = 15_360

    @Test("US5 SC-003: 1,000 random games end, stay legal and undo exactly")
    func randomGames() throws {
        var outcomes: [Outcome: Int] = [:]
        for game in 0..<1_000 {
            let outcome = try playAndUndo(seed: UInt64(game), label: "game \(game)")
            outcomes[outcome, default: 0] += 1
        }
        // Random play reaches every kind of ending except resignation.
        #expect(
            outcomes.keys.contains { if case .win(_, .noMovesLeft) = $0 { true } else { false } })
        #expect(outcomes[.draw(reason: .repetition), default: 0] > 0)
        #expect(outcomes[.draw(reason: .noProgress), default: 0] > 0)
    }

    /// Plays one game of random legal steps, checking the invariants after every step, then
    /// undoes it turn by turn and returns its outcome.
    private func playAndUndo(seed: UInt64, label: String) throws -> Outcome {
        var generator = SeededGenerator(seed: seed)
        var state = GameState()
        var turnStarts: [GameState] = []
        while state.outcome == .inProgress {
            if state.chainSquare == nil {
                turnStarts.append(state)
                try #require(turnStarts.count <= Self.turnBound, "\(label) did not end")
            }
            let step = try #require(state.legalSteps.randomElement(using: &generator), "\(label)")
            let before = state
            try state.apply(step)
            try checkInvariants(state, after: step, from: before, label: label)
        }

        // Undo is unavailable once the game has ended (FR-024), so undo starts from the start of
        // the final turn and must match every recorded turn start back to the beginning.
        var undoing = try #require(turnStarts.last, "\(label)")
        for expected in turnStarts.reversed().dropFirst() {
            try undoing.undo()
            try #require(
                undoing == expected, "\(label): undo did not restore turn \(turnStarts.count)")
        }
        #expect(undoing == GameState(), "\(label)")
        #expect(!undoing.canUndo, "\(label)")
        return state.outcome
    }

    /// The invariants of data-model.md, checked after every step.
    private func checkInvariants(
        _ state: GameState, after step: Step, from before: GameState, label: String
    ) throws {
        let position = state.position
        let context = "\(label) after \(step.from.name)-\(step.to.name)"
        try #require(position.light & position.dark == 0, "\(context): a square holds both sides")
        try #require(
            position.kings & ~(position.light | position.dark) == 0, "\(context): lone king bit")
        for side in [Side.light, .dark] {
            try #require(position.pieceCount(of: side) <= 12, "\(context): more than 12 pieces")
            let uncrowned = position.squares(of: side).filter {
                $0.row == side.farRow && position.piece(at: $0)?.kind == .man
            }
            try #require(uncrowned.isEmpty, "\(context): a man on its far row")
        }
        let piecesBefore =
            before.position.pieceCount(of: .light) + before.position.pieceCount(of: .dark)
        let piecesAfter = position.pieceCount(of: .light) + position.pieceCount(of: .dark)
        try #require(
            piecesAfter == piecesBefore - (step.isJump ? 1 : 0), "\(context): wrong piece count")
        if state.outcome == .inProgress {
            try #require(!state.legalSteps.isEmpty, "\(context): in progress with no legal step")
            try #require((0...79).contains(state.noProgressCount), "\(context): no-progress count")
        }
        if let chainSquare = state.chainSquare {
            try #require(
                position.piece(at: chainSquare)?.side == state.sideToMove, "\(context): chain")
            let jumps = position.jumps(from: chainSquare)
            try #require(!jumps.isEmpty && state.legalSteps == jumps, "\(context): chain steps")
        }
    }
}
