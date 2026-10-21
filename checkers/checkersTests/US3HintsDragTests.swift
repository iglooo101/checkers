import CheckersEngine
import Foundation
import Testing

@testable import checkers

struct US3HintsDragTests {
    static let twoPlayers = GameSetup.defaults

    @Test(
        "US3 FR-AID-01 FR-AID-04: hints mark every movable piece, only capturers when capture is required"
    )
    func hintedPieces() {
        let newGame = GameSession(setup: Self.twoPlayers)
        #expect(newGame.hintedPieces == Set(["a3", "c3", "e3", "g3"].map { Square($0) }))

        let capture = US2CaptureChainTests.capturePosition()
        #expect(capture.hintedPieces == [Square("c3")])

        let over = GameSession(
            setup: Self.twoPlayers, state: GameState(["h8": .darkMan], toMove: .light))
        #expect(over.hintedPieces.isEmpty)
    }

    @Test("US3 FR-AID-02 FR-AID-03: a selected piece is marked and its legal targets are hinted")
    func targets() {
        let session = GameSession(setup: Self.twoPlayers)
        #expect(session.targets.isEmpty)
        session.tap(Square("c3"))
        #expect(session.selection == Square("c3"))
        #expect(session.targets == [Square("b4"), Square("d4")])
    }

    @Test("US3 FR-MOVE-02: dragging a movable piece onto a target moves it")
    func dragToTarget() {
        let session = GameSession(setup: Self.twoPlayers)
        #expect(session.beginDrag(at: Square("c3")))
        #expect(session.selection == Square("c3"))
        session.drop(on: Square("d4"))
        #expect(session.state.position.piece(at: Square("d4")) == .lightMan)
        #expect(session.turnText.key == "Dark to move")
    }

    @Test("US3 FR-MOVE-02: a piece that cannot move does not follow the finger")
    func dragOfAnUnmovablePiece() {
        let session = GameSession(setup: Self.twoPlayers)
        #expect(!session.beginDrag(at: Square("c1")))
        #expect(session.selection == nil)
        session.drop(on: Square("d2"))
        #expect(session.state == GameState())
    }

    @Test("US3 FR-MOVE-02: dropping anywhere but a target, or off the board, changes nothing")
    func invalidDrops() {
        for drop in [Square("c5"), Square("c3"), nil] {
            let session = GameSession(setup: Self.twoPlayers)
            #expect(session.beginDrag(at: Square("c3")))
            session.drop(on: drop)
            #expect(session.state == GameState(), "drop on \(drop?.name ?? "nothing")")
        }
    }

    @Test("US3 FR-MOVE-02 FR-CHAIN-02: during a chain only the jumping piece can be dragged")
    func dragDuringChain() {
        let session = US2CaptureChainTests.chainPosition()
        session.tap(Square("a3"))
        session.tap(Square("c5"))
        #expect(!session.beginDrag(at: Square("g1")))
        #expect(session.beginDrag(at: Square("c5")))
        session.drop(on: Square("e7"))
        #expect(session.turnText.key == "Dark to move")
    }

    @Test("US3 FR-MOVE-02 FR-MOVE-05: dragging a piece that cannot capture shows the notice")
    func dragWhenCaptureIsRequired() {
        let session = US2CaptureChainTests.capturePosition()
        #expect(!session.beginDrag(at: Square("a1")))
        #expect(session.notice == .captureRequired)
    }
}
