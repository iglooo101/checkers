import Testing

@testable import CheckersEngine

struct SquareTests {
    @Test("Every dark square exists, named by its column and row")
    func darkSquares() {
        var count = 0
        for row in 0..<8 {
            for column in 0..<8 where (column + row).isMultiple(of: 2) {
                let square = Square(column: column, row: row)
                #expect(square?.column == column)
                #expect(square?.row == row)
                count += 1
            }
        }
        #expect(count == 32)
    }

    @Test(
        "Light squares and out-of-range coordinates are not squares",
        arguments: [(1, 0), (0, 1), (7, 6), (-1, 0), (0, -1), (0, 8), (8, 0)]
    )
    func invalidCoordinates(column: Int, row: Int) {
        #expect(Square(column: column, row: row) == nil)
    }

    @Test(
        "Names of light squares and invalid names are not squares",
        arguments: ["b1", "i1", "a9", "a10", "A1", "", "a", "1a", "a0", "c 3"]
    )
    func invalidNames(name: String) {
        #expect(Square(name: name) == nil)
    }

    @Test("a1 is a dark square in column a, row 1")
    func a1IsDark() throws {
        let square = try #require(Square(column: 0, row: 0))
        #expect(square.name == "a1")
        #expect(Square(name: "a1") == square)
    }

    @Test("Every square's name leads back to the same square")
    func namesRoundTrip() {
        for square in Square.all {
            #expect(Square(name: square.name) == square)
        }
    }

    @Test("Square.all lists the 32 squares row by row, from a1 to h8")
    func allSquares() {
        let names = Square.all.map(\.name)
        #expect(names.count == 32)
        #expect(Set(names).count == 32)
        #expect(Array(names.prefix(5)) == ["a1", "c1", "e1", "g1", "b2"])
        #expect(names.last == "h8")
    }

    @Test("Diagonal neighbors come in the engine's direction order")
    func neighborOrder() {
        #expect(neighbors(of: "d4") == [Square("c5"), Square("e5"), Square("c3"), Square("e3")])
    }

    @Test("Corner squares have one neighbor and one landing square")
    func corners() {
        #expect(neighbors(of: "a1") == [Square("b2")])
        #expect(landings(of: "a1") == [Square("c3")])
        #expect(neighbors(of: "h8") == [Square("g7")])
        #expect(landings(of: "h8") == [Square("f6")])
    }

    @Test("A landing square needs a square beyond the neighbor")
    func landingNeedsRoom() {
        #expect(landings(of: "b2") == [Square("d4")])
    }

    /// The diagonal neighbors of a square, in direction order.
    private func neighbors(of name: String) -> [Square] {
        Direction.allCases.compactMap { BoardGeometry.neighbor(of: Square(name), $0) }
    }

    /// The jump landing squares of a square, in direction order.
    private func landings(of name: String) -> [Square] {
        Direction.allCases.compactMap { BoardGeometry.landing(of: Square(name), $0) }
    }
}
