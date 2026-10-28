import CheckersEngine
import Foundation
import Testing

@testable import checkers

/// The saved game and the record on the device (specs/006-saving-and-statistics/contracts/
/// saved-game.md, "Format" and "Stores"): the `UserDefaults` stores each on a private suite, and the
/// in-memory stores that tests and previews use, which must give the same answers.
struct StorageTests {
    /// A version 1 saved game: against the computer at Medium, the player Dark; the computer
    /// played c3–d4 and the player f6–e5.
    static let savedGameFixture = """
        {
          "version": 1,
          "setup": {"opponent": "computer", "difficulty": "medium", "side": "dark"},
          "playerSide": "dark",
          "state": {
            "position": {"light": 11775, "dark": 4289986560, "kings": 0},
            "sideToMove": "light",
            "chainSquare": null,
            "outcome": "inProgress",
            "noProgressCount": 0,
            "turns": [
              {"position": {"light": 4095, "dark": 4293918720, "kings": 0},
               "sideToMove": "light", "noProgressCount": 0},
              {"position": {"light": 11775, "dark": 4293918720, "kings": 0},
               "sideToMove": "dark", "noProgressCount": 0}
            ]
          }
        }
        """

    /// A version 1 record with games at every level.
    static let recordFixture = """
        {
          "version": 1,
          "easy": {"wins": 3, "losses": 1, "draws": 2},
          "medium": {"wins": 0, "losses": 4, "draws": 0},
          "hard": {"wins": 1, "losses": 0, "draws": 0}
        }
        """

    /// The fixture's saved game, played through the rules.
    static func savedGame() throws -> SavedGame {
        var state = GameState()
        try state.apply(Step("c3", "d4"))
        try state.apply(Step("f6", "e5"))
        return SavedGame(
            setup: GameSetup(opponent: .computer, difficulty: .medium, side: .dark),
            playerSide: .dark, state: state)
    }

    static let record = Record(
        easy: Record.Tally(wins: 3, losses: 1, draws: 2),
        medium: Record.Tally(wins: 0, losses: 4, draws: 0),
        hard: Record.Tally(wins: 1, losses: 0, draws: 0))

