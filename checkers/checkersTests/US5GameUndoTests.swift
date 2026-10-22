import CheckersEngine
import Foundation
import Testing

@testable import checkers

struct US5GameUndoTests {
    static let twoPlayers = GameSetup(opponent: .twoPlayers, difficulty: .easy, side: .light)

    @Test(
        "US5 FR-UNDO-01 FR-UNDO-02: undo takes back the last turn, whichever side made it, back to the start"
    )
    func undoTurnByTurn() {
        let session = GameSession(setup: Self.twoPlayers)
        US4GameEndTests.play([Step("c3", "d4")], in: session)
        let beforeDark = session.state
        US4GameEndTests.play([Step("b6", "a5")], in: session)

        session.undo()
        #expect(session.state == beforeDark)
        #expect(session.turnText.key == "Dark to move")
        session.undo()
        #expect(session.state == GameState())
        #expect(!session.canUndo)
    }

    @Test("US5 FR-UNDO-05: undo during a chain restores the position from before the chain")
    func undoMidChain() {
        let session = US2CaptureChainTests.chainPosition()
        let beforeChain = session.state
        session.tap(Square("a3"))
        session.tap(Square("c5"))
        session.undo()
        #expect(session.state == beforeChain)
        #expect(session.turnText.key == "Light to move · capture required")
        #expect(session.selection == nil)
    }

    @Test(
        "US5 FR-UNDO-06: undo is unavailable at the start and after the end, available after a move"
    )
    func undoAvailability() {
        let session = GameSession(setup: Self.twoPlayers)
        #expect(!session.canUndo)
        US4GameEndTests.play([Step("c3", "d4")], in: session)
        #expect(session.canUndo)
        session.resign()
        #expect(!session.canUndo)
        let finished = session.state
        session.undo()
        #expect(session.state == finished)
    }

    @Test("US5 FR-UNDO-02: after an undo nothing is selected and no notice is shown")
    func undoClearsSelectionAndNotice() {
        let session = GameSession(setup: Self.twoPlayers)
        US4GameEndTests.play([Step("c3", "d4")], in: session)
        session.tap(Square("f6"))
        #expect(session.selection == Square("f6"))
        session.undo()
        #expect(session.selection == nil)
        #expect(session.notice == nil)
    }
}
