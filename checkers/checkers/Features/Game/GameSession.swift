import CheckersEngine
import Foundation
import OSLog
import Observation

/// A message for the player about their last tap (FR-023).
enum Notice: Equatable {
    case captureRequired
}

/// One game on the game screen: the engine's rules state plus what the player has selected. It
/// turns taps into engine steps by the rules in `contracts/game-session.md`, so every interaction
/// rule is tested without the user interface (FR-024).
@Observable
final class GameSession {
    private(set) var state: GameState
    let setup: GameSetup
    /// The player's side in a game against the computer; `nil` in a two-player game.
    let playerSide: Side?
    /// The square of the selected piece, if any.
    private(set) var selection: Square?
    /// What the last tap told the player, if anything; cleared by the next tap or move.
    private(set) var notice: Notice?

    init(setup: GameSetup, playerSide: Side? = nil, state: GameState = GameState()) {
        self.setup = setup
        self.playerSide = playerSide
        self.state = state
    }

    /// Light at the bottom in a two-player game; the player's side against the computer (FR-015).
    var layout: BoardLayout {
        BoardLayout(bottomSide: playerSide ?? .light)
    }

    /// The turn indicator's sentence (FR-014).
    var turnText: LocalizedStringResource {
        GameText.turn(state.sideToMove, captureRequired: state.isCaptureRequired)
    }

    /// Handles a tap on a square, by the first matching row of the contract's taps table.
    func tap(_ square: Square) {
        notice = nil
        guard state.outcome == .inProgress else { return }
        if let chainSquare = state.chainSquare {
            // A chain locks the turn to its piece: only its next jumps do anything (FR-030).
            if state.targets(from: chainSquare).contains(square) {
                apply(Step(from: chainSquare, to: square))
            }
        } else if let selection, state.targets(from: selection).contains(square) {
            apply(Step(from: selection, to: square))
        } else if square == selection {
            selection = nil
        } else if state.movablePieces.contains(square) {
            selection = square
        } else if state.isCaptureRequired,
            state.position.piece(at: square)?.side == state.sideToMove
        {
            notice = .captureRequired
        } else {
            selection = nil
        }
    }

    /// Applies a step to a legal target: the piece stays selected while its chain continues
    /// (contract: Applying a step).
    private func apply(_ step: Step) {
        do {
            let result = try state.apply(step)
            selection = result.turnContinues ? result.to : nil
            notice = nil
        } catch {
            Log.game.error(
                "Rejected step \(step.from.name)-\(step.to.name): \(String(describing: error))")
        }
    }
}
