import CheckersEngine

/// A game played through `GameSession` from a starting state by a list of steps, for the
/// accessibility tests that check every square and every announcement after every step
/// (specs/004-accessibility, SC-002 and SC-003).
struct ScriptedGame {
    let name: String
    let start: GameState
    let steps: [Step]

    static let all: [ScriptedGame] = [
        ScriptedGame(
            name: "opening", start: GameState(), steps: [Step("c3", "d4"), Step("b6", "a5")]),
        ScriptedGame(
            name: "capture and recapture", start: GameState(),
            steps: [Step("c3", "d4"), Step("f6", "e5"), Step("d4", "f6")]),
        ScriptedGame(
            name: "double jump",
            start: GameState(
                ["a3": .lightMan, "g1": .lightMan, "b4": .darkMan, "d6": .darkMan, "h8": .darkMan],
                toMove: .light),
            steps: [Step("a3", "c5"), Step("c5", "e7")]),
        ScriptedGame(
            name: "crowning jump",
            start: GameState(["b6": .lightMan, "c7": .darkMan, "e7": .darkMan], toMove: .light),
            steps: [Step("b6", "d8")]),
        ScriptedGame(
            name: "repetition",
            start: GameState(["h2": .lightKing, "a7": .darkKing], toMove: .light),
            steps: US4GameEndTests.shuffle),
        ScriptedGame(
            name: "last capture",
            start: GameState(["c3": .lightMan, "d4": .darkMan], toMove: .light),
            steps: [Step("c3", "e5")]),
    ]
}
