import XCTest

/// The sound effects switch in the running app (specs/007-settings-themes-sound-and-rules/
/// spec.md, US4). Settings outlive each test, so a test that turns sound off turns it back on.
final class US4SoundUITests: XCTestCase {
    /// FR-SET-01 FR-SET-04: Settings shows the switch on, and it turns off and on.
    @MainActor
    func testUS4_soundSwitch() {
        let app = XCUIApplication()
        app.launch(settings: ["soundEffects": "<true/>"])
        app.openSettingsFromHome()
        XCTAssertEqual(app.switchValue("settings.soundEffects"), true)
        app.setSwitch("settings.soundEffects", isOn: false)
        XCTAssertEqual(app.switchValue("settings.soundEffects"), false)
        app.setSwitch("settings.soundEffects", isOn: true)
    }

    /// FR-SET-03: sound effects turned off stay off after the app is closed and opened again.
    @MainActor
    func testUS4_soundKeptAfterRelaunch() {
        let app = XCUIApplication()
        app.launch()
        app.openSettingsFromHome()
        app.setSwitch("settings.soundEffects", isOn: false)

        app.terminate()
        app.launch()
        app.openSettingsFromHome()
        XCTAssertEqual(app.switchValue("settings.soundEffects"), false)
        app.setSwitch("settings.soundEffects", isOn: true)
        XCTAssertEqual(app.switchValue("settings.soundEffects"), true)
    }
}
