import CheckersEngine
import Foundation
import OSLog
import Observation

/// A message for the player about their last tap (FR-023).
enum Notice: Equatable {
    case captureRequired
}

/// Where the computer's turn stands (specs/005-computer-opponent/contracts/computer-turn.md).
enum ComputerPhase: Equatable {
    /// It is not the computer's turn, or its turn has not started.
    case idle
    /// Choosing its turn, or waiting to show the first step.
    case thinking
    /// Between the jumps of its capture chain.
    case playing
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
    /// Where VoiceOver focus goes: the landing square of the last step (FR-A11Y-02).
    private(set) var focusSquare: Square?
    /// The square of the piece being dragged, once a drag has been accepted.
    @ObservationIgnored private var dragged: Square?
    /// Where the computer's turn stands; `idle` in a two-player game.
    private(set) var computerPhase = ComputerPhase.idle
    /// The task playing the computer's turn, if one is running.
    @ObservationIgnored private var computerTask: Task<Void, Never>?
    /// Counts the computer's turns, so a cancelled turn cannot reset the phase of a newer one.
    @ObservationIgnored private var computerTurnNumber = 0
    /// Speaks game events with VoiceOver (FR-A11Y-03).
    @ObservationIgnored let announcer: any Announcer
    /// Chooses the computer's turns (specs/005-computer-opponent/research.md R7).
    @ObservationIgnored let opponent: any ComputerOpponent
    /// Paces the computer's turn (research R8).
    @ObservationIgnored let pacer: any TurnPacer

    init(
        setup: GameSetup, playerSide: Side? = nil, state: GameState = GameState(),
        announcer: any Announcer = AccessibilityAnnouncer(),
        opponent: any ComputerOpponent = ScriptedComputerOpponent(),
        pacer: any TurnPacer = SleepingPacer()
    ) {
        self.setup = setup
        self.playerSide = playerSide
        self.state = state
        self.announcer = announcer
        self.opponent = opponent
        self.pacer = pacer
    }

    /// The computer's side in a game against the computer; `nil` in a two-player game.
    var computerSide: Side? {
        playerSide?.opponent
    }

    /// Whether the computer is taking its turn; the board takes no input meanwhile (FR-MOVE-04).
    var isComputerTurn: Bool {
        computerPhase != .idle
    }

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

    /// Whether the game has ended.
    var isOver: Bool {
        state.outcome != .inProgress
    }

    /// The result panel's sentence, once the game is over (FR-033).
    var resultText: LocalizedStringResource? {
        GameText.result(state.outcome)
    }

    /// Whether Undo can take back a turn: the game is in progress and a turn has been played
    /// (FR-037).
    var canUndo: Bool {
        state.canUndo
    }

    /// The side that resigns: the side to move in a two-player game, the player against the
    /// computer (FR-032).
    var resigningSide: Side {
        playerSide ?? state.sideToMove
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

    /// The turn indicator's sentence (FR-014), or that the computer is thinking (FR-AI-03).
    var turnText: LocalizedStringResource {
        if isComputerTurn, let computerSide {
            return GameText.thinking(computerSide)
        }
        return GameText.turn(state.sideToMove, captureRequired: state.isCaptureRequired)
    }

    /// Handles a tap on a square, by the first matching row of the contract's taps table.
    func tap(_ square: Square) {
        // The board takes no input during the computer's turn (FR-MOVE-04).
        guard !isComputerTurn else { return }
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
            announcer.announce(GameText.notice(.captureRequired))
        } else {
            selection = nil
        }
    }

    /// Takes back the last turn, or the partial turn of a chain; nothing is selected afterwards
    /// (FR-036, FR-038).
    func undo() {
        guard canUndo else { return }
        do {
            try state.undo()
        } catch {
            Log.game.error("Undo rejected: \(String(describing: error))")
            return
        }
        selection = nil
        notice = nil
        focusSquare = nil
        announcer.announce(
            GameText.undone(state.sideToMove, captureRequired: state.isCaptureRequired))
    }

    /// Resigns for `resigningSide`; nothing happens once the game is over (FR-032).
    func resign() {
        guard !isOver else { return }
        do {
            try state.resign(resigningSide)
        } catch {
            Log.game.error("Resign rejected: \(String(describing: error))")
        }
        selection = nil
        notice = nil
        if let result = resultText {
            announcer.announce(result)
        }
    }

