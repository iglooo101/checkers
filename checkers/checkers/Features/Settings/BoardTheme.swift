import Foundation

/// How the board looks: its squares, frame, pieces and marks (FR-008, FR-009;
/// specs/007-settings-themes-sound-and-rules/data-model.md). Stored by its raw value.
nonisolated enum BoardTheme: String, CaseIterable, Sendable {
    case classic
    case modern
    case playful

    /// The name Settings shows (FR-SET-02).
    var name: LocalizedStringResource {
        switch self {
        case .classic: return "Classic"
        case .modern: return "Modern"
        case .playful: return "Playful"
        }
    }
}
