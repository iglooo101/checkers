/// Remembers the last Game setup choices (FR-009). Injected so tests and previews use an in-memory
/// store (Constitution II.3).
protocol SetupStore: AnyObject {
    /// The stored choices, or the defaults when nothing usable is stored.
    func load() -> GameSetup
    /// Replaces the stored choices.
    func save(_ setup: GameSetup)
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
