import CheckersEngine
import Foundation
import Testing

@testable import checkers

struct US3AnnouncementTests {
    static func session(_ state: GameState = GameState()) -> (GameSession, RecordingAnnouncer) {
        let announcer = RecordingAnnouncer()
        return (
            GameSession(
                setup: US1TwoPlayerMoveTests.twoPlayers, state: state, announcer: announcer),
            announcer
        )
    }

    @Test("US3 FR-A11Y-03: a move announces itself and the turn that follows")
    func movesAndTurns() {
        let (session, announcer) = Self.session()
        US4GameEndTests.play([Step("c3", "d4")], in: session)
        US4GameEndTests.play([Step("f6", "e5")], in: session)
        US4GameEndTests.play([Step("d4", "f6")], in: session)
        #expect(
            announcer.announcements == [
                "Light c3 to d4. Dark to move.",
                "Dark f6 to e5. Light to move, capture required.",
                "Light captures e5. Dark to move, capture required.",
            ])
    }

    @Test("US3 FR-A11Y-03: a chain announces each jump, saying when the piece must jump again")
    func chain() {
        let (session, announcer) = Self.session(ScriptedGame.all[2].start)
        US4GameEndTests.play([Step("a3", "c5")], in: session)
        session.tap(Square("e7"))
        #expect(
            announcer.announcements == [
                "Light captures b4. Jump again.", "Light captures d6. Dark to move.",
            ])
    }

    @Test("US3 FR-A11Y-03: crowning is announced, by a jump or by a move")
    func crowning() {
        let (jump, jumpAnnouncer) = Self.session(ScriptedGame.all[3].start)
        US4GameEndTests.play([Step("b6", "d8")], in: jump)
        #expect(jumpAnnouncer.announcements == ["Light captures c7, crowned on d8. Dark to move."])

        let (move, moveAnnouncer) = Self.session(
            GameState(["b2": .darkMan, "g3": .lightMan], toMove: .dark))
        US4GameEndTests.play([Step("b2", "a1")], in: move)
        #expect(moveAnnouncer.announcements == ["Dark b2 to a1, crowned. Light to move."])
    }

    @Test("US3 FR-A11Y-03: the step that ends a game announces the result")
    func results() {
        let (last, lastAnnouncer) = Self.session(ScriptedGame.all[5].start)
        US4GameEndTests.play([Step("c3", "e5")], in: last)
        #expect(lastAnnouncer.announcements == ["Light captures d4. Light wins: no moves left"])

        let (shuffle, shuffleAnnouncer) = Self.session(ScriptedGame.all[4].start)
        US4GameEndTests.play(US4GameEndTests.shuffle, in: shuffle)
        #expect(shuffleAnnouncer.announcements.last == "Dark b8 to a7. Draw by repetition")
    }

    @Test("US3 FR-A11Y-03: undo and resignation are announced")
    func undoAndResign() {
        let (session, announcer) = Self.session()
        US4GameEndTests.play([Step("c3", "d4")], in: session)
        session.undo()
        session.resign()
        #expect(
            announcer.announcements == [
                "Light c3 to d4. Dark to move.", "Move undone. Light to move.", "Light resigned",
            ])
    }

    @Test("US3 FR-A11Y-03: each step, undo and resignation makes exactly one announcement (SC-003)")
    func oneAnnouncementPerEvent() {
        for game in ScriptedGame.all {
            let (session, announcer) = Self.session(game.start)
            for (index, step) in game.steps.enumerated() {
                let before = announcer.announcements.count
                session.tap(step.from)
                session.tap(step.to)
                #expect(
                    announcer.announcements.count == before + 1, "\(game.name), step \(index + 1)")
            }
            let before = announcer.announcements.count
            if session.canUndo {
                session.undo()
                #expect(announcer.announcements.count == before + 1, "\(game.name), undo")
            }
        }
    }
}
