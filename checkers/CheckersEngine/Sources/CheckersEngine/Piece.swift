/// Whether a piece is a man or a king (FRD glossary).
public enum PieceKind: Sendable, Hashable {
    case man
    case king
}

/// A piece on the board: the side it belongs to and its kind (FR-002).
public struct Piece: Sendable, Hashable {
    public let side: Side
    public let kind: PieceKind

    public init(side: Side, kind: PieceKind) {
        self.side = side
        self.kind = kind
    }
}
