import Foundation
import OSLog

/// Keeps the record (FR-020). Injected so tests and previews use an in-memory store
/// (Constitution II.3; contracts/saved-game.md, "Stores").
protocol RecordStore: AnyObject {
    /// The stored record, an empty one when none is stored, or `.unreadable`.
    func load() throws(RecordError) -> Record
    /// Replaces the record.
    func save(_ record: Record)
}

/// Keeps the record on the device in `UserDefaults`, as one JSON value (research R2).
final class UserDefaultsRecordStore: RecordStore {
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults, key: String = "record") {
        self.defaults = defaults
        self.key = key
    }

    func load() throws(RecordError) -> Record {
        guard let data = defaults.data(forKey: key) else { return Record() }
        return try Record.decoding(data)
    }

    func save(_ record: Record) {
        do {
            defaults.set(try JSONEncoder().encode(record), forKey: key)
        } catch {
            Log.storage.error("Could not store the record: \(String(describing: error))")
        }
    }
}

/// Keeps the record in memory only, for tests and previews. It holds the encoded bytes, so it
/// reads them exactly as the device store does, and it can be given damaged bytes.
final class InMemoryRecordStore: RecordStore {
    private var data: Data?

    init(data: Data? = nil) {
        self.data = data
    }

    convenience init(_ record: Record) {
        self.init()
        save(record)
    }

    func load() throws(RecordError) -> Record {
        guard let data else { return Record() }
        return try Record.decoding(data)
    }

    func save(_ record: Record) {
        do {
            data = try JSONEncoder().encode(record)
        } catch {
            Log.storage.error("Could not store the record: \(String(describing: error))")
        }
    }
}
