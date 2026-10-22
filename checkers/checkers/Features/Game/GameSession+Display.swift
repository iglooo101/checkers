import CheckersEngine
import Foundation

/// What the game screen shows for a session, derived from its state: the board's orientation,
/// hints and targets, the turn indicator, the result, and each square's VoiceOver label
/// (specs/003-game-experience/contracts/game-session.md).
extension GameSession {
    /// Light at the bottom in a two-player game; the player's side against the computer (FR-015).
    var layout: BoardLayout {
        BoardLayout(bottomSide: playerSide ?? .light)
    }

    /// The pieces the board highlights: every movable piece of the side to move, which the
    /// engine limits to capturing pieces when a capture is required (FR-025). Hints are always on
    /// until Settings (E6) adds the switch.
    var hintedPieces: Set<Square> {
        isComputerTurn ? [] : Set(state.movablePieces)
    }

    /// The selected piece's legal target squares (FR-026, FR-030).
    var targets: Set<Square> {
        guard let selection else { return [] }
        return Set(state.targets(from: selection))
    }

    /// The result panel's sentence, once the game is over (FR-033).
    var resultText: LocalizedStringResource? {
        GameText.result(state.outcome)
    }

    /// The turn indicator's sentence (FR-014), or that the computer is thinking (FR-AI-03).
    var turnText: LocalizedStringResource {
        if isComputerTurn, let computerSide {
            return GameText.thinking(computerSide)
        }
        return GameText.turn(state.sideToMove, captureRequired: state.isCaptureRequired)
    }

    /// What a square can do, for VoiceOver: whatever the hints setting, and nothing once the game
    /// is over (FR-A11Y-01; specs/004-accessibility research R1).
    func state(of square: Square) -> SquareState {
        guard !isOver, !isComputerTurn else { return .none }
        if square == selection { return .selected }
        if let selection, state.position.piece(at: square) == nil,
            state.targets(from: selection).contains(square)
        {
            return .legalTarget
        }
        return state.movablePieces.contains(square) ? .canMove : .none
    }

    /// A square's VoiceOver label: coordinate, contents and state.
    func squareLabel(_ square: Square) -> LocalizedStringResource {
        GameText.squareLabel(square, state.position.piece(at: square), state(of: square))
    }
}
