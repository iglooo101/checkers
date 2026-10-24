import CheckersEngine
import OSLog
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

    /// Whether a saved game exists, so Home offers Continue (FR-NAV-02).
    private(set) var hasSavedGame = false
    /// Whether Start is asking "Abandon current game?" (FR-SETUP-04).
    private(set) var isConfirmingAbandon = false
    /// The player's results against the computer, which Statistics shows (FR-STAT-01).
    private(set) var record = Record()
    /// The player's settings, shared with every game this router shows (FR-003; specs/
    /// 007-settings-themes-sound-and-rules/research.md R2).
    let settings: AppSettings
    /// The restore alert Home shows, if any: the saved game's first, then the record's
    /// (FR-SAVE-05, FR-STAT-06).
    var restoreNotice: RestoreNotice? { restoreNotices.first }
    /// The stored values found unreadable at launch, not yet reported.
    private var restoreNotices: [RestoreNotice] = []

    @ObservationIgnored private let store: any SetupStore
    /// Draws the player's side when the setup says Random (FR-034).
    @ObservationIgnored private let drawSide: () -> Side
    /// Chooses the computer's turns in the games this router starts.
    @ObservationIgnored private let opponent: any ComputerOpponent
    /// Paces the computer's turns in the games this router starts.
    @ObservationIgnored private let pacer: any TurnPacer
    /// Keeps the game in play (specs/006-saving-and-statistics/contracts/saved-game.md).
    @ObservationIgnored private let games: any SavedGameStore
    /// Keeps the record of games against the computer.
    @ObservationIgnored private let records: any RecordStore

    /// The stores default to in-memory ones, so previews and tests never touch the device's
    /// storage (workflow gate 4); the app passes the `UserDefaults` stores.
    init(
        store: any SetupStore, drawSide: @escaping () -> Side = { Bool.random() ? .light : .dark },
        opponent: any ComputerOpponent = EngineComputerOpponent(),
        pacer: any TurnPacer = SleepingPacer(),
        games: any SavedGameStore = InMemorySavedGameStore(),
        records: any RecordStore = InMemoryRecordStore(),
        settingsStore: any SettingsStore = InMemorySettingsStore()
    ) {
        self.store = store
        self.drawSide = drawSide
        self.opponent = opponent
        self.pacer = pacer
        self.games = games
        self.records = records
        settings = AppSettings(store: settingsStore)
        setup = store.load()
        do {
            hasSavedGame = try games.load() != nil
        } catch {
            // The store has logged why. The save is discarded, so Home offers no Continue and
            // reports it only this once (FR-SAVE-05).
            Log.storage.error("Discarding the saved game, which cannot be continued")
            games.clear()
            hasSavedGame = false
            restoreNotices.append(.savedGame)
        }
        do {
            record = try records.load()
        } catch {
            // The store has logged why. The record starts again from zero and is stored so, which
            // Home reports only this once (FR-STAT-06).
            Log.storage.error("Starting the record again from zero, as it cannot be read")
            record = Record()
            records.save(record)
            restoreNotices.append(.record)
        }
    }

    /// Closes the restore alert; the next one, if any, follows.
    func dismissRestoreNotice() {
        guard !restoreNotices.isEmpty else { return }
        restoreNotices.removeFirst()
    }

    /// Opens Game setup with the remembered choices (FR-007, FR-009).
    func newGame() {
        setup = store.load()
        path.append(.setup)
    }

    /// Starts a game with the current choices, replacing setup in the path, and remembers them
    /// (FR-SETUP-03). With a saved game it asks first, starting nothing (FR-SETUP-04).
    func startGame() {
        guard !hasSavedGame else {
            isConfirmingAbandon = true
            return
        }
        store.save(setup)
        open(gameWith: setup)
    }

    /// Discards the saved game and starts the new one; the record is unchanged (FR-SETUP-04,
    /// FR-SETUP-05).
    func confirmAbandon() {
        isConfirmingAbandon = false
        clearSavedGame()
        startGame()
    }

    /// Keeps the saved game and the setup screen with its choices.
    func cancelAbandon() {
        isConfirmingAbandon = false
    }

    /// Opens a new game with these choices, in place of setup or of the current game. The computer
    /// moves first when it plays Light (FR-AI-06).
    func open(gameWith setup: GameSetup) {
        show(
            GameSession(
                setup: setup, playerSide: playerSide(for: setup), opponent: opponent, pacer: pacer))
    }

    /// Opens the saved game as it was left (FR-SAVE-03); the computer moves if it is its turn
    /// (FR-SAVE-04). The setup choices stay as they are (FR-SETUP-03).
    func continueGame() {
        let saved: SavedGame?
        do {
            saved = try games.load()
        } catch {
            // The store has logged why; there is nothing to continue.
            saved = nil
        }
        guard let saved else {
            hasSavedGame = false
            return
        }
        show(GameSession(saved: saved, opponent: opponent, pacer: pacer))
    }

    /// Shows a game in place of setup or of the current game, saving it at its save points, and
    /// starts the computer's turn if it is the computer's to move.
    private func show(_ game: GameSession) {
        session?.cancelComputerTurn()
        game.onEvent = { [weak self, weak game] event in
            guard let self, let game else { return }
            switch event {
            case .saved: save(game)
            case .ended: finish(game)
            }
        }
        session = game
        if path.last == .setup {
            path.removeLast()
        }
        if path.last != .game {
            path.append(.game)
        }
        game.startComputerTurnIfNeeded()
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

    /// Returns Home at once; a game in progress stays the saved game (FR-NAV-03). It is saved
    /// before the computer's turn is cancelled, so that turn is kept from its start.
    func requestHome() {
        saveNow()
        path.removeAll()
        session?.cancelComputerTurn()
        session = nil
    }

    /// Saves the game on screen, if any; the app calls it when it moves to the background
    /// (FR-SAVE-01).
    func saveNow() {
        guard let session else { return }
        save(session)
    }

    /// Keeps a game in progress as the saved game, replacing the previous one, and clears the
    /// saved game once the game is over (FR-SAVE-02, FR-END-08).
    private func save(_ game: GameSession) {
        guard let snapshot = game.snapshot else {
            clearSavedGame()
            return
        }
        games.save(snapshot)
        hasSavedGame = true
    }

    /// A game has ended: it is no longer the saved game, and a game against the computer counts
    /// once in the record (FR-END-08, FR-STAT-02). The session reports the end once, so undo,
    /// leaving and Continue cannot count a game twice (FR-UNDO-08).
    private func finish(_ game: GameSession) {
        clearSavedGame()
        guard let result = game.result else { return }
        record = record.adding(result)
        records.save(record)
    }

    /// No game is saved any more: it ended or was abandoned (FR-END-08, FR-SETUP-04).
    private func clearSavedGame() {
        games.clear()
        hasSavedGame = false
    }

    /// Opens a screen on top of the current one.
    func open(_ route: Route) {
        path.append(route)
    }
}
