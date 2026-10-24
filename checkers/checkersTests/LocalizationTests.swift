import Foundation
import Testing

@testable import checkers

struct LocalizationTests {
    /// Every user-facing string in `specs/003-game-experience/contracts/screens.md` and the later
    /// slices' screen contracts.
    static let screenStrings: Set<String> = Set([
        // Home
        "Checkers", "New game", "Statistics", "Rules", "Settings",
        // Setup
        "Opponent", "Computer", "Two players", "Difficulty", "Easy", "Medium", "Hard", "Side",
        "Light", "Dark", "Random", "Start",
        // Game screen
        "Light to move", "Dark to move", "Light to move · capture required",
        "Dark to move · capture required", "A capture is required.", "Game menu", "Undo", "Resign",
        "Home", "Resign as Light?", "Resign as Dark?", "Cancel",
        "%@, empty", "%@, Light man", "%@, Light king", "%@, Dark man", "%@, Dark king",
        // Square descriptions with states (specs/004-accessibility/contracts/announcements.md)
        "%@, empty, legal target", "%@, Light man, can move", "%@, Light man, selected",
        "%@, Light king, can move", "%@, Light king, selected", "%@, Dark man, can move",
        "%@, Dark man, selected", "%@, Dark king, can move", "%@, Dark king, selected",
        // VoiceOver announcements (specs/004-accessibility/contracts/announcements.md)
        "%@ %@", "Light %@ to %@.", "Light %@ to %@, crowned.", "Light captures %@.",
        "Light captures %@, crowned on %@.", "Dark %@ to %@.", "Dark %@ to %@, crowned.",
        "Dark captures %@.", "Dark captures %@, crowned on %@.", "Jump again.", "Move undone.",
        "Light to move.", "Dark to move.", "Light to move, capture required.",
        "Dark to move, capture required.",
        // The computer's turn (specs/005-computer-opponent/contracts/computer-turn.md)
        "Light is thinking…", "Dark is thinking…",
        // Result panel
        "Light wins: no moves left", "Dark wins: no moves left", "Light resigned", "Dark resigned",
        "Draw by repetition", "Draw by no progress", "Play again",
        // Saving and statistics (specs/006-saving-and-statistics/contracts/screens.md)
        "Continue", "Abandon current game?", "Starting a new game discards the game in progress.",
        "Abandon", "No games yet.", "Finish a game against the computer to start your record.",
        "%lld wins", "%lld losses", "%lld draws", "Easy: %@, %@, %@", "Medium: %@, %@, %@",
        "Hard: %@, %@, %@", "Your previous game couldn't be restored.",
        "Your record couldn't be restored and starts again from zero.", "OK",
        // Settings (specs/007-settings-themes-sound-and-rules/contracts/screens.md)
        "Board theme", "Classic", "Modern", "Playful", "Game", "Move hints",
        "Rings the pieces that can move and dots the squares the selected piece can go to.",
        // Rules (specs/007-settings-themes-sound-and-rules/contracts/rules-content.md): the
        // menu illustration's items; the titles, texts and descriptions are `rulesStrings`.
        "Undo", "Resign",
    ]).union(rulesStrings)

    /// The Rules screen's titles, texts and picture descriptions, which `US2RulesTests` checks
    /// word for word against contracts/rules-content.md.
    static let rulesStrings = Set(
        RulesContent.sections.flatMap { section in
            [section.title.key, section.text.key] + section.pictures.map(\.description.key)
        })

    /// Reads the source catalog rather than the compiled string table, which may omit untranslated
    /// source-language keys. `scripts/check-string-catalog.sh` covers completeness in CI.
    static func catalogKeys() throws -> Set<String> {
        let catalogURL = URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "checkers/Localizable.xcstrings")
        let data = try Data(contentsOf: catalogURL)
        let catalog = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        return Set((catalog["strings"] as? [String: Any] ?? [:]).keys)
    }

    @Test("US7 FR-PLAT-03: every user-facing string comes from the string catalog")
    func catalogListsUserFacingStrings() throws {
        let keys = try Self.catalogKeys()
        let missing = Self.screenStrings.subtracting(keys)
        #expect(missing.isEmpty, "Missing: \(missing.sorted())")
    }

    @Test("US7 FR-006: the web prototype's strings are gone from the catalog")
    func prototypeStringsRemoved() throws {
        // "Classic", "Modern" and "Playful" are the board themes' names since
        // specs/007-settings-themes-sound-and-rules (US3).
        let leftovers = try Self.catalogKeys().intersection(["Play", "Screen"])
        #expect(leftovers.isEmpty, "Still in the catalog: \(leftovers.sorted())")
    }
}
