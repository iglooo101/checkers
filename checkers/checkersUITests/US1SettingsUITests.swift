import XCTest

/// Settings and move hints in the running app (specs/007-settings-themes-sound-and-rules/spec.md,
/// US1). Settings outlive each test, so a test that changes one puts it back (research R10).
final class US1SettingsUITests: XCTestCase {
    /// Research R10 in the simulator: a typed launch argument sets a setting for one launch.
    @MainActor
    func testUS1_launchArgumentSetsHints() {
        let app = XCUIApplication()
        app.launch(settings: ["moveHints": "<false/>"])
        app.openSettingsFromHome()
        XCTAssertEqual(app.switchValue("settings.moveHints"), false)
    }

    /// FR-SET-01 FR-NAV-02: Home's Settings shows the move hints switch and returns Home. The game
    /// menu's Settings is `testUS7_rulesAndSettingsReturnToTheGame`.
    @MainActor
    func testUS1_settingsFromHome() {
        let app = XCUIApplication()
        app.launch()
        app.openSettingsFromHome()
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.element("home.newGame").waitForExistence(timeout: 3))
    }

    /// FR-SET-03: a setting turned off is still off after the app is closed and opened again.
    @MainActor
    func testUS1_hintsKeptAfterRelaunch() {
        let app = XCUIApplication()
        app.launch()
        app.openSettingsFromHome()
        app.setSwitch("settings.moveHints", isOn: false)

        app.terminate()
        app.launch()
        app.openSettingsFromHome()
        XCTAssertEqual(app.switchValue("settings.moveHints"), false)
        app.setSwitch("settings.moveHints", isOn: true)
        XCTAssertEqual(app.switchValue("settings.moveHints"), true)
    }
}
