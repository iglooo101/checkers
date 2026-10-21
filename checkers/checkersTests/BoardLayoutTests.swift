import CheckersEngine
import Testing

@testable import checkers

struct BoardLayoutTests {
    static let lightAtBottom = BoardLayout(bottomSide: .light)
    static let darkAtBottom = BoardLayout(bottomSide: .dark)

    @Test("US1 FR-GAME-04: with Light at the bottom, a1 is bottom left and h8 top right")
    func lightAtBottomCorners() {
        #expect(Self.lightAtBottom.square(row: 7, column: 0) == Square("a1"))
        #expect(Self.lightAtBottom.square(row: 0, column: 7) == Square("h8"))
    }

    @Test(
        "US6 FR-GAME-03: with Dark at the bottom the board is turned: h8 bottom left, a1 top right")
    func darkAtBottomCorners() {
        #expect(Self.darkAtBottom.square(row: 7, column: 0) == Square("h8"))
        #expect(Self.darkAtBottom.square(row: 0, column: 7) == Square("a1"))
    }

    @Test("US1 FR-GAME-04: light cells hold no square in either orientation")
    func lightCells() {
        for layout in [Self.lightAtBottom, Self.darkAtBottom] {
            for row in 0..<8 {
                for column in 0..<8 where (row + column).isMultiple(of: 2) {
                    #expect(layout.square(row: row, column: column) == nil, "\(row), \(column)")
                }
            }
        }
    }

    @Test("US1 FR-GAME-04: every square sits in exactly one cell, in both orientations")
    func cellInvertsSquare() {
        for layout in [Self.lightAtBottom, Self.darkAtBottom] {
            for square in Square.all {
                let cell = layout.cell(of: square)
                #expect(
                    layout.square(row: cell.row, column: cell.column) == square, "\(square.name)")
            }
        }
    }
}
