import CheckersEngine
import Foundation
import Testing

@testable import checkers

/// Playing a game against the computer (specs/005-computer-opponent/spec.md, US1;
/// contracts/computer-turn.md, Timeline and Input).
struct US1ComputerGameTests {
    /// A game against a scripted computer, with the player on `playerSide`.
    struct Game {
        let session: GameSession
        let opponent: ScriptedComputerOpponent
        let pacer: ManualPacer
        let announcer: RecordingAnnouncer

        init(
            playerSide: Side = .light, state: GameState = GameState(), turns: [[Step]] = [],
            isHeld: Bool = false
        ) {
            opponent = ScriptedComputerOpponent(turns: turns, isHeld: isHeld)
            pacer = ManualPacer()
            announcer = RecordingAnnouncer()
            session = GameSession(
                setup: GameSetup(
                    opponent: .computer, difficulty: .easy,
                    side: playerSide == .light ? .light : .dark),
                playerSide: playerSide, state: state, announcer: announcer, opponent: opponent,
                pacer: pacer)
        }

        /// Plays the player's steps by tapping.
        func play(_ steps: [Step]) {
            for step in steps {
                session.tap(step.from)
                session.tap(step.to)
            }
        }

        /// Ends the next pause once the computer's turn has asked for it.
        func resumePause(sourceLocation: SourceLocation = #_sourceLocation) async {
            await waitUntil({ pacer.waiting == 1 }, sourceLocation: sourceLocation)
            pacer.resumeNext()
        }
    }

    @Test("US1 FR-AI-03 FR-MOVE-04: while the computer thinks, the board takes no input")
    func boardLockedWhileThinking() async {
        let game = Game(turns: [[Step("f6", "e5")]])
        game.play([Step("c3", "d4")])
        let session = game.session

        #expect(session.computerPhase == .thinking)
        #expect(session.isComputerTurn)
        #expect(session.turnText.key == "Dark is thinking…")
        #expect(session.hintedPieces.isEmpty)
        #expect(session.targets.isEmpty)
        #expect(Square.all.allSatisfy { session.state(of: $0) == .none })
        session.tap(Square("e3"))
        #expect(session.selection == nil)
        #expect(!session.beginDrag(at: Square("e3")))
        session.tap(Square("b6"))
        #expect(session.selection == nil)
        #expect(session.notice == nil)

        await game.resumePause()
        await waitUntil { session.computerPhase == .idle }
        #expect(session.state.position.piece(at: Square("e5")) == .darkMan)
        #expect(session.turnText.key == "Light to move · capture required")
        #expect(session.selection == nil)
        #expect(session.notice == nil)
        #expect(session.hintedPieces == Set(session.state.movablePieces))
        #expect(session.hintedPieces == [Square("d4")])
    }

    @Test("US1 FR-AI-03: the first step waits for both the computer's choice and the 0.5 s pause")
    func firstStepWaitsForBoth() async {
        // The pause ends first; the step waits for the answer.
        let held = Game(turns: [[Step("f6", "e5")]], isHeld: true)
        held.play([Step("c3", "d4")])
        await held.resumePause()
        await settle()
        #expect(held.session.state.position.piece(at: Square("f6")) == .darkMan)
        #expect(held.session.computerPhase == .thinking)
        held.opponent.release()
        await waitUntil { held.session.computerPhase == .idle }
        #expect(held.session.state.position.piece(at: Square("e5")) == .darkMan)
        #expect(held.pacer.requested == [.milliseconds(500)])

        // The answer comes first; the step waits for the pause.
        let quick = Game(turns: [[Step("f6", "e5")]])
        quick.play([Step("c3", "d4")])
        await waitUntil { quick.opponent.requests == 1 && quick.pacer.waiting == 1 }
        await settle()
        #expect(quick.session.state.position.piece(at: Square("f6")) == .darkMan)
        quick.pacer.resumeNext()
        await waitUntil { quick.session.computerPhase == .idle }
        #expect(quick.session.state.position.piece(at: Square("e5")) == .darkMan)
    }

