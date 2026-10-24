import CheckersEngine
import Foundation
import Testing

@testable import checkers

/// Move hints off and on (specs/007-settings-themes-sound-and-rules/spec.md, US1;
/// contracts/settings-and-sound.md, "Move hints").
struct US1SettingsTests {
    static let twoPlayers = GameSetup(opponent: .twoPlayers, difficulty: .easy, side: .light)

    /// Light men c3 and a1, Dark men d4 and h8, Light to move: c3 must capture.
    static let capture = GameState(
        ["c3": .lightMan, "a1": .lightMan, "d4": .darkMan, "h8": .darkMan], toMove: .light)
    /// Light man a3 jumps b4 and then d6; Light man g1 could otherwise move.
    static let chain = GameState(
        ["a3": .lightMan, "g1": .lightMan, "b4": .darkMan, "d6": .darkMan, "h8": .darkMan],
        toMove: .light)

    /// Settings in memory with move hints on or off and the other settings at their defaults.
    static func settings(moveHints: Bool) -> AppSettings {
        var values = SettingsValues.defaults
        values.moveHints = moveHints
        return AppSettings(store: InMemorySettingsStore(values))
    }

    /// A two-player session with move hints on or off.
    static func session(hints: Bool, state: GameState = GameState()) -> GameSession {
        GameSession(setup: twoPlayers, state: state, settings: settings(moveHints: hints))
    }

    @Test(
        "US1 FR-AID-01 FR-AID-02 FR-AID-04: with hints on, the default, the board hints as before")
    func hintsOn() {
        let session = GameSession(setup: Self.twoPlayers)
        #expect(session.settings.moveHints)
        #expect(session.hintedPieces == Set(["a3", "c3", "e3", "g3"].map { Square($0) }))
        session.tap(Square("c3"))
        #expect(session.targets == [Square("b4"), Square("d4")])
    }

    @Test(
        "US1 FR-AID-01 FR-AID-02: with hints off, no piece or target is hinted, in captures and chains too"
    )
    func hintsOff() {
        let start = Self.session(hints: false)
        #expect(start.hintedPieces.isEmpty)
        start.tap(Square("c3"))
        #expect(start.selection == Square("c3"))
        #expect(start.targets.isEmpty)

        let capture = Self.session(hints: false, state: Self.capture)
        #expect(capture.hintedPieces.isEmpty)
        capture.tap(Square("c3"))
        #expect(capture.targets.isEmpty)

        let chain = Self.session(hints: false, state: Self.chain)
        chain.tap(Square("a3"))
        chain.tap(Square("c5"))
        #expect(chain.state.chainSquare == Square("c5"))
        #expect(chain.hintedPieces.isEmpty)
        #expect(chain.targets.isEmpty)
    }

    @Test(
        "US1 FR-AID-03 FR-MOVE-05: with hints off, selection, chains, notices and VoiceOver work as before"
    )
    func everythingElseUnchanged() {
        let session = Self.session(hints: false)
        session.tap(Square("c3"))
        #expect(session.selection == Square("c3"))
        session.tap(Square("d4"))
        #expect(session.state.position.piece(at: Square("d4")) == .lightMan)
        #expect(session.turnText.key == "Dark to move")

        let chain = Self.session(hints: false, state: Self.chain)
        chain.tap(Square("a3"))
        chain.tap(Square("c5"))
        #expect(chain.selection == Square("c5"))
        chain.tap(Square("g1"))
        #expect(chain.selection == Square("c5"))
        chain.tap(Square("e7"))
        #expect(chain.turnText.key == "Dark to move")

        let capture = Self.session(hints: false, state: Self.capture)
        #expect(capture.turnText.key == "Light to move · capture required")
        capture.tap(Square("a1"))
        #expect(capture.notice == .captureRequired)
        #expect(capture.selection == nil)
    }

