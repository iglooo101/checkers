import Testing

@testable import CheckersEngine

/// The three levels differ in how far they look and how widely they choose
/// (specs/005-computer-opponent/spec.md, US2; FRD 1.3.4). Since build 5 Easy, Medium and Hard
/// look 1, 2 and 3 turns ahead, so every level runs in Debug; the strength matches are in
/// CheckersEngineStrengthTests.
struct US2ComputerLevelTests {
    static let nodeCap = 20_000
    /// A deep search under a node cap the Debug run can afford, for the node limit itself.
    static let deepCapped = SearchLimits(maxDepth: 16, nodeLimit: nodeCap, margin: 0)

    @Test(
        "US2 FR-AI-02: Easy, Medium and Hard look 1, 2 and 3 turns ahead and stray less at each level; only Hard has a node limit"
    )
    func limitsAreOrdered() {
        let easy = ComputerLevel.easy.limits
        let medium = ComputerLevel.medium.limits
        let hard = ComputerLevel.hard.limits
        #expect([easy.maxDepth, medium.maxDepth, hard.maxDepth] == [1, 2, 3])
        #expect(easy.margin > medium.margin)
        #expect(medium.margin > hard.margin)
        #expect(hard.margin == 0)
        #expect(easy.nodeLimit == nil)
        #expect(medium.nodeLimit == nil)
        #expect(hard.nodeLimit != nil)
    }

