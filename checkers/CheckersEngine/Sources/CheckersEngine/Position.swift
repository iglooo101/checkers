/// Which piece, if any, stands on each of the 32 dark squares. Two positions are equal when the
/// same pieces of the same kind stand on the same squares (FR-016).
public struct Position: Sendable, Hashable {
    /// Squares holding a Light piece, one bit per square index.
    private(set) var light: UInt32 = 0
    /// Squares holding a Dark piece.
    private(set) var dark: UInt32 = 0
    /// Squares holding a king of either side; always a subset of the occupied squares.
    private(set) var kings: UInt32 = 0

    /// The standard starting position: Light men on the 12 dark squares of rows 1–3, Dark men on
    /// those of rows 6–8 (FR-003).
    public static let start: Position = {
        var position = Position()
        for square in Square.all {
            switch square.row {
            case 0...2: position.place(Piece(side: .light, kind: .man), at: square)
            case 5...7: position.place(Piece(side: .dark, kind: .man), at: square)
            default: break
            }
        }
        return position
    }()

    /// An empty board.
    init() {}

    /// A board holding exactly these pieces, for games that start from a custom position.
    public init(_ pieces: [Square: Piece]) {
        for (square, piece) in pieces {
            place(piece, at: square)
        }
    }

    /// The piece on a square, if any.
    public func piece(at square: Square) -> Piece? {
        let bit = Self.bit(square)
        let kind: PieceKind = kings & bit != 0 ? .king : .man
        if light & bit != 0 { return Piece(side: .light, kind: kind) }
        if dark & bit != 0 { return Piece(side: .dark, kind: kind) }
        return nil
    }

    /// Whether no piece stands on a square.
    func isEmpty(_ square: Square) -> Bool {
        (light | dark) & Self.bit(square) == 0
    }

    /// The number of pieces a side has on the board.
    func pieceCount(of side: Side) -> Int {
        pieces(of: side).nonzeroBitCount
    }

    /// The squares holding a side's pieces, in `Square.all` order.
    func squares(of side: Side) -> [Square] {
        let set = pieces(of: side)
        return Square.all.filter { set & Self.bit($0) != 0 }
    }

    /// Puts a piece on a square, replacing anything already there.
    mutating func place(_ piece: Piece, at square: Square) {
        remove(at: square)
        let bit = Self.bit(square)
        switch piece.side {
        case .light: light |= bit
        case .dark: dark |= bit
        }
        if piece.kind == .king {
            kings |= bit
        }
    }

    /// Empties a square.
    mutating func remove(at square: Square) {
        let mask = ~Self.bit(square)
        light &= mask
        dark &= mask
        kings &= mask
    }

    private func pieces(of side: Side) -> UInt32 {
        switch side {
        case .light: light
        case .dark: dark
        }
    }

    private static func bit(_ square: Square) -> UInt32 {
        1 << UInt32(square.index)
    }
}
