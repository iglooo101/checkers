import CheckersEngine
import Foundation
import Testing

@testable import checkers

/// Undo against the computer (specs/005-computer-opponent/spec.md, US4; contracts/computer-turn.md,
/// Undo in a computer game; research R9).
struct US4ComputerUndoTests {
    typealias Game = US1ComputerGameTests.Game

    /// Plays the player's steps, then lets the computer finish its reply.
    static func playTurn(_ steps: [Step], in game: Game) async {
        game.play(steps)
        await game.resumePause()
        await waitUntil { game.session.computerPhase == .idle }
    }

    @Test("US4 FR-UNDO-03: undo takes back the computer's reply and the player's turn together")
    func undoTakesBackAPair() async {
        // Kings only, so neither turn is progress and the no-progress count must come back too.
        let start = GameState(["b2": .lightKing, "g7": .darkKing], toMove: .light)
        let game = Game(state: start, turns: [[Step("g7", "f8")]])
        await Self.playTurn([Step("b2", "c3")], in: game)
        #expect(game.session.state.position.piece(at: Square("f8")) == .darkKing)

        game.session.undo()
        #expect(game.session.state == start)
        #expect(game.session.computerPhase == .idle)
        #expect(game.announcer.announcements.last == "Move undone. Light to move.")
        await settle()
        #expect(game.opponent.requests == 1)
    }

    @Test(
        "US4 FR-UNDO-03: Undo is unavailable until the player has moved, and once the game is over"
    )
    func undoAvailability() async {
        let asLight = Game(turns: [[Step("f6", "e5")]])
        #expect(!asLight.session.canUndo)
        asLight.play([Step("c3", "d4")])
        #expect(asLight.session.canUndo)
        await asLight.resumePause()
        await waitUntil { asLight.session.computerPhase == .idle }
        #expect(asLight.session.canUndo)
        asLight.session.resign()
        #expect(!asLight.session.canUndo)

        // The computer opens as Light: still nothing of the player's to take back.
        let asDark = Game(playerSide: .dark, turns: [[Step("c3", "d4")]])
        asDark.session.startComputerTurnIfNeeded()
        #expect(!asDark.session.canUndo)
        await asDark.resumePause()
        await waitUntil { asDark.session.computerPhase == .idle }
        #expect(asDark.session.state.sideToMove == .dark)
        #expect(!asDark.session.canUndo)
        let opened = asDark.session.state
        asDark.session.undo()
        #expect(asDark.session.state == opened)
    }

    @Test(
        "US4 FR-UNDO-04: undo while the computer thinks takes back the player's move and stops it"
    )
    func undoWhileThinking() async {
        let game = Game(turns: [[Step("f6", "e5")]])
        game.play([Step("c3", "d4")])
        await waitUntil { game.opponent.requests == 1 && game.pacer.waiting == 1 }

        game.session.undo()
        #expect(game.session.state == GameState())
        #expect(game.session.computerPhase == .idle)
        #expect(!game.session.isComputerTurn)
        game.pacer.resumeNext()
        await settle()
        #expect(game.session.state == GameState())
        #expect(game.announcer.announcements.last == "Move undone. Light to move.")
    }

    @Test("US4 FR-UNDO-04: undo between the computer's jumps takes back its partial chain too")
    func undoBetweenJumps() async {
        let game = Game(
            state: US3ComputerControlTests.chainPosition,
            turns: [[Step("f6", "d4"), Step("d4", "b2")]])
        game.play([Step("h2", "g3")])
        await game.resumePause()
        await waitUntil { game.session.computerPhase == .playing }

        game.session.undo()
        #expect(game.session.state == US3ComputerControlTests.chainPosition)
        #expect(game.session.computerPhase == .idle)
        game.pacer.resumeNext()
        await settle()
        #expect(game.session.state == US3ComputerControlTests.chainPosition)
    }

    @Test("US4 FR-UNDO-05: undo in the player's own chain restores the position before it")
    func undoInPlayersChain() async {
        let start = GameState(
            ["a3": .lightMan, "g1": .lightMan, "b4": .darkMan, "d6": .darkMan, "h8": .darkMan],
            toMove: .light)
        let game = Game(state: start)
        game.play([Step("a3", "c5")])
        #expect(game.session.state.chainSquare == Square("c5"))

        game.session.undo()
        #expect(game.session.state == start)
        #expect(game.session.computerPhase == .idle)
        #expect(game.session.turnText.key == "Light to move · capture required")
        await settle()
        #expect(game.opponent.requests == 0)
    }

    @Test("US4 FR-UNDO-01: each undo goes back one of the player's turns, to the player's first")
    func undoRepeatedly() async {
        let asLight = Game(
            turns: [[Step("h6", "g5")], [Step("g7", "h6")], [Step("f6", "e5")]])
        for step in [Step("a3", "b4"), Step("b4", "a5"), Step("c3", "b4")] {
            await Self.playTurn([step], in: asLight)
        }
        for _ in 0..<3 {
            asLight.session.undo()
        }
        #expect(asLight.session.state == GameState())
        #expect(!asLight.session.canUndo)

        // The computer's opening move as Light is never taken back.
        let asDark = Game(
            playerSide: .dark,
            turns: [[Step("c3", "d4")], [Step("g3", "h4")], [Step("b2", "c3")]])
        asDark.session.startComputerTurnIfNeeded()
        await asDark.resumePause()
        await waitUntil { asDark.session.computerPhase == .idle }
        let opened = asDark.session.state
        for step in [Step("b6", "a5"), Step("h6", "g5")] {
            await Self.playTurn([step], in: asDark)
        }
        for _ in 0..<3 {
            asDark.session.undo()
        }
        #expect(asDark.session.state == opened)
        #expect(asDark.session.state.sideToMove == .dark)
        #expect(!asDark.session.canUndo)
    }
}
