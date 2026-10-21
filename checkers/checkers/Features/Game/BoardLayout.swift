import CheckersEngine

/// Which square each display cell of the board shows, for the side drawn at the bottom
/// (FR-015). Display row 0 is the top and column 0 the left. Drawing, tapping and dropping all go
/// through this one mapping.
nonisolated struct BoardLayout: Equatable, Sendable {
    let bottomSide: Side

    /// The square in a display cell, or `nil` for a light square.
    func square(row: Int, column: Int) -> Square? {
        switch bottomSide {
        case .light: Square(column: column, row: 7 - row)
        case .dark: Square(column: 7 - column, row: row)
        }
    }

    /// The display cell that shows a square.
    func cell(of square: Square) -> (row: Int, column: Int) {
        switch bottomSide {
        case .light: (row: 7 - square.row, column: square.column)
        case .dark: (row: square.row, column: 7 - square.column)
        }
    }
}
