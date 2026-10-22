import CheckersEngine

/// Who the player plays against (FR-SETUP-01).
nonisolated enum Opponent: String, Codable, CaseIterable, Sendable {
    case computer
    case twoPlayers
}

/// How strongly the computer plays (FR-SETUP-02).
nonisolated enum Difficulty: String, Codable, CaseIterable, Sendable {
    case easy
    case medium
    case hard
}

extension Difficulty {
    /// The engine's level for this difficulty (specs/005-computer-opponent/research.md R4).
    nonisolated var computerLevel: ComputerLevel {
        switch self {
        case .easy: .easy
        case .medium: .medium
        case .hard: .hard
        }
    }
}

/// The side the player takes against the computer; Random is drawn when a game starts
/// (FR-SETUP-02, FR-END-07).
nonisolated enum SideChoice: String, Codable, CaseIterable, Sendable {
    case light
    case dark
    case random
}

/// The choices made in Game setup. Difficulty and side apply only against the computer; they are
/// kept while Two players is chosen.
nonisolated struct GameSetup: Codable, Equatable, Sendable {
    var opponent: Opponent
    var difficulty: Difficulty
    var side: SideChoice

    /// First-use choices: Computer, Easy and Light (FR-SETUP-03).
    static let defaults = GameSetup(opponent: .computer, difficulty: .easy, side: .light)
}
