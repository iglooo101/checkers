/// Legal step generation on a bare position, without turn state (FR-004, FR-008).
extension Position {
    /// The legal single steps of a side, ordered by from square in `Square.all` order and then by
    /// direction (contract: Queries).
    func steps(for side: Side) -> [Step] {
        var steps: [Step] = []
        for square in squares(of: side) {
            for direction in side.forwardDirections {
                if let target = BoardGeometry.neighbor(of: square, direction), isEmpty(target) {
                    steps.append(Step(from: square, to: target))
                }
            }
        }
        return steps
    }
}
