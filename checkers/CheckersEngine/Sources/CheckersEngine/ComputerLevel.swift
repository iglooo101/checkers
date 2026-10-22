/// How strongly the computer plays (FR-AI-02; specs/005-computer-opponent/research.md R4).
public enum ComputerLevel: Sendable, CaseIterable {
    case easy
    case medium
    case hard

    /// How this level searches. Until the levels are tuned apart, every level looks four turns
    /// ahead and plays its best turn.
    var limits: SearchLimits {
        SearchLimits(maxDepth: 4, nodeLimit: nil, margin: 0)
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
