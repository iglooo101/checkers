import Testing

@testable import CheckersEngine

/// Whether this is an optimized build: SwiftPM defines DEBUG only in debug builds.
private let isOptimized: Bool = {
    #if DEBUG
        false
    #else
        true
    #endif
}()

/// The levels' strength, proven by matches between them (specs/005-computer-opponent/spec.md,
/// US2; contracts/computer-player.md, "Strength matches"). Hard searches about a million
/// positions a turn, which takes hours in Debug, so the suite runs only in an optimized build:
/// `swift test -c release --filter CheckersEngineStrengthTests` (CI job engine-strength). Its
/// tests run one at a time, so the timings they print are not slowed by each other.
@Suite(.serialized, .enabled(if: isOptimized, "Run with swift test -c release"))
struct US2StrengthMatchTests {
    /// Each opening is played twice, the stronger level taking Light in one game and Dark in
    /// the other: 100 games per pairing.
    static let openings = 50
    /// Far more turns than any game can last under the no-progress rule; reaching it means the
    /// game never ended.
    static let turnLimit = 20_000

    @Test(
        "US2 FR-AI-01 FR-AI-02 SC-002 SC-003: in 100 games the stronger level scores at least 70 points; every step applies and every game ends",
        arguments: [
            Pairing(stronger: .medium, weaker: .easy), Pairing(stronger: .hard, weaker: .medium),
        ])
    func match(_ pairing: Pairing) async throws {
        let clock = ContinuousClock()
        let start = clock.now
        let games = try await Self.play(pairing)
        let elapsed = clock.now - start

        let points = games.map(\.points).reduce(0, +)
        let wins = games.count { $0.points == 1 }
        let draws = games.count { $0.points == 0.5 }
        let problems = games.flatMap(\.problems)
        #expect(games.count == 2 * Self.openings)
        #expect(problems.isEmpty, "\(problems.prefix(5))")
        #expect(points >= 70, "\(pairing): \(points) points")

        // The games ran in parallel, so the slowest turns are timed again alone.
        let slowest = games.compactMap(\.slowestTurn).sorted { $0.duration > $1.duration }
        let replays = slowest.prefix(5).map { turn in
            (turn, clock.measure { _ = turn.replay(at: pairing.stronger) })
        }
        var report =
            "\(pairing): \(points) of \(games.count) points (\(wins) wins, \(draws) draws) in"
            + " \(Self.seconds(elapsed)) s"
        if let (turn, alone) = replays.max(by: { $0.1 < $1.1 }) {
            report +=
                "; \(pairing.stronger)'s slowest turn \(Self.milliseconds(alone)) ms alone"
                + " (\(Self.milliseconds(turn.duration)) ms in the match), depth \(turn.depth),"
                + " \(turn.nodes) nodes"
        }
        print(report)
    }

    @Test(
        "FR-AI-01: complete-turn counts from the start match the published counts for 1–9 turns",
        arguments: [
            (1, 7), (2, 49), (3, 302), (4, 1_469), (5, 7_361), (6, 36_768), (7, 179_740),
            (8, 845_931), (9, 3_963_680),
        ])
    func referenceCount(turns: Int, expected: Int) {
        var counter = TurnCounter(depth: turns)
        let clock = ContinuousClock()
        var count = 0
        let elapsed = clock.measure {
            count = counter.count(Board(Position.start), .light, turns)
        }
        #expect(count == expected)
        if turns == 9 {
            let milliseconds = Self.milliseconds(elapsed)
            // Tenths of a million turns per second.
            let tenths = counter.generated / max(milliseconds, 1) / 100
            print(
                "Turn generator: \(counter.generated) turns in \(milliseconds) ms,"
                    + " \(tenths / 10).\(tenths % 10) million per second")
        }
    }

