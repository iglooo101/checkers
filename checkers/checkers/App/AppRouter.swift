import CheckersEngine
import Observation

/// Where the player is in the app: the navigation path above Home, the game being played and the
/// setup choices (contract: Navigation). Keeping the game here, not in a view, lets it survive the
/// screens opened on top of it (FR-005).
@Observable
final class AppRouter {
    var path: [Route] = []
    private(set) var session: GameSession?
    /// The setup choices; every change is remembered at once (FR-009, research R7).
    var setup: GameSetup {
        didSet { store.save(setup) }
    }

    /// Whether the leave confirmation is showing (FR-042).
    var isConfirmingLeave = false

    @ObservationIgnored private let store: any SetupStore
    /// Draws the player's side when the setup says Random (FR-034).
    @ObservationIgnored private let drawSide: () -> Side

    init(store: any SetupStore, drawSide: @escaping () -> Side = { Bool.random() ? .light : .dark })
    {
        self.store = store
        self.drawSide = drawSide
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
        open(gameWith: setup)
    }

    /// Opens a new game with these choices, in place of setup or of the current game.
    func open(gameWith setup: GameSetup) {
        session = GameSession(setup: setup, playerSide: playerSide(for: setup))
        if path.last == .setup {
            path.removeLast()
        }
        if path.last != .game {
            path.append(.game)
        }
    }

    /// Starts a new game with the finished game's setup, drawing a Random side again (FR-034).
    func playAgain() {
        guard let session else { return }
        open(gameWith: session.setup)
    }

    /// The player's side against the computer; `nil` in a two-player game.
    private func playerSide(for setup: GameSetup) -> Side? {
        guard setup.opponent == .computer else { return nil }
        switch setup.side {
        case .light: return .light
        case .dark: return .dark
        case .random: return drawSide()
        }
    }

    /// Returns Home. A finished game, or no game, is left at once; a game in progress asks first,
    /// because it cannot be resumed until saving exists (FR-042).
    func requestHome() {
        if let session, !session.isOver {
            isConfirmingLeave = true
        } else {
            leave()
        }
    }

    /// Leaves the game in progress for Home, discarding it.
    func confirmLeave() {
        leave()
    }

    /// Stays in the game.
    func cancelLeave() {
        isConfirmingLeave = false
    }

    private func leave() {
        isConfirmingLeave = false
        path.removeAll()
        session = nil
    }

    /// Opens a screen on top of the current one.
    func open(_ route: Route) {
        path.append(route)
    }
}