    @Test("US1 FR-AID-03: VoiceOver states every square the same with hints on and off")
    func voiceOverUnchanged() {
        for (state, tapped) in [(GameState(), "c3"), (Self.capture, "c3"), (Self.chain, "a3")] {
            let hintsOn = Self.session(hints: true, state: state)
            let hintsOff = Self.session(hints: false, state: state)
            for session in [hintsOn, hintsOff] {
                session.tap(Square(tapped))
            }
            for square in Square.all {
                #expect(
                    hintsOff.squareLabel(square).key == hintsOn.squareLabel(square).key,
                    "\(square.name) after tapping \(tapped)")
                #expect(hintsOff.state(of: square) == hintsOn.state(of: square))
            }
        }
    }

    @Test("US1 FR-SET-03: turning hints off and on mid-game changes only the hints, at once")
    func toggleMidGame() {
        let session = Self.session(hints: true)
        session.tap(Square("c3"))
        session.tap(Square("d4"))
        session.tap(Square("f6"))
        let state = session.state
        let canUndo = session.canUndo

        session.settings.moveHints = false
        #expect(session.hintedPieces.isEmpty)
        #expect(session.targets.isEmpty)
        session.settings.moveHints = true
        #expect(!session.hintedPieces.isEmpty)
        #expect(session.targets == Set(state.targets(from: Square("f6"))))
        #expect(session.state == state)
        #expect(session.selection == Square("f6"))
        #expect(session.canUndo == canUndo)
    }

    @Test(
        "US1 FR-SET-03 FR-NAV-04: changing hints while Settings covers the computer's turn keeps it"
    )
    func toggleWhileTheComputerWaits() async throws {
        let opponent = ScriptedComputerOpponent(turns: [[Step("f6", "e5")]])
        let pacer = ManualPacer()
        let router = AppRouter(store: InMemorySetupStore(), opponent: opponent, pacer: pacer)
        router.newGame()
        router.setup = GameSetup(opponent: .computer, difficulty: .easy, side: .light)
        router.startGame()
        let session = try #require(router.session)
        session.tap(Square("c3"))
        session.tap(Square("d4"))
        await waitUntil { opponent.requests == 1 && pacer.waiting == 1 }
        let state = session.state

        router.open(.settings)
        router.settings.moveHints = false
        pacer.resumeNext()
        await settle()
        #expect(session.state == state)
        #expect(session.isComputerTurn)

        router.path.removeLast()
        await waitUntil { pacer.waiting == 1 }
        pacer.resumeNext()
        await waitUntil { !session.isComputerTurn }
        #expect(session.state.position.piece(at: Square("e5")) == .darkMan)
        #expect(session.hintedPieces.isEmpty)
        router.settings.moveHints = true
        #expect(!session.hintedPieces.isEmpty)
    }

    @Test("US1 FR-SET-03: every game gets the router's settings, which change no game data")
    func routerSharesItsSettings() throws {
        let games = InMemorySavedGameStore()
        let records = InMemoryRecordStore()
        let setups = InMemorySetupStore()
        let router = AppRouter(store: setups, games: games, records: records)
        router.newGame()
        router.setup = GameSetup(opponent: .twoPlayers, difficulty: .medium, side: .dark)
        router.startGame()
        #expect(router.session?.settings === router.settings)
        router.session?.tap(Square("c3"))
        router.session?.tap(Square("d4"))
        router.playAgain()
        #expect(router.session?.settings === router.settings)
        router.session?.tap(Square("c3"))
        router.session?.tap(Square("d4"))
        router.requestHome()
        router.continueGame()
        #expect(router.session?.settings === router.settings)

        let saved = try games.load()
        let record = try records.load()
        let setup = setups.load()
        router.settings.moveHints = false
        router.settings.soundEffects = false
        router.settings.boardTheme = .playful
        #expect(try games.load() == saved)
        #expect(try records.load() == record)
        #expect(setups.load() == setup)
    }
}
