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

    /// First-use choices until the computer opponent exists (E4): Two players, with Easy and Light
    /// ready for when Computer is chosen (spec, Clarifications).
    static let defaults = GameSetup(opponent: .twoPlayers, difficulty: .easy, side: .light)

    /// Whether a game with these choices can start: games against the computer wait for E4
    /// (FR-011).
    var canStart: Bool {
        opponent == .twoPlayers
    }
}
