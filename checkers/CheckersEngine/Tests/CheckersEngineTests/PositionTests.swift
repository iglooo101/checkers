import Testing

@testable import CheckersEngine

struct PositionTests {
    static let pieces: [Piece] = [.lightMan, .lightKing, .darkMan, .darkKing]

    @Test("An empty position has no pieces")
    func empty() {
        let position = Position()
        #expect(Square.all.allSatisfy { position.piece(at: $0) == nil })
    }

    @Test("A placed piece reads back on its square and nowhere else", arguments: pieces)
    func placeAndRead(piece: Piece) {
        for square in Square.all {
            var position = Position()
            position.place(piece, at: square)
            #expect(position.piece(at: square) == piece)
            #expect(Square.all.filter { position.piece(at: $0) != nil } == [square])
        }
    }

    @Test("Removing a piece empties its square")
    func remove() {
        var position = Position(["c3": .lightKing, "d4": .darkMan])
        position.remove(at: Square("c3"))
        #expect(position.piece(at: Square("c3")) == nil)
        #expect(position.piece(at: Square("d4")) == .darkMan)
    }

    @Test("Placing a piece on an occupied square replaces it")
    func replace() {
        var position = Position(["c3": .darkKing])
        position.place(.lightMan, at: Square("c3"))
        #expect(position.piece(at: Square("c3")) == .lightMan)
        #expect(position == Position(["c3": .lightMan]))
    }

    @Test("Positions with the same pieces on the same squares are equal and hash equally")
    func equality() {
        let first = Position(["c3": .lightMan, "d4": .darkKing])
        let second = Position(["d4": .darkKing, "c3": .lightMan])
        #expect(first == second)
        #expect(first.hashValue == second.hashValue)
    }

    @Test("A different kind or side on a square makes positions different")
    func inequality() {
        #expect(Position(["c3": .lightMan]) != Position(["c3": .lightKing]))
        #expect(Position(["c3": .lightMan]) != Position(["c3": .darkMan]))
        #expect(Position(["c3": .lightMan]) != Position(["e3": .lightMan]))
    }

    @Test("The layout initializer places exactly the named pieces")
    func layout() {
        let position = Position(["c3": .lightMan, "f6": .darkKing])
        for square in Square.all {
            switch square.name {
            case "c3": #expect(position.piece(at: square) == .lightMan)
            case "f6": #expect(position.piece(at: square) == .darkKing)
            default: #expect(position.piece(at: square) == nil)
            }
        }
    }
}
