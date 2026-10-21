/// The four diagonal directions, in the order the engine lists steps. North is toward row 8
/// and west toward column a, as seen from Light's side.
enum Direction: Int, CaseIterable {
    case northwest
    case northeast
    case southwest
    case southeast

    var columnStep: Int {
        switch self {
        case .northwest, .southwest: -1
        case .northeast, .southeast: 1
        }
    }

    var rowStep: Int {
        switch self {
        case .northwest, .northeast: 1
        case .southwest, .southeast: -1
        }
    }
}

/// Diagonal neighbors and jump landing squares of every square, computed once.
enum BoardGeometry {
    /// The adjacent square in a direction, or `nil` at the edge of the board.
    static func neighbor(of square: Square, _ direction: Direction) -> Square? {
        neighbors[square.index][direction.rawValue]
    }

    /// The square two steps away in a direction, where a jump lands, or `nil` if it is off the
    /// board.
    static func landing(of square: Square, _ direction: Direction) -> Square? {
        landings[square.index][direction.rawValue]
    }

    private static let neighbors = table(distance: 1)
    private static let landings = table(distance: 2)

    private static func table(distance: Int) -> [[Square?]] {
        Square.all.map { square in
            Direction.allCases.map { direction in
                Square(
                    column: square.column + direction.columnStep * distance,
                    row: square.row + direction.rowStep * distance)
            }
        }
    }
}
