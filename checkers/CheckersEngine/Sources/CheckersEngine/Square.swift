/// One of the 32 dark squares, named by column a–h and row 1–8 as seen from Light's side, such
/// as "c3". a1 is a dark square (FR-001).
public struct Square: Sendable, Hashable {
    /// Position in `Square.all`: `row * 4 + column / 2`, so a1 is 0 and h8 is 31.
    let index: Int

    /// The square at a known-valid index, 0 to 31.
    init(index: Int) {
        self.index = index
    }

    /// The square at a zero-based column (0 is a) and row (0 is row 1), or `nil` unless both
    /// are in range and the square is dark.
    public init?(column: Int, row: Int) {
        guard (0..<8).contains(column), (0..<8).contains(row), (column + row).isMultiple(of: 2)
        else { return nil }
        self.init(index: row * 4 + column / 2)
    }

    /// The square with a name such as "c3" (a lowercase column letter a–h followed by a row
    /// 1–8), or `nil` for any other text or a light square.
    public init?(name: String) {
        let characters = Array(name.utf8)
        guard characters.count == 2 else { return nil }
        self.init(
            column: Int(characters[0]) - Int(UInt8(ascii: "a")),
            row: Int(characters[1]) - Int(UInt8(ascii: "1")))
    }

    /// Zero-based column: 0 is column a.
    public var column: Int {
        (index % 4) * 2 + row % 2
    }

    /// Zero-based row: 0 is row 1, on Light's side.
    public var row: Int {
        index / 4
    }

    /// Board notation such as "c3".
    public var name: String {
        String(Self.columnLetters[column]) + String(row + 1)
    }

    /// The 32 dark squares in index order: a1, c1, e1, g1, b2, …, h8.
    public static let all: [Square] = (0..<32).map(Square.init(index:))

    private static let columnLetters = Array("abcdefgh")
}
