import CheckersEngine
import Foundation
import OSLog

/// The one unfinished game the app keeps (FR-002, FR-003): the engine's state of the game, the
/// choices it was started with and the player's side (contracts/saved-game.md, "Format").
nonisolated struct SavedGame: Codable, Equatable, Sendable {
    /// The format this app writes and reads; a saved game of any other version is unreadable.
    static let currentVersion = 1

    let version: Int
    /// Opponent, difficulty and side choice of the game.
    let setup: GameSetup
    /// The player's side against the computer; `nil` in a two-player game.
    let playerSide: Side?
    /// The game, always in progress.
    let state: GameState

    private enum CodingKeys: String, CodingKey {
        case version, setup, playerSide, state
    }

    init(setup: GameSetup, playerSide: Side?, state: GameState) {
        version = Self.currentVersion
        self.setup = setup
        self.playerSide = playerSide
        self.state = state
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version, forKey: .version)
        try container.encode(setup, forKey: .setup)
        // Written as null in a two-player game, so every saved game has the same keys.
        try container.encode(playerSide, forKey: .playerSide)
        try container.encode(state, forKey: .state)
    }

    /// The saved game in stored bytes, if it is one the app can continue: it decodes (the engine
    /// checks the game), has this version and is still in progress.
    static func decoding(_ data: Data) throws(SavedGameError) -> SavedGame {
        let game: SavedGame
        do {
            game = try JSONDecoder().decode(SavedGame.self, from: data)
        } catch {
            Log.storage.error("The saved game does not decode: \(String(describing: error))")
            throw .unreadable
        }
        guard game.version == currentVersion, game.state.outcome == .inProgress else {
            Log.storage.error(
                "The saved game has version \(game.version) or is over; it cannot be continued")
            throw .unreadable
        }
        return game
    }
}

/// Why the saved game cannot be continued (contracts/saved-game.md, "Stores").
nonisolated enum SavedGameError: Error, Equatable {
    /// It does not decode, has another version, describes no valid game or a finished one.
    case unreadable
}
