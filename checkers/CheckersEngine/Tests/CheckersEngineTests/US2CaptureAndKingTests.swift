import Testing

@testable import CheckersEngine

struct US2CaptureAndKingTests {
    /// Light man c3 can jump the Dark man on d4; Light man a1 could otherwise move.
    static let captureLayout: [String: Piece] = [
        "c3": .lightMan, "a1": .lightMan, "d4": .darkMan, "h8": .darkMan,
    ]

    @Test(
        "US2 FR-RULE-03 FR-RULE-05: a man must jump an adjacent piece and no simple move is legal")
    func captureOnly() {
        let game = GameState(Self.captureLayout, toMove: .light)
        #expect(game.legalSteps == [Step("c3", "e5")])
        #expect(game.movablePieces == [Square("c3")])
        #expect(game.isCaptureRequired)
    }

    @Test("US2 FR-RULE-03: a jump removes the jumped piece and the man lands beyond it")
    func applyJump() throws {
        var game = GameState(Self.captureLayout, toMove: .light)
        let result = try game.apply(Step("c3", "e5"))
        #expect(game.position.piece(at: Square("c3")) == nil)
        #expect(game.position.piece(at: Square("d4")) == nil)
        #expect(game.position.piece(at: Square("e5")) == .lightMan)
        #expect(game.sideToMove == .dark)
        #expect(result.captured == Square("d4"))
        #expect(!result.turnContinues)
    }

    @Test("US2 FR-RULE-03: a man cannot capture backward")
    func noBackwardCapture() {
        var game = GameState(["d4": .lightMan, "c3": .darkMan, "h8": .darkMan], toMove: .light)
        #expect(!game.legalSteps.contains(Step("d4", "b2")))
        #expect(!game.isCaptureRequired)
        #expect(throws: RuleError.illegalStep) { try game.apply(Step("d4", "b2")) }
    }

    @Test("US2 FR-RULE-04: a king moves one square in all four directions, never farther")
    func kingMoves() {
        var game = GameState(["d4": .lightKing, "h8": .darkMan], toMove: .light)
        #expect(
            game.targets(from: Square("d4")) == [
                Square("c5"), Square("e5"), Square("c3"), Square("e3"),
            ])
        let before = game
        for target in ["b6", "f2"] {
            #expect(throws: RuleError.illegalStep, "d4-\(target)") {
                try game.apply(Step("d4", target))
            }
        }
        #expect(game == before)
    }

    @Test("US2 FR-RULE-04: a king captures backward")
    func kingCapturesBackward() {
        let game = GameState(["e5": .lightKing, "d4": .darkMan, "h8": .darkMan], toMove: .light)
        #expect(game.legalSteps == [Step("e5", "c3")])
    }

    @Test("US2 FR-RULE-05: any capture may be chosen, whatever its chain length or capturing piece")
    func freeChoiceOfCapture() {
        let game = GameState(
            [
                "a3": .lightMan, "b4": .darkMan, "d6": .darkMan,
                "h2": .lightKing, "g3": .darkMan, "h8": .darkMan,
            ], toMove: .light)
        #expect(game.legalSteps == [Step("h2", "f4"), Step("a3", "c5")])
    }

    @Test("US2 FR-RULE-05: a simple move is rejected while a capture is available")
    func captureRequired() {
        var game = GameState(Self.captureLayout, toMove: .light)
        let before = game
        #expect(throws: RuleError.captureRequired) { try game.apply(Step("a1", "b2")) }
        #expect(game == before)
    }

    @Test("US2 FR-RULE-03 FR-RULE-04: no jump over an own piece, onto a piece, or over two pieces")
    func invalidJumps() {
        var ownPiece = GameState(["c3": .lightMan, "d4": .lightMan], toMove: .light)
        #expect(throws: RuleError.illegalStep) { try ownPiece.apply(Step("c3", "e5")) }

        var occupiedLanding = GameState(
            ["c3": .lightMan, "d4": .darkMan, "e5": .darkMan], toMove: .light)
        #expect(throws: RuleError.illegalStep) { try occupiedLanding.apply(Step("c3", "e5")) }

        var twoPieces = GameState(
            ["a1": .lightKing, "b2": .darkMan, "c3": .darkMan, "g1": .lightMan], toMove: .light)
        #expect(!twoPieces.isCaptureRequired)
        #expect(throws: RuleError.illegalStep) { try twoPieces.apply(Step("a1", "c3")) }
        #expect(throws: RuleError.illegalStep) { try twoPieces.apply(Step("a1", "d4")) }
    }
}
