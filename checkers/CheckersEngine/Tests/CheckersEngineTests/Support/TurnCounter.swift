@testable import CheckersEngine

/// Counts every sequence of complete turns from a state (a "perft" count). A capture chain is
/// one turn, and different jump sequences count separately, as in the published reference
/// counts (research R1). A finished game has no legal steps, so it adds nothing.
func countTurnSequences(from state: GameState, turns: Int) throws -> Int {
    guard turns > 0 else { return 1 }
    var count = 0
    for step in state.legalSteps {
        var next = state
        let result = try next.apply(step)
        count += try countTurnSequences(from: next, turns: result.turnContinues ? turns : turns - 1)
    }
    return count
}
