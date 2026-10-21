import Foundation
import Testing

@testable import checkers

struct LoggingTests {
    @Test("US5: logs use the bundle identifier as subsystem")
    func subsystemIsBundleIdentifier() {
        #expect(Log.subsystem == Bundle.main.bundleIdentifier)
        #expect(Log.Category.app.rawValue == "app")
    }

    @Test("Each feature logs under its own category: app, game and setup")
    func featureCategories() {
        #expect(Log.Category.allCases.map(\.rawValue) == ["app", "game", "setup"])
        _ = [Log.app, Log.game, Log.setup]
    }
}
