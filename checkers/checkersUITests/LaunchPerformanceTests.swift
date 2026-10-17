import XCTest

/// Cold-launch timing (Constitution VII). Runs only in the Performance test plan: timing is
/// compared against the recorded local baseline and only reported in CI, while a launch that
/// errors still fails the run.
final class LaunchPerformanceTests: XCTestCase {
    @MainActor
    func testUS6_coldLaunchDuration() {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
