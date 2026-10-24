import Foundation
import Testing

struct PrivacyManifestTests {
    @Test("US5 FR-PRIV-01: privacy manifest declares no tracking and no collected data")
    func manifestDeclaresNothingCollected() throws {
        let manifest = try Self.manifest()
        #expect(manifest["NSPrivacyTracking"] as? Bool == false)
        #expect((manifest["NSPrivacyTrackingDomains"] as? [Any])?.isEmpty == true)
        #expect((manifest["NSPrivacyCollectedDataTypes"] as? [Any])?.isEmpty == true)
    }

    @Test("US6 FR-SETUP-03: the manifest declares exactly the user-defaults API, reason CA92.1")
    func manifestDeclaresUserDefaults() throws {
        let apis = try #require(
            try Self.manifest()["NSPrivacyAccessedAPITypes"] as? [[String: Any]])
        #expect(apis.count == 1)
        #expect(
            apis.first?["NSPrivacyAccessedAPIType"] as? String
                == "NSPrivacyAccessedAPICategoryUserDefaults")
        #expect(apis.first?["NSPrivacyAccessedAPITypeReasons"] as? [String] == ["CA92.1"])
    }

    @Test("US4 FR-PRIV-02: the app asks for no permission")
    func noPermissionAsked() throws {
        let info = try #require(Bundle.main.infoDictionary)
        let usages = info.keys.filter { $0.hasSuffix("UsageDescription") }
        #expect(usages.isEmpty, "Usage descriptions: \(usages.sorted())")
    }

    private static func manifest() throws -> [String: Any] {
        let url = try #require(
            Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy")
        )
        let data = try Data(contentsOf: url)
        return try #require(
            PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        )
    }
}