    @Test("US2 FR-AI-02: Medium sees a quiet reply that costs Dark two men; Easy does not")
    func mediumLooksFurther() throws {
        // Dark to move, from a played game. Two turns ahead every turn scores at least Medium's
        // 40 points below g7–f6, and b6–a5 more than two men below it. Easy, which looks only at
        // its own turn and the captures after it, plays b6–a5 for some seeds.
        let state = GameState(
            [
                "g1": .darkKing, "h4": .lightMan, "e5": .darkMan, "g5": .lightMan,
                "b6": .darkKing, "h6": .lightMan, "a7": .darkMan, "c7": .darkMan,
                "e7": .darkMan, "g7": .darkMan, "f8": .darkMan, "h8": .darkMan,
            ], toMove: .dark)
        var easyTurns: Set<[Step]> = []
        for seed in 0..<UInt64(10) {
            let medium = try #require(
                ComputerPlayer.chooseTurn(in: state, level: .medium, seed: seed))
            let easy = try #require(ComputerPlayer.chooseTurn(in: state, level: .easy, seed: seed))
            #expect(medium.steps == [Step("g7", "f6")], "seed \(seed)")
            easyTurns.insert(easy.steps)
        }
        #expect(easyTurns.contains([Step("b6", "a5")]))
    }

    @Test("US2 FR-AI-02: Hard wins material three turns ahead, which Medium does not see")
    func hardLooksFurther() throws {
        // Dark to move, from a played game. Three turns ahead b4–a3 is Dark's best turn, and
        // Medium's choices, b4–c3 and d6–e5, score more than a man below it.
        let state = GameState(
            [
                "b2": .lightMan, "g3": .lightMan, "b4": .darkMan, "c5": .darkMan,
                "g5": .lightMan, "b6": .darkMan, "d6": .darkMan, "c7": .darkMan,
            ], toMove: .dark)
        for seed in 0..<UInt64(10) {
            let hard = try #require(ComputerPlayer.chooseTurn(in: state, level: .hard, seed: seed))
            let medium = try #require(
                ComputerPlayer.chooseTurn(in: state, level: .medium, seed: seed))
            #expect(hard.steps == [Step("b4", "a3")], "seed \(seed)")
            #expect(medium.steps != [Step("b4", "a3")], "seed \(seed)")
        }
    }

    @Test("US2 FR-AI-02: Easy now and then gives a man away; build 4's Easy never did")
    func easyGivesAManAway() throws {
        // Dark to move, from a played opening, all 24 men on the board. h6–g5 lets Light's f4
        // jump it, landing on h6, and Dark cannot jump back. Easy may play a turn up to 150
        // points below its best (a man is 100, a little more as pieces come off), so some seeds
        // play h6–g5; Easy as builds 1 to 4 had it (two turns, 40 points; research R4) never does.
        let state = GameState(
            [
                "a1": .lightMan, "c1": .lightMan, "e1": .lightMan, "g1": .lightMan,
                "b2": .lightMan, "d2": .lightMan, "f2": .lightMan, "h2": .lightMan,
                "a3": .lightMan, "b4": .lightMan, "f4": .lightMan, "h4": .lightMan,
                "c5": .darkMan, "b6": .darkMan, "d6": .darkMan, "f6": .darkMan,
                "h6": .darkMan, "a7": .darkMan, "e7": .darkMan, "g7": .darkMan,
                "b8": .darkMan, "d8": .darkMan, "f8": .darkMan, "h8": .darkMan,
            ], toMove: .dark)
        let buildFourEasy = SearchLimits(maxDepth: 2, nodeLimit: nil, margin: 40)
        var easyTurns: Set<[Step]> = []
        for seed in 0..<UInt64(20) {
            let easy = try #require(ComputerPlayer.chooseTurn(in: state, level: .easy, seed: seed))
            let before = try #require(
                ComputerPlayer.chooseTurn(in: state, limits: buildFourEasy, seed: seed))
            easyTurns.insert(easy.steps)
            #expect(before.steps != [Step("h6", "g5")], "seed \(seed)")
        }
        #expect(easyTurns.contains([Step("h6", "g5")]))

        var after = state
        try after.apply(Step("h6", "g5"))
        #expect(after.legalSteps == [Step("f4", "h6")])
    }

    @Test("US2 FR-AI-02: Easy never gives two men away in one turn")
    func easyNeverGivesTwoMen() throws {
        // Dark to move. d6–c5 lets Light's b4 jump c5 and e7 and crown on f8; d6–e5, e7–f6 and
        // h8–g7 are safe. Two men are more than Easy's 150 points, so no seed plays d6–c5.
        let state = GameState(
            ["d6": .darkMan, "e7": .darkMan, "h8": .darkMan, "b4": .lightMan, "a1": .lightMan],
            toMove: .dark)
        for seed in 0..<UInt64(20) {
            let easy = try #require(ComputerPlayer.chooseTurn(in: state, level: .easy, seed: seed))
            #expect(easy.steps != [Step("d6", "c5")], "seed \(seed)")
        }

        var after = state
        try after.apply(Step("d6", "c5"))
        try after.apply(Step("b4", "d6"))
        #expect(after.legalSteps == [Step("d6", "f8")])
    }

    @Test("US2 FR-AI-02: a node cap stops the search within 1,024 nodes, at its last whole depth")
    func nodeCap() throws {
        let start = GameState()
        let capped = try #require(
            ComputerPlayer.chooseTurn(in: start, limits: Self.deepCapped, seed: 3))
        #expect(capped.nodes >= Self.nodeCap)
        #expect(capped.nodes < Self.nodeCap + 1_024)
        #expect(capped.depth < Self.deepCapped.maxDepth)

        // The same search stopped by depth instead gives the same turn.
        let completed = SearchLimits(
            maxDepth: capped.depth, nodeLimit: nil, margin: Self.deepCapped.margin)
        let uncapped = try #require(
            ComputerPlayer.chooseTurn(in: start, limits: completed, seed: 3))
        #expect(capped.steps == uncapped.steps)
        #expect(capped.score == uncapped.score)
        #expect(capped.depth == uncapped.depth)
    }

    @Test("US2 FR-AI-02 (FR-013): Easy and Medium vary their opening turn with the seed")
    func openingsVary() throws {
        for level in [ComputerLevel.easy, .medium] {
            var chosen: Set<[Step]> = []
            for seed in 0..<UInt64(20) {
                let turn = try #require(
                    ComputerPlayer.chooseTurn(in: GameState(), level: level, seed: seed))
                chosen.insert(turn.steps)
            }
            #expect(chosen.count >= 2, "\(level)")
        }
    }

    @Test("US2 FR-AI-02 (FR-013): the same seed always gives the same turn")
    func sameSeedSameTurn() {
        let levels = ComputerLevel.allCases.map(\.limits)
        for limits in levels {
            for seed: UInt64 in [0, 7, 99] {
                let first = ComputerPlayer.chooseTurn(in: GameState(), limits: limits, seed: seed)
                let second = ComputerPlayer.chooseTurn(in: GameState(), limits: limits, seed: seed)
                #expect(first != nil)
                #expect(first == second, "\(limits), seed \(seed)")
            }
        }
    }

    @Test("US2 FR-AI-02 (FR-013): with Hard's margin only turns tied for the best are chosen")
    func hardChoosesAmongTies() throws {
        // Light's king takes all four men around it, by way of b4 or of f4, and lands back on
        // d2: the same board either way, so the two chains tie. a5xc7 takes one man and lets c3
        // take the king.
        let state = GameState(
            [
                "d2": .lightKing, "a5": .lightMan, "c3": .darkMan, "e3": .darkMan,
                "c5": .darkMan, "e5": .darkMan, "b6": .darkMan,
            ], toMove: .light)
        let byB4 = [Step("d2", "b4"), Step("b4", "d6"), Step("d6", "f4"), Step("f4", "d2")]
        let byF4 = [Step("d2", "f4"), Step("f4", "d6"), Step("d6", "b4"), Step("b4", "d2")]
        var chosen: Set<[Step]> = []
        for seed in 0..<UInt64(20) {
            let turn = try #require(
                ComputerPlayer.chooseTurn(in: state, level: .hard, seed: seed))
            chosen.insert(turn.steps)
        }
        #expect(chosen == [byB4, byF4])
    }

    @Test("US2 FR-AI-02: SeededGenerator produces the SplitMix64 reference values for seed 0")
    func seededGeneratorReference() {
        // From the reference implementation, https://prng.di.unimi.it/splitmix64.c.
        var generator = SeededGenerator(seed: 0)
        let values = (0..<4).map { _ in generator.next() }
        #expect(
            values == [
                0xE220_A839_7B1D_CDAF, 0x6E78_9E6A_A1B9_65F4, 0x06C4_5D18_8009_454F,
                0xF88B_B8A8_724C_81EC,
            ])
    }
}
