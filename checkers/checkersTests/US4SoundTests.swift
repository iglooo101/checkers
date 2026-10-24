import CheckersEngine
import Foundation
import Testing

@testable import checkers

/// The game's sounds (specs/007-settings-themes-sound-and-rules/spec.md, US4;
/// contracts/settings-and-sound.md, "Sounds").
struct US4SoundTests {
    static let twoPlayers = GameSetup(opponent: .twoPlayers, difficulty: .easy, side: .light)
    static let computer = GameSetup(opponent: .computer, difficulty: .easy, side: .light)

    /// Light men c3 and a1, Dark men d4 and h8, Light to move: c3 must capture.
    static let capture = GameState(
        ["c3": .lightMan, "a1": .lightMan, "d4": .darkMan, "h8": .darkMan], toMove: .light)
    /// Light to move h2–g3; then Dark, the computer, jumps f6–d4 and d4–b2. Dark's g7 keeps e5
    /// from capturing f6.
    static let computerChain = GameState(
        ["e5": .lightMan, "c3": .lightMan, "h2": .lightMan, "f6": .darkMan, "g7": .darkMan],
        toMove: .light)
    static let chainTurn = [Step("f6", "d4"), Step("d4", "b2")]

    /// Settings in memory with sound effects on or off.
    static func settings(sound: Bool) -> AppSettings {
        var values = SettingsValues.defaults
        values.soundEffects = sound
        return AppSettings(store: InMemorySettingsStore(values))
    }

    /// A two-player session that plays into `sounds`.
    static func session(
        state: GameState = GameState(), sound: Bool = true, sounds: RecordingSoundPlayer
    ) -> GameSession {
        GameSession(
            setup: twoPlayers, state: state, settings: settings(sound: sound), sounds: sounds)
    }

    /// A game against the computer from `computerChain`, with a manual pacer.
    static func computerSession(sound: Bool = true, sounds: RecordingSoundPlayer)
        -> (GameSession, ManualPacer)
    {
        let pacer = ManualPacer()
        let session = GameSession(
            setup: computer, playerSide: .light, state: computerChain,
            opponent: ScriptedComputerOpponent(turns: [chainTurn]), pacer: pacer,
            settings: settings(sound: sound), sounds: sounds)
        return (session, pacer)
    }

    /// What one step from a state did.
    static func result(_ step: Step, from state: GameState) throws -> StepResult {
        var state = state
        return try state.apply(step)
    }

