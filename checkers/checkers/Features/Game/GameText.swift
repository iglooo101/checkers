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
        // Explicit returns: from a switch expression with an optional result the compiler
        // extracts only one literal into the String Catalog.
        switch outcome {
        case .inProgress: return nil
        case .win(winner: .light, reason: .noMovesLeft): return "Light wins: no moves left"
        case .win(winner: .dark, reason: .noMovesLeft): return "Dark wins: no moves left"
        case .win(winner: .dark, reason: .resignation): return "Light resigned"
        case .win(winner: .light, reason: .resignation): return "Dark resigned"
        case .draw(reason: .repetition): return "Draw by repetition"
        case .draw(reason: .noProgress): return "Draw by no progress"
        }
    }

    /// The resign confirmation's title (FR-032).
    static func resignTitle(_ side: Side) -> LocalizedStringResource {
        switch side {
        case .light: "Resign as Light?"
        case .dark: "Resign as Dark?"
        }
    }

    /// A square's VoiceOver label: its coordinate, contents and state, as one whole sentence
    /// (FR-A11Y-01; specs/004-accessibility/contracts/announcements.md).
    static func squareLabel(_ square: Square, _ piece: Piece?, _ state: SquareState)
        -> LocalizedStringResource
    {
        let name = square.name
        guard let piece else {
            return state == .legalTarget ? "\(name), empty, legal target" : "\(name), empty"
        }
        switch (piece.side, piece.kind) {
        case (.light, .man): return lightMan(name, state)
        case (.light, .king): return lightKing(name, state)
        case (.dark, .man): return darkMan(name, state)
        case (.dark, .king): return darkKing(name, state)
        }
    }

    private static func lightMan(_ name: String, _ state: SquareState) -> LocalizedStringResource {
        switch state {
        case .canMove: return "\(name), Light man, can move"
        case .selected: return "\(name), Light man, selected"
        case .none, .legalTarget: return "\(name), Light man"
        }
    }

    private static func lightKing(_ name: String, _ state: SquareState) -> LocalizedStringResource {
        switch state {
        case .canMove: return "\(name), Light king, can move"
        case .selected: return "\(name), Light king, selected"
        case .none, .legalTarget: return "\(name), Light king"
        }
    }

    private static func darkMan(_ name: String, _ state: SquareState) -> LocalizedStringResource {
        switch state {
        case .canMove: return "\(name), Dark man, can move"
        case .selected: return "\(name), Dark man, selected"
        case .none, .legalTarget: return "\(name), Dark man"
        }
    }

    private static func darkKing(_ name: String, _ state: SquareState) -> LocalizedStringResource {
        switch state {
        case .canMove: return "\(name), Dark king, can move"
        case .selected: return "\(name), Dark king, selected"
        case .none, .legalTarget: return "\(name), Dark king"
        }
    }
}
