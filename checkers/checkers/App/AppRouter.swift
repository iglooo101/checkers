import CheckersEngine
import Observation

/// Where the player is in the app: the navigation path above Home, the game being played and the
/// setup choices (contract: Navigation). Keeping the game here, not in a view, lets it survive the
/// screens opened on top of it (FR-005).
@Observable
final class AppRouter {
    /// The screens above Home. While Rules or Settings covers the game, the computer's next step
    /// waits (FR-NAV-04).
    var path: [Route] = [] {
        didSet { session?.setCovered(path.last != .game) }
    }
    private(set) var session: GameSession?
    /// The setup choices, remembered when a game starts (FR-SETUP-03;
    /// specs/005-computer-opponent/research.md R11).
    var setup: GameSetup

    /// Whether the leave confirmation is showing (FR-042).
    var isConfirmingLeave = false

    @ObservationIgnored private let store: any SetupStore
    /// Draws the player's side when the setup says Random (FR-034).
    @ObservationIgnored private let drawSide: () -> Side
    /// Chooses the computer's turns in the games this router starts.
    @ObservationIgnored private let opponent: any ComputerOpponent
    /// Paces the computer's turns in the games this router starts.
    @ObservationIgnored private let pacer: any TurnPacer

    init(
        store: any SetupStore, drawSide: @escaping () -> Side = { Bool.random() ? .light : .dark },
        opponent: any ComputerOpponent = EngineComputerOpponent(),
        pacer: any TurnPacer = SleepingPacer()
    ) {
        self.store = store
        self.drawSide = drawSide
        self.opponent = opponent
        self.pacer = pacer
        setup = store.load()
    }

    /// Opens Game setup with the remembered choices (FR-007, FR-009).
    func newGame() {
        setup = store.load()
        path.append(.setup)
    }

    /// Starts a game with the current choices, replacing setup in the path, and remembers them
    /// (FR-SETUP-03).
    func startGame() {
        store.save(setup)
        open(gameWith: setup)
    }

    /// Opens a new game with these choices, in place of setup or of the current game. The computer
    /// moves first when it plays Light (FR-AI-06).
    func open(gameWith setup: GameSetup) {
        session?.cancelComputerTurn()
        session = GameSession(
            setup: setup, playerSide: playerSide(for: setup), opponent: opponent, pacer: pacer)
        if path.last == .setup {
            path.removeLast()
        }
        if path.last != .game {
            path.append(.game)
        }
        session?.startComputerTurnIfNeeded()
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
        session?.cancelComputerTurn()
        session = nil
    }

    /// Opens a screen on top of the current one.
    func open(_ route: Route) {
        path.append(route)
    }
}
