import XCTest

final class US6SetupUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    /// FR-SETUP-02, FR-SETUP-03 (E4 FR-001, FR-003): Computer offers difficulty and side and can
    /// start, and the choices of the game started are remembered across a relaunch.
    @MainActor
    func testUS6_computerChoicesRemembered() {
        let app = XCUIApplication()
        app.launch()
        openSetup(in: app)

        app.buttons["Computer"].tap()
        app.scrolledTo(app.buttons["Hard"]).tap()
        app.scrolledTo(app.buttons["Dark"]).tap()
        XCTAssertFalse(app.element("setup.computerNote").exists)
        XCTAssertTrue(app.scrolledTo(app.element("setup.start")).isEnabled)
        app.tapStart()
        XCTAssertTrue(app.element("game.turn").waitForExistence(timeout: 5))

        app.terminate()
        app.launch()
        openSetup(in: app)
        XCTAssertTrue(app.buttons["Computer"].isSelected)
        XCTAssertTrue(app.scrolledTo(app.buttons["Hard"]).isSelected)
        XCTAssertTrue(app.scrolledTo(app.buttons["Dark"]).isSelected)

        app.swipeDown()
        app.swipeDown()
        app.buttons["Two players"].tap()
        XCTAssertFalse(app.buttons["Hard"].exists)
        XCTAssertTrue(app.scrolledTo(app.element("setup.start")).isEnabled)
    }

    /// FR-SETUP-07: with Computer chosen, whose rows reach furthest, Start is on screen without
    /// scrolling, at the default and at the largest text size.
    @MainActor
    func testUS6_startStaysOnScreen() {
        for size in ["UICTContentSizeCategoryL", "UICTContentSizeCategoryAccessibilityXXXL"] {
            let app = XCUIApplication()
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", size]
            app.launch()
            openSetup(in: app)
            app.buttons["Computer"].tap()

            let start = app.element("setup.start")
            XCTAssertTrue(start.waitForExistence(timeout: 3), size)
            XCTAssertTrue(start.isHittable, size)
            XCTAssertTrue(app.windows.firstMatch.frame.contains(start.frame), size)
        }
    }

    @MainActor
    private func openSetup(in app: XCUIApplication) {
        let newGame = app.element("home.newGame")
        XCTAssertTrue(newGame.waitForExistence(timeout: 10))
        newGame.tap()
        XCTAssertTrue(app.buttons["Computer"].waitForExistence(timeout: 5))
    }
}
