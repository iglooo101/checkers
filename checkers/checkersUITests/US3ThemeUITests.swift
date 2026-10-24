import XCTest

/// Board themes in the running app (specs/007-settings-themes-sound-and-rules/spec.md, US3).
/// Settings outlive each test, so a test that changes the theme puts Classic back.
final class US3ThemeUITests: XCTestCase {
    /// FR-SET-02: Settings offers the three themes, the stored one chosen.
    @MainActor
    func testUS3_themeChoices() {
        let app = XCUIApplication()
        app.launch(settings: ["boardTheme": "classic"])
        app.openSettingsFromHome()
        XCTAssertTrue(app.themeRow("classic").isSelected)
        XCTAssertFalse(app.themeRow("modern").isSelected)
        XCTAssertFalse(app.themeRow("playful").isSelected)
    }

    /// FR-SET-03: a chosen theme is still chosen after the app is closed and opened again.
    @MainActor
    func testUS3_themeKeptAfterRelaunch() {
        let app = XCUIApplication()
        app.launch()
        app.openSettingsFromHome()
        app.themeRow("modern").tap()
        XCTAssertTrue(app.themeRow("modern").isSelected)

        app.terminate()
        app.launch()
        app.openSettingsFromHome()
        XCTAssertTrue(app.themeRow("modern").isSelected)
        app.themeRow("classic").tap()
        XCTAssertTrue(app.themeRow("classic").isSelected)
    }

    /// FR-GAME-07, a smoke test: a game in Playful shows its board and a selected piece. UI tests
    /// cannot see colors; `US3ThemeTests` and `US4ContrastTests` check them.
    @MainActor
    func testUS3_themedGame() {
        let app = XCUIApplication()
        app.launch(settings: ["boardTheme": "playful"])
        app.startTwoPlayerGame()
        app.square("c3").tap()
        XCTAssertTrue(app.element("board").exists)
        XCTAssertEqual(app.square("c3").label, "c3, Light man, selected")
    }
}

extension XCUIApplication {
    /// The Settings row of a theme, by its stored name, such as "modern".
    @MainActor
    func themeRow(_ name: String) -> XCUIElement {
        scrolledTo(descendants(matching: .any)["settings.theme.\(name)"].firstMatch)
    }
}
