import CheckersEngine
import Foundation
import OSLog

/// Chooses the computer's turns. Injected into `GameSession` so tests and previews can script
/// them (Constitution II.3; specs/005-computer-opponent/research.md R7, R8).
protocol ComputerOpponent {
    /// The steps of the turn the side to move plays, in order, or `nil` if the task was cancelled.
    /// Must not block the main actor.
    func chooseTurn(in state: GameState, difficulty: Difficulty) async -> [Step]?
}

/// Chooses turns with the engine's search, off the main actor. Thinking stops after
/// `timeLimit`, keeping the best turn found by then, so the first step appears within about a
/// second in every build (FR-008; research R7).
struct EngineComputerOpponent: ComputerOpponent {
    nonisolated static let timeLimit: Duration = .milliseconds(800)

    func chooseTurn(in state: GameState, difficulty: Difficulty) async -> [Step]? {
        let level = difficulty.computerLevel
        // A fresh seed for every turn, so games vary (FR-013).
        let seed = UInt64.random(in: .min ... .max)
        guard let (turn, thinking) = await Self.search(state, level: level, seed: seed),
            !Task.isCancelled
        else { return nil }
        let milliseconds = Int(thinking / .milliseconds(1))
        Log.computer.debug(
            "\(String(describing: level), privacy: .public) turn: depth \(turn.depth, privacy: .public), \(turn.nodes, privacy: .public) nodes, \(milliseconds, privacy: .public) ms"
        )
        return turn.steps
    }

    /// Runs the search on the cooperative pool, never on the main actor (Constitution VII.3).
    @concurrent
    nonisolated private static func search(_ state: GameState, level: ComputerLevel, seed: UInt64)
        async -> (ComputerTurn, Duration)?
    {
        let clock = ContinuousClock()
        let start = clock.now
        let deadline = start + timeLimit
        let turn = ComputerPlayer.chooseTurn(in: state, level: level, seed: seed) {
            Task.isCancelled || clock.now >= deadline
        }
        return turn.map { ($0, clock.now - start) }
    }
}

/// Plays scripted turns, for tests and previews. With no turn left, or while held, it waits
/// until released or cancelled.
final class ScriptedComputerOpponent: ComputerOpponent {
    private var turns: [[Step]]
    /// Whether answers wait for `release()`.
    private var isHeld: Bool
    private var waiting: (id: UUID, continuation: CheckedContinuation<Void, Never>)?
    /// How many turns have been asked for.
    private(set) var requests = 0

    init(turns: [[Step]] = [], isHeld: Bool = false) {
        self.turns = turns
        self.isHeld = isHeld
    }

    func chooseTurn(in state: GameState, difficulty: Difficulty) async -> [Step]? {
        requests += 1
        if isHeld || turns.isEmpty {
            let id = UUID()
            await withTaskCancellationHandler {
                await withCheckedContinuation { continuation in
                    waiting = (id, continuation)
                }
            } onCancel: {
                Task { @MainActor in self.resume(id) }
            }
        }
        guard !Task.isCancelled, !turns.isEmpty else { return nil }
        return turns.removeFirst()
    }

    /// Lets a held or waiting answer go, and stops holding later ones.
    func release() {
        isHeld = false
        if let waiting {
            resume(waiting.id)
        }
    }

    private func resume(_ id: UUID) {
        guard let waiting, waiting.id == id else { return }
        self.waiting = nil
        waiting.continuation.resume()
    }
}
