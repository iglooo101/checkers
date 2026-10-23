// The saved form of a game (specs/006-saving-and-statistics/contracts/saved-game.md): explicit
// keys keep the format readable and stable, and decoding accepts only states the rules could
// reach, so damaged data never becomes a game (research R1).

extension GameState: Codable {
    private enum CodingKeys: String, CodingKey {
        case position, sideToMove, chainSquare, outcome, noProgressCount, turns
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let chainSquare = try container.decode(String?.self, forKey: .chainSquare).map { name in
            guard let square = Square(name: name) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .chainSquare, in: container, debugDescription: "Unknown square \(name)")
            }
            return square
        }
        self.init(
            position: try container.decode(EncodedPosition.self, forKey: .position).position,
            sideToMove: try container.decode(Side.self, forKey: .sideToMove),
            chainSquare: chainSquare,
            outcome: try container.decode(EncodedOutcome.self, forKey: .outcome).outcome,
            noProgressCount: try container.decode(Int.self, forKey: .noProgressCount),
            history: try container.decode([TurnRecord].self, forKey: .turns))
        if let problem = validityProblem {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: problem))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(EncodedPosition(position), forKey: .position)
        try container.encode(sideToMove, forKey: .sideToMove)
        // Written as null between turns, so every saved game has the same keys.
        try container.encode(chainSquare?.name, forKey: .chainSquare)
        try container.encode(EncodedOutcome(outcome), forKey: .outcome)
        try container.encode(noProgressCount, forKey: .noProgressCount)
        try container.encode(history, forKey: .turns)
    }

    /// Why the rules could not have reached this state, or `nil` if they could (contract:
    /// Validity). Positions and turn records are checked as they are decoded.
    private var validityProblem: String? {
        guard (0...80).contains(noProgressCount) else { return "No-progress count out of range" }
        if let chainSquare {
            guard outcome == .inProgress else { return "A chain in a finished game" }
            guard position.piece(at: chainSquare)?.side == sideToMove,
                !position.jumps(from: chainSquare).isEmpty
            else { return "A chain without a jump for the side to move" }
        }
        guard outcome == .inProgress else { return nil }
        guard noProgressCount < 80 else { return "No progress for 80 turns in a game in progress" }
        guard !legalSteps.isEmpty else { return "No legal step in a game in progress" }
        guard repetitionCount < 3 else { return "A third repetition in a game in progress" }
        return nil
    }
}

/// The state at the start of a turn, as saved: a position, a side and a no-progress count below
/// 80, since a turn starts only while the game goes on.
extension TurnRecord: Codable {
    private enum CodingKeys: String, CodingKey {
        case position, sideToMove, noProgressCount
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let noProgressCount = try container.decode(Int.self, forKey: .noProgressCount)
        guard (0...79).contains(noProgressCount) else {
            throw DecodingError.dataCorruptedError(
                forKey: .noProgressCount, in: container,
                debugDescription: "No-progress count out of range")
        }
        self.init(
            position: try container.decode(EncodedPosition.self, forKey: .position).position,
            sideToMove: try container.decode(Side.self, forKey: .sideToMove),
            noProgressCount: noProgressCount)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(EncodedPosition(position), forKey: .position)
        try container.encode(sideToMove, forKey: .sideToMove)
        try container.encode(noProgressCount, forKey: .noProgressCount)
    }
}

/// A position as its three sets of squares, one bit per square index. Decoding rejects sets the
/// board cannot show: a square held by both sides, or a king on an empty square.
private struct EncodedPosition: Codable {
    let light: UInt32
    let dark: UInt32
    let kings: UInt32

    init(_ position: Position) {
        light = position.light
        dark = position.dark
        kings = position.kings
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        light = try container.decode(UInt32.self, forKey: .light)
        dark = try container.decode(UInt32.self, forKey: .dark)
        kings = try container.decode(UInt32.self, forKey: .kings)
        guard light & dark == 0, kings & ~(light | dark) == 0 else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath, debugDescription: "Impossible position"))
        }
    }

    var position: Position {
        var position = Position()
        for square in Square.all {
            let bit = UInt32(1) << UInt32(square.index)
            let kind: PieceKind = kings & bit != 0 ? .king : .man
            if light & bit != 0 {
                position.place(Piece(side: .light, kind: kind), at: square)
            } else if dark & bit != 0 {
                position.place(Piece(side: .dark, kind: kind), at: square)
            }
        }
        return position
    }
}

/// An outcome as `"inProgress"`, `{"win": {"winner", "reason"}}` or `{"draw": reason}`.
private struct EncodedOutcome: Codable {
    let outcome: Outcome

    private enum CodingKeys: String, CodingKey {
        case win, draw
    }

    private enum WinKeys: String, CodingKey {
        case winner, reason
    }

    init(_ outcome: Outcome) {
        self.outcome = outcome
    }

    init(from decoder: any Decoder) throws {
        // A game in progress is the one outcome written as a plain string.
        if let name = try? decoder.singleValueContainer().decode(String.self) {
            guard name == "inProgress" else {
                throw Self.corrupted(decoder, "Unknown outcome \(name)")
            }
            outcome = .inProgress
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.win) {
            let win = try container.nestedContainer(keyedBy: WinKeys.self, forKey: .win)
            let winner = try win.decode(Side.self, forKey: .winner)
            switch try win.decode(String.self, forKey: .reason) {
            case "noMovesLeft": outcome = .win(winner: winner, reason: .noMovesLeft)
            case "resignation": outcome = .win(winner: winner, reason: .resignation)
            case let reason: throw Self.corrupted(decoder, "Unknown win reason \(reason)")
            }
        } else {
            switch try container.decode(String.self, forKey: .draw) {
            case "repetition": outcome = .draw(reason: .repetition)
            case "noProgress": outcome = .draw(reason: .noProgress)
            case let reason: throw Self.corrupted(decoder, "Unknown draw reason \(reason)")
            }
        }
    }

    func encode(to encoder: any Encoder) throws {
        switch outcome {
        case .inProgress:
            var container = encoder.singleValueContainer()
            try container.encode("inProgress")
        case .win(let winner, let reason):
            var container = encoder.container(keyedBy: CodingKeys.self)
            var win = container.nestedContainer(keyedBy: WinKeys.self, forKey: .win)
            try win.encode(winner, forKey: .winner)
            try win.encode(reason == .noMovesLeft ? "noMovesLeft" : "resignation", forKey: .reason)
        case .draw(let reason):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(reason == .repetition ? "repetition" : "noProgress", forKey: .draw)
        }
    }

    private static func corrupted(_ decoder: any Decoder, _ description: String) -> DecodingError {
        .dataCorrupted(
            DecodingError.Context(codingPath: decoder.codingPath, debugDescription: description))
    }
}
