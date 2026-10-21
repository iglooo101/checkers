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

    /// The result panel's sentence once the game is over (FR-033). A resignation names the side
    /// that resigned: the winner's opponent.
    static func result(_ outcome: Outcome) -> LocalizedStringResource? {
        switch outcome {
        case .inProgress: nil
        case .win(winner: .light, reason: .noMovesLeft): "Light wins: no moves left"
        case .win(winner: .dark, reason: .noMovesLeft): "Dark wins: no moves left"
        case .win(winner: .dark, reason: .resignation): "Light resigned"
        case .win(winner: .light, reason: .resignation): "Dark resigned"
        case .draw(reason: .repetition): "Draw by repetition"
        case .draw(reason: .noProgress): "Draw by no progress"
        }
    }

    /// The resign confirmation's title (FR-032).
    static func resignTitle(_ side: Side) -> LocalizedStringResource {
        switch side {
        case .light: "Resign as Light?"
        case .dark: "Resign as Dark?"
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