    /// The saved-game fixture with one change, as stored bytes.
    static func changedSavedGame(_ change: (inout [String: Any]) -> Void) throws -> Data {
        var object = try #require(
            try JSONSerialization.jsonObject(with: Data(savedGameFixture.utf8)) as? [String: Any])
        change(&object)
        return try JSONSerialization.data(withJSONObject: object)
    }

    /// Stored bytes that no saved game may be read from: not JSON, another version, a finished
    /// game, and a game the rules could not reach.
    static func unreadableSavedGames() throws -> [(String, Data)] {
        var finished = try savedGame()
        var state = finished.state
        try state.resign(.dark)
        finished = SavedGame(setup: finished.setup, playerSide: finished.playerSide, state: state)
        return [
            ("not JSON", Data("not a saved game".utf8)),
            ("version 2", try changedSavedGame { $0["version"] = 2 }),
            ("a finished game", try JSONEncoder().encode(finished)),
            (
                "an impossible game",
                try changedSavedGame {
                    var state = $0["state"] as? [String: Any] ?? [:]
                    state["noProgressCount"] = 81
                    $0["state"] = state
                }
            ),
        ]
    }

    static let unreadableRecords: [(String, Data)] = [
        ("not JSON", Data("not a record".utf8)),
        (
            "version 2",
            Data(
                recordFixture.replacingOccurrences(of: "\"version\": 1", with: "\"version\": 2")
                    .utf8)
        ),
    ]

    /// A private defaults suite for one test, removed afterwards.
    static func withDefaults(_ body: (UserDefaults) throws -> Void) rethrows {
        let name = "StorageTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        try body(defaults)
    }

    /// Checks one saved-game store, made over the given stored bytes by `make`.
    static func checkSavedGameStore(_ make: (Data?) -> any SavedGameStore) throws {
        let empty = make(nil)
        #expect(try empty.load() == nil)
        let game = try savedGame()
        empty.save(game)
        #expect(try empty.load() == game)
        var replacement = GameState()
        try replacement.apply(Step("a3", "b4"))
        let second = SavedGame(
            setup: GameSetup(opponent: .twoPlayers, difficulty: .easy, side: .light),
            playerSide: nil, state: replacement)
        empty.save(second)
        #expect(try empty.load() == second)
        empty.clear()
        #expect(try empty.load() == nil)

        for (label, data) in try unreadableSavedGames() {
            #expect(throws: SavedGameError.unreadable, "\(label)") { try make(data).load() }
        }
    }

    /// Checks one record store, made over the given stored bytes by `make`.
    static func checkRecordStore(_ make: (Data?) -> any RecordStore) throws {
        let empty = make(nil)
        #expect(try empty.load() == Record())
        empty.save(record)
        #expect(try empty.load() == record)
        for (label, data) in unreadableRecords {
            #expect(throws: RecordError.unreadable, "\(label)") { try make(data).load() }
        }
    }

    @Test("FR-SAVE-02 FR-SAVE-05: the device keeps one saved game and refuses one it cannot use")
    func userDefaultsSavedGameStore() throws {
        try Self.withDefaults { defaults in
            try Self.checkSavedGameStore { data in
                defaults.set(data, forKey: "savedGame")
                return UserDefaultsSavedGameStore(defaults: defaults)
            }
        }
    }

    @Test("FR-STAT-05 FR-STAT-06: the device keeps the record and refuses one it cannot read")
    func userDefaultsRecordStore() throws {
        try Self.withDefaults { defaults in
            try Self.checkRecordStore { data in
                defaults.set(data, forKey: "record")
                return UserDefaultsRecordStore(defaults: defaults)
            }
        }
    }

    @Test("FR-SAVE-02 FR-SAVE-05 FR-STAT-05: the in-memory stores give the same answers")
    func inMemoryStores() throws {
        try Self.checkSavedGameStore { InMemorySavedGameStore(data: $0) }
        try Self.checkRecordStore { InMemoryRecordStore(data: $0) }
    }

    @Test("FR-SAVE-03 FR-STAT-05: version 1 of the saved game and the record still reads the same")
    func formatFixtures() throws {
        let gameData = Data(Self.savedGameFixture.utf8)
        let game = try Self.savedGame()
        #expect(try InMemorySavedGameStore(data: gameData).load() == game)
        #expect(try Self.object(JSONEncoder().encode(game)) == Self.object(gameData))

        let twoPlayers = SavedGame(
            setup: GameSetup(opponent: .twoPlayers, difficulty: .easy, side: .light),
            playerSide: nil, state: GameState())
        #expect(try Self.object(JSONEncoder().encode(twoPlayers))["playerSide"] is NSNull)

        let recordData = Data(Self.recordFixture.utf8)
        #expect(try InMemoryRecordStore(data: recordData).load() == Self.record)
        #expect(try Self.object(JSONEncoder().encode(Self.record)) == Self.object(recordData))
    }

    /// A JSON value as Foundation objects, for comparing formats.
    static func object(_ data: Data) throws -> NSDictionary {
        try #require(try JSONSerialization.jsonObject(with: data) as? NSDictionary)
    }

    /// The steps `DeviceSessionUITests` plays from scripts/device-session-game.json, a position
    /// found by a throwaway search over seeded games (specs/008-release-1-0/research.md R5):
    /// Light e1–f2 (by tap), Dark e5–f4, Light c3–d4 (by drag), Dark f4–g3, Light f2–h4 (a
    /// capture), Dark b6–c5, then Light d4–b6–d8, a two-jump chain that crowns.
    static let deviceSessionSteps = [
        ("e1", "f2"), ("e5", "f4"), ("c3", "d4"), ("f4", "g3"), ("f2", "h4"), ("b6", "c5"),
        ("d4", "b6"), ("b6", "d8"),
    ]

    @Test("US2 FR-012: the device session's saved game is valid and plays its steps")
    func deviceSessionGame() throws {
        let file = URL(filePath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "scripts/device-session-game.json")
        let game = try SavedGame.decoding(Data(contentsOf: file))
        #expect(game.setup.opponent == .twoPlayers)
        #expect(game.playerSide == nil)
        var state = game.state
        #expect(state.sideToMove == .light)

        var results: [StepResult] = []
        for (from, to) in Self.deviceSessionSteps {
            results.append(try state.apply(Step(from, to)))
        }
        #expect(results.prefix(4).allSatisfy { $0.captured == nil && !$0.crowned })
        #expect(results[4].captured != nil && !results[4].turnContinues)
        #expect(results[6].captured != nil && results[6].turnContinues)
        #expect(results[7].captured != nil && results[7].crowned && !results[7].turnContinues)
        #expect(state.outcome == .inProgress)
    }
}
