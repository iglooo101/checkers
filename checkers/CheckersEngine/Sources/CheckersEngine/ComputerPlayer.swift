/// The turn the computer chose, with what its search found.
public struct ComputerTurn: Sendable, Equatable {
    /// The turn's steps in order: one step, or every jump of a chain. Never empty.
    public let steps: [Step]
    /// The deepest search iteration completed, in turns; at least 1.
    public let depth: Int
    /// How many positions the search visited.
    public let nodes: Int
    /// The turn's score from the computer's view, in points where a man is 100.
    public let score: Int
}

/// Chooses the computer's turns (FR-AI-01, FR-AI-02; specs/005-computer-opponent/contracts/
/// computer-player.md).
public enum ComputerPlayer {
    /// The turn the side to move plays at this level, or `nil` when the game is over or a capture
    /// chain is in progress (the computer only starts turns). The same state, level and seed give
    /// the same turn while `shouldStop` stays false; when it returns true, the best turn of the
    /// last completed search iteration is returned.
    public static func chooseTurn(
        in state: GameState, level: ComputerLevel, seed: UInt64,
        shouldStop: () -> Bool = { false }
    ) -> ComputerTurn? {
        chooseTurn(in: state, limits: level.limits, seed: seed, shouldStop: shouldStop)
    }

    /// `chooseTurn(in:level:seed:shouldStop:)` with explicit limits, for tests.
    static func chooseTurn(
        in state: GameState, limits: SearchLimits, seed: UInt64,
        shouldStop: () -> Bool = { false }
    ) -> ComputerTurn? {
        guard state.outcome == .inProgress, state.chainSquare == nil else { return nil }
        let roots = rootTurns(of: state)
        guard !roots.isEmpty else { return nil }

        let side = state.sideToMove
        // A root turn that ends the game is scored by the rules engine itself.
        let exact = roots.map { root -> Int? in
            switch root.after.outcome {
            case .inProgress: nil
            case .draw: 0
            case .win(let winner, _): winner == side ? Search.win - 1 : -(Search.win - 1)
            }
        }
        let path =
            state.history.suffix(state.noProgressCount).map {
                Search.Key(board: Board($0.position), side: $0.sideToMove)
            } + [Search.Key(board: Board(state.position), side: side)]

        return withoutActuallyEscaping(shouldStop) { shouldStop in
            var search = Search(path: path, limits: limits, shouldStop: shouldStop)
            let result = search.run(
                from: Board(state.position), side: side, noProgress: state.noProgressCount,
                children: roots.map(\.turn), exact: exact)
            let best = result.scores.compactMap { $0 }.max() ?? -Search.infinity
            // Ties go to the first turn in the rules engine's order.
            let index = result.scores.firstIndex { ($0 ?? -Search.infinity) >= best } ?? 0
            return ComputerTurn(
                steps: roots[index].steps, depth: result.depth, nodes: search.nodes,
                score: result.scores[index] ?? best)
        }
    }

    /// A complete turn found through `GameState`, so every step the computer plays is one the
    /// rules engine accepted (research R1).
    private struct RootTurn {
        let steps: [Step]
        let after: GameState
        let turn: Turn
    }

    /// Every complete turn of the side to move, in the rules engine's step order.
    private static func rootTurns(of state: GameState) -> [RootTurn] {
        var roots: [RootTurn] = []
        func extend(_ state: GameState, steps: [Step], captures: Int, movedMan: Bool) {
            for step in state.legalSteps {
                var next = state
                guard let result = try? next.apply(step) else { continue }
                let isMan = steps.isEmpty ? result.piece.kind == .man : movedMan
                let taken = captures + (result.captured == nil ? 0 : 1)
                if result.turnContinues {
                    extend(next, steps: steps + [step], captures: taken, movedMan: isMan)
                } else {
                    roots.append(
                        RootTurn(
                            steps: steps + [step], after: next,
                            turn: Turn(
                                board: Board(next.position), captures: taken,
                                isProgress: taken > 0 || isMan)))
                }
            }
        }
        extend(state, steps: [], captures: 0, movedMan: false)
        return roots
    }
}
