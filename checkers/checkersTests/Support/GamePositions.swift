import CheckersEngine

// Shorthands for test positions through the engine's public API, such as
// `GameState(["c3": .lightMan, "d4": .darkMan], toMove: .light)`. Test positions only name dark
// squares, so the force unwrap below cannot fail.

extension Square {
    /// The square with this name, such as "c3".
    init(_ name: String) {
        self.init(name: name)!
    }
}

extension Step {
    /// The step between two named squares, such as `Step("c3", "d4")`.
    init(_ from: String, _ to: String) {
        self.init(from: Square(from), to: Square(to))
    }
}

extension Piece {
    static let lightMan = Piece(side: .light, kind: .man)
    static let lightKing = Piece(side: .light, kind: .king)
    static let darkMan = Piece(side: .dark, kind: .man)
    static let darkKing = Piece(side: .dark, kind: .king)
}

extension GameState {
    /// A game in the named position with the given side to move.
    init(_ layout: [String: Piece], toMove side: Side) {
        let pieces = Dictionary(uniqueKeysWithValues: layout.map { (Square($0.key), $0.value) })
        self.init(position: Position(pieces), sideToMove: side)
    }
}
