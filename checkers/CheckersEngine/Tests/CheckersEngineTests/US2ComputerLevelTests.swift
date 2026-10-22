import Testing

@testable import CheckersEngine

/// The three levels differ in how far they look and how widely they choose
/// (specs/005-computer-opponent/spec.md, US2). These tests run in Debug, so Hard is checked
/// through its limits and through searches with its margin under a node cap of 20,000; Hard at
/// full strength is exercised in CheckersEngineStrengthTests.
struct US2ComputerLevelTests {
    static let nodeCap = 20_000
    /// Hard's depth and margin, under a node cap the Debug run can afford.
    static let cappedHard = SearchLimits(
        maxDepth: ComputerLevel.hard.limits.maxDepth, nodeLimit: nodeCap,
        margin: ComputerLevel.hard.limits.margin)

    @Test("US2 FR-AI-02: each level looks further and strays less; only Hard has a node limit")
    func limitsAreOrdered() {
        let easy = ComputerLevel.easy.limits
        let medium = ComputerLevel.medium.limits
        let hard = ComputerLevel.hard.limits
        #expect(easy.maxDepth < medium.maxDepth)
        #expect(medium.maxDepth < hard.maxDepth)
        #expect(easy.margin > medium.margin)
        #expect(medium.margin > hard.margin)
        #expect(hard.margin == 0)
        #expect(easy.nodeLimit == nil)
        #expect(medium.nodeLimit == nil)
        #expect(hard.nodeLimit != nil)
    }

    @Test("US2 FR-AI-02: Medium finds the only safe turn four turns ahead; Easy does not")
    func mediumLooksFurther() throws {
        // Dark's lone king. Two turns ahead e1–d2 scores better, since it attacks c3; four turns
        // ahead it loses the game: Light crowns c7–b8, the king must take c3, Light's king steps
        // to c7, and the Dark king must take c5 and land on d6, where Light's king takes it.
        // e1–f2 is the only safe turn.
        let state = GameState(
            [
                "e1": .darkKing, "c3": .lightMan, "c5": .lightMan, "d6": .lightKing,
                "c7": .lightMan,
            ], toMove: .dark)
        for seed in 0..<UInt64(10) {
            let medium = try #require(
                ComputerPlayer.chooseTurn(in: state, level: .medium, seed: seed))
            let easy = try #require(ComputerPlayer.chooseTurn(in: state, level: .easy, seed: seed))
            #expect(medium.steps == [Step("e1", "f2")], "seed \(seed)")
            #expect(easy.steps == [Step("e1", "d2")], "seed \(seed)")
        }
    }

    @Test("US2 FR-AI-02: a node cap stops the search within 1,024 nodes, at its last whole depth")
    func nodeCap() throws {
        let start = GameState()
        let capped = try #require(
            ComputerPlayer.chooseTurn(in: start, limits: Self.cappedHard, seed: 3))
        #expect(capped.nodes >= Self.nodeCap)
        #expect(capped.nodes < Self.nodeCap + 1_024)
        #expect(capped.depth < Self.cappedHard.maxDepth)

        // The same search stopped by depth instead gives the same turn.
        let completed = SearchLimits(
            maxDepth: capped.depth, nodeLimit: nil, margin: Self.cappedHard.margin)
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
        let levels = [ComputerLevel.easy.limits, ComputerLevel.medium.limits, Self.cappedHard]
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
                ComputerPlayer.chooseTurn(in: state, limits: Self.cappedHard, seed: seed))
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
