import CheckersEngine
import Foundation
import Testing

@testable import checkers

/// Continuing where the player left off (specs/006-saving-and-statistics/spec.md, US1;
/// contracts/saved-game.md, "Save points" and "Launch and Continue").
struct US1ContinueTests {
    /// A router over in-memory stores, with a scripted computer and a manual pacer.
    struct Routed {
        let router: AppRouter
        let games: InMemorySavedGameStore
        let opponent: ScriptedComputerOpponent
        let pacer: ManualPacer
        let setups: InMemorySetupStore

        init(saved: SavedGame? = nil, turns: [[Step]] = []) {
            games = saved.map { InMemorySavedGameStore($0) } ?? InMemorySavedGameStore()
            opponent = ScriptedComputerOpponent(turns: turns)
            pacer = ManualPacer()
            setups = InMemorySetupStore()
            router = AppRouter(store: setups, opponent: opponent, pacer: pacer, games: games)
        }

        /// The session the router shows.
        var session: GameSession {
            get throws { try #require(router.session) }
        }

        /// The state of the saved game, if any.
        var savedState: GameState? {
            get throws { try games.load()?.state }
        }

        /// Starts a game with these choices from Game setup.
        func start(_ setup: GameSetup) {
            router.newGame()
            router.setup = setup
            router.startGame()
        }

        /// Plays the player's steps by tapping.
        func play(_ steps: [Step]) throws {
            let session = try session
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

    static let twoPlayers = GameSetup(opponent: .twoPlayers, difficulty: .easy, side: .light)
    static let computerLight = GameSetup(opponent: .computer, difficulty: .easy, side: .light)
    static let computerDark = GameSetup(opponent: .computer, difficulty: .hard, side: .dark)

    /// Light, to move, can jump c3–e5 and then e5–g7.
    static let doubleJump = GameState(
        ["c3": .lightMan, "h2": .lightMan, "d4": .darkMan, "f6": .darkMan, "a7": .darkMan],
        toMove: .light)

    /// After Light's h2–g3, Dark (the computer) jumps f6–d4 and then d4–b2.
    static let computerChain = GameState(
        ["e5": .lightMan, "c3": .lightMan, "h2": .lightMan, "f6": .darkMan, "g7": .darkMan],
        toMove: .light)
    static let chainReply = [Step("f6", "d4"), Step("d4", "b2")]

    @Test("US1 FR-SAVE-01: the game is saved after every turn of either side and after undo")
    func savedAfterEveryTurn() async throws {
        let pair = Routed()
        pair.start(Self.twoPlayers)
        try pair.play([Step("c3", "d4")])
        #expect(try pair.savedState == pair.session.state)
        try pair.play([Step("f6", "e5")])
        #expect(try pair.savedState == pair.session.state)
        try pair.session.undo()
        #expect(try pair.savedState?.position.piece(at: Square("f6")) == .darkMan)
        #expect(try pair.savedState == pair.session.state)

        let computer = Routed(turns: [[Step("f6", "e5")]])
        computer.start(Self.computerLight)
        try computer.play([Step("c3", "d4")])
        #expect(try computer.savedState == computer.session.state)
        await computer.resumePause()
        let session = try computer.session
        await waitUntil { session.computerPhase == .idle }
        #expect(session.state.position.piece(at: Square("e5")) == .darkMan)
        #expect(try computer.savedState == session.state)
    }

    @Test(
        "US1 FR-SAVE-01 FR-SAVE-04: the app saves the computer's turn from its start, the player's chain as it is"
    )
    func saveNowMidTurn() async throws {
        let thinking = Routed(turns: [[Step("f6", "e5")]])
        thinking.start(Self.computerLight)
        try thinking.play([Step("c3", "d4")])
        let start = try thinking.session.state
        #expect(try thinking.session.computerPhase == .thinking)
        thinking.router.saveNow()
        #expect(try thinking.savedState == start)

        let chain = Routed(
            saved: SavedGame(
                setup: Self.computerLight, playerSide: .light, state: Self.computerChain),
            turns: [Self.chainReply])
        chain.router.continueGame()
        try chain.play([Step("h2", "g3")])
        let chainStart = try chain.session.state
        await chain.resumePause()
        let session = try chain.session
        await waitUntil { session.computerPhase == .playing }
        #expect(session.state.chainSquare == Square("d4"))
        chain.router.saveNow()
        #expect(try chain.savedState == chainStart)

        let player = Routed(
            saved: SavedGame(setup: Self.twoPlayers, playerSide: nil, state: Self.doubleJump))
        player.router.continueGame()
        try player.play([Step("c3", "e5")])
        #expect(try player.session.state.chainSquare == Square("e5"))
        player.router.saveNow()
        #expect(try player.savedState == player.session.state)
        #expect(try player.savedState?.chainSquare == Square("e5"))
    }

    @Test("US1 FR-NAV-03: Home returns at once, keeps the game and stops the computer's turn")
    func homeKeepsTheGame() async throws {
        let game = Routed(turns: [[Step("f6", "e5")]])
        game.start(Self.computerLight)
        try game.play([Step("c3", "d4")])
        let session = try game.session
        let start = session.state
        game.router.requestHome()
        #expect(game.router.path.isEmpty)
        #expect(game.router.session == nil)
        #expect(session.computerPhase == .idle)
        #expect(game.router.hasSavedGame)
        #expect(try game.savedState == start)
    }

    @Test(
        "US1 FR-NAV-03 FR-SAVE-04: Home between the computer's jumps keeps the start of its turn, which it then replays"
    )
    func homeBetweenJumps() async throws {
        let game = Routed(
            saved: SavedGame(
                setup: Self.computerLight, playerSide: .light, state: Self.computerChain),
            turns: [Self.chainReply, Self.chainReply])
        game.router.continueGame()
        try game.play([Step("h2", "g3")])
        let start = try game.session.state
        await game.resumePause()
        let left = try game.session
        await waitUntil { left.computerPhase == .playing }

        game.router.requestHome()
        #expect(try game.savedState == start)
        #expect(try game.savedState?.chainSquare == nil)
        // The cancelled turn's pause goes away before the continued game asks for its own.
        await settle()
        #expect(game.pacer.waiting == 0)

        game.router.continueGame()
        let resumed = try game.session
        #expect(resumed.state == start)
        #expect(resumed.computerPhase == .thinking)
        await game.resumePause()
        await game.resumePause()
        await waitUntil { resumed.computerPhase == .idle }
        #expect(resumed.state.position.piece(at: Square("b2")) == .darkMan)
        #expect(resumed.state.sideToMove == .light)
        #expect(try game.savedState == resumed.state)
    }

    @Test("US1 FR-NAV-02: Continue is offered when, and only when, a saved game exists")
    func continueOffered() throws {
        #expect(!Routed().router.hasSavedGame)
        let saved = SavedGame(setup: Self.twoPlayers, playerSide: nil, state: GameState())
        #expect(Routed(saved: saved).router.hasSavedGame)
    }

    @Test(
        "US1 FR-SAVE-03 FR-SETUP-03: Continue restores the game exactly and leaves the setup choices alone"
    )
    func continueRestoresExactly() throws {
        var state = GameState()
        try state.apply(Step("c3", "d4"))
        try state.apply(Step("f6", "e5"))
        try state.apply(Step("d4", "f6"))
        let saved = SavedGame(setup: Self.computerDark, playerSide: .dark, state: state)
        let game = Routed(saved: saved)
        game.setups.save(Self.twoPlayers)

        game.router.continueGame()
        #expect(game.router.path == [.game])
        let session = try game.session
        #expect(session.state == state)
        #expect(session.setup == Self.computerDark)
        #expect(session.playerSide == .dark)
        #expect(session.layout.bottomSide == .dark)
        #expect(game.setups.load() == Self.twoPlayers)

        // Undo takes back the computer's capture and the player's f6–e5, as it would have before.
        var expected = state
        try expected.undo()
        try expected.undo()
        session.undo()
        #expect(session.state == expected)

        let chain = Routed(
            saved: SavedGame(setup: Self.twoPlayers, playerSide: nil, state: Self.doubleJump))
        chain.router.continueGame()
        try chain.play([Step("c3", "e5")])
        chain.router.requestHome()
        chain.router.continueGame()
        #expect(try chain.session.selection == Square("e5"))
        #expect(try chain.session.state.chainSquare == Square("e5"))
    }

    @Test(
        "US1 FR-SAVE-04: a game saved on the computer's turn resumes with exactly one computer turn"
    )
    func computerResumes() async throws {
        var state = GameState()
        try state.apply(Step("c3", "d4"))
        let saved = SavedGame(setup: Self.computerLight, playerSide: .light, state: state)
        let game = Routed(saved: saved, turns: [[Step("f6", "e5")], [Step("g7", "f6")]])

        game.router.continueGame()
        let session = try game.session
        #expect(session.computerPhase == .thinking)
        await game.resumePause()
        await waitUntil { session.computerPhase == .idle }
        #expect(session.state.position.piece(at: Square("e5")) == .darkMan)
        #expect(session.state.sideToMove == .light)
        await settle()
        #expect(game.opponent.requests == 1)
        #expect(try game.savedState == session.state)
    }
}