    @Test("US1 FR-AI-05: the computer's chain is shown one jump at a time, 0.5 s apart")
    func chainJumpByJump() async {
        let state = GameState(
            [
                "e5": .lightMan, "c3": .lightMan, "h2": .lightMan, "f6": .darkMan,
                "g7": .darkMan,
            ], toMove: .light)
        let game = Game(state: state, turns: [[Step("f6", "d4"), Step("d4", "b2")]])
        game.play([Step("h2", "g3")])
        let session = game.session

        await game.resumePause()
        await waitUntil { session.computerPhase == .playing }
        #expect(session.state.position.piece(at: Square("e5")) == nil)
        #expect(session.state.position.piece(at: Square("d4")) == .darkMan)
        #expect(session.state.position.piece(at: Square("c3")) == .lightMan)
        #expect(session.turnText.key == "Dark is thinking…")

        await game.resumePause()
        await waitUntil { session.computerPhase == .idle }
        #expect(session.state.position.piece(at: Square("c3")) == nil)
        #expect(session.state.position.piece(at: Square("b2")) == .darkMan)
        #expect(game.pacer.requested == [.milliseconds(500), .milliseconds(500)])
        #expect(session.state.sideToMove == .light)
    }

    @Test("US1 FR-AI-06: the computer starts its turn at once when it plays Light")
    func computerOpensAsLight() async {
        let asDark = Game(playerSide: .dark, turns: [[Step("c3", "d4")]])
        asDark.session.startComputerTurnIfNeeded()
        #expect(asDark.session.computerPhase == .thinking)
        await asDark.resumePause()
        await waitUntil { asDark.session.computerPhase == .idle }
        #expect(asDark.session.state.position.piece(at: Square("d4")) == .lightMan)
        #expect(asDark.session.state.sideToMove == .dark)

        let asLight = Game(playerSide: .light)
        asLight.session.startComputerTurnIfNeeded()
        #expect(asLight.session.computerPhase == .idle)
        await settle()
        #expect(asLight.opponent.requests == 0)
    }

    @Test("US1 FR-END-06: a computer step that ends the game shows the result")
    func computerEndsTheGame() async {
        let state = GameState(["c3": .lightMan, "e5": .darkMan], toMove: .light)
        let game = Game(state: state, turns: [[Step("e5", "c3")]])
        game.play([Step("c3", "d4")])
        await game.resumePause()
        await waitUntil { game.session.computerPhase == .idle }
        #expect(game.session.isOver)
        #expect(game.session.resultText?.key == "Dark wins: no moves left")
        #expect(!game.session.canUndo)
    }

    @Test(
        "US1 FR-AI-01: if the computer gives no turn while the game goes on, it plays the first legal one"
    )
    func fallbackTurn() async {
        let game = Game(isHeld: true)
        game.play([Step("c3", "d4")])
        await game.resumePause()
        await waitUntil { game.opponent.requests == 1 }
        game.opponent.release()
        await waitUntil { game.session.computerPhase == .idle }
        #expect(game.session.state.position.piece(at: Square("a5")) == .darkMan)
        #expect(game.session.state.sideToMove == .light)
    }

    @Test("US1 FR-AI-01: the engine opponent at Easy answers with a legal turn for either side")
    func engineOpponent() async throws {
        let opponent = EngineComputerOpponent()
        var state = GameState()
        for _ in 0..<2 {
            let steps = try #require(await opponent.chooseTurn(in: state, difficulty: .easy))
            for step in steps {
                try state.apply(step)
            }
            #expect(state.chainSquare == nil)
        }
        #expect(state.sideToMove == .light)
    }

    @Test("US1 FR-AI-06: from setup, the computer moves first as Light, also after Play again")
    func routerStartsTheComputer() async {
        var draws: [Side] = [.light, .dark]
        let pacer = ManualPacer()
        let router = AppRouter(
            store: InMemorySetupStore(), drawSide: { draws.removeFirst() },
            opponent: ScriptedComputerOpponent(), pacer: pacer)
        router.newGame()
        router.setup = GameSetup(opponent: .computer, difficulty: .easy, side: .dark)
        router.startGame()
        #expect(router.path == [.game])
        #expect(router.session?.computerPhase == .thinking)

        router.setup.side = .random
        router.open(gameWith: router.setup)
        #expect(router.session?.playerSide == .light)
        #expect(router.session?.computerPhase == .idle)
        router.playAgain()
        #expect(router.session?.playerSide == .dark)
        #expect(router.session?.computerPhase == .thinking)
    }
}
