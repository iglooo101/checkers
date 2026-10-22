import Testing

@testable import CheckersEngine

/// The computer's turn generator must produce exactly the turns the rules engine allows
/// (specs/005-computer-opponent/research.md R1).
struct TurnGeneratorTests {
    @Test(
        "FR-AI-01: complete-turn counts from the start match the published counts",
        arguments: [
            (1, 7), (2, 49), (3, 302), (4, 1_469), (5, 7_361), (6, 36_768), (7, 179_740),
        ])
    func referenceCount(turns: Int, expected: Int) {
        var buffers = (0...turns).map { _ in [Turn]() }
        #expect(countTurns(Board(Position.start), .light, turns, &buffers) == expected)
    }

    @Test("FR-AI-01: in 1,000 random positions the turns equal those the rules engine allows")
    func sameTurnsAsGameState() throws {
        var buffer: [Turn] = []
        for seed in 0..<1_000 {
            let state = try randomPosition(seed: UInt64(seed))
            TurnGenerator.turns(of: state.sideToMove, on: Board(state.position), into: &buffer)
            let expected = try turnsThroughGameState(state)
            #expect(tally(buffer) == tally(expected), "seed \(seed): \(state.position)")
        }
    }

    @Test("FR-AI-01: a chain stops when a man is crowned; a king keeps jumping")
    func crowningEndsChain() {
        var buffer: [Turn] = []
        // From b6 over c7 the man lands on d8 and is crowned; the jump over e7 a king could
        // make from there is not part of the turn.
        let man = Position(["b6": .lightMan, "c7": .darkMan, "e7": .darkMan])
        TurnGenerator.turns(of: .light, on: Board(man), into: &buffer)
        #expect(buffer.count == 1)
        #expect(buffer.first?.board == Board(Position(["d8": .lightKing, "e7": .darkMan])))
        #expect(buffer.first?.captures == 1)

        let king = Position(["b6": .lightKing, "c7": .darkMan, "e7": .darkMan])
        TurnGenerator.turns(of: .light, on: Board(king), into: &buffer)
        #expect(buffer.map(\.board) == [Board(Position(["f6": .lightKing]))])
        #expect(buffer.first?.captures == 2)
    }

    @Test("FR-AI-01: only jumps when any jump exists, and progress means a capture or a man move")
    func mandatoryCaptureAndProgress() {
        var buffer: [Turn] = []
        let capture = Position(["c3": .lightMan, "a1": .lightMan, "d4": .darkMan])
        TurnGenerator.turns(of: .light, on: Board(capture), into: &buffer)
        #expect(buffer.map(\.board) == [Board(Position(["e5": .lightMan, "a1": .lightMan]))])
        #expect(buffer.allSatisfy { $0.isProgress })

        let kings = Position(["d4": .lightKing, "h8": .darkKing])
        TurnGenerator.turns(of: .light, on: Board(kings), into: &buffer)
        #expect(buffer.count == 4)
        #expect(buffer.allSatisfy { !$0.isProgress && $0.captures == 0 })
    }

    /// Counts complete-turn sequences with the turn generator (a "perft" count).
    private func countTurns(_ board: Board, _ side: Side, _ turns: Int, _ buffers: inout [[Turn]])
        -> Int
    {
        guard turns > 0 else { return 1 }
        var buffer = buffers[turns]
        TurnGenerator.turns(of: side, on: board, into: &buffer)
        var count = 0
        for turn in buffer {
            count += countTurns(turn.board, side.opponent, turns - 1, &buffers)
        }
        buffers[turns] = buffer
        return count
    }

    /// A position reached by seeded random play, at the start of a turn of a game in progress.
    private func randomPosition(seed: UInt64) throws -> GameState {
        var generator = SeededGenerator(seed: seed)
        var state = GameState()
        let length = Int.random(in: 0..<120, using: &generator)
        var last = state
        for _ in 0..<length {
            guard state.outcome == .inProgress else { break }
            if state.chainSquare == nil {
                last = state
            }
            let step = try #require(state.legalSteps.randomElement(using: &generator))
            try state.apply(step)
        }
        return state.outcome == .inProgress && state.chainSquare == nil ? state : last
    }

    /// Every complete turn of the side to move, enumerated step by step through `GameState`.
    private func turnsThroughGameState(_ state: GameState) throws -> [Turn] {
        var turns: [Turn] = []
        // `movedMan` is decided by the turn's first step; later jumps are by the same piece.
        func extend(_ state: GameState, captures: Int, movedMan: Bool?) throws {
            for step in state.legalSteps {
                let isMan = movedMan ?? (state.position.piece(at: step.from)?.kind == .man)
                var next = state
                let result = try next.apply(step)
                let total = captures + (result.captured == nil ? 0 : 1)
                if result.turnContinues {
                    try extend(next, captures: total, movedMan: isMan)
                } else {
                    turns.append(
                        Turn(
                            board: Board(next.position), captures: total,
                            isProgress: total > 0 || isMan))
                }
            }
        }
        try extend(state, captures: 0, movedMan: nil)
        return turns
    }

    /// How many times each turn occurs, so different jump orders that end alike still count.
    private func tally(_ turns: [Turn]) -> [Turn: Int] {
        turns.reduce(into: [:]) { counts, turn in counts[turn, default: 0] += 1 }
    }
}