    @Test("US2 FR-AI-02: Hard wins a man six turns ahead, which Medium does not see")
    func hardLooksFurther() throws {
        // Dark to move. After e5–f4, h2–g3 would lose that man to f4, and Light's other man
        // runs out of safe squares (a3–b4, b4–c5, then d8–c7 covers b6 and d6), so on the
        // sixth turn Light must give a man away. Four turns ahead e5–f4 scores below the other
        // turns, so Medium never plays it.
        let state = GameState(
            [
                "h2": .lightMan, "a3": .lightMan, "e3": .darkMan, "e5": .darkMan,
                "d8": .darkMan,
            ], toMove: .dark)
        for seed in 0..<UInt64(5) {
            let hard = try #require(ComputerPlayer.chooseTurn(in: state, level: .hard, seed: seed))
            let medium = try #require(
                ComputerPlayer.chooseTurn(in: state, level: .medium, seed: seed))
            #expect(hard.steps == [Step("e5", "f4")], "seed \(seed)")
            #expect(medium.steps != [Step("e5", "f4")], "seed \(seed)")
        }
    }

    /// Plays the pairing's 100 games in parallel, in game order.
    private static func play(_ pairing: Pairing) async throws -> [GameRecord] {
        try await withThrowingTaskGroup(of: (Int, GameRecord).self) { group in
            for game in 0..<2 * openings {
                group.addTask { (game, try play(game, pairing)) }
            }
            var games: [Int: GameRecord] = [:]
            for try await (game, record) in group {
                games[game] = record
            }
            return games.sorted { $0.key < $1.key }.map(\.value)
        }
    }

    /// Plays game `game`: opening `game / 2`, with the stronger level as Light in even games.
    /// Each computer turn's seed is derived from the game and turn number.
    private static func play(_ game: Int, _ pairing: Pairing) throws -> GameRecord {
        var state = try opening(game / 2)
        let strongerSide: Side = game.isMultiple(of: 2) ? .light : .dark
        var record = GameRecord()
        let clock = ContinuousClock()
        var turn = 0
        while state.outcome == .inProgress, record.problems.isEmpty {
            guard turn < turnLimit else {
                record.problems.append("game \(game) did not end in \(turnLimit) turns")
                break
            }
            let isStronger = state.sideToMove == strongerSide
            let seed = UInt64(game) << 32 | UInt64(turn)
            var chosen: ComputerTurn?
            let duration = clock.measure {
                chosen = ComputerPlayer.chooseTurn(
                    in: state, level: isStronger ? pairing.stronger : pairing.weaker, seed: seed)
            }
            guard let chosen else {
                record.problems.append("game \(game), turn \(turn): no turn while in progress")
                break
            }
            if isStronger, duration > record.slowestTurn?.duration ?? .zero {
                record.slowestTurn = TimedTurn(
                    duration: duration, state: state, seed: seed, nodes: chosen.nodes,
                    depth: chosen.depth)
            }
            record.problems += apply(chosen.steps, to: &state, label: "game \(game), turn \(turn)")
            turn += 1
        }
        switch state.outcome {
        case .win(let winner, _): record.points = winner == strongerSide ? 1 : 0
        case .draw: record.points = 0.5
        case .inProgress: record.points = 0
        }
        return record
    }

    /// Opening `index`: two turns drawn at random with seed `index`, from every legal step.
    private static func opening(_ index: Int) throws -> GameState {
        var generator = SeededGenerator(seed: UInt64(index))
        var state = GameState()
        for _ in 0..<2 {
            repeat {
                let step = try #require(state.legalSteps.randomElement(using: &generator))
                try state.apply(step)
            } while state.chainSquare != nil
        }
        return state
    }

    /// Applies a turn's steps through the rules engine and returns what went wrong: a step it
    /// rejected, or a turn that stopped before its chain ended or went on after it.
    private static func apply(_ steps: [Step], to state: inout GameState, label: String)
        -> [String]
    {
        guard !steps.isEmpty else { return ["\(label): an empty turn"] }
        for (index, step) in steps.enumerated() {
            do {
                let result = try state.apply(step)
                guard result.turnContinues == (index < steps.count - 1) else {
                    return ["\(label): the chain does not end with step \(steps.count)"]
                }
            } catch {
                return ["\(label): step \(index + 1) rejected: \(error)"]
            }
        }
        return []
    }

    private static func milliseconds(_ duration: Duration) -> Int {
        Int(duration / .milliseconds(1))
    }

    private static func seconds(_ duration: Duration) -> Int {
        Int(duration / .seconds(1))
    }
}

/// A stronger and a weaker level that play a match.
struct Pairing: Sendable, CustomStringConvertible, CustomTestStringConvertible {
    let stronger: ComputerLevel
    let weaker: ComputerLevel

    var description: String { "\(stronger) against \(weaker)" }
    var testDescription: String { description }
}

/// What one game of a match showed.
struct GameRecord: Sendable {
    /// The stronger level's result: 1 for a win, 0.5 for a draw, 0 for a loss.
    var points = 0.0
    /// Every rule the computer broke, and a game that never ended; empty when all went well.
    var problems: [String] = []
    /// The stronger level's slowest turn of the game.
    var slowestTurn: TimedTurn?
}

/// A computer turn, its time during the match, and what it takes to play it again.
struct TimedTurn: Sendable {
    let duration: Duration
    let state: GameState
    let seed: UInt64
    let nodes: Int
    let depth: Int

    /// Chooses the same turn again: the same state, level and seed always give the same turn.
    func replay(at level: ComputerLevel) -> ComputerTurn? {
        ComputerPlayer.chooseTurn(in: state, level: level, seed: seed)
    }
}

/// Counts complete-turn sequences with the turn generator (a "perft" count), and how many turns
/// it generated on the way.
struct TurnCounter {
    private var buffers: [[Turn]]
    private(set) var generated = 0

    init(depth: Int) {
        buffers = (0...depth).map { _ in [] }
    }

    mutating func count(_ board: Board, _ side: Side, _ turns: Int) -> Int {
        guard turns > 0 else { return 1 }
        // Take the buffer out while it is in use, so filling it does not copy it.
        var buffer = buffers[turns]
        buffers[turns] = []
        TurnGenerator.turns(of: side, on: board, into: &buffer)
        generated += buffer.count
        var count = 0
        for turn in buffer {
            count += self.count(turn.board, side.opponent, turns - 1)
        }
        buffers[turns] = buffer
        return count
    }
}
