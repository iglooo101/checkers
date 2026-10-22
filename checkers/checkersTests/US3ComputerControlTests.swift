import CheckersEngine
import Foundation
import Testing

@testable import checkers

/// Staying in control while the computer thinks (specs/005-computer-opponent/spec.md, US3;
/// contracts/computer-turn.md, Cancelling and Router).
struct US3ComputerControlTests {
    /// A computer game started from Game setup, with the player as Light, a scripted computer
    /// and a manual pacer.
    struct RoutedGame {
        let router: AppRouter
        let session: GameSession
        let opponent: ScriptedComputerOpponent
        let pacer: ManualPacer

        init(playerSide: SideChoice = .light, turns: [[Step]] = [[Step("f6", "e5")]]) {
            opponent = ScriptedComputerOpponent(turns: turns)
            pacer = ManualPacer()
            router = AppRouter(store: InMemorySetupStore(), opponent: opponent, pacer: pacer)
            router.newGame()
            router.setup = GameSetup(opponent: .computer, difficulty: .easy, side: playerSide)
            router.startGame()
            session = router.session!
        }

        /// The player plays c3–d4, so the computer starts thinking.
        func playerMoves() {
            session.tap(Square("c3"))
            session.tap(Square("d4"))
        }

        /// Waits until the computer has answered and its thinking pause is waiting.
        func computerHasAnswered(sourceLocation: SourceLocation = #_sourceLocation) async {
            await waitUntil(
                { opponent.requests == 1 && pacer.waiting == 1 }, sourceLocation: sourceLocation)
        }

        /// Whether the computer's reply f6–e5 is still unplayed.
        var isReplyUnplayed: Bool {
            session.state.position.piece(at: Square("f6")) == .darkMan
                && session.state.position.piece(at: Square("e5")) == nil
        }
    }

    @Test("US3 FR-AI-04 FR-END-02: resigning while the computer thinks stops its turn")
    func resignWhileThinking() async {
        let game = RoutedGame()
        game.playerMoves()
        let session = game.session
        await game.computerHasAnswered()

        session.resign()
        #expect(session.computerPhase == .idle)
        #expect(!session.isComputerTurn)
        #expect(session.resultText?.key == "Light resigned")
        game.pacer.resumeNext()
        await settle()
        #expect(game.isReplyUnplayed)
        #expect(session.resultText?.key == "Light resigned")
    }

    @Test("US3 FR-AI-04 FR-END-02: resigning between the computer's jumps stops its chain")
    func resignBetweenJumps() async {
        let game = US1ComputerGameTests.Game(
            state: Self.chainPosition, turns: [[Step("f6", "d4"), Step("d4", "b2")]])
        game.play([Step("h2", "g3")])
        let session = game.session
        await game.resumePause()
        await waitUntil { session.computerPhase == .playing }

        session.resign()
        #expect(session.computerPhase == .idle)
        game.pacer.resumeNext()
        await settle()
        #expect(session.state.position.piece(at: Square("c3")) == .lightMan)
        #expect(session.state.position.piece(at: Square("b2")) == nil)
        #expect(session.resultText?.key == "Light resigned")
    }

    @Test("US3 FR-AI-04: leaving while the computer thinks drops the game; staying lets it move")
    func leaveWhileThinking() async {
        let left = RoutedGame()
        left.playerMoves()
        await left.computerHasAnswered()
        left.router.requestHome()
        #expect(left.router.isConfirmingLeave)
        left.router.confirmLeave()
        #expect(left.router.session == nil)
        #expect(left.router.path.isEmpty)
        #expect(left.session.computerPhase == .idle)
        left.pacer.resumeNext()
        await settle()
        #expect(left.isReplyUnplayed)

        let stayed = RoutedGame()
        stayed.playerMoves()
        await stayed.computerHasAnswered()
        stayed.router.requestHome()
        stayed.router.cancelLeave()
        #expect(stayed.router.path == [.game])
        stayed.pacer.resumeNext()
        await waitUntil { stayed.session.computerPhase == .idle }
        #expect(stayed.session.state.position.piece(at: Square("e5")) == .darkMan)
    }

