import CheckersEngine
import Testing

/// The app builds custom positions (for previews and tests) through the engine's public API only.
struct GamePositionsTests {
    @Test("A game can start from any position through the engine's public API")
    func customPosition() throws {
        let mover = try #require(Square(name: "c3"))
        let jumped = try #require(Square(name: "d4"))
        let landing = try #require(Square(name: "e5"))
        let position = Position([
            mover: Piece(side: .light, kind: .man), jumped: Piece(side: .dark, kind: .man),
        ])
        let game = GameState(position: position, sideToMove: .light)
        #expect(game.legalSteps == [Step(from: mover, to: landing)])
    }
}
