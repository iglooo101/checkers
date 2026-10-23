import CheckersEngine
import Foundation
import Testing

@testable import checkers

/// Saved data that cannot be read (specs/006-saving-and-statistics/spec.md, US4;
/// contracts/saved-game.md, "Launch and Continue"): the router reports each unreadable value once,
/// the saved game's first, and leaves stores that cannot report it again.
struct US4RestoreFailureTests {
    /// A router over these stores, with a computer that plays nothing unless asked.
    static func router(
        games: InMemorySavedGameStore = InMemorySavedGameStore(),
        records: InMemoryRecordStore = InMemoryRecordStore()
    ) -> AppRouter {
        AppRouter(
            store: InMemorySetupStore(), opponent: ScriptedComputerOpponent(), pacer: ManualPacer(),
            games: games, records: records)
    }

    /// Stored bytes no saved game can be continued from: the cases of SC-005 (empty, cut short,
    /// bytes that are not text, another version) and those of `StorageTests` (not JSON, a
    /// finished game, a game the rules could not reach).
    static func unreadableSavedGames() throws -> [(String, Data)] {
        let fixture = Data(StorageTests.savedGameFixture.utf8)
        let bytes = Data((0..<64).map { UInt8(truncatingIfNeeded: $0 &* 157 &+ 31) })
        return [
            ("empty", Data()),
            ("cut short", fixture.prefix(fixture.count / 2)),
            ("bytes that are not text", bytes),
        ] + (try StorageTests.unreadableSavedGames())
    }

    @Test(
        "US4 FR-SAVE-05: an unreadable saved game is cleared, reported once, and Start does not ask"
    )
    func unreadableSavedGame() throws {
        for (label, data) in try Self.unreadableSavedGames() {
            let games = InMemorySavedGameStore(data: data)
            let router = Self.router(games: games)
            #expect(!router.hasSavedGame, "\(label)")
            #expect(router.restoreNotice == .savedGame, "\(label)")
            #expect(try games.load() == nil, "\(label)")

            router.dismissRestoreNotice()
            #expect(router.restoreNotice == nil, "\(label)")

            let relaunched = Self.router(games: games)
            #expect(relaunched.restoreNotice == nil, "\(label)")
            #expect(!relaunched.hasSavedGame, "\(label)")
            relaunched.newGame()
            relaunched.setup = US1ContinueTests.twoPlayers
            relaunched.startGame()
            #expect(!relaunched.isConfirmingAbandon, "\(label)")
            #expect(relaunched.path == [.game], "\(label)")
        }
    }

    @Test(
        "US4 FR-STAT-06: an unreadable record starts again from zero, kept so, and is reported once"
    )
    func unreadableRecord() throws {
        for (label, data) in StorageTests.unreadableRecords {
            let records = InMemoryRecordStore(data: data)
            let router = Self.router(records: records)
            #expect(router.record == Record(), "\(label)")
            #expect(try records.load() == Record(), "\(label)")
            #expect(router.restoreNotice == .record, "\(label)")

            router.dismissRestoreNotice()
            #expect(router.restoreNotice == nil, "\(label)")

            let relaunched = Self.router(records: records)
            #expect(relaunched.restoreNotice == nil, "\(label)")
            #expect(relaunched.record == Record(), "\(label)")
        }
    }

    @Test("US4 FR-SAVE-05 FR-STAT-06: with both unreadable, the saved game's notice comes first")
    func bothUnreadable() {
        let router = Self.router(
            games: InMemorySavedGameStore(data: Data("not a saved game".utf8)),
            records: InMemoryRecordStore(data: Data("not a record".utf8)))
        #expect(router.restoreNotice == .savedGame)
        router.dismissRestoreNotice()
        #expect(router.restoreNotice == .record)
        router.dismissRestoreNotice()
        #expect(router.restoreNotice == nil)
        router.dismissRestoreNotice()
        #expect(router.restoreNotice == nil)
    }

    @Test("US4 FR-SAVE-05 FR-STAT-06: readable or missing data is not reported")
    func readableDataNotReported() throws {
        #expect(Self.router().restoreNotice == nil)

        let games = InMemorySavedGameStore(try StorageTests.savedGame())
        let records = InMemoryRecordStore(StorageTests.record)
        let router = Self.router(games: games, records: records)
        #expect(router.restoreNotice == nil)
        #expect(router.hasSavedGame)
        #expect(router.record == StorageTests.record)
        #expect(try games.load() == StorageTests.savedGame())
    }
}
