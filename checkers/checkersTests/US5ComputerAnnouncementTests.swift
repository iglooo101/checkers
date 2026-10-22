import CheckersEngine
import Foundation
import Testing

@testable import checkers

/// Hearing the computer's moves with VoiceOver (specs/005-computer-opponent/spec.md, US5;
/// contracts/computer-turn.md, Announcements and focus).
struct US5ComputerAnnouncementTests {
    typealias Game = US1ComputerGameTests.Game

    /// Plays the player's steps, then lets the computer's turn run to its end.
    static func playTurn(_ steps: [Step], in game: Game) async {
        game.play(steps)
        while game.session.isComputerTurn {
            await waitUntil { game.pacer.waiting == 1 || !game.session.isComputerTurn }
            game.pacer.resumeNext()
        }
    }

    @Test("US5 FR-A11Y-03: the computer's move is announced with the player's turn that follows")
    func simpleMove() async {
        let game = Game(turns: [[Step("f6", "e5")]])
        await Self.playTurn([Step("c3", "d4")], in: game)
        #expect(
            game.announcer.announcements == [
                "Light c3 to d4. Dark to move.", "Dark f6 to e5. Light to move, capture required.",
            ])
    }

    @Test("US5 FR-A11Y-03: each jump of the computer's chain is announced, without \"Jump again.\"")
    func chain() async {
        let game = Game(
            state: US3ComputerControlTests.chainPosition,
            turns: [[Step("f6", "d4"), Step("d4", "b2")]])
        await Self.playTurn([Step("h2", "g3")], in: game)
        #expect(
            game.announcer.announcements == [
                "Light h2 to g3. Dark to move, capture required.", "Dark captures e5.",
                "Dark captures c3. Light to move.",
            ])
    }

    @Test("US5 FR-A11Y-03: a computer move that crowns or ends the game says so")
    func crowningAndResult() async {
        let crowning = Game(
            state: GameState(["b2": .darkMan, "e3": .lightMan], toMove: .light),
            turns: [[Step("b2", "a1")]])
        await Self.playTurn([Step("e3", "f4")], in: crowning)
        #expect(crowning.announcer.announcements.last == "Dark b2 to a1, crowned. Light to move.")

        let ending = Game(
            state: GameState(["c3": .lightMan, "e5": .darkMan], toMove: .light),
            turns: [[Step("e5", "c3")]])
        await Self.playTurn([Step("c3", "d4")], in: ending)
        #expect(ending.announcer.announcements.last == "Dark captures d4. Dark wins: no moves left")
    }

    @Test(
        "US5 FR-A11Y-03: one announcement per computer step, none while it thinks or Rules is open"
    )
    func oneAnnouncementPerStep() async {
        let game = Game(
            state: US3ComputerControlTests.chainPosition,
            turns: [[Step("f6", "d4"), Step("d4", "b2")]])
        let announcer = game.announcer
        game.play([Step("h2", "g3")])
        #expect(announcer.announcements.count == 1)
        game.session.setCovered(true)
        await game.resumePause()
        await settle()
        #expect(announcer.announcements.count == 1)

        game.session.setCovered(false)
        await game.resumePause()
        await waitUntil { game.session.computerPhase == .playing }
        #expect(announcer.announcements.count == 2)
        await game.resumePause()
        await waitUntil { game.session.computerPhase == .idle }
        #expect(announcer.announcements.count == 3)
    }

    @Test("US5 FR-A11Y-03: VoiceOver focus stays on the player's landing square")
    func focusStays() async {
        let game = Game(
            state: US3ComputerControlTests.chainPosition,
            turns: [[Step("f6", "d4"), Step("d4", "b2")]])
        let session = game.session
        game.play([Step("h2", "g3")])
        #expect(session.focusSquare == Square("g3"))
        await game.resumePause()
        await waitUntil { session.computerPhase == .playing }
        #expect(session.focusSquare == Square("g3"))
        await game.resumePause()
        await waitUntil { session.computerPhase == .idle }
        #expect(session.focusSquare == Square("g3"))
    }

    @Test("US5 FR-A11Y-03: undo while the computer thinks is announced like any undo")
    func undoWhileThinking() async {
        let game = Game(turns: [[Step("f6", "e5")]])
        game.play([Step("c3", "d4")])
        await waitUntil { game.pacer.waiting == 1 }
        game.session.undo()
        #expect(game.announcer.announcements.last == "Move undone. Light to move.")
        await settle()
        #expect(game.announcer.announcements.count == 2)
    }
}
