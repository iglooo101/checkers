import Foundation
import Testing

struct PrivacyManifestTests {
    @Test("US5: privacy manifest declares no tracking and no collected data")
    func manifestDeclaresNothingCollected() throws {
        let url = try #require(
            Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy")
        )
        let data = try Data(contentsOf: url)
        let manifest = try #require(
            PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        )

        #expect(manifest["NSPrivacyTracking"] as? Bool == false)
        #expect((manifest["NSPrivacyTrackingDomains"] as? [Any])?.isEmpty == true)
        #expect((manifest["NSPrivacyCollectedDataTypes"] as? [Any])?.isEmpty == true)
        #expect((manifest["NSPrivacyAccessedAPITypes"] as? [Any])?.isEmpty == true)
    }
}