    @Test(
        "US3 FR-NAV-04: with Rules or Settings open the computer's move waits, then comes after a fresh pause"
    )
    func moveWaitsWhileCovered() async {
        for route in [Route.rules, .settings] {
            let game = RoutedGame()
            game.playerMoves()
            let session = game.session
            game.router.open(route)
            #expect(session.isCovered, "\(route)")
            await game.computerHasAnswered()
            game.pacer.resumeNext()
            await settle()
            #expect(game.isReplyUnplayed, "\(route)")
            #expect(session.computerPhase == .thinking, "\(route)")
            #expect(game.pacer.waiting == 0, "\(route)")

            game.router.path.removeLast()
            #expect(!session.isCovered, "\(route)")
            await waitUntil { game.pacer.waiting == 1 }
            #expect(game.pacer.requested == [.milliseconds(500), .milliseconds(500)], "\(route)")
            #expect(game.isReplyUnplayed, "\(route)")
            game.pacer.resumeNext()
            await waitUntil { session.computerPhase == .idle }
            #expect(session.state.position.piece(at: Square("e5")) == .darkMan, "\(route)")
        }
    }

    @Test("US3 FR-NAV-04: covered between the computer's jumps, the next jump waits unannounced")
    func chainWaitsWhileCovered() async {
        let game = US1ComputerGameTests.Game(
            state: Self.chainPosition, turns: [[Step("f6", "d4"), Step("d4", "b2")]])
        game.play([Step("h2", "g3")])
        let session = game.session
        await game.resumePause()
        await waitUntil { session.computerPhase == .playing }
        let announced = game.announcer.announcements.count

        session.setCovered(true)
        await game.resumePause()
        await settle()
        #expect(session.state.position.piece(at: Square("c3")) == .lightMan)
        #expect(session.computerPhase == .playing)
        #expect(game.announcer.announcements.count == announced)

        session.setCovered(false)
        await game.resumePause()
        await waitUntil { session.computerPhase == .idle }
        #expect(session.state.position.piece(at: Square("b2")) == .darkMan)
        #expect(game.pacer.requested == Array(repeating: .milliseconds(500), count: 3))
        #expect(game.announcer.announcements.count == announced + 1)
    }

    @Test(
        "US3 FR-AI-04: while the computer thinks, Undo follows its rule and the menu's screens open"
    )
    func menuWhileThinking() async {
        let game = RoutedGame()
        game.playerMoves()
        let session = game.session
        #expect(session.isComputerTurn)
        // The player's turn can be taken back.
        #expect(session.canUndo)
        for route in [Route.rules, .settings] {
            game.router.open(route)
            #expect(game.router.path == [.game, route])
            game.router.path.removeLast()
        }
        game.router.requestHome()
        #expect(game.router.isConfirmingLeave)
        game.router.cancelLeave()

        // When the computer opens as Light, the player has no turn to take back yet.
        let opening = RoutedGame(playerSide: .dark, turns: [[Step("c3", "d4")]])
        #expect(opening.session.isComputerTurn)
        #expect(!opening.session.canUndo)
    }

    @Test("US3 FR-AI-04 SC-006: a Hard search leaves the main actor free while it runs")
    func searchLeavesMainActor() async throws {
        let state = GameState(
            [
                "a1": .lightMan, "c1": .lightMan, "e1": .lightMan, "b2": .lightMan,
                "f2": .lightMan, "h2": .lightMan, "a3": .lightMan, "c3": .lightMan,
                "g3": .lightMan, "d4": .lightMan, "e5": .darkMan, "b6": .darkMan,
                "f6": .darkMan, "h6": .darkMan, "a7": .darkMan, "c7": .darkMan, "e7": .darkMan,
                "g7": .darkMan, "d8": .darkMan, "f8": .darkMan,
            ], toMove: .light)
        let events = EventLog()
        let search = Task {
            events.record("search started")
            let steps = await EngineComputerOpponent().chooseTurn(in: state, difficulty: .hard)
            events.record("search ended")
            return steps
        }
        // The main actor runs its tasks in order, so this one runs before the search ends only if
        // the search left the main actor; a search on it would hold it to the end. Order, unlike
        // a time limit, does not depend on how busy the other tests keep the main actor.
        let probe = Task { events.record("main actor free") }
        await probe.value
        let steps = try #require(await search.value)
        #expect(!steps.isEmpty)
        #expect(events.entries == ["search started", "main actor free", "search ended"])
    }

    /// Light to move with h2–g3, after which Dark's f6 takes e5 and c3 in one chain.
    static let chainPosition = GameState(
        ["e5": .lightMan, "c3": .lightMan, "h2": .lightMan, "f6": .darkMan, "g7": .darkMan],
        toMove: .light)

    /// What happened, in order, on the main actor.
    final class EventLog {
        private(set) var entries: [String] = []

        func record(_ entry: String) {
            entries.append(entry)
        }
    }
}
