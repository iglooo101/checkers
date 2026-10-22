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

    /// The turn indicator while the computer takes its turn (FR-AI-03;
    /// specs/005-computer-opponent/contracts/computer-turn.md).
    static func thinking(_ side: Side) -> LocalizedStringResource {
        switch side {
        case .light: "Light is thinking…"
        case .dark: "Dark is thinking…"
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

    /// What a step did, for its announcement (FR-A11Y-03; contract: What happened).
    static func stepSentence(_ result: StepResult) -> LocalizedStringResource {
        let from = result.from.name
        let to = result.to.name
        switch (result.side, result.captured?.name, result.crowned) {
        case (.light, nil, false): return "Light \(from) to \(to)."
        case (.light, nil, true): return "Light \(from) to \(to), crowned."
        case (.light, let captured?, false): return "Light captures \(captured)."
        case (.light, let captured?, true): return "Light captures \(captured), crowned on \(to)."
        case (.dark, nil, false): return "Dark \(from) to \(to)."
        case (.dark, nil, true): return "Dark \(from) to \(to), crowned."
        case (.dark, let captured?, false): return "Dark captures \(captured)."
        case (.dark, let captured?, true): return "Dark captures \(captured), crowned on \(to)."
        }
    }

    /// What follows a step, for its announcement: jump again, the result, or the next turn
    /// (contract: What follows).
    static func followUp(after step: StepResult, in state: GameState) -> LocalizedStringResource {
        if step.turnContinues { return "Jump again." }
        if let ending = result(step.outcome) { return ending }
        return spokenTurn(state.sideToMove, captureRequired: state.isCaptureRequired)
    }

    /// The announcement after an undo (contract: When to announce).
    static func undone(_ side: Side, captureRequired: Bool) -> LocalizedStringResource {
        joined("Move undone.", spokenTurn(side, captureRequired: captureRequired))
    }

    /// Two whole sentences spoken as one announcement, through a localizable template
    /// (research R4).
    static func joined(_ first: LocalizedStringResource, _ second: LocalizedStringResource)
        -> LocalizedStringResource
    {
        "\(first) \(second)"
    }

    /// The turn as a spoken sentence, ending with a period.
    private static func spokenTurn(_ side: Side, captureRequired: Bool) -> LocalizedStringResource {
        switch (side, captureRequired) {
        case (.light, false): return "Light to move."
        case (.dark, false): return "Dark to move."
        case (.light, true): return "Light to move, capture required."
        case (.dark, true): return "Dark to move, capture required."
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
