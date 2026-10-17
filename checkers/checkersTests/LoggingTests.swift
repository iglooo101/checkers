import Foundation
import Testing

@testable import checkers

struct LoggingTests {
    @Test("US5: logs use the bundle identifier as subsystem")
    func subsystemIsBundleIdentifier() {
        #expect(Log.subsystem == Bundle.main.bundleIdentifier)
        #expect(Log.Category.app.rawValue == "app")
    }
}
