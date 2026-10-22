import CheckersEngine
import Foundation
import Testing

@testable import checkers

struct US1SquareDescriptionTests {
    static let twoPlayers = GameSetup(opponent: .twoPlayers, difficulty: .easy, side: .light)

    static func session(_ state: GameState = GameState()) -> GameSession {
        GameSession(setup: twoPlayers, state: state, announcer: RecordingAnnouncer())
    }

    /// What VoiceOver says for a square.
    static func label(_ name: String, in session: GameSession) -> String {
        String(localized: session.squareLabel(Square(name)))
    }

    /// The description computed independently from the engine, for comparison (SC-002).
    static func expectedLabel(_ square: Square, in session: GameSession) -> String {
        let piece = session.state.position.piece(at: square)
        let contents =
            piece.map {
                "\($0.side == .light ? "Light" : "Dark") \($0.kind == .man ? "man" : "king")"
            }
            ?? "empty"
        var state: String?
        if session.state.outcome == .inProgress {
            if session.selection == square {
                state = "selected"
            } else if piece == nil, let selection = session.selection,
                session.state.targets(from: selection).contains(square)
            {
                state = "legal target"
            } else if session.state.movablePieces.contains(square) {
                state = "can move"
            }
        }
        return [square.name, contents, state].compactMap { $0 }.joined(separator: ", ")
    }

    @Test("US1 FR-A11Y-01: in a new game the movable men say they can move")
    func newGame() {
        let session = Self.session()
        for name in ["a3", "c3", "e3", "g3"] {
            #expect(Self.label(name, in: session) == "\(name), Light man, can move")
        }
        #expect(Self.label("c1", in: session) == "c1, Light man")
        #expect(Self.label("b6", in: session) == "b6, Dark man")
        #expect(Self.label("d4", in: session) == "d4, empty")
    }

    @Test("US1 FR-A11Y-01: a selected piece and its targets say so")
    func selection() {
        let session = Self.session()
        session.tap(Square("c3"))
        #expect(Self.label("c3", in: session) == "c3, Light man, selected")
        #expect(Self.label("b4", in: session) == "b4, empty, legal target")
        #expect(Self.label("d4", in: session) == "d4, empty, legal target")
        #expect(Self.label("e3", in: session) == "e3, Light man, can move")
    }

    @Test("US1 FR-A11Y-01: when a capture is required only capturing pieces can move")
    func captureRequired() {
        let session = US2CaptureChainTests.capturePosition()
        #expect(Self.label("c3", in: session) == "c3, Light man, can move")
        #expect(Self.label("a1", in: session) == "a1, Light man")
        #expect(Self.label("d4", in: session) == "d4, Dark man")
    }

    @Test("US1 FR-A11Y-01: kings are named as kings in every state")
    func kings() {
        let session = Self.session(
            GameState(["d4": .lightKing, "f6": .darkKing, "h8": .darkMan], toMove: .light))
        #expect(Self.label("d4", in: session) == "d4, Light king, can move")
        #expect(Self.label("f6", in: session) == "f6, Dark king")
        session.tap(Square("d4"))
        #expect(Self.label("d4", in: session) == "d4, Light king, selected")
    }

    @Test("US1 FR-A11Y-01: during a chain only the jumping piece and its next landing have a state")
    func chain() {
        let session = Self.session(ScriptedGame.all[2].start)
        session.tap(Square("a3"))
        session.tap(Square("c5"))
        #expect(Self.label("c5", in: session) == "c5, Light man, selected")
        #expect(Self.label("e7", in: session) == "e7, empty, legal target")
        #expect(Self.label("g1", in: session) == "g1, Light man")
    }

    @Test("US1 FR-A11Y-01: a finished game has no states")
    func finished() {
        let session = Self.session()
        session.resign()
        for square in Square.all {
            #expect(!String(localized: session.squareLabel(square)).contains("can move"))
        }
        #expect(Self.label("c3", in: session) == "c3, Light man")
    }

    @Test(
        "US1 FR-A11Y-01: in scripted games every square matches the board after every tap (SC-002)")
    func scriptedGames() {
        for game in ScriptedGame.all {
            let session = Self.session(game.start)
            for step in game.steps {
                for square in [step.from, step.to] {
                    session.tap(square)
                    for each in Square.all {
                        #expect(
                            String(localized: session.squareLabel(each))
                                == Self.expectedLabel(each, in: session),
                            "\(game.name), after tapping \(square.name), at \(each.name)")
                    }
                }
            }
        }
    }
}
