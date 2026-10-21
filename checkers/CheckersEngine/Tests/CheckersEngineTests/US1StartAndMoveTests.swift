import Testing

@testable import CheckersEngine

struct US1StartAndMoveTests {
    @Test(
        "US1 FR-RULE-01 FR-SETUP-06: a new game has 12 men per side on rows 1–3 and 6–8, Light to move"
    )
    func startingPosition() {
        let game = GameState()
        for square in Square.all {
            let expected: Piece? =
                switch square.row {
                case 0...2: .lightMan
                case 5...7: .darkMan
                default: nil
                }
            #expect(game.position.piece(at: square) == expected, "\(square.name)")
            #expect(
                (square.column + square.row).isMultiple(of: 2), "pieces stand on dark squares only")
        }
        #expect(game.sideToMove == .light)
        #expect(game.chainSquare == nil)
        #expect(game.outcome == .inProgress)
    }

    @Test("US1 FR-RULE-02: Light has exactly 7 opening moves, each from row 3 to row 4")
    func openingMoves() {
        let game = GameState()
        #expect(
            game.legalSteps == [
                Step("a3", "b4"), Step("c3", "b4"), Step("c3", "d4"), Step("e3", "d4"),
                Step("e3", "f4"), Step("g3", "f4"), Step("g3", "h4"),
            ])
        #expect(game.movablePieces == [Square("a3"), Square("c3"), Square("e3"), Square("g3")])
        #expect(game.targets(from: Square("c3")) == [Square("b4"), Square("d4")])
        #expect(game.targets(from: Square("c1")).isEmpty)
        #expect(!game.isCaptureRequired)
    }

    @Test("US1 FR-RULE-02: moving c3 to d4 moves the man and passes the turn to Dark")
    func simpleMove() throws {
        var game = GameState()
        let result = try game.apply(Step("c3", "d4"))
        #expect(game.position.piece(at: Square("c3")) == nil)
        #expect(game.position.piece(at: Square("d4")) == .lightMan)
        #expect(game.sideToMove == .dark)
        #expect(
            result
                == StepResult(
                    side: .light, piece: .lightMan, from: Square("c3"), to: Square("d4"),
                    captured: nil, crowned: false, turnContinues: false, outcome: .inProgress))
    }

    @Test("US1 FR-RULE-02: a man never moves backward, sideways, two squares or onto a piece")
    func manRestrictions() {
        var game = GameState(["d4": .lightMan, "c5": .lightMan, "h8": .darkMan], toMove: .light)
        let before = game
        #expect(game.targets(from: Square("d4")) == [Square("e5")])
        for target in ["c3", "e3", "f4", "f6", "c5"] {
            #expect(throws: RuleError.illegalStep, "d4-\(target)") {
                try game.apply(Step("d4", target))
            }
            #expect(game == before)
        }

        let dark = GameState(["e5": .darkMan, "a1": .lightMan], toMove: .dark)
        #expect(dark.targets(from: Square("e5")) == [Square("d4"), Square("f4")])
    }

    @Test("US1: moving the other side's piece or from an empty square is rejected")
    func rejections() {
        var game = GameState()
        let before = game
        #expect(throws: RuleError.notSideToMove) { try game.apply(Step("b6", "a5")) }
        #expect(throws: RuleError.illegalStep) { try game.apply(Step("d4", "e5")) }
        #expect(game == before)
    }

    @Test("US1: a copy of a game is independent, and the same step gives the same result")
    func valueSemantics() throws {
        let original = GameState()
        var copy = original
        try copy.apply(Step("c3", "d4"))
        #expect(original == GameState())
        #expect(copy != original)

        var first = GameState()
        var second = GameState()
        let firstResult = try first.apply(Step("g3", "h4"))
        let secondResult = try second.apply(Step("g3", "h4"))
        #expect(first == second)
        #expect(firstResult == secondResult)
    }
}
