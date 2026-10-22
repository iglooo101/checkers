import CheckersEngine
import Foundation
import Testing

@testable import checkers

struct US4GameEndTests {
    static let twoPlayers = GameSetup(opponent: .twoPlayers, difficulty: .easy, side: .light)

    /// Taps each step's from and to squares in turn.
    static func play(_ steps: [Step], in session: GameSession) {
        for step in steps {
            session.tap(step.from)
            session.tap(step.to)
        }
    }

    /// Two kings shuffling: the opening position occurs for the third time after eight turns.
    static let shuffle = Array(
        repeating: [Step("h2", "g1"), Step("a7", "b8"), Step("g1", "h2"), Step("b8", "a7")],
        count: 2
    ).flatMap { $0 }

    /// Two kings touring loops of 8 and 6 squares that never touch and never repeat a position
    /// three times within 80 turns (E2, specs/002-rules-engine/tasks.md T025).
    static func tour(turns: Int) -> [Step] {
        let lightTour = ["b2", "c1", "d2", "e3", "d4", "c5", "b4", "c3"]
        let darkTour = ["e7", "f8", "g7", "h6", "g5", "f6"]
        return (1...turns).map { turn in
            let (loop, move) =
                turn.isMultiple(of: 2) ? (darkTour, turn / 2 - 1) : (lightTour, turn / 2)
            return Step(loop[move % loop.count], loop[(move + 1) % loop.count])
        }
    }

    @Test("US4 FR-END-02: in a two-player game the side to move resigns")
    func resignation() {
        let lightToMove = GameSession(setup: Self.twoPlayers)
        #expect(lightToMove.resigningSide == .light)
        lightToMove.resign()
        #expect(lightToMove.isOver)
        #expect(lightToMove.resultText?.key == "Light resigned")

        let darkToMove = GameSession(setup: Self.twoPlayers)
        Self.play([Step("c3", "d4")], in: darkToMove)
        #expect(darkToMove.resigningSide == .dark)
        darkToMove.resign()
        #expect(darkToMove.resultText?.key == "Dark resigned")
    }

    @Test("US4 FR-END-01 FR-END-06: capturing the last opposing piece wins, reason no moves left")
    func winByNoMovesLeft() {
        let light = GameSession(
            setup: Self.twoPlayers,
            state: GameState(["c3": .lightMan, "d4": .darkMan], toMove: .light))
        Self.play([Step("c3", "e5")], in: light)
        #expect(light.resultText?.key == "Light wins: no moves left")

        let dark = GameSession(
            setup: Self.twoPlayers,
            state: GameState(["f6": .darkMan, "e5": .lightMan], toMove: .dark))
        Self.play([Step("f6", "d4")], in: dark)
        #expect(dark.resultText?.key == "Dark wins: no moves left")
    }

    @Test("US4 FR-END-03 FR-END-06: the third occurrence of a position draws by repetition")
    func drawByRepetition() {
        let session = GameSession(
            setup: Self.twoPlayers,
            state: GameState(["h2": .lightKing, "a7": .darkKing], toMove: .light))
        Self.play(Self.shuffle, in: session)
        #expect(session.resultText?.key == "Draw by repetition")
    }

    @Test("US4 FR-END-04 FR-END-06: 80 turns without a capture or man move draw by no progress")
    func drawByNoProgress() {
        let session = GameSession(
            setup: Self.twoPlayers,
            state: GameState(["b2": .lightKing, "e7": .darkKing], toMove: .light))
        Self.play(Self.tour(turns: 79), in: session)
        #expect(!session.isOver)
        Self.play(Array(Self.tour(turns: 80).suffix(1)), in: session)
        #expect(session.resultText?.key == "Draw by no progress")
    }

    @Test("US4 FR-END-06: once the game is over, the board accepts nothing")
    func nothingAfterTheEnd() {
        let session = GameSession(setup: Self.twoPlayers)
        session.tap(Square("c3"))
        session.resign()
        #expect(session.selection == nil)
        #expect(session.notice == nil)
        #expect(session.hintedPieces.isEmpty)

        let finished = session.state
        session.tap(Square("e3"))
        #expect(!session.beginDrag(at: Square("e3")))
        session.drop(on: Square("f4"))
        session.resign()
        #expect(session.state == finished)
        #expect(session.selection == nil)
    }

    @Test(
        "US4 FR-END-07: Play again starts a new game with the same setup; Home after the end does not ask"
    )
    func playAgainAndHome() {
        let router = AppRouter(store: InMemorySetupStore())
        router.newGame()
        router.startGame()
        let first = router.session
        router.session?.tap(Square("c3"))
        router.session?.tap(Square("d4"))
        router.session?.resign()

        router.playAgain()
        #expect(router.session !== first)
        #expect(router.session?.state == GameState())
        #expect(router.session?.setup == first?.setup)
        #expect(router.path == [.game])

        router.session?.resign()
        router.requestHome()
        #expect(router.path.isEmpty)
        #expect(router.session == nil)
    }
}
