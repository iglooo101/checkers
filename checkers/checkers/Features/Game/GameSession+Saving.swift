import CheckersEngine

/// Saving the game in play and recording its result
/// (specs/006-saving-and-statistics/contracts/saved-game.md).
extension GameSession {
    /// A session for a saved game, as it was left (FR-SAVE-03).
    convenience init(
        saved game: SavedGame, announcer: any Announcer = AccessibilityAnnouncer(),
        opponent: any ComputerOpponent, pacer: any TurnPacer,
        settings: AppSettings = AppSettings(store: InMemorySettingsStore())
    ) {
        self.init(
            setup: game.setup, playerSide: game.playerSide, state: game.state,
            announcer: announcer, opponent: opponent, pacer: pacer, settings: settings)
    }

    /// The game to save: the current state, or the state at the start of the computer's turn
    /// while that turn is unfinished (E5 FR-004); `nil` once the game is over (FR-END-08).
    var snapshot: SavedGame? {
        guard !isOver else { return nil }
        return SavedGame(setup: setup, playerSide: playerSide, state: computerTurnStart ?? state)
    }

    /// How the game counts in the record once it is over; `nil` while it goes on and in a
    /// two-player game (FR-STAT-02, FR-STAT-03).
    var result: GameResult? {
        GameResult(outcome: state.outcome, playerSide: playerSide, difficulty: setup.difficulty)
    }
}
