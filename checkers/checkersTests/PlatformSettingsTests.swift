import Foundation
import Testing

struct PlatformSettingsTests {
    @Test("US5: the app targets iPhone only, in portrait")
    func iPhoneOnlyPortrait() {
        let info = Bundle.main.infoDictionary ?? [:]

        #expect(info["UIDeviceFamily"] as? [Int] == [1])
        #expect(
            info["UISupportedInterfaceOrientations"] as? [String]
                == ["UIInterfaceOrientationPortrait"]
        )
        #expect(info["UISupportedInterfaceOrientations~ipad"] == nil)
        #expect(info["UISupportedInterfaceOrientations~iphone"] == nil)
    }

    @Test("US4 FR-016: the name under the icon is Checkers")
    func displayName() {
        #expect(Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String == "Checkers")
        #expect(
            Bundle.main.localizedInfoDictionary?["CFBundleDisplayName"] as? String == "Checkers"
        )
    }

    @Test("US4 FR-022: the app declares that it uses no non-exempt encryption")
    func encryptionDeclaration() {
        #expect(Bundle.main.infoDictionary?["ITSAppUsesNonExemptEncryption"] as? Bool == false)
    }

    @Test("US4 FR-017: the launch screen is the plain system background, as Home's")
    func plainLaunchScreen() throws {
        let launchScreen = try #require(
            Bundle.main.infoDictionary?["UILaunchScreen"] as? [String: Any]
        )

        #expect(launchScreen["UIImageName"] == nil)
        #expect(launchScreen["UIColorName"] == nil)
    }
}
