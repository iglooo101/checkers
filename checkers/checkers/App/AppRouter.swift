import Observation

/// Where the player is in the app: the navigation path above Home, the game being played and the
/// setup choices (contract: Navigation). Keeping the game here, not in a view, lets it survive the
/// screens opened on top of it (FR-005).
@Observable
final class AppRouter {
    var path: [Route] = []
    private(set) var session: GameSession?
    var setup: GameSetup

    @ObservationIgnored private let store: any SetupStore

    init(store: any SetupStore) {
        self.store = store
        setup = store.load()
    }

    /// Opens Game setup with the remembered choices (FR-007, FR-009).
    func newGame() {
        setup = store.load()
        path.append(.setup)
    }

    /// Starts a game with the current choices, replacing setup in the path; games against the
    /// computer cannot start yet (FR-011).
    func startGame() {
        guard setup.canStart else { return }
        session = GameSession(setup: setup)
        if path.last == .setup {
            path.removeLast()
        }
        path.append(.game)
    }

    /// Starts a new game with the finished game's setup (FR-034).
    func playAgain() {
        guard let session else { return }
        self.session = GameSession(setup: session.setup, playerSide: session.playerSide)
    }

    /// Returns Home. A finished game, or no game, is left at once.
    func requestHome() {
        guard session?.isOver ?? true else { return }
        path.removeAll()
        session = nil
    }

    /// Opens a screen on top of the current one.
    func open(_ route: Route) {
        path.append(route)
    }
}
