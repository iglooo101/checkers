import Foundation
import Testing

@testable import CheckersEngine

/// The saved form of a game (specs/006-saving-and-statistics/contracts/saved-game.md): exact round
/// trips, a stable format and the rejection of damaged data.
struct GameStateCodingTests {
    /// A version 1 game: Light played h2–g3, Dark e5–d4, and Light is in the middle of the double
    /// jump c3–e5–g7. Three turn records: the two turns played and the turn in progress.
    static let fixture = """
        {
          "position": {"light": 264192, "dark": 4194304, "kings": 0},
          "sideToMove": "light",
          "chainSquare": "e5",
          "outcome": "inProgress",
          "noProgressCount": 0,
          "turns": [
            {"position": {"light": 640, "dark": 4456448, "kings": 0},
             "sideToMove": "light", "noProgressCount": 0},
            {"position": {"light": 2560, "dark": 4456448, "kings": 0},
             "sideToMove": "dark", "noProgressCount": 0},
            {"position": {"light": 2560, "dark": 4202496, "kings": 0},
             "sideToMove": "light", "noProgressCount": 0}
          ]
        }
        """

    /// The fixture's game, played through the rules.
    static func fixtureGame() throws -> GameState {
        var game = GameState(
            ["c3": .lightMan, "h2": .lightMan, "e5": .darkMan, "f6": .darkMan], toMove: .light)
        try game.apply(Step("h2", "g3"))
        try game.apply(Step("e5", "d4"))
        try game.apply(Step("c3", "e5"))
        return game
    }

    /// The four kinds of finished game: a win by no moves left, a resignation, and the two draws.
    static func finishedGames() throws -> [GameState] {
        var win = GameState(["c3": .lightMan, "d4": .darkMan], toMove: .light)
        try win.apply(Step("c3", "e5"))
        var resigned = try fixtureGame()
        try resigned.resign(.dark)
        var repetition = GameState(US4EndingTests.shuffleLayout, toMove: .light)
        for step in US4EndingTests.shuffle {
            try repetition.apply(step)
        }
        var noProgress = GameState(US4EndingTests.tourLayout, toMove: .light)
        for step in US4EndingTests.tour(turns: 80) {
            try noProgress.apply(step)
        }
        return [win, resigned, repetition, noProgress]
    }

