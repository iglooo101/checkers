import Foundation
import OSLog

/// Remembers the last Game setup choices (FR-009). Injected so tests and previews use an in-memory
/// store (Constitution II.3).
protocol SetupStore: AnyObject {
    /// The stored choices, or the defaults when nothing usable is stored.
    func load() -> GameSetup
    /// Replaces the stored choices.
    func save(_ setup: GameSetup)
}

/// Keeps the choices on the device in `UserDefaults`, as one JSON value (research R7).
final class UserDefaultsSetupStore: SetupStore {
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults, key: String = "lastGameSetup") {
        self.defaults = defaults
        self.key = key
    }

    func load() -> GameSetup {
        guard let data = defaults.data(forKey: key) else { return .defaults }
        do {
            return try JSONDecoder().decode(GameSetup.self, from: data)
        } catch {
            Log.setup.error(
                "Stored setup is unreadable; using the defaults: \(String(describing: error))")
            return .defaults
        }
    }

    func save(_ setup: GameSetup) {
        do {
            defaults.set(try JSONEncoder().encode(setup), forKey: key)
        } catch {
            Log.setup.error("Could not store the setup: \(String(describing: error))")
        }
    }
}

/// Keeps the choices in memory only, for tests and previews.
final class InMemorySetupStore: SetupStore {
    private var setup: GameSetup

    init(_ setup: GameSetup = .defaults) {
        self.setup = setup
    }

    func load() -> GameSetup {
        setup
    }

    func save(_ setup: GameSetup) {
        self.setup = setup
    }
}
