import CheckersEngine
import Foundation
import Testing

@testable import checkers

/// The record against the computer (specs/006-saving-and-statistics/spec.md, US3;
/// contracts/saved-game.md, "Recording"; contracts/screens.md, "Statistics").
struct US3RecordTests {
    typealias Routed = US1ContinueTests.Routed

    /// Light, to move, captures Dark's last piece with c3–e5.
    static let lastCapture = GameState(["c3": .lightMan, "d4": .darkMan], toMove: .light)

    /// Light, to move, can only play c3–d4 or c3–b4; after Dark's f6–e5, Light's d4–f6 captures
    /// Dark's last piece.
    static let beforeAWin = GameState(["c3": .lightMan, "f6": .darkMan], toMove: .light)

    /// The state after these steps of a game played by the rules.
    static func played(_ steps: [Step], from start: GameState) throws -> GameState {
        var state = start
        for step in steps {
            try state.apply(step)
        }
        return state
    }

    /// Dark to move, whose king's last step makes the third occurrence of a position.
    static func beforeRepetition() throws -> (state: GameState, step: Step) {
        let shuffle = US4GameEndTests.shuffle
        let start = GameState(["h2": .lightKing, "a7": .darkKing], toMove: .light)
        return (try played(Array(shuffle.dropLast()), from: start), try #require(shuffle.last))
    }

    /// Dark to move after 79 turns without a capture or a man's move; Dark's step is the 80th.
    static func beforeNoProgress() throws -> (state: GameState, step: Step) {
        let tour = US4GameEndTests.tour(turns: 80)
        let start = GameState(["b2": .lightKing, "e7": .darkKing], toMove: .light)
        return (try played(Array(tour.dropLast()), from: start), try #require(tour.last))
    }

    /// A record holding one result of this kind at this difficulty, built without
    /// `Record.adding(_:)`.
    static func record(one kind: GameResult.Kind, at difficulty: Difficulty) -> Record {
        var tally = Record.Tally()
        switch kind {
        case .win: tally.wins = 1
        case .loss: tally.losses = 1
        case .draw: tally.draws = 1
        }
        switch difficulty {
        case .easy: return Record(easy: tally)
        case .medium: return Record(medium: tally)
        case .hard: return Record(hard: tally)
        }
    }

    /// Checks that the router shows, and the store holds, exactly one result of this kind at this
    /// difficulty.
    static func expectRecorded(
        _ game: Routed, _ kind: GameResult.Kind, at difficulty: Difficulty,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws {
        let expected = record(one: kind, at: difficulty)
        #expect(game.router.record == expected, sourceLocation: sourceLocation)
        #expect(try game.records.load() == expected, sourceLocation: sourceLocation)
    }

    @Test(
        "US3 FR-STAT-02: every ending of a game against the computer counts once, at its difficulty",
        arguments: Difficulty.allCases)
    func endingsCount(_ difficulty: Difficulty) async throws {
        let light = GameSetup(opponent: .computer, difficulty: difficulty, side: .light)
        let dark = GameSetup(opponent: .computer, difficulty: difficulty, side: .dark)

        // The computer's side is left without a move: a win.
        let won = Routed(
            saved: SavedGame(setup: light, playerSide: .light, state: Self.lastCapture))
        won.router.continueGame()
        try won.play([Step("c3", "e5")])
        try Self.expectRecorded(won, .win, at: difficulty)

        // The player's side is left without a move: a loss.
        let lost = Routed(
            saved: SavedGame(setup: dark, playerSide: .dark, state: Self.lastCapture),
            turns: [[Step("c3", "e5")]])
        lost.router.continueGame()
        await lost.resumePause()
        let session = try lost.session
        await waitUntil { session.isOver }
        try Self.expectRecorded(lost, .loss, at: difficulty)

        // The player resigns: a loss.
        let resigned = Routed()
        resigned.start(light)
        try resigned.session.resign()
        try Self.expectRecorded(resigned, .loss, at: difficulty)

        // A draw by repetition or by no progress: a draw.
        for (before, reason) in [
            (try Self.beforeRepetition(), DrawReason.repetition),
            (try Self.beforeNoProgress(), DrawReason.noProgress),
        ] {
            let drawn = Routed(
                saved: SavedGame(setup: dark, playerSide: .dark, state: before.state))
            drawn.router.continueGame()
            try drawn.play([before.step])
            #expect(try drawn.session.state.outcome == .draw(reason: reason))
            try Self.expectRecorded(drawn, .draw, at: difficulty)
        }
    }

    @Test("US3 FR-STAT-03 FR-SETUP-05: two-player, abandoned and unfinished games count nowhere")
    func uncountedGames() throws {
        let twoPlayers = Routed(
            saved: SavedGame(
                setup: US1ContinueTests.twoPlayers, playerSide: nil, state: Self.lastCapture))
        twoPlayers.router.continueGame()
        try twoPlayers.play([Step("c3", "e5")])
        #expect(try twoPlayers.session.isOver)
        #expect(twoPlayers.router.record == Record())
        #expect(try twoPlayers.records.load() == Record())

        let abandoned = Routed(
            saved: SavedGame(
                setup: US1ContinueTests.computerLight, playerSide: .light, state: Self.lastCapture))
        abandoned.start(US1ContinueTests.computerLight)
        abandoned.router.confirmAbandon()
        #expect(abandoned.router.record == Record())
        #expect(try abandoned.records.load() == Record())

        let left = Routed()
        left.start(US1ContinueTests.computerLight)
        try left.play([Step("c3", "d4")])
        left.router.requestHome()
        #expect(left.router.record == Record())
        #expect(try left.records.load() == Record())
    }

    @Test(
        "US3 FR-UNDO-08: a game counts once, by its final result, after undos or after leaving and continuing"
    )
    func countsOnce() async throws {
        let medium = GameSetup(opponent: .computer, difficulty: .medium, side: .light)
        let undone = Routed(
            saved: SavedGame(setup: medium, playerSide: .light, state: Self.beforeAWin),
            turns: [[Step("f6", "e5")], [Step("f6", "e5")]])
        undone.router.continueGame()
        let session = try undone.session
        try undone.play([Step("c3", "d4")])
        await undone.resumePause()
        await waitUntil { !session.isComputerTurn }
        session.undo()
        #expect(session.state == Self.beforeAWin)
        #expect(undone.router.record == Record())
        try undone.play([Step("c3", "d4")])
        await undone.resumePause()
        await waitUntil { !session.isComputerTurn }
        try undone.play([Step("d4", "f6")])
        #expect(session.state.outcome == .win(winner: .light, reason: .noMovesLeft))
        try Self.expectRecorded(undone, .win, at: .medium)

        let hard = GameSetup(opponent: .computer, difficulty: .hard, side: .light)
        let continued = Routed(
            saved: SavedGame(setup: hard, playerSide: .light, state: Self.beforeAWin),
            turns: [[Step("f6", "e5")]])
        continued.router.continueGame()
        let first = try continued.session
        try continued.play([Step("c3", "d4")])
        await continued.resumePause()
        await waitUntil { !first.isComputerTurn }
        continued.router.requestHome()
        #expect(continued.router.record == Record())
        continued.router.continueGame()
        try continued.play([Step("d4", "f6")])
        try Self.expectRecorded(continued, .win, at: .hard)
    }

    @Test(
        "US3 FR-STAT-01: a result for each outcome from the player's view, none for two-player or unfinished games"
    )
    func results() {
        #expect(
            GameResult(
                outcome: .win(winner: .light, reason: .noMovesLeft), playerSide: .light,
                difficulty: .easy) == GameResult(difficulty: .easy, kind: .win))
        #expect(
            GameResult(
                outcome: .win(winner: .dark, reason: .noMovesLeft), playerSide: .light,
                difficulty: .medium) == GameResult(difficulty: .medium, kind: .loss))
        #expect(
            GameResult(
                outcome: .win(winner: .light, reason: .resignation), playerSide: .dark,
                difficulty: .hard) == GameResult(difficulty: .hard, kind: .loss))
        #expect(
            GameResult(outcome: .draw(reason: .repetition), playerSide: .dark, difficulty: .easy)
                == GameResult(difficulty: .easy, kind: .draw))
        #expect(
            GameResult(outcome: .draw(reason: .noProgress), playerSide: .light, difficulty: .hard)
                == GameResult(difficulty: .hard, kind: .draw))
        #expect(GameResult(outcome: .inProgress, playerSide: .light, difficulty: .easy) == nil)
        #expect(
            GameResult(
                outcome: .win(winner: .light, reason: .noMovesLeft), playerSide: nil,
                difficulty: .easy) == nil)

        let twoPlayers = GameSession(setup: US1ContinueTests.twoPlayers, state: Self.lastCapture)
        twoPlayers.tap(Square("c3"))
        twoPlayers.tap(Square("e5"))
        #expect(twoPlayers.isOver)
        #expect(twoPlayers.result == nil)

        let hard = GameSetup(opponent: .computer, difficulty: .hard, side: .light)
        let computer = GameSession(setup: hard, playerSide: .light, state: Self.lastCapture)
        #expect(computer.result == nil)
        computer.tap(Square("c3"))
        computer.tap(Square("e5"))
        #expect(computer.result == GameResult(difficulty: .hard, kind: .win))
    }

    @Test("US3 FR-STAT-01: the record adds each result in its place; empty until the first")
    func recordAdding() {
        #expect(Record().isEmpty)
        let one = Record().adding(GameResult(difficulty: .medium, kind: .loss))
        #expect(one == Record(medium: Record.Tally(losses: 1)))
        #expect(!one.isEmpty)
        let more =
            one
            .adding(GameResult(difficulty: .easy, kind: .win))
            .adding(GameResult(difficulty: .hard, kind: .draw))
            .adding(GameResult(difficulty: .hard, kind: .draw))
        #expect(
            more
                == Record(
                    easy: Record.Tally(wins: 1), medium: Record.Tally(losses: 1),
                    hard: Record.Tally(draws: 2)))
    }

    @Test(
        "US3 FR-STAT-04: counts read with their plurals, a block as one sentence, and the empty state"
    )
    func statisticsText() {
        #expect(String(localized: StatisticsText.wins(3)) == "3 wins")
        #expect(String(localized: StatisticsText.wins(1)) == "1 win")
        #expect(String(localized: StatisticsText.losses(0)) == "0 losses")
        #expect(String(localized: StatisticsText.losses(1)) == "1 loss")
        #expect(String(localized: StatisticsText.draws(2)) == "2 draws")
        #expect(String(localized: StatisticsText.draws(1)) == "1 draw")
        #expect(String(localized: StatisticsText.name(.medium)) == "Medium")
        #expect(
            String(
                localized: StatisticsText.label(
                    Record.Tally(wins: 3, losses: 1, draws: 2), at: .easy))
                == "Easy: 3 wins, 1 loss, 2 draws")
        #expect(StatisticsText.emptyTitle.key == "No games yet.")
        #expect(
            StatisticsText.emptyMessage.key
                == "Finish a game against the computer to start your record.")
    }

    @Test("US3 FR-STAT-05: the router shows the stored record and saves each recorded game back")
    func storedRecord() throws {
        let stored = Record(
            easy: Record.Tally(wins: 3, losses: 1, draws: 2), hard: Record.Tally(wins: 1))
        let game = Routed(records: InMemoryRecordStore(stored))
        #expect(game.router.record == stored)

        game.start(US1ContinueTests.computerLight)
        try game.session.resign()
        let expected = Record(
            easy: Record.Tally(wins: 3, losses: 2, draws: 2), hard: Record.Tally(wins: 1))
        #expect(game.router.record == expected)
        #expect(try game.records.load() == expected)
    }
}