    static func roundTrip(_ state: GameState) throws -> GameState {
        try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(state))
    }

    /// A JSON value as Foundation objects, for comparing formats.
    static func object(_ data: Data) throws -> NSDictionary {
        try #require(try JSONSerialization.jsonObject(with: data) as? NSDictionary)
    }

    @Test(
        "FR-SAVE-03: a game survives encoding exactly, at the start, mid-game, mid-chain and over")
    func roundTrips() throws {
        #expect(try Self.roundTrip(GameState()) == GameState())

        // Seeded random games stopped after a random number of steps, plus the first moment of
        // each game in the middle of a chain.
        var states: [GameState] = []
        for seed in 0..<200 {
            var generator = SeededGenerator(seed: UInt64(seed))
            let length = Int.random(in: 1...200, using: &generator)
            var state = GameState()
            var chainSeen = false
            for _ in 0..<length where state.outcome == .inProgress {
                let step = try #require(state.legalSteps.randomElement(using: &generator))
                try state.apply(step)
                if state.chainSquare != nil, !chainSeen {
                    states.append(state)
                    chainSeen = true
                }
            }
            states.append(state)
        }
        #expect(states.contains { $0.chainSquare != nil })
        #expect(states.contains { $0.position.kings != 0 })
        #expect(states.contains { $0.noProgressCount > 0 })
        for (index, state) in states.enumerated() {
            #expect(try Self.roundTrip(state) == state, "state \(index)")
        }

        let finished = try Self.finishedGames()
        #expect(
            finished.map(\.outcome) == [
                .win(winner: .light, reason: .noMovesLeft),
                .win(winner: .light, reason: .resignation),
                .draw(reason: .repetition), .draw(reason: .noProgress),
            ])
        for state in finished {
            #expect(try Self.roundTrip(state) == state, "\(state.outcome)")
        }
    }

    @Test("FR-SAVE-03: the format has explicit keys, and a version 1 fixture still decodes")
    func formatAndFixture() throws {
        let start = try Self.object(JSONEncoder().encode(GameState()))
        #expect(
            Set(start.allKeys.compactMap { $0 as? String }) == [
                "position", "sideToMove", "chainSquare", "outcome", "noProgressCount", "turns",
            ])
        #expect(start["chainSquare"] is NSNull)
        #expect(start["sideToMove"] as? String == "light")
        #expect(start["outcome"] as? String == "inProgress")
        #expect(
            start["position"] as? NSDictionary == [
                "light": 4095, "dark": 4_293_918_720, "kings": 0,
            ])

        let fixture = Data(Self.fixture.utf8)
        let game = try Self.fixtureGame()
        #expect(try JSONDecoder().decode(GameState.self, from: fixture) == game)
        #expect(try Self.object(JSONEncoder().encode(game)) == Self.object(fixture))

        let outcomes = try Self.finishedGames().map {
            try #require(Self.object(JSONEncoder().encode($0))["outcome"] as? NSDictionary)
        }
        let expected: [NSDictionary] = [
            ["win": ["winner": "light", "reason": "noMovesLeft"]],
            ["win": ["winner": "light", "reason": "resignation"]],
            ["draw": "repetition"], ["draw": "noProgress"],
        ]
        #expect(outcomes == expected)
    }

    /// The fixture with one change for each rule of "Validity", and each unknown name.
    static let damaged: [(String, @Sendable (inout [String: Any]) -> Void)] = [
        ("Light and Dark on one square", { $0["position"] = position(light: 264192 | 4_194_304) }),
        ("a king on an empty square", { $0["position"] = position(kings: 1) }),
        ("a no-progress count of 81", { $0["noProgressCount"] = 81 }),
        ("a no-progress count of 80 in a game in progress", { $0["noProgressCount"] = 80 }),
        ("a chain on an empty square", { $0["chainSquare"] = "a1" }),
        ("a chain on the other side's piece", { $0["chainSquare"] = "f6" }),
        ("a chain from a piece without a jump", { $0["chainSquare"] = "g3" }),
        (
            "a chain in a finished game",
            { $0["outcome"] = ["win": ["winner": "light", "reason": "resignation"]] }
        ),
        (
            "a side to move without a step",
            {
                $0["position"] = position(dark: 0)
                $0["sideToMove"] = "dark"
                $0["chainSquare"] = NSNull()
            }
        ),
        (
            "a position occurring for the third time",
            {
                $0["chainSquare"] = NSNull()
                let current = turn(light: 264192, dark: 4_194_304, side: "light")
                $0["turns"] = [current, current]
            }
        ),
        (
            "a turn record with Light and Dark on one square",
            { $0["turns"] = [turn(light: 640 | 262144, dark: 4_456_448, side: "light")] }
        ),
        (
            "a turn record with a no-progress count of 80",
            { $0["turns"] = [turn(light: 640, dark: 4_456_448, side: "light", count: 80)] }
        ),
        ("an unknown side", { $0["sideToMove"] = "blue" }),
        ("an unknown square", { $0["chainSquare"] = "z9" }),
        ("an unknown outcome", { $0["outcome"] = "lost" }),
        ("an unknown win reason", { $0["outcome"] = ["win": ["winner": "light", "reason": "x"]] }),
    ]

    /// The fixture's position with some sets replaced.
    static func position(light: Int = 264192, dark: Int = 4_194_304, kings: Int = 0) -> [String:
        Int]
    {
        ["light": light, "dark": dark, "kings": kings]
    }

    static func turn(light: Int, dark: Int, side: String, count: Int = 0) -> [String: Any] {
        [
            "position": ["light": light, "dark": dark, "kings": 0], "sideToMove": side,
            "noProgressCount": count,
        ]
    }

    @Test("FR-SAVE-05: damaged data is rejected as corrupted, never decoded into a game")
    func damagedDataRejected() throws {
        let fixture = try #require(
            try JSONSerialization.jsonObject(with: Data(Self.fixture.utf8)) as? [String: Any])
        for (label, damage) in Self.damaged {
            var object = fixture
            damage(&object)
            let data = try JSONSerialization.data(withJSONObject: object)
            let error = #expect(throws: DecodingError.self, "\(label)") {
                try JSONDecoder().decode(GameState.self, from: data)
            }
            guard let error else { continue }
            if case .dataCorrupted = error { continue }
            Issue.record("\(label): expected corrupted data, got \(error)")
        }
    }
}
