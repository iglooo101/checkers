import Foundation
import Testing

@testable import checkers

struct LocalizationTests {
    /// Every user-facing string in `specs/003-game-experience/contracts/screens.md`.
    static let screenStrings: Set<String> = [
        // Home and placeholders
        "Checkers", "New game", "Statistics", "Rules", "Settings",
        "Your wins, losses and draws against the computer will appear here.",
        "How to play American checkers will be explained here.",
        "Board theme, sound effects and move hints will be set here.",
        // Setup
        "Opponent", "Computer", "Two players", "Difficulty", "Easy", "Medium", "Hard", "Side",
        "Light", "Dark", "Random", "Games against the computer arrive in a later update.", "Start",
        // Game screen
        "Light to move", "Dark to move", "Light to move · capture required",
        "Dark to move · capture required", "A capture is required.", "Game menu", "Undo", "Resign",
        "Home", "Resign as Light?", "Resign as Dark?", "Cancel", "Leave this game?",
        "It can't be resumed yet.", "Leave",
        "%@, empty", "%@, Light man", "%@, Light king", "%@, Dark man", "%@, Dark king",
        // Result panel
        "Light wins: no moves left", "Dark wins: no moves left", "Light resigned", "Dark resigned",
        "Draw by repetition", "Draw by no progress", "Play again",
    ]

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
        let leftovers = try Self.catalogKeys().intersection(
            ["Classic", "Modern", "Play", "Playful", "Screen"])
        #expect(leftovers.isEmpty, "Still in the catalog: \(leftovers.sorted())")
    }
}
