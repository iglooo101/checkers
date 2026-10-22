/// How strongly the computer plays (FR-AI-02; specs/005-computer-opponent/research.md R4).
public enum ComputerLevel: Sendable, CaseIterable {
    case easy
    case medium
    case hard

    /// How this level searches (research R4): Easy looks two turns ahead and often strays from
    /// its best turn, Medium looks four turns ahead and strays a little, and Hard looks as far as
    /// its node limit allows and plays only its best turns.
    var limits: SearchLimits {
        switch self {
        case .easy: SearchLimits(maxDepth: 2, nodeLimit: nil, margin: 40)
        case .medium: SearchLimits(maxDepth: 4, nodeLimit: nil, margin: 8)
        case .hard: SearchLimits(maxDepth: 16, nodeLimit: 1_500_000, margin: 0)
        }
    }
}

/// How far and how widely the computer searches, and how far it may stray from the best turn.
struct SearchLimits: Sendable, Equatable {
    /// The deepest iteration, in complete turns.
    let maxDepth: Int
    /// The most positions one search may visit, or `nil` for no limit.
    let nodeLimit: Int?
    /// Turns scoring within this many points of the best may be chosen; a man is 100.
    let margin: Int
}
