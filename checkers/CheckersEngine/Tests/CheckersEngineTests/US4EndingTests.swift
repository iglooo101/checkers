import Testing

@testable import CheckersEngine

struct US4EndingTests {
    /// Light's king move d2–c1 leaves the Dark man on a3 with no legal move.
    static let blockingLayout: [String: Piece] = [
        "b2": .lightMan, "d2": .lightKing, "a3": .darkMan,
    ]

    /// Two kings shuffling between two squares each: the opening position recurs every four
    /// turns, so its third occurrence comes after turn 8.
    static let shuffleLayout: [String: Piece] = ["h2": .lightKing, "a7": .darkKing]
    static let shuffle = Array(
        repeating: [Step("h2", "g1"), Step("a7", "b8"), Step("g1", "h2"), Step("b8", "a7")],
        count: 2
    ).flatMap { $0 }

    /// Two kings touring loops of 8 and 6 squares that never touch: no position occurs three
    /// times within 80 turns (checked with the research prototype).
    static let tourLayout: [String: Piece] = ["b2": .lightKing, "e7": .darkKing]
    static let lightTour = ["b2", "c1", "d2", "e3", "d4", "c5", "b4", "c3"]
    static let darkTour = ["e7", "f8", "g7", "h6", "g5", "f6"]

    /// The first `turns` steps of the tour, Light moving on odd turns and Dark on even turns.
    static func tour(turns: Int) -> [Step] {
        (1...turns).map { turn in
            let (loop, move) =
                turn.isMultiple(of: 2) ? (darkTour, turn / 2 - 1) : (lightTour, turn / 2)
            return Step(loop[move % loop.count], loop[(move + 1) % loop.count])
        }
    }

    @Test("US4 FR-END-01: capturing the last opposing piece wins, reason no moves left")
    func lastPieceCaptured() throws {
        var game = GameState(["c3": .lightMan, "d4": .darkMan], toMove: .light)
        let result = try game.apply(Step("c3", "e5"))
        #expect(game.outcome == .win(winner: .light, reason: .noMovesLeft))
        #expect(result.outcome == game.outcome)
        #expect(game.legalSteps.isEmpty)
    }

    @Test("US4 FR-END-01: leaving the opponent with pieces but no legal move wins")
    func opponentBlocked() throws {
        var game = GameState(Self.blockingLayout, toMove: .light)
        try game.apply(Step("d2", "c1"))
        #expect(game.position.piece(at: Square("a3")) == .darkMan)
        #expect(game.outcome == .win(winner: .light, reason: .noMovesLeft))
    }

    @Test("US4 FR-END-01: a side to move with no pieces has already lost")
    func noPiecesAtStart() {
        let game = GameState(["h8": .darkMan], toMove: .light)
        #expect(game.outcome == .win(winner: .dark, reason: .noMovesLeft))
        #expect(game.legalSteps.isEmpty)
    }

    @Test(
        "US4 FR-END-02: either side may resign at any time, even mid-chain or on the other's turn")
    func resignation() throws {
        var game = GameState()
        try game.resign(.dark)
        #expect(game.outcome == .win(winner: .light, reason: .resignation))

        var chain = GameState(US3ChainAndCrowningTests.chainLayout, toMove: .light)
        try chain.apply(Step("a3", "c5"))
        let position = chain.position
        try chain.resign(.light)
        #expect(chain.outcome == .win(winner: .dark, reason: .resignation))
        #expect(chain.position == position)
        #expect(chain.chainSquare == nil)
    }

    @Test("US4 FR-END-03: the third occurrence of a position with the same side to move draws")
    func threefoldRepetition() throws {
        var game = GameState(Self.shuffleLayout, toMove: .light)
        for step in Self.shuffle.dropLast() {
            try game.apply(step)
            #expect(game.outcome == .inProgress)
        }
        let result = try game.apply(Self.shuffle[7])
        #expect(game.outcome == .draw(reason: .repetition))
        #expect(result.outcome == game.outcome)
    }

    @Test("US4 FR-END-03: only turn starts are recorded, never positions in the middle of a chain")
    func onlyTurnStartsRecorded() throws {
        let start = GameState(US3ChainAndCrowningTests.chainLayout, toMove: .light)
        var game = start
        try game.apply(Step("a3", "c5"))
        try game.apply(Step("c5", "e7"))
        #expect(game.history.count == 1)
        #expect(game.history.first?.position == start.position)
        #expect(game.history.first?.sideToMove == .light)
    }

    @Test("US4 FR-END-04: 80 turns without a capture or a man move draw by no progress")
    func noProgress() throws {
        var game = GameState(Self.tourLayout, toMove: .light)
        let steps = Self.tour(turns: 80)
        for step in steps.dropLast() {
            try game.apply(step)
        }
        #expect(game.outcome == .inProgress)
        #expect(game.noProgressCount == 79)
        try game.apply(steps[79])
        #expect(game.outcome == .draw(reason: .noProgress))
    }

    @Test("US4 FR-END-04: a man move, including a crowning move, resets the no-progress count")
    func progressResetsCount() throws {
        var layout = Self.tourLayout
        layout["h2"] = .lightMan
        var game = GameState(layout, toMove: .light)
        let steps = Self.tour(turns: 80)
        for step in steps.prefix(78) {
            try game.apply(step)
        }
        try game.apply(Step("h2", "g3"))
        try game.apply(steps[79])
        #expect(game.outcome == .inProgress)
        #expect(game.noProgressCount == 1)

        var crowning = GameState(["g7": .lightMan, "a1": .darkKing], toMove: .light)
        crowning.noProgressCount = 79
        try crowning.apply(Step("g7", "h8"))
        #expect(crowning.noProgressCount == 0)
        #expect(crowning.outcome == .inProgress)
    }

    @Test("US4 FR-END-01 FR-END-04: a win by no moves left beats a draw by no progress")
    func winBeatsDraw() throws {
        var game = GameState(Self.blockingLayout, toMove: .light)
        game.noProgressCount = 79
        try game.apply(Step("d2", "c1"))
        #expect(game.outcome == .win(winner: .light, reason: .noMovesLeft))
    }

    @Test(
        "US4 FR-END-03 FR-END-04: when both draw rules trigger together, the draw is by repetition")
    func repetitionBeatsNoProgress() throws {
        var game = GameState(Self.shuffleLayout, toMove: .light)
        game.noProgressCount = 72
        for step in Self.shuffle {
            try game.apply(step)
        }
        #expect(game.noProgressCount == 80)
        #expect(game.outcome == .draw(reason: .repetition))
    }

    @Test("US4 FR-END-05: a game is drawn only by repetition or no progress, never by agreement")
    func noDrawByAgreement() {
        // Exhaustive on purpose: a new kind of draw would stop this from compiling.
        for reason in [DrawReason.repetition, .noProgress] {
            switch reason {
            case .repetition, .noProgress: break
            }
        }
    }

    @Test("US4 FR-END-01 FR-END-02: once the game is over, steps and resignations are rejected")
    func nothingAfterTheEnd() throws {
        var game = GameState(["c3": .lightMan, "d4": .darkMan], toMove: .light)
        try game.apply(Step("c3", "e5"))
        let finished = game
        #expect(throws: RuleError.gameOver) { try game.apply(Step("e5", "f6")) }
        #expect(throws: RuleError.gameOver) { try game.resign(.light) }
        #expect(throws: RuleError.gameOver) { try game.resign(.dark) }
        #expect(game == finished)
    }
}
