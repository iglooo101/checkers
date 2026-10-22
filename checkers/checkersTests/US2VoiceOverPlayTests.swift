import CheckersEngine
import Foundation
import Testing

@testable import checkers

struct US2VoiceOverPlayTests {
    static func session(_ state: GameState = GameState()) -> (GameSession, RecordingAnnouncer) {
        let announcer = RecordingAnnouncer()
        return (GameSession(setup: .defaults, state: state, announcer: announcer), announcer)
    }

    @Test("US2 FR-A11Y-02: VoiceOver focus follows each move to the square the piece landed on")
    func focusFollowsMoves() {
        let (session, _) = Self.session()
        session.tap(Square("c3"))
        #expect(session.focusSquare == nil)
        session.tap(Square("d4"))
        #expect(session.focusSquare == Square("d4"))

        let (chain, _) = Self.session(ScriptedGame.all[2].start)
        chain.tap(Square("a3"))
        chain.tap(Square("c5"))
        #expect(chain.focusSquare == Square("c5"))
        chain.tap(Square("e7"))
        #expect(chain.focusSquare == Square("e7"))
    }

    @Test("US2 FR-A11Y-02: undo and a new game clear the focus square")
    func focusCleared() {
        let (session, _) = Self.session()
        session.tap(Square("c3"))
        session.tap(Square("d4"))
        session.undo()
        #expect(session.focusSquare == nil)
        #expect(Self.session().0.focusSquare == nil)
    }

    @Test("US2 FR-A11Y-02: the capture-required notice is spoken when it appears")
    func noticeSpoken() {
        let (session, announcer) = Self.session(US2CaptureChainTests.capturePosition().state)
        session.tap(Square("a1"))
        #expect(announcer.announcements == ["A capture is required."])
        #expect(!session.beginDrag(at: Square("a1")))
        #expect(announcer.announcements == ["A capture is required.", "A capture is required."])
    }

    @Test("US2 FR-A11Y-02: selecting and deselecting pieces announces nothing")
    func selectionIsSilent() {
        let (session, announcer) = Self.session()
        session.tap(Square("c3"))
        session.tap(Square("e3"))
        session.tap(Square("e3"))
        #expect(announcer.announcements.isEmpty)
    }
}
