import CheckersEngine
import Foundation

/// The game screen's sentences, each a whole sentence in the String Catalog so it translates as a
/// unit (Constitution V.4; contracts/screens.md).
enum GameText {
    /// The turn indicator (FR-014).
    static func turn(_ side: Side) -> LocalizedStringResource {
        switch side {
        case .light: "Light to move"
        case .dark: "Dark to move"
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