    @Test(
        "US4 FR-SND-01: a step plays the end of the game, else crowning, else capture, else move"
    )
    func soundOfEachStep() throws {
        #expect(SoundEffect.of(try Self.result(Step("c3", "d4"), from: GameState())) == .move)
        #expect(SoundEffect.of(try Self.result(Step("c3", "e5"), from: Self.capture)) == .capture)
        let crowningMove = GameState(
            ["c7": .lightMan, "a1": .lightMan, "h6": .darkMan], toMove: .light)
        #expect(
            SoundEffect.of(try Self.result(Step("c7", "d8"), from: crowningMove)) == .crowning)
        let crowningJump = GameState(
            ["b6": .lightMan, "c7": .darkMan, "e7": .darkMan], toMove: .light)
        #expect(
            SoundEffect.of(try Self.result(Step("b6", "d8"), from: crowningJump)) == .crowning)

        // Last steps that leave the other side no move: plain, capturing and crowning.
        let blocking = GameState(
            ["h6": .lightMan, "f6": .lightMan, "h8": .darkMan], toMove: .light)
        #expect(SoundEffect.of(try Self.result(Step("h6", "g7"), from: blocking)) == .gameEnd)
        let lastCapture = GameState(["c3": .lightMan, "d4": .darkMan], toMove: .light)
        #expect(
            SoundEffect.of(try Self.result(Step("c3", "e5"), from: lastCapture)) == .gameEnd)
        let crowningEnd = GameState(
            ["c7": .lightMan, "g7": .lightMan, "f6": .lightMan, "h8": .darkMan], toMove: .light)
        #expect(
            SoundEffect.of(try Self.result(Step("c7", "d8"), from: crowningEnd)) == .gameEnd)

        // The step that draws by repetition.
        var shuffle = GameState(["h2": .lightKing, "a7": .darkKing], toMove: .light)
        var last: StepResult?
        for step in US4GameEndTests.shuffle {
            last = try shuffle.apply(step)
        }
        #expect(last?.outcome != .inProgress)
        #expect(last.map(SoundEffect.of) == .gameEnd)
    }

    @Test("US4 FR-SND-01: replayed games play one sound per step, the step's own, in order")
    func oneSoundPerStep() throws {
        for game in ScriptedGame.all {
            let sounds = RecordingSoundPlayer()
            let session = Self.session(state: game.start, sounds: sounds)
            var state = game.start
            var expected: [SoundEffect] = []
            for step in game.steps {
                expected.append(SoundEffect.of(try state.apply(step)))
                session.tap(step.from)
                session.tap(step.to)
                #expect(sounds.played == expected, "\(game.name) after \(step.from.name)")
            }
            if game.name == "double jump" {
                #expect(sounds.played == [.capture, .capture])
            }
        }
    }

    @Test("US4 FR-SND-01 FR-SND-03: each of the computer's steps plays its sound as it appears")
    func computerSteps() async {
        let sounds = RecordingSoundPlayer()
        let (session, pacer) = Self.computerSession(sounds: sounds)
        session.tap(Square("h2"))
        session.tap(Square("g3"))
        #expect(sounds.played == [.move])

        await waitUntil { pacer.waiting == 1 }
        #expect(sounds.played == [.move], "thinking is silent")
        pacer.resumeNext()
        await waitUntil { sounds.played.count == 2 }
        #expect(sounds.played == [.move, .capture])
        await waitUntil { pacer.waiting == 1 }
        pacer.resumeNext()
        await waitUntil { sounds.played.count == 3 }
        await settle()
        #expect(sounds.played == [.move, .capture, .capture])
    }

    @Test("US4 FR-SND-01: a resignation plays the game-end sound once")
    func resignation() {
        let sounds = RecordingSoundPlayer()
        let session = Self.session(sounds: sounds)
        session.resign()
        #expect(sounds.played == [.gameEnd])
        session.resign()
        #expect(sounds.played == [.gameEnd], "resigning a finished game plays nothing")
    }

    @Test("US4 FR-SND-03: selecting, refused taps and drops, notices and undo make no sound")
    func silentActions() {
        let sounds = RecordingSoundPlayer()
        let session = Self.session(sounds: sounds)
        session.tap(Square("c3"))
        session.tap(Square("c3"))
        session.tap(Square("c5"))
        #expect(!session.beginDrag(at: Square("c1")))
        #expect(session.beginDrag(at: Square("c3")))
        session.drop(on: Square("c5"))
        #expect(sounds.played.isEmpty)
        // The refused drop leaves c3 selected; its move plays, and undoing it does not.
        #expect(session.selection == Square("c3"))
        session.tap(Square("d4"))
        session.undo()
        #expect(sounds.played == [.move])

        let noticeSounds = RecordingSoundPlayer()
        let capture = Self.session(state: Self.capture, sounds: noticeSounds)
        capture.tap(Square("a1"))
        #expect(capture.notice == .captureRequired)
        #expect(noticeSounds.played.isEmpty)
    }

    @Test("US4 FR-SND-03: Continue is silent; the computer's resumed turn plays its own step")
    func continueIsSilent() async throws {
        var state = GameState()
        _ = try state.apply(Step("c3", "d4"))
        let saved = SavedGame(setup: Self.computer, playerSide: .light, state: state)
        let pacer = ManualPacer()
        let sounds = RecordingSoundPlayer()
        let router = AppRouter(
            store: InMemorySetupStore(),
            opponent: ScriptedComputerOpponent(turns: [[Step("f6", "e5")]]), pacer: pacer,
            games: InMemorySavedGameStore(saved), sounds: sounds)
        router.continueGame()
        await waitUntil { pacer.waiting == 1 }
        #expect(sounds.played.isEmpty)
        pacer.resumeNext()
        await waitUntil { !sounds.played.isEmpty }
        #expect(sounds.played == [.move])
    }

    @Test("US4 FR-SET-04: with sound effects off nothing plays; turned on, the next step plays")
    func soundOff() async {
        let sounds = RecordingSoundPlayer()
        let session = Self.session(sound: false, sounds: sounds)
        for (from, to) in [("c3", "d4"), ("f6", "e5"), ("d4", "f6")] {
            session.tap(Square(from))
            session.tap(Square(to))
        }
        #expect(sounds.played.isEmpty)
        session.settings.soundEffects = true
        session.tap(Square("g7"))
        session.tap(Square("e5"))
        #expect(sounds.played == [.capture])
        session.settings.soundEffects = false
        session.resign()
        #expect(sounds.played == [.capture])

        let computerSounds = RecordingSoundPlayer()
        let (game, pacer) = Self.computerSession(sound: false, sounds: computerSounds)
        game.tap(Square("h2"))
        game.tap(Square("g3"))
        await waitUntil { pacer.waiting == 1 }
        pacer.resumeNext()
        await waitUntil { pacer.waiting == 1 }
        pacer.resumeNext()
        await waitUntil { !game.isComputerTurn }
        #expect(computerSounds.played.isEmpty)
    }
}
