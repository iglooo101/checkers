import Testing

@testable import CheckersEngine

struct US3ChainAndCrowningTests {
    /// Light man a3 can jump b4 and then d6; Light man g1 could otherwise move.
    static let chainLayout: [String: Piece] = [
        "a3": .lightMan, "g1": .lightMan, "b4": .darkMan, "d6": .darkMan, "h8": .darkMan,
    ]

    /// Light man b6 jumps c7 onto row 8, where a king could jump e7 next.
    static let crowningLayout: [String: Piece] = [
        "b6": .lightMan, "c7": .darkMan, "e7": .darkMan,
    ]

    @Test(
        "US3 FR-CHAIN-01 FR-CHAIN-02 FR-RULE-06: after a chain's first jump only that man may jump on"
    )
    func firstJumpOfChain() throws {
        var game = GameState(Self.chainLayout, toMove: .light)
        let result = try applyChecked(Step("a3", "c5"), to: &game)
        #expect(game.position.piece(at: Square("b4")) == nil)
        #expect(game.position.piece(at: Square("c5")) == .lightMan)
        #expect(game.sideToMove == .light)
        #expect(game.chainSquare == Square("c5"))
        #expect(game.legalSteps == [Step("c5", "e7")])
        #expect(game.isCaptureRequired)
        #expect(result.turnContinues)
    }

    @Test("US3 FR-CHAIN-02: during a chain, another piece or a simple move is rejected")
    func chainLock() throws {
        var game = GameState(Self.chainLayout, toMove: .light)
        try game.apply(Step("a3", "c5"))
        let before = game
        #expect(throws: RuleError.mustContinueChain) { try game.apply(Step("g1", "h2")) }
        #expect(throws: RuleError.mustContinueChain) { try game.apply(Step("c5", "b6")) }
        #expect(game == before)
    }

    @Test("US3 FR-CHAIN-03 FR-RULE-06: the turn ends when the jumping piece has no further jump")
    func chainEnds() throws {
        var game = GameState(Self.chainLayout, toMove: .light)
        try game.apply(Step("a3", "c5"))
        let result = try applyChecked(Step("c5", "e7"), to: &game)
        #expect(game.position.piece(at: Square("d6")) == nil)
        #expect(game.sideToMove == .dark)
        #expect(game.chainSquare == nil)
        #expect(!result.turnContinues)
    }

    @Test(
        "US3 FR-RULE-07 FR-CHAIN-03: a man crowned mid-chain stops, though the king could jump on")
    func crownedMidChain() throws {
        var game = GameState(Self.crowningLayout, toMove: .light)
        let result = try applyChecked(Step("b6", "d8"), to: &game)
        #expect(result.crowned)
        #expect(!result.turnContinues)
        #expect(game.position.piece(at: Square("d8")) == .lightKing)
        #expect(game.position.jumps(from: Square("d8")) == [Step("d8", "f6")])
        #expect(game.position.piece(at: Square("e7")) == .darkMan)
        #expect(game.sideToMove == .dark)
    }

    @Test("US3 FR-RULE-07: a Dark man reaching row 1 by a simple move is crowned")
    func crownedBySimpleMove() throws {
        var game = GameState(["b2": .darkMan, "g3": .lightMan], toMove: .dark)
        let result = try applyChecked(Step("b2", "a1"), to: &game)
        #expect(result.crowned)
        #expect(game.position.piece(at: Square("a1")) == .darkKing)
        #expect(game.sideToMove == .light)
    }

    @Test("US3 FR-CHAIN-02: when the jumping piece has two next jumps, either may be chosen")
    func branchingChain() throws {
        let layout: [String: Piece] = [
            "c3": .lightMan, "d4": .darkMan, "d6": .darkMan, "f6": .darkMan, "h8": .darkMan,
        ]
        var game = GameState(layout, toMove: .light)
        try applyChecked(Step("c3", "e5"), to: &game)
        #expect(game.legalSteps == [Step("e5", "c7"), Step("e5", "g7")])
        for next in game.legalSteps {
            var branch = game
            try applyChecked(next, to: &branch)
            #expect(branch.sideToMove == .dark)
        }
    }

    @Test("US3 FR-CHAIN-01: a king's chain may cross a square again but never jumps a piece twice")
    func kingLoop() throws {
        let layout: [String: Piece] = [
            "c1": .lightKing, "d2": .darkMan, "d4": .darkMan, "b4": .darkMan, "b2": .darkMan,
            "h8": .darkMan,
        ]
        var game = GameState(layout, toMove: .light)
        for (from, to) in [("c1", "e3"), ("e3", "c5"), ("c5", "a3"), ("a3", "c1")] {
            try applyChecked(Step(from, to), to: &game)
        }
        for name in ["d2", "d4", "b4", "b2"] {
            #expect(game.position.piece(at: Square(name)) == nil, "\(name)")
        }
        #expect(game.position.piece(at: Square("c1")) == .lightKing)
        #expect(game.sideToMove == .dark)
        #expect(game.chainSquare == nil)
    }

    @Test("US3 FR-027: a step result names the side, piece, squares, capture, crowning and turn")
    func stepResults() throws {
        var game = GameState(Self.chainLayout, toMove: .light)
        #expect(
            try game.apply(Step("a3", "c5"))
                == StepResult(
                    side: .light, piece: .lightMan, from: Square("a3"), to: Square("c5"),
                    captured: Square("b4"), crowned: false, turnContinues: true,
                    outcome: .inProgress))
        #expect(
            try game.apply(Step("c5", "e7"))
                == StepResult(
                    side: .light, piece: .lightMan, from: Square("c5"), to: Square("e7"),
                    captured: Square("d6"), crowned: false, turnContinues: false,
                    outcome: .inProgress))

        var crowning = GameState(Self.crowningLayout, toMove: .light)
        #expect(
            try crowning.apply(Step("b6", "d8"))
                == StepResult(
                    side: .light, piece: .lightMan, from: Square("b6"), to: Square("d8"),
                    captured: Square("c7"), crowned: true, turnContinues: false,
                    outcome: .inProgress))
    }

    /// Applies a step and checks that its result describes exactly what changed on the board
    /// (FR-027, acceptance scenario 6): the piece left `from` and stands on `to` (as a king if
    /// crowned), the captured square alone was emptied, and `turnContinues` matches the chain.
    @discardableResult
    private func applyChecked(_ step: Step, to game: inout GameState) throws -> StepResult {
        let before = game
        let result = try game.apply(step)
        let label = "\(step.from.name)-\(step.to.name)"
        let moved = try #require(before.position.piece(at: step.from), "\(label)")
        #expect(result.side == before.sideToMove, "\(label)")
        #expect(result.piece == moved, "\(label)")
        #expect(result.from == step.from && result.to == step.to, "\(label)")
        #expect(result.captured == step.captured, "\(label)")
        #expect(game.position.piece(at: step.from) == nil, "\(label)")
        let landed = Piece(side: moved.side, kind: result.crowned ? .king : moved.kind)
        #expect(game.position.piece(at: step.to) == landed, "\(label)")
        if result.crowned {
            #expect(moved.kind == .man && step.to.row == moved.side.farRow, "\(label)")
        }
        for square in Square.all
        where square != step.from && square != step.to && square != step.captured {
            #expect(
                game.position.piece(at: square) == before.position.piece(at: square),
                "\(label) changed \(square.name)")
        }
        if let captured = step.captured {
            #expect(game.position.piece(at: captured) == nil, "\(label)")
        }
        #expect(result.turnContinues == (game.chainSquare == step.to), "\(label)")
        return result
    }
}
