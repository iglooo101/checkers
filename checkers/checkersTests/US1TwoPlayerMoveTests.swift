import CheckersEngine
import Foundation
import Testing

@testable import checkers

struct US1TwoPlayerMoveTests {
    static let twoPlayers = GameSetup(opponent: .twoPlayers, difficulty: .easy, side: .light)

    @Test("US1 FR-SETUP-01: a two-player game starts from setup")
    func twoPlayerGameStarts() {
        let router = AppRouter(store: InMemorySetupStore())
        router.newGame()
        router.setup.opponent = .twoPlayers
        router.startGame()
        #expect(router.path == [.game])
        #expect(router.session?.setup.opponent == .twoPlayers)
        #expect(router.session?.playerSide == nil)
    }

    @Test(
        "US1 FR-SETUP-06 FR-GAME-04: a two-player game starts from the standard position, Light at the bottom"
    )
    func newSession() {
        let session = GameSession(setup: Self.twoPlayers)
        #expect(session.state == GameState())
        #expect(session.layout.bottomSide == .light)
        #expect(session.playerSide == nil)
        #expect(session.selection == nil)
        #expect(session.turnText.key == "Light to move")
    }

    @Test("US1 FR-MOVE-03: tapping selects, switches and clears the selection")
    func selection() {
        let session = GameSession(setup: Self.twoPlayers)
        session.tap(Square("c3"))
        #expect(session.selection == Square("c3"))
        session.tap(Square("e3"))
        #expect(session.selection == Square("e3"))
        session.tap(Square("e3"))
        #expect(session.selection == nil)
        session.tap(Square("c3"))
        session.tap(Square("c5"))
        #expect(session.selection == nil)
        #expect(session.state == GameState())
    }

    @Test(
        "US1 FR-MOVE-01 FR-GAME-02 FR-GAME-05: tapping a piece and then a target moves it and passes the turn"
    )
    func tapToMove() {
        let session = GameSession(setup: Self.twoPlayers)
        session.tap(Square("c3"))
        session.tap(Square("d4"))
        #expect(session.state.position.piece(at: Square("d4")) == .lightMan)
        #expect(session.state.position.piece(at: Square("c3")) == nil)
        #expect(session.selection == nil)
        #expect(session.turnText.key == "Dark to move")
    }

    @Test("US1 FR-MOVE-04: only movable pieces of the side to move can be selected")
    func onlySideToMove() {
        let session = GameSession(setup: Self.twoPlayers)
        session.tap(Square("b6"))
        #expect(session.selection == nil)
        session.tap(Square("c1"))
        #expect(session.selection == nil)
    }

    @Test("US1 FR-NAV-01 FR-SETUP-01: New game opens setup, and Start opens a two-player game")
    func routerStartsAGame() {
        let router = AppRouter(store: InMemorySetupStore())
        #expect(router.path.isEmpty)
        #expect(router.session == nil)
        router.newGame()
        #expect(router.path == [.setup])
        router.setup.opponent = .twoPlayers
        router.startGame()
        #expect(router.path == [.game])
        #expect(router.session?.state == GameState())
    }
}
