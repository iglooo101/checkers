/// How strongly the computer plays (FR-AI-02; specs/005-computer-opponent/research.md R4).
public enum ComputerLevel: Sendable, CaseIterable {
    case easy
    case medium
    case hard

    /// How this level searches (research R4; FRD 1.3.4): Easy looks 1 turn ahead, Medium 2 and
    /// Hard 3, each also seeing the captures that follow. Easy may play a turn up to a man and a
    /// half below its best, so now and then it gives a man away but never two; Medium strays less
    /// than half a man; Hard plays only its best turns, and its node limit only guards against a
    /// position whose captures run on.
    var limits: SearchLimits {
        switch self {
        case .easy: SearchLimits(maxDepth: 1, nodeLimit: nil, margin: 150)
        case .medium: SearchLimits(maxDepth: 2, nodeLimit: nil, margin: 40)
        case .hard: SearchLimits(maxDepth: 3, nodeLimit: 1_500_000, margin: 0)
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
