import Testing

@testable import CheckersEngine

// Shorthands for writing test positions, such as `Position(["c3": .lightMan, "d4": .darkMan])`.
// Test positions only name dark squares, so the force unwrap below cannot fail.

extension Square {
    /// The square with this name, such as "c3".
    init(_ name: String) {
        self.init(name: name)!
    }
}

extension Piece {
    static let lightMan = Piece(side: .light, kind: .man)
    static let lightKing = Piece(side: .light, kind: .king)
    static let darkMan = Piece(side: .dark, kind: .man)
    static let darkKing = Piece(side: .dark, kind: .king)
}

extension Position {
    /// A position holding exactly the named pieces.
    init(_ layout: [String: Piece]) {
        self.init(Dictionary(uniqueKeysWithValues: layout.map { (Square($0.key), $0.value) }))
    }
}

// Readable values in failure messages: squares by name, steps as "c3-d4", positions as a board.

extension Square: CustomTestStringConvertible {
    public var testDescription: String { name }
}

extension Step: CustomTestStringConvertible {
    public var testDescription: String { "\(from.name)-\(to.name)" }
}

extension Position: CustomTestStringConvertible {
    /// An 8×8 diagram with row 8 on top: `l`/`L` for a Light man/king, `d`/`D` for a Dark
    /// man/king, `.` for an empty dark square and a space for a light square.
    public var testDescription: String {
        let rows = (0..<8).reversed().map { row in
            String(
                (0..<8).map { column -> Character in
                    guard let square = Square(column: column, row: row) else { return " " }
                    switch piece(at: square) {
                    case nil: return "."
                    case .some(let piece):
                        let symbol: Character = piece.side == .light ? "l" : "d"
                        return piece.kind == .king ? Character(symbol.uppercased()) : symbol
                    }
                })
        }
        return "\n" + rows.joined(separator: "\n")
    }
}
