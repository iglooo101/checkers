import CheckersEngine
import Foundation

/// The game screen's sentences, each a whole sentence in the String Catalog so it translates as a
/// unit (Constitution V.4; contracts/screens.md).
enum GameText {
    /// The turn indicator, saying when a capture is required (FR-014).
    static func turn(_ side: Side, captureRequired: Bool = false) -> LocalizedStringResource {
        switch (side, captureRequired) {
        case (.light, false): "Light to move"
        case (.dark, false): "Dark to move"
        case (.light, true): "Light to move · capture required"
        case (.dark, true): "Dark to move · capture required"
        }
    }

    /// A notice shown under the turn indicator (FR-023).
    static func notice(_ notice: Notice) -> LocalizedStringResource {
        switch notice {
        case .captureRequired: "A capture is required."
        }
    }

    /// A square's VoiceOver label: its coordinate and contents (FR-040).
    static func squareLabel(_ square: Square, _ piece: Piece?) -> LocalizedStringResource {
        let name = square.name
        guard let piece else { return "\(name), empty" }
        switch (piece.side, piece.kind) {
        case (.light, .man): return "\(name), Light man"
        case (.light, .king): return "\(name), Light king"
        case (.dark, .man): return "\(name), Dark man"
        case (.dark, .king): return "\(name), Dark king"
        }
    }
}
