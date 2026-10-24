import Foundation
import OSLog

/// The player's three settings (FR-001; specs/007-settings-themes-sound-and-rules/contracts/
/// settings-and-sound.md, "Stored settings").
nonisolated struct SettingsValues: Equatable, Sendable {
    var boardTheme: BoardTheme
    var soundEffects: Bool
    var moveHints: Bool

    /// Classic, sound effects on and move hints on (FR-SET-02, FR-SET-04, FR-AID-04).
    static let defaults = SettingsValues(boardTheme: .classic, soundEffects: true, moveHints: true)

    /// The stored keys, one per setting (research R1).
    enum Key {
        static let boardTheme = "boardTheme"
        static let soundEffects = "soundEffects"
        static let moveHints = "moveHints"
    }

    /// Reads each setting on its own from stored objects: a missing one takes its default, and so
    /// does one of the wrong type or an unknown theme, which is logged without its value
    /// (FR-005).
    static func reading(_ object: (String) -> Any?) -> SettingsValues {
        var values = SettingsValues.defaults
        if let stored = object(Key.boardTheme) {
            if let name = stored as? String, let theme = BoardTheme(rawValue: name) {
                values.boardTheme = theme
            } else {
                logUnreadable(Key.boardTheme)
            }
        }
        values.soundEffects =
            boolean(object(Key.soundEffects), key: Key.soundEffects)
            ?? values.soundEffects
        values.moveHints = boolean(object(Key.moveHints), key: Key.moveHints) ?? values.moveHints
        return values
    }

    /// A stored boolean, or `nil` when none is stored or the value is not a boolean. Numbers
    /// such as 1 or 3.5 are not booleans, though Foundation would convert them.
    private static func boolean(_ stored: Any?, key: String) -> Bool? {
        guard let stored else { return nil }
        guard let number = stored as? NSNumber, CFGetTypeID(number) == CFBooleanGetTypeID() else {
            logUnreadable(key)
            return nil
        }
        return number.boolValue
    }

    private static func logUnreadable(_ key: String) {
        Log.settings.error(
            "Stored setting \(key, privacy: .public) is unreadable; using its default")
    }
}

/// Keeps the settings (FR-004). Injected so tests and previews use an in-memory store
/// (Constitution II.3).
protocol SettingsStore: AnyObject {
    /// The stored settings; each one missing or unreadable takes its default (FR-005).
    func load() -> SettingsValues
    /// Stores the settings, writing only those that changed since the last load or save, so an
    /// unreadable value stays as it is until the player changes that setting.
    func save(_ values: SettingsValues)
}

/// Keeps the settings on the device in `UserDefaults`, one key per setting (research R1).
final class UserDefaultsSettingsStore: SettingsStore {
    private let defaults: UserDefaults
    /// The values last loaded or saved.
    private var known: SettingsValues?

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    func load() -> SettingsValues {
        let values = SettingsValues.reading { defaults.object(forKey: $0) }
        known = values
        return values
    }

    func save(_ values: SettingsValues) {
        if values.boardTheme != known?.boardTheme {
            defaults.set(values.boardTheme.rawValue, forKey: SettingsValues.Key.boardTheme)
        }
        if values.soundEffects != known?.soundEffects {
            defaults.set(values.soundEffects, forKey: SettingsValues.Key.soundEffects)
        }
        if values.moveHints != known?.moveHints {
            defaults.set(values.moveHints, forKey: SettingsValues.Key.moveHints)
        }
        known = values
    }
}

/// Keeps the settings in memory only, for tests and previews. It holds stored objects as
/// `UserDefaults` would and reads them the same way, so it can be given unreadable ones.
final class InMemorySettingsStore: SettingsStore {
    /// The stored objects by key.
    private(set) var objects: [String: Any]

    init(objects: [String: Any] = [:]) {
        self.objects = objects
    }

    convenience init(_ values: SettingsValues) {
        self.init()
        save(values)
    }

    func load() -> SettingsValues {
        SettingsValues.reading { objects[$0] }
    }

    func save(_ values: SettingsValues) {
        objects[SettingsValues.Key.boardTheme] = values.boardTheme.rawValue
        objects[SettingsValues.Key.soundEffects] = values.soundEffects
        objects[SettingsValues.Key.moveHints] = values.moveHints
    }
}
