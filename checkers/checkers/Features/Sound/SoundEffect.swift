import CheckersEngine

/// One of the game's four sounds (FR-014; specs/007-settings-themes-sound-and-rules/contracts/
/// settings-and-sound.md, "Which sound").
nonisolated enum SoundEffect: String, CaseIterable, Sendable {
    case move
    case capture
    case crowning
    case gameEnd

    /// The sound's file in the app bundle, such as `gameEnd.wav`.
    var fileName: String {
        "\(rawValue).wav"
    }

    /// The one sound a step plays, the most important that applies: the end of the game, then
    /// crowning, then capture, then a plain move (FR-014).
    static func of(_ result: StepResult) -> SoundEffect {
        if result.outcome != .inProgress { return .gameEnd }
        if result.crowned { return .crowning }
        if result.captured != nil { return .capture }
        return .move
    }
}
