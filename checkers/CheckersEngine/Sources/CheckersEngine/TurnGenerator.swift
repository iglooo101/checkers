/// A position as three 32-bit sets, for the computer's search. Bit `i` is the square with index
/// `i` (`row * 4 + column / 2`), exactly as in `Position`, so converting costs nothing
/// (specs/005-computer-opponent/research.md R1).
struct Board: Hashable, Sendable {
    var light: UInt32
    var dark: UInt32
    var kings: UInt32

    init(light: UInt32, dark: UInt32, kings: UInt32) {
        self.light = light
        self.dark = dark
        self.kings = kings
    }

    init(_ position: Position) {
        self.init(light: position.light, dark: position.dark, kings: position.kings)
    }

    /// The squares holding a side's pieces.
    func pieces(of side: Side) -> UInt32 {
        switch side {
        case .light: light
        case .dark: dark
        }
    }

    /// The board after the piece on `from` moves to `to`, removing whatever stands on
    /// `captured` (an empty set for a simple move). A man that lands on `crowning` becomes a
    /// king.
    func moving(_ side: Side, from: UInt32, to: UInt32, captured: UInt32, crowning: UInt32)
        -> Board
    {
        let isKing = kings & from != 0
        var next = self
        switch side {
        case .light:
            next.light = (light & ~from) | to
            next.dark = dark & ~captured
        case .dark:
            next.dark = (dark & ~from) | to
            next.light = light & ~captured
        }
        next.kings = (kings & ~(from | captured)) | (isKing || to & crowning != 0 ? to : 0)
        return next
    }
}

/// One complete turn: one simple move, or every jump of a capture chain.
struct Turn: Hashable, Sendable {
    /// The board after the turn.
    let board: Board
    /// How many pieces the turn captured.
    let captures: Int
    /// Whether the turn captured or moved a man, which resets the no-progress count (FR-017).
    let isProgress: Bool
}

/// Generates every complete turn of a side without allocating per position, so the computer can
/// search many turns ahead. It follows the rules of `Position.steps(for:)`, which the tests hold
/// it to: only jumps when any jump exists, a chain continues while the piece can jump, and a man
/// that reaches the far row is crowned and ends the turn (research R1).
enum TurnGenerator {
    /// Replaces the contents of `turns` with every complete turn of `side` on `board`: its
    /// capture chains if it has any jump, otherwise its simple moves. Different jump sequences
    /// are separate turns, even when they end on the same board.
    static func turns(of side: Side, on board: Board, into turns: inout [Turn]) {
        turns.removeAll(keepingCapacity: true)
        let opponents = board.pieces(of: side.opponent)
        let empty = ~(board.light | board.dark)
        var pieces = board.pieces(of: side)
        while pieces != 0 {
            let square = pieces.trailingZeroBitCount
            pieces &= pieces - 1
            let isKing = board.kings & (1 << UInt32(square)) != 0
            if canJump(from: square, side: side, isKing: isKing, opponents: opponents, empty: empty)
            {
                addChains(
                    from: square, of: Mover(side: side, isKing: isKing), on: board, captures: 0,
                    &turns)
            }
        }
        guard turns.isEmpty else { return }

        pieces = board.pieces(of: side)
        while pieces != 0 {
            let square = pieces.trailingZeroBitCount
            pieces &= pieces - 1
            let from = UInt32(1) << UInt32(square)
            let isKing = board.kings & from != 0
            for direction in directions(side: side, isKing: isKing) {
                let to = neighbors[direction * 32 + square]
                guard to & empty != 0 else { continue }
                turns.append(
                    Turn(
                        board: board.moving(
                            side, from: from, to: to, captured: 0, crowning: farRow(side)),
                        captures: 0, isProgress: !isKing))
            }
        }
    }

    /// Adds every chain the piece on `square` can complete from here. `captures` counts the
    /// jumps already made in this turn; with none left, the turn ends where it stands.
    private static func addChains(
        from square: Int, of mover: Mover, on board: Board, captures: Int, _ turns: inout [Turn]
    ) {
        let side = mover.side
        let isKing = mover.isKing
        let opponents = board.pieces(of: side.opponent)
        let empty = ~(board.light | board.dark)
        let from = UInt32(1) << UInt32(square)
        var jumped = false
        for direction in directions(side: side, isKing: isKing) {
            let over = neighbors[direction * 32 + square]
            let landing = landings[direction * 32 + square]
            guard landing & empty != 0, over & opponents != 0 else { continue }
            jumped = true
            let next = board.moving(
                side, from: from, to: landing, captured: over, crowning: farRow(side))
            if !isKing, next.kings & landing != 0 {
                // Crowning ends the turn, even in the middle of a chain (FR-012).
                turns.append(Turn(board: next, captures: captures + 1, isProgress: true))
            } else {
                addChains(
                    from: landing.trailingZeroBitCount, of: mover, on: next,
                    captures: captures + 1, &turns)
            }
        }
        if !jumped, captures > 0 {
            turns.append(Turn(board: board, captures: captures, isProgress: true))
        }
    }

    /// The side and kind of the piece making a chain.
    private struct Mover {
        let side: Side
        let isKing: Bool
    }

    private static func canJump(
        from square: Int, side: Side, isKing: Bool, opponents: UInt32, empty: UInt32
    ) -> Bool {
        for direction in directions(side: side, isKing: isKing)
        where landings[direction * 32 + square] & empty != 0
            && neighbors[direction * 32 + square] & opponents != 0
        {
            return true
        }
        return false
    }

    /// The directions a piece moves in, as `Direction` raw values: toward row 8 for a Light man,
    /// toward row 1 for a Dark man, all four for a king.
    private static func directions(side: Side, isKing: Bool) -> Range<Int> {
        if isKing { return 0..<4 }
        switch side {
        case .light: return 0..<2
        case .dark: return 2..<4
        }
    }

    /// The far row of a side's men, where they are crowned: row 8 for Light, row 1 for Dark.
    private static func farRow(_ side: Side) -> UInt32 {
        switch side {
        case .light: 0xF000_0000
        case .dark: 0x0000_000F
        }
    }

    /// The adjacent square in each direction, as a one-bit set (0 off the board), indexed
    /// `direction * 32 + square`.
    private static let neighbors = table { BoardGeometry.neighbor(of: $0, $1) }
    /// The square two steps away in each direction, where a jump lands.
    private static let landings = table { BoardGeometry.landing(of: $0, $1) }

    private static func table(_ target: (Square, Direction) -> Square?) -> [UInt32] {
        Direction.allCases.flatMap { direction in
            Square.all.map { square in
                target(square, direction).map { UInt32(1) << UInt32($0.index) } ?? 0
            }
        }
    }
}
