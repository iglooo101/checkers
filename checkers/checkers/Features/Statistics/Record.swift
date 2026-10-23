import CheckersEngine
import Foundation
import OSLog

/// The player's wins, losses and draws against the computer at each difficulty (FR-016;
/// contracts/saved-game.md, "Format").
nonisolated struct Record: Codable, Equatable, Sendable {
    /// The results at one difficulty.
    nonisolated struct Tally: Codable, Equatable, Sendable {
        var wins = 0
        var losses = 0
        var draws = 0
    }

    /// The format this app writes and reads; a record of any other version is unreadable.
    static let currentVersion = 1

    let version: Int
    var easy: Tally
    var medium: Tally
    var hard: Tally

    init(easy: Tally = Tally(), medium: Tally = Tally(), hard: Tally = Tally()) {
        version = Self.currentVersion
        self.easy = easy
        self.medium = medium
        self.hard = hard
    }

    /// Whether no game has been recorded at any difficulty (FR-STAT-04).
    var isEmpty: Bool {
        self == Record()
    }

    /// The results at a difficulty.
    func tally(at difficulty: Difficulty) -> Tally {
        switch difficulty {
        case .easy: easy
        case .medium: medium
        case .hard: hard
        }
    }

    /// The record with one more result at the result's difficulty (FR-STAT-02).
    func adding(_ result: GameResult) -> Record {
        var tally = self.tally(at: result.difficulty)
        switch result.kind {
        case .win: tally.wins += 1
        case .loss: tally.losses += 1
        case .draw: tally.draws += 1
        }
        var record = self
        switch result.difficulty {
        case .easy: record.easy = tally
        case .medium: record.medium = tally
        case .hard: record.hard = tally
        }
        return record
    }

    /// The record in stored bytes, if it decodes and has this version.
    static func decoding(_ data: Data) throws(RecordError) -> Record {
        let record: Record
        do {
            record = try JSONDecoder().decode(Record.self, from: data)
        } catch {
            Log.storage.error("The record does not decode: \(String(describing: error))")
            throw .unreadable
        }
        guard record.version == currentVersion else {
            Log.storage.error("The record has version \(record.version)")
            throw .unreadable
        }
        return record
    }
}

/// How a finished game against the computer counts in the record, from the player's view
/// (contracts/saved-game.md, "Recording").
nonisolated struct GameResult: Equatable, Sendable {
    nonisolated enum Kind: Equatable, Sendable {
        case win, loss, draw
    }

    let difficulty: Difficulty
    let kind: Kind

    init(difficulty: Difficulty, kind: Kind) {
        self.difficulty = difficulty
        self.kind = kind
    }

    /// The result of a finished game against the computer: a win when the player's side wins, a
    /// loss when the computer's side does, by no moves left or by the player's resignation, and a
    /// draw for either draw. `nil` for a game in progress or a two-player game (FR-STAT-03).
    init?(outcome: Outcome, playerSide: Side?, difficulty: Difficulty) {
        guard let playerSide else { return nil }
        switch outcome {
        case .inProgress: return nil
        case .win(let winner, _): kind = winner == playerSide ? .win : .loss
        case .draw: kind = .draw
        }
        self.difficulty = difficulty
    }
}

/// Why the stored record cannot be read (FR-020).
nonisolated enum RecordError: Error, Equatable {
    /// It does not decode or has another version.
    case unreadable
}
