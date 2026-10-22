import CheckersEngine
import Foundation
import Testing

@testable import checkers

struct US2CaptureChainTests {
    static let twoPlayers = GameSetup(opponent: .twoPlayers, difficulty: .easy, side: .light)

    /// Light man c3 must jump d4; Light man a1 could otherwise move.
    static func capturePosition(toMove side: Side = .light) -> GameSession {
        let layout: [String: Piece] =
            side == .light
            ? ["c3": .lightMan, "a1": .lightMan, "d4": .darkMan, "h8": .darkMan]
            : ["f6": .darkMan, "h8": .darkMan, "e5": .lightMan, "a1": .lightMan]
        return GameSession(setup: twoPlayers, state: GameState(layout, toMove: side))
    }

    /// Light man a3 can jump b4 and then d6; Light man g1 could otherwise move.
    static func chainPosition() -> GameSession {
        GameSession(
            setup: twoPlayers,
            state: GameState(
                ["a3": .lightMan, "g1": .lightMan, "b4": .darkMan, "d6": .darkMan, "h8": .darkMan],
                toMove: .light))
    }

    @Test("US2 FR-GAME-02: the turn indicator says when a capture is required")
    func captureRequiredIndicator() {
        #expect(Self.capturePosition().turnText.key == "Light to move · capture required")
        #expect(
            Self.capturePosition(toMove: .dark).turnText.key == "Dark to move · capture required")
    }

    @Test(
        "US2 FR-MOVE-05: tapping a piece that cannot capture shows the notice and selects nothing")
    func captureRequiredNotice() {
        let session = Self.capturePosition()
        session.tap(Square("a1"))
        #expect(session.notice == .captureRequired)
        #expect(session.selection == nil)

        session.tap(Square("c3"))
        #expect(session.notice == nil)
        session.tap(Square("a1"))
        #expect(session.notice == .captureRequired)
        #expect(session.selection == Square("c3"))

        session.tap(Square("e5"))
        #expect(session.notice == nil)
        #expect(session.state.position.piece(at: Square("e5")) == .lightMan)
    }

    @Test(
        "US2 FR-CHAIN-01 FR-CHAIN-02: after a chain's first jump only the jumping piece may go on")
    func chainLock() {
        let session = Self.chainPosition()
        session.tap(Square("a3"))
        session.tap(Square("c5"))
        #expect(session.state.position.piece(at: Square("b4")) == nil)
        #expect(session.selection == Square("c5"))
        #expect(session.state.targets(from: Square("c5")) == [Square("e7")])

        let midChain = session.state
        for square in ["g1", "b6", "h4", "c5"] {
            session.tap(Square(square))
            #expect(session.selection == Square("c5"), "after tapping \(square)")
            #expect(session.state == midChain, "after tapping \(square)")
        }
    }

    @Test("US2 FR-CHAIN-03: the turn ends when the jumping piece has no further jump")
    func chainEnds() {
        let session = Self.chainPosition()
        session.tap(Square("a3"))
        session.tap(Square("c5"))
        session.tap(Square("e7"))
        #expect(session.state.position.piece(at: Square("d6")) == nil)
        #expect(session.selection == nil)
        #expect(session.turnText.key == "Dark to move")
    }

    @Test("US2 FR-RULE-07 FR-CHAIN-03: a man reaching the far row is crowned and the turn ends")
    func crowning() {
        let session = GameSession(
            setup: Self.twoPlayers,
            state: GameState(["b6": .lightMan, "c7": .darkMan, "e7": .darkMan], toMove: .light))
        session.tap(Square("b6"))
        session.tap(Square("d8"))
        #expect(session.state.position.piece(at: Square("d8")) == .lightKing)
        #expect(session.selection == nil)
        #expect(session.turnText.key == "Dark to move")
    }
}
