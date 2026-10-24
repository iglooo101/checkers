import Foundation
import Testing

@testable import checkers

/// The stored settings and `AppSettings` (specs/007-settings-themes-sound-and-rules/contracts/
/// settings-and-sound.md, "Stored settings" and "Applying a change").
struct SettingsStoreTests {
    /// Runs `body` with a `UserDefaults` suite of its own, removed afterwards.
    static func withSuite(_ body: (UserDefaults, String) throws -> Void) throws {
        let name = "SettingsStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        try body(defaults, name)
    }

    /// Every combination of the three settings.
    static let combinations: [SettingsValues] = BoardTheme.allCases.flatMap { theme in
        [true, false].flatMap { sound in
            [true, false].map { hints in
                SettingsValues(boardTheme: theme, soundEffects: sound, moveHints: hints)
            }
        }
    }

    @Test(
        "FR-SET-02 FR-SET-04 FR-AID-04: with nothing stored, the settings are Classic, sound on, hints on"
    )
    func defaults() throws {
        #expect(
            SettingsValues.defaults
                == SettingsValues(boardTheme: .classic, soundEffects: true, moveHints: true))
        try Self.withSuite { defaults, _ in
            #expect(UserDefaultsSettingsStore(defaults: defaults).load() == .defaults)
        }
        #expect(InMemorySettingsStore().load() == .defaults)
    }

    @Test("FR-SET-03: every combination of settings is stored and read back, under three keys")
    func roundTrip() throws {
        for values in Self.combinations {
            try Self.withSuite { defaults, name in
                UserDefaultsSettingsStore(defaults: defaults).save(values)
                #expect(UserDefaultsSettingsStore(defaults: defaults).load() == values)
                let stored = try #require(defaults.persistentDomain(forName: name))
                #expect(Set(stored.keys) == ["boardTheme", "soundEffects", "moveHints"])
                #expect(stored["boardTheme"] as? String == values.boardTheme.rawValue)
                #expect(stored["soundEffects"] as? Bool == values.soundEffects)
                #expect(stored["moveHints"] as? Bool == values.moveHints)
            }
            #expect(InMemorySettingsStore(values).load() == values)
        }
    }

    /// Stored objects that cannot be read, each with the setting that falls back to its default.
    static let unreadable: [(key: String, object: Any)] = [
        ("boardTheme", "wooden"), ("boardTheme", 42), ("boardTheme", true),
        ("soundEffects", "NO"), ("soundEffects", 3.5), ("soundEffects", 1),
        ("moveHints", "false"), ("moveHints", 0),
    ]

    /// Values that differ from the defaults in every setting, so a fallback shows.
    static let chosen = SettingsValues(boardTheme: .playful, soundEffects: false, moveHints: false)

    @Test("FR-005: an unreadable setting takes its default; the other two keep their stored values")
    func unreadableSettings() throws {
        for (key, object) in Self.unreadable {
            var expected = Self.chosen
            switch key {
            case "boardTheme": expected.boardTheme = .classic
            case "soundEffects": expected.soundEffects = true
            default: expected.moveHints = true
            }
            try Self.withSuite { defaults, _ in
                UserDefaultsSettingsStore(defaults: defaults).save(Self.chosen)
                // UserDefaults skips a write equal to the stored value, and 0 equals false.
                defaults.removeObject(forKey: key)
                defaults.set(object, forKey: key)
                #expect(
                    UserDefaultsSettingsStore(defaults: defaults).load() == expected,
                    "\(key) = \(object)")
            }
            let memory = InMemorySettingsStore(Self.chosen)
            var objects = memory.objects
            objects[key] = object
            #expect(
                InMemorySettingsStore(objects: objects).load() == expected, "\(key) = \(object)")
        }
    }

    @Test("FR-005: a missing setting takes its default; the others keep their stored values")
    func missingSettings() throws {
        try Self.withSuite { defaults, _ in
            defaults.set("modern", forKey: "boardTheme")
            #expect(
                UserDefaultsSettingsStore(defaults: defaults).load()
                    == SettingsValues(boardTheme: .modern, soundEffects: true, moveHints: true))
        }
        #expect(
            InMemorySettingsStore(objects: ["moveHints": false]).load()
                == SettingsValues(boardTheme: .classic, soundEffects: true, moveHints: false))
    }

    @Test("FR-005: an unreadable value stays stored until the player changes that setting")
    func unreadableValueIsKept() throws {
        try Self.withSuite { defaults, _ in
            defaults.set("wooden", forKey: "boardTheme")
            let store = UserDefaultsSettingsStore(defaults: defaults)
            var values = store.load()
            values.moveHints = false
            store.save(values)
            #expect(defaults.string(forKey: "boardTheme") == "wooden")
            #expect(defaults.object(forKey: "moveHints") as? Bool == false)
            values.boardTheme = .modern
            store.save(values)
            #expect(defaults.string(forKey: "boardTheme") == "modern")
        }
    }

    @Test("FR-SET-03: AppSettings starts with the stored values and saves each change at once")
    func appSettingsSavesEachChange() {
        let store = InMemorySettingsStore(Self.chosen)
        let settings = AppSettings(store: store)
        #expect(settings.values == Self.chosen)

        settings.boardTheme = .modern
        #expect(AppSettings(store: store).boardTheme == .modern)
        settings.soundEffects = true
        #expect(AppSettings(store: store).soundEffects)
        settings.moveHints = true
        #expect(AppSettings(store: store).moveHints)
        #expect(
            AppSettings(store: store).values
                == SettingsValues(boardTheme: .modern, soundEffects: true, moveHints: true))
    }

    @Test("FR-SET-02: the themes are Classic, Modern and Playful, stored by name")
    func themes() {
        #expect(BoardTheme.allCases == [.classic, .modern, .playful])
        #expect(BoardTheme.allCases.map(\.rawValue) == ["classic", "modern", "playful"])
    }
}
