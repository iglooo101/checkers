import Foundation
import OSLog

/// Keeps the one saved game (FR-002, FR-005). Injected so tests and previews use an in-memory
/// store (Constitution II.3; contracts/saved-game.md, "Stores").
protocol SavedGameStore: AnyObject {
    /// The saved game, or `nil` when there is none; `.unreadable` when the stored one cannot be
    /// continued.
    func load() throws(SavedGameError) -> SavedGame?
    /// Replaces the saved game.
    func save(_ game: SavedGame)
    /// Removes the saved game.
    func clear()
}

/// Keeps the saved game on the device in `UserDefaults`, as one JSON value (research R2).
final class UserDefaultsSavedGameStore: SavedGameStore {
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults, key: String = "savedGame") {
        self.defaults = defaults
        self.key = key
    }

    func load() throws(SavedGameError) -> SavedGame? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try SavedGame.decoding(data)
    }

    func save(_ game: SavedGame) {
        do {
            defaults.set(try JSONEncoder().encode(game), forKey: key)
        } catch {
            Log.storage.error("Could not store the game: \(String(describing: error))")
        }
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}

/// Keeps the saved game in memory only, for tests and previews. It holds the encoded bytes, so
/// it reads them exactly as the device store does, and it can be given damaged bytes.
final class InMemorySavedGameStore: SavedGameStore {
    private var data: Data?

    init(data: Data? = nil) {
        self.data = data
    }

    convenience init(_ game: SavedGame) {
        self.init()
        save(game)
    }

    func load() throws(SavedGameError) -> SavedGame? {
        guard let data else { return nil }
        return try SavedGame.decoding(data)
    }

    func save(_ game: SavedGame) {
        do {
            data = try JSONEncoder().encode(game)
        } catch {
            Log.storage.error("Could not store the game: \(String(describing: error))")
        }
    }

    func clear() {
        data = nil
    }
}
