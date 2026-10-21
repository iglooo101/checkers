import Testing

@testable import CheckersEngine

/// Complete-turn sequences from the starting position, checked against the published counts:
/// OEIS A133046 (https://oeis.org/A133046, submitted by Jonathan Schaeffer, later terms by Aart
/// Bik) and Aart Bik's checkers page (https://aartbik.com/strategy.php). Depth 7 is the first
/// that includes crowning (research R1).
struct ReferenceCountTests {
    @Test(
        "US3 SC-002: complete-turn sequences from the start match the published counts",
        arguments: [
            (1, 7), (2, 49), (3, 302), (4, 1_469), (5, 7_361), (6, 36_768), (7, 179_740),
        ])
    func referenceCount(turns: Int, expected: Int) throws {
        #expect(try countTurnSequences(from: GameState(), turns: turns) == expected)
    }

    @Test("US3 SC-004: the 6-turn count takes under 10 seconds")
    func sixTurnSpeed() throws {
        var count = 0
        let duration = try ContinuousClock().measure {
            count = try countTurnSequences(from: GameState(), turns: 6)
        }
        #expect(count == 36_768)
        #expect(duration < .seconds(10))
    }
}
