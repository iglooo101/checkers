/// Why a side won (FR-014, FR-015).
public enum WinReason: Sendable, Hashable {
    /// The losing side had no legal move at the start of its turn, including having no pieces.
    case noMovesLeft
    /// The losing side resigned.
    case resignation
}

/// Why a game was drawn (FR-016, FR-017). There is no draw by agreement (FR-018).
public enum DrawReason: Sendable, Hashable {
    /// The same position with the same side to move occurred at the start of a turn for the
    /// third time.
    case repetition
    /// 80 consecutive turns (40 per side) passed with no capture and no man moved.
    case noProgress
}

/// Whether a game is still being played, and if not, how it ended (FR-013).
public enum Outcome: Sendable, Hashable {
    case inProgress
    case win(winner: Side, reason: WinReason)
    case draw(reason: DrawReason)
}
