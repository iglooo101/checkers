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

/// Why the stored record cannot be read (FR-020).
nonisolated enum RecordError: Error, Equatable {
    /// It does not decode or has another version.
    case unreadable
}
