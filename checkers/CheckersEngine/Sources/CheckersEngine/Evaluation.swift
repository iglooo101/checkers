/// Scores a quiet position for the computer's search, in points where a man is 100
/// (specs/005-computer-opponent/research.md R3). Every term is a count of bits, so it stays fast.
enum Evaluation {
    static let man = 100
    static let king = 130
    /// Per row a man has advanced from its own back row.
    static let advancement = 2
    /// For each man still guarding its back row while the opponent has men to crown.
    static let backRowGuard = 8
    /// For each piece on c5, e5, d4 or f4.
    static let center = 5

    /// The score of `board` from the view of `side`: positive when `side` is better.
    static func score(_ board: Board, for side: Side) -> Int {
        let light = sideScore(
            men: board.light & ~board.kings, kings: board.light & board.kings,
            opponentMen: board.dark & ~board.kings, backRow: lightBackRow,
            rowOf: { $0 })
        let dark = sideScore(
            men: board.dark & ~board.kings, kings: board.dark & board.kings,
            opponentMen: board.light & ~board.kings, backRow: darkBackRow,
            rowOf: { 7 - $0 })
        var lead = light - dark
        // Trading down when ahead converts the advantage and avoids a no-progress draw.
        let material = material(board.light, board.kings) - material(board.dark, board.kings)
        let pieces = (board.light | board.dark).nonzeroBitCount
        lead += material * (24 - pieces) / 8
        return side == .light ? lead : -lead
    }

    private static func sideScore(
        men: UInt32, kings: UInt32, opponentMen: UInt32, backRow: UInt32, rowOf: (Int) -> Int
    ) -> Int {
        var score = men.nonzeroBitCount * man + kings.nonzeroBitCount * king
        score += ((men | kings) & centerSquares).nonzeroBitCount * center
        if opponentMen != 0 {
            score += (men & backRow).nonzeroBitCount * backRowGuard
        }
        for row in 1..<8 {
            score += (men & rowMask(row)).nonzeroBitCount * rowOf(row) * advancement
        }
        return score
    }

    private static func material(_ pieces: UInt32, _ kings: UInt32) -> Int {
        (pieces & ~kings).nonzeroBitCount * man + (pieces & kings).nonzeroBitCount * king
    }

    private static func rowMask(_ row: Int) -> UInt32 {
        UInt32(0xF) << UInt32(row * 4)
    }

    private static let lightBackRow: UInt32 = 0x0000_000F
    private static let darkBackRow: UInt32 = 0xF000_0000
    /// d4, f4, c5 and e5.
    private static let centerSquares: UInt32 = 0x0006_6000
}
