import Testing

@testable import CheckersEngine

struct US5UndoTests {
    /// Four opening turns with no captures, Light first.
    static let opening = [Step("c3", "d4"), Step("b6", "a5"), Step("g3", "h4"), Step("a7", "b6")]

    /// Plays the opening and returns the game and the state before each of its turns.
    private func playOpening() throws -> (game: GameState, before: [GameState]) {
        var game = GameState()
        var before: [GameState] = []
        for step in Self.opening {
            before.append(game)
            try game.apply(step)
        }
        return (game, before)
    }

    @Test("US5 FR-UNDO-02 FR-UNDO-07: one undo restores the full state from before the last turn")
    func undoOnce() throws {
        var (game, before) = try playOpening()
        try game.undo()
        #expect(game == before[3])
        #expect(game.sideToMove == .dark)
        #expect(game.noProgressCount == before[3].noProgressCount)
        #expect(game.history == before[3].history)
    }

    @Test("US5 FR-UNDO-01: undo repeats back to the start, where it is no longer available")
    func undoToStart() throws {
        var (game, before) = try playOpening()
        for expected in before.reversed() {
            try game.undo()
            #expect(game == expected)
        }
        #expect(game == GameState())
        #expect(!game.canUndo)
        #expect(throws: RuleError.nothingToUndo) { try game.undo() }
        #expect(game == GameState())
    }

    @Test("US5 FR-UNDO-05: undo during a chain restores the position from before the chain")
    func undoMidChain() throws {
        let start = GameState(US3ChainAndCrowningTests.chainLayout, toMove: .light)
        var game = start
        try game.apply(Step("a3", "c5"))
        #expect(game.canUndo)
        try game.undo()
        #expect(game == start)
        #expect(game.sideToMove == .light)
        #expect(game.chainSquare == nil)
        #expect(!game.canUndo)
    }

    @Test("US5 FR-UNDO-06: undo is unavailable after the game has ended")
    func noUndoAfterTheEnd() throws {
        var won = GameState(["c3": .lightMan, "d4": .darkMan], toMove: .light)
        try won.apply(Step("c3", "e5"))
        var resigned = GameState()
        try resigned.apply(Step("c3", "d4"))
        try resigned.resign(.dark)
        for var game in [won, resigned] {
            let finished = game
            #expect(!game.canUndo)
            #expect(throws: RuleError.gameOver) { try game.undo() }
            #expect(game == finished)
        }
    }

    @Test("US5 FR-UNDO-07 FR-END-03: an undone turn no longer counts toward a draw by repetition")
    func undoUncountsRepetition() throws {
        let shuffle = US4EndingTests.shuffle
        var game = GameState(US4EndingTests.shuffleLayout, toMove: .light)
        for step in shuffle.prefix(7) {
            try game.apply(step)
        }
        for _ in 0..<4 {
            try game.undo()
        }
        for step in shuffle[3..<7] {
            try game.apply(step)
        }
        #expect(game.outcome == .inProgress)
        try game.apply(shuffle[7])
        #expect(game.outcome == .draw(reason: .repetition))
    }

    @Test("US5 FR-UNDO-01: undo is unavailable at the start and available after the first step")
    func undoAvailability() throws {
        var game = GameState()
        #expect(!game.canUndo)
        try game.apply(Step("c3", "d4"))
        #expect(game.canUndo)
    }
}
