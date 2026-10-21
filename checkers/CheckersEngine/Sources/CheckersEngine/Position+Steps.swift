/// Legal step generation on a bare position, without turn state (FR-004 to FR-008).
extension Position {
    /// The legal single steps of a side: only jumps when any jump exists (FR-007), otherwise its
    /// simple moves. Steps are ordered by from square in `Square.all` order and then by direction
    /// (contract: Queries).
    func steps(for side: Side) -> [Step] {
        let squares = squares(of: side)
        let jumps = squares.flatMap(jumps(from:))
        return jumps.isEmpty ? squares.flatMap(simpleMoves(from:)) : jumps
    }

    /// The jumps of the piece on a square: over an adjacent opposing piece onto the empty square
    /// beyond it, forward for a man and in all four directions for a king (FR-005, FR-006).
    func jumps(from square: Square) -> [Step] {
        guard let mover = piece(at: square) else { return [] }
        return Self.directions(for: mover).compactMap { direction in
            guard let over = BoardGeometry.neighbor(of: square, direction),
                let landing = BoardGeometry.landing(of: square, direction),
                piece(at: over)?.side == mover.side.opponent, isEmpty(landing)
            else { return nil }
            return Step(from: square, to: landing)
        }
    }

    /// The simple moves of the piece on a square: one square onto an empty neighbor, forward for
    /// a man and in all four directions for a king (FR-004, FR-006).
    private func simpleMoves(from square: Square) -> [Step] {
        guard let mover = piece(at: square) else { return [] }
        return Self.directions(for: mover).compactMap { direction in
            guard let target = BoardGeometry.neighbor(of: square, direction), isEmpty(target)
            else { return nil }
            return Step(from: square, to: target)
        }
    }

    private static func directions(for piece: Piece) -> [Direction] {
        switch piece.kind {
        case .man: piece.side.forwardDirections
        case .king: Direction.allCases
        }
    }
}
