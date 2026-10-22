import Testing

@testable import CheckersEngine

/// The computer chooses legal, sensible turns (specs/005-computer-opponent/spec.md, US1). Every
/// search here is shallow (Easy, Medium or depth 4) because the blocking tests run in Debug;
/// Hard at full strength is exercised in CheckersEngineStrengthTests.
struct US1ComputerPlayerTests {
    static let depthFour = SearchLimits(maxDepth: 4, nodeLimit: nil, margin: 0)

    @Test("US1 FR-AI-01: from the start and 50 random positions, every turn chosen is legal")
    func legalTurns() throws {
        var states = [GameState()]
        for seed in 0..<50 {
            states.append(try randomPosition(seed: UInt64(seed)))
        }
        for (index, state) in states.enumerated() {
            for level in [ComputerLevel.easy, .medium] {
                let turn = try #require(
                    ComputerPlayer.chooseTurn(in: state, level: level, seed: UInt64(index)))
                try checkLegal(turn.steps, in: state, label: "position \(index), \(level)")
            }
            let turn = try #require(
                ComputerPlayer.chooseTurn(in: state, limits: Self.depthFour, seed: 0))
            try checkLegal(turn.steps, in: state, label: "position \(index), depth 4")
        }
    }

    @Test("US1 FR-AI-01: captures are made, chains are completed, and crowning ends a chain")
    func capturesAndChains() throws {
        let capture = GameState(["c3": .lightMan, "a1": .lightMan, "d4": .darkMan], toMove: .light)
        #expect(choose(capture) == [Step("c3", "e5")])

        let doubleJump = GameState(
            ["a3": .lightMan, "g1": .lightMan, "b4": .darkMan, "d6": .darkMan, "h8": .darkMan],
            toMove: .light)
        #expect(choose(doubleJump) == [Step("a3", "c5"), Step("c5", "e7")])

        let crowning = GameState(
            ["b6": .lightMan, "c7": .darkMan, "e7": .darkMan, "a1": .lightMan], toMove: .light)
        #expect(choose(crowning) == [Step("b6", "d8")])
    }

    @Test("US1 FR-AI-01: no turn once the game is over or while a chain is in progress")
    func noTurn() throws {
        var over = GameState()
        try over.resign(.light)
        #expect(ComputerPlayer.chooseTurn(in: over, level: .easy, seed: 0) == nil)

        var chain = GameState(
            ["a3": .lightMan, "g1": .lightMan, "b4": .darkMan, "d6": .darkMan, "h8": .darkMan],
            toMove: .light)
        try chain.apply(Step("a3", "c5"))
        #expect(chain.chainSquare != nil)
        #expect(ComputerPlayer.chooseTurn(in: chain, level: .easy, seed: 0) == nil)
    }

    @Test("US1 FR-AI-01: does not give a man away for nothing")
    func keepsMaterial() {
        // c3–d4 lets e5 jump to c3; c3–b4 is safe.
        let state = GameState(["c3": .lightMan, "e5": .darkMan], toMove: .light)
        #expect(choose(state) == [Step("c3", "b4")])
    }

    @Test("US1 FR-AI-01: plays a two-for-one shot")
    func playsShot() {
        // e3–d4 forces c5 to jump to e3, then f2 jumps e3 and e5 and Dark has nothing left.
        let state = GameState(
            [
                "c3": .lightMan, "e3": .lightMan, "f2": .lightMan, "g1": .lightMan,
                "c5": .darkMan, "e5": .darkMan,
            ], toMove: .light)
        #expect(choose(state) == [Step("e3", "d4")])
    }

    @Test("US1 FR-AI-01: prefers a win in one turn to a slower one")
    func fastestWin() throws {
        // King to g1 leaves the Dark man on h2 without a move.
        let state = GameState(["f2": .lightKing, "h2": .darkMan], toMove: .light)
        let turn = try #require(
            ComputerPlayer.chooseTurn(in: state, limits: Self.depthFour, seed: 0))
        #expect(turn.steps == [Step("f2", "g1")])
        #expect(turn.score > 9_000)
    }

    @Test("US1 FR-AI-01: a position already seen in the game scores as a draw")
    func repetitionIsDraw() throws {
        // One king against two, after both sides moved and moved back: b2–c3 repeats the
        // position Dark faced after the first b2–c3, the draw a losing side should take.
        var state = GameState(["b2": .lightKing, "g7": .darkKing, "h8": .darkKing], toMove: .light)
        for step in [Step("b2", "c3"), Step("g7", "f8"), Step("c3", "b2"), Step("f8", "g7")] {
            try state.apply(step)
        }
        let turn = try #require(
            ComputerPlayer.chooseTurn(in: state, limits: Self.depthFour, seed: 0))
        #expect(turn.steps == [Step("b2", "c3")])
        #expect(turn.score == 0)
    }

    @Test("US1 FR-AI-01: a turn that reaches 80 turns without progress scores as a draw")
    func noProgressIsDraw() throws {
        var state = GameState(
            ["a1": .lightKing, "c1": .lightKing, "h8": .darkKing], toMove: .light)
        state.noProgressCount = 79
        let turn = try #require(
            ComputerPlayer.chooseTurn(in: state, limits: Self.depthFour, seed: 0))
        #expect(turn.score == 0)
    }

    @Test("US1 FR-AI-01: stopping at once still gives a legal depth-1 turn; same seed, same turn")
    func stoppingAndRepeatability() throws {
        let state = try randomPosition(seed: 7)
        let stopped = try #require(
            ComputerPlayer.chooseTurn(in: state, limits: Self.depthFour, seed: 1) { true })
        #expect(stopped.depth == 1)
        try checkLegal(stopped.steps, in: state, label: "stopped")

        let start = GameState()
        let first = try #require(ComputerPlayer.chooseTurn(in: start, level: .medium, seed: 42))
        let second = try #require(ComputerPlayer.chooseTurn(in: start, level: .medium, seed: 42))
        #expect(first == second)
        #expect(first.depth == ComputerLevel.medium.limits.maxDepth)
        #expect(first.nodes > 0)
    }

    private func choose(_ state: GameState) -> [Step]? {
        ComputerPlayer.chooseTurn(in: state, limits: Self.depthFour, seed: 0)?.steps
    }

    /// Applies the steps and checks they form exactly one complete turn.
    private func checkLegal(_ steps: [Step], in state: GameState, label: String) throws {
        var state = state
        try #require(!steps.isEmpty, "\(label)")
        for (index, step) in steps.enumerated() {
            let result = try state.apply(step)
            #expect(result.turnContinues == (index < steps.count - 1), "\(label): step \(index)")
        }
    }

    /// A position reached by seeded random play, at the start of a turn of a game in progress.
    private func randomPosition(seed: UInt64) throws -> GameState {
        var generator = SeededGenerator(seed: seed)
        var state = GameState()
        var last = state
        for _ in 0..<Int.random(in: 0..<120, using: &generator) {
            guard state.outcome == .inProgress else { break }
            if state.chainSquare == nil {
                last = state
            }
            try state.apply(try #require(state.legalSteps.randomElement(using: &generator)))
        }
        return state.outcome == .inProgress && state.chainSquare == nil ? state : last
    }
}
