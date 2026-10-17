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
}
