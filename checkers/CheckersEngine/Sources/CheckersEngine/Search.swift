/// The computer's alpha-beta search over complete turns (specs/005-computer-opponent/research.md
/// R2). It scores each of the root turns it is given, deepening one turn at a time, and keeps the
/// scores of the last iteration it completed.
struct Search {
    /// A score beyond any position's, for the open ends of the search window.
    static let infinity = 1_000_000
    /// The score of a won game; a win `n` turns away scores `win - n`, so faster wins rank higher.
    static let win = 10_000

    /// A position and the side to move, which together decide repetition (FR-016).
    struct Key: Equatable {
        let board: Board
        let side: Side
    }

    /// A position in the search: the board, the side to move, how many turns from the root, and
    /// how many turns without progress led to it.
    private struct Node {
        let board: Board
        let side: Side
        let ply: Int
        let noProgress: Int

        /// The position after `turn`, with the other side to move.
        func child(after turn: Turn) -> Node {
            Node(
                board: turn.board, side: side.opponent, ply: ply + 1,
                noProgress: turn.isProgress ? 0 : noProgress + 1)
        }
    }

    private let limits: SearchLimits
    private let shouldStop: () -> Bool
    /// The positions at the start of every turn since the last capture or man move, in the game
    /// and then along the search path; the last entry is the position being searched.
    private var path: [Key]
    /// One reusable turn buffer per ply, so the search does not allocate per position.
    private var buffers: [[Turn]] = []
    private(set) var nodes = 0
    private var isAborted = false
    private var mayAbort = false

    init(path: [Key], limits: SearchLimits, shouldStop: @escaping () -> Bool) {
        self.path = path
        self.limits = limits
        self.shouldStop = shouldStop
    }

    /// The result of the deepest completed iteration: one score per root turn, in the order
    /// given (`nil` for a turn scored below the window, which cannot be among the best), and the
    /// depth reached.
    struct Scores {
        var scores: [Int?]
        var depth: Int
    }

    /// Scores the root turns of `board` with `side` to move, deepening from one turn up to the
    /// limit. `children` are the root turns; `exact` holds the score of a root turn that already
    /// ended the game. Depth 1 always completes.
    mutating func run(
        from board: Board, side: Side, noProgress: Int, children: [Turn], exact: [Int?]
    ) -> Scores {
        var completed = Scores(scores: Array(repeating: nil, count: children.count), depth: 0)
        var order = Array(children.indices)
        let root = Node(board: board, side: side, ply: 0, noProgress: noProgress)
        for depth in 1...max(1, limits.maxDepth) {
            mayAbort = depth > 1
            var scores = [Int?](repeating: nil, count: children.count)
            var best = -Self.infinity
            for index in order {
                let score: Int
                if let known = exact[index] {
                    score = known
                } else {
                    let floor = best == -Self.infinity ? -Self.infinity : best - limits.margin - 1
                    score = -negamax(
                        root.child(after: children[index]), depth: depth - 1,
                        alpha: -Self.infinity, beta: -floor)
                    if isAborted { return completed }
                    guard score > floor else { continue }
                }
                scores[index] = score
                best = max(best, score)
            }
            completed = Scores(scores: scores, depth: depth)
            // Search the best turns of this iteration first in the next one.
            order.sort { (scores[$0] ?? -Self.infinity) > (scores[$1] ?? -Self.infinity) }
            if shouldStop() || reachedNodeLimit { break }
        }
        return completed
    }

    private var reachedNodeLimit: Bool {
        limits.nodeLimit.map { nodes >= $0 } ?? false
    }

    /// The score of the node's position, from the view of its side to move.
    private mutating func negamax(_ node: Node, depth: Int, alpha: Int, beta: Int) -> Int {
        let ply = node.ply
        nodes += 1
        if mayAbort, nodes & 1023 == 0, shouldStop() || reachedNodeLimit {
            isAborted = true
        }
        if isAborted { return 0 }

        let key = Key(board: node.board, side: node.side)
        while buffers.count <= ply {
            buffers.append([])
        }
        // Take the buffer out while it is in use, so filling it does not copy it.
        var turns = buffers[ply]
        buffers[ply] = []
        TurnGenerator.turns(of: node.side, on: node.board, into: &turns)
        defer { buffers[ply] = turns }

        // The order of FR-019: a side without a turn has lost, before any draw.
        if turns.isEmpty { return -(Self.win - ply) }
        if node.noProgress >= 80 || isRepetition(key, within: node.noProgress) { return 0 }
        let isCapture = turns[0].captures > 0
        if depth <= 0, !isCapture {
            return Evaluation.score(node.board, for: node.side)
        }
        if isCapture, turns.count > 1 {
            turns.sort { $0.captures > $1.captures }
        }

        path.append(key)
        defer { path.removeLast() }
        var alpha = alpha
        var best = -Self.infinity
        for turn in turns {
            // Captures at the horizon are searched until the position is quiet.
            let score = -negamax(
                node.child(after: turn), depth: depth - 1, alpha: -beta, beta: -alpha)
            if isAborted { return 0 }
            best = max(best, score)
            alpha = max(alpha, score)
            if alpha >= beta { break }
        }
        return best
    }

    /// Whether the position occurred before at the start of a turn with the same side to move.
    /// Only the last `noProgress` turns can repeat it: a capture or a man move cannot be undone.
    private func isRepetition(_ key: Key, within noProgress: Int) -> Bool {
        guard noProgress > 0 else { return false }
        for earlier in path.suffix(noProgress) where earlier == key {
            return true
        }
        return false
    }
}