    /// Starts dragging the piece on a square, if it may move; otherwise answers as a tap would and
    /// returns false, so the piece stays put (contract: Drags).
    func beginDrag(at square: Square) -> Bool {
        dragged = nil
        guard !isComputerTurn else { return false }
        notice = nil
        guard state.outcome == .inProgress else { return false }
        if let chainSquare = state.chainSquare {
            guard square == chainSquare else { return false }
        } else if square != selection {
            guard state.movablePieces.contains(square) else {
                tap(square)
                return false
            }
            selection = square
        }
        dragged = square
        return true
    }

    /// Ends a drag: moves the dragged piece if it was dropped on one of its targets; anything
    /// else, including a drop off the board, leaves it where it was (FR-020).
    func drop(on square: Square?) {
        defer { dragged = nil }
        guard let from = dragged, let square, state.targets(from: from).contains(square) else {
            return
        }
        apply(Step(from: from, to: square))
    }

    /// Applies a step to a legal target: the piece stays selected while its chain continues
    /// (contract: Applying a step). When the player's turn ends, the computer's begins.
    private func apply(_ step: Step) {
        guard let result = applyStep(step) else { return }
        selection = result.turnContinues ? result.to : nil
        if !result.turnContinues {
            startComputerTurnIfNeeded()
        }
    }

    /// Applies a step and announces it; `nil` if the engine rejected it.
    @discardableResult
    private func applyStep(_ step: Step) -> StepResult? {
        do {
            let result = try state.apply(step)
            notice = nil
            focusSquare = result.to
            announcer.announce(
                GameText.joined(
                    GameText.stepSentence(result), GameText.followUp(after: result, in: state)))
            return result
        } catch {
            Log.game.error(
                "Rejected step \(step.from.name)-\(step.to.name): \(String(describing: error))")
            return nil
        }
    }

    // MARK: - The computer's turn (specs/005-computer-opponent/contracts/computer-turn.md)

    /// The pause before the computer's first step, even if it chose sooner (FR-AI-03).
    static let thinkingPause = Duration.milliseconds(500)
    /// The pause before each further jump of the computer's chain (FR-AI-05, Clarifications).
    static let jumpPause = Duration.milliseconds(500)

    /// Starts the computer's turn when it is the computer's side to move in a game in progress
    /// (FR-AI-06); does nothing otherwise.
    func startComputerTurnIfNeeded() {
        guard computerPhase == .idle, !isOver, state.chainSquare == nil,
            let computerSide, state.sideToMove == computerSide
        else { return }
        computerPhase = .thinking
        selection = nil
        notice = nil
        dragged = nil
        computerTurnNumber += 1
        let number = computerTurnNumber
        let start = state
        computerTask = Task { [weak self] in
            await self?.playComputerTurn(from: start)
            self?.endComputerTurn(number)
        }
    }

    /// Stops the computer's turn; it applies no further step.
    func cancelComputerTurn() {
        computerTask?.cancel()
        computerTask = nil
        computerTurnNumber += 1
        computerPhase = .idle
    }

    private func endComputerTurn(_ number: Int) {
        guard number == computerTurnNumber else { return }
        computerTask = nil
        computerPhase = .idle
    }

    /// Thinks and pauses together, then shows the turn step by step (contract: Timeline).
    private func playComputerTurn(from start: GameState) async {
        let opponent = opponent
        let difficulty = setup.difficulty
        let choosing = Task { await opponent.chooseTurn(in: start, difficulty: difficulty) }
        do {
            try await pacer.pause(Self.thinkingPause)
        } catch {
            choosing.cancel()
            return
        }
        let chosen = await withTaskCancellationHandler {
            await choosing.value
        } onCancel: {
            choosing.cancel()
        }
        guard !Task.isCancelled, state == start else { return }
        let steps: [Step]
        if let chosen, !chosen.isEmpty {
            steps = chosen
        } else {
            Log.computer.error("The computer chose no turn; playing the first legal one")
            steps = Self.firstLegalTurn(from: start)
        }
        for (index, step) in steps.enumerated() {
            if index > 0 {
                do {
                    try await pacer.pause(Self.jumpPause)
                } catch {
                    return
                }
            }
            guard !Task.isCancelled, applyStep(step) != nil else { return }
            if index == 0, steps.count > 1 {
                computerPhase = .playing
            }
        }
    }

    /// The first complete turn in the engine's order, for when the opponent gives none.
    private static func firstLegalTurn(from start: GameState) -> [Step] {
        var state = start
        var steps: [Step] = []
        while let step = state.legalSteps.first {
            steps.append(step)
            guard let result = try? state.apply(step), result.turnContinues else { break }
        }
        return steps
    }
}
