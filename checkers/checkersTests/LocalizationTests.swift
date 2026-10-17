import Foundation
import Testing

@testable import checkers

struct LocalizationTests {
    /// Reads the source catalog rather than the compiled string table, which may omit untranslated
    /// source-language keys. `scripts/check-string-catalog.sh` covers completeness in CI.
    @Test("US5: user-facing strings come from the string catalog")
    func catalogListsUserFacingStrings() throws {
        let catalogURL = URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "checkers/Localizable.xcstrings")
        let data = try Data(contentsOf: catalogURL)
        let catalog = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let keys = Set((catalog["strings"] as? [String: Any] ?? [:]).keys)

        let expected = Set(Screen.all.map(\.title.key)).union(["Screen"])
        #expect(expected.isSubset(of: keys), "Missing: \(expected.subtracting(keys).sorted())")
    }
}
