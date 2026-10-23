import CheckersEngine
import Foundation
import Testing

@testable import checkers

/// Starting a new game without losing one by accident (specs/006-saving-and-statistics/spec.md,
/// US2; contracts/saved-game.md, "Save points").
struct US2AbandonTests {
    typealias Routed = US1ContinueTests.Routed

    /// A two-player game in which Light's c3–e5 captures Dark's last piece.
    static let lastCapture = GameState(["c3": .lightMan, "d4": .darkMan], toMove: .light)

    /// A game against the computer (Dark) in which Light's only men can move to d4 or b4, and
    /// the computer's e5–c3 then captures Light's last piece.
    static let lostToComputer = GameState(["c3": .lightMan, "e5": .darkMan], toMove: .light)

    @Test(
        "US2 FR-SETUP-04: with a saved game, Start asks first; Cancel keeps both, Abandon starts afresh"
    )
    func abandonQuestion() throws {
        let saved = SavedGame(
            setup: US1ContinueTests.twoPlayers, playerSide: nil, state: Self.lastCapture)
        let game = Routed(saved: saved)
        game.router.newGame()
        game.router.setup = US1ContinueTests.computerDark

        game.router.startGame()
        #expect(game.router.isConfirmingAbandon)
        #expect(game.router.path == [.setup])
        #expect(game.router.session == nil)

        game.router.cancelAbandon()
        #expect(!game.router.isConfirmingAbandon)
        #expect(game.router.path == [.setup])
        #expect(game.router.setup == US1ContinueTests.computerDark)
        #expect(game.router.hasSavedGame)
        #expect(try game.games.load() == saved)
        #expect(game.setups.load() == .defaults)

        game.router.startGame()
        game.router.confirmAbandon()
        #expect(!game.router.isConfirmingAbandon)
        #expect(game.router.path == [.game])
        #expect(try game.session.setup == US1ContinueTests.computerDark)
        #expect(try game.session.state == GameState())
        #expect(game.setups.load() == US1ContinueTests.computerDark)
        #expect(!game.router.hasSavedGame)
        #expect(try game.games.load() == nil)
    }

    @Test("US2 FR-SETUP-04: without a saved game, Start and Play again start at once")
    func noQuestionWithoutASavedGame() throws {
        let game = Routed()
        game.start(US1ContinueTests.twoPlayers)
        #expect(!game.router.isConfirmingAbandon)
        #expect(game.router.path == [.game])
        try game.play([Step("c3", "d4")])
        #expect(game.router.hasSavedGame)

        try game.session.resign()
        #expect(!game.router.hasSavedGame)
        let finished = try game.session
        game.router.playAgain()
        #expect(!game.router.isConfirmingAbandon)
        #expect(try game.session !== finished)
        #expect(try game.session.state == GameState())
    }

    @Test(
        "US2 FR-END-08: a game that ends by a last step of either side or by resignation is no longer saved"
    )
    func finishedGameCleared() async throws {
        let won = Routed(
            saved: SavedGame(
                setup: US1ContinueTests.twoPlayers, playerSide: nil, state: Self.lastCapture))
        won.router.continueGame()
        try won.play([Step("c3", "e5")])
        #expect(try won.session.isOver)
        #expect(!won.router.hasSavedGame)
        #expect(try won.games.load() == nil)

        let lost = Routed(
            saved: SavedGame(
                setup: US1ContinueTests.computerLight, playerSide: .light,
                state: Self.lostToComputer),
            turns: [[Step("e5", "c3")]])
        lost.router.continueGame()
        try lost.play([Step("c3", "d4")])
        #expect(lost.router.hasSavedGame)
        await lost.resumePause()
        let session = try lost.session
        await waitUntil { session.isOver }
        #expect(session.state.outcome == .win(winner: .dark, reason: .noMovesLeft))
        #expect(!lost.router.hasSavedGame)
        #expect(try lost.games.load() == nil)

        let resigned = Routed()
        resigned.start(US1ContinueTests.twoPlayers)
        try resigned.play([Step("c3", "d4")])
        try resigned.session.resign()
        #expect(!resigned.router.hasSavedGame)
        #expect(try resigned.games.load() == nil)
    }

    @Test("US2 FR-END-08: the session reports a game's end exactly once, and no save for it")
    func endedOnce() async throws {
        let won = GameSession(setup: US1ContinueTests.twoPlayers, state: Self.lastCapture)
        var events: [GameSessionEvent] = []
        won.onEvent = { events.append($0) }
        won.tap(Square("c3"))
        won.tap(Square("e5"))
        won.resign()
        won.undo()
        #expect(events == [.ended])

        let resigned = GameSession(setup: US1ContinueTests.twoPlayers)
        var resignEvents: [GameSessionEvent] = []
        resigned.onEvent = { resignEvents.append($0) }
        resigned.tap(Square("c3"))
        resigned.tap(Square("d4"))
        resigned.resign()
        resigned.resign()
        #expect(resignEvents == [.saved, .ended])

        let pacer = ManualPacer()
        let lost = GameSession(
            setup: US1ContinueTests.computerLight, playerSide: .light, state: Self.lostToComputer,
            opponent: ScriptedComputerOpponent(turns: [[Step("e5", "c3")]]), pacer: pacer)
        var lostEvents: [GameSessionEvent] = []
        lost.onEvent = { lostEvents.append($0) }
        lost.tap(Square("c3"))
        lost.tap(Square("d4"))
        await waitUntil { pacer.waiting == 1 }
        pacer.resumeNext()
        await waitUntil { lost.isOver }
        await settle()
        #expect(lostEvents == [.saved, .ended])
    }

    @Test("US2 FR-SETUP-05: abandoning a game against the computer leaves the record unchanged")
    func abandonRecordsNothing() throws {
        let records = InMemoryRecordStore()
        let saved = SavedGame(
            setup: US1ContinueTests.computerLight, playerSide: .light, state: GameState())
        let router = AppRouter(
            store: InMemorySetupStore(), opponent: ScriptedComputerOpponent(),
            games: InMemorySavedGameStore(saved), records: records)
        router.newGame()
        router.startGame()
        router.confirmAbandon()
        #expect(try records.load() == Record())
    }
}
