import XCTest

final class US6SetupUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    /// FR-SETUP-02, FR-SETUP-03, FR-011: Computer offers difficulty and side, cannot start yet,
    /// and its choices are remembered across a relaunch.
    @MainActor
    func testUS6_computerChoicesRemembered() {
        let app = XCUIApplication()
        app.launch()
        openSetup(in: app)

        app.buttons["Computer"].tap()
        app.scrolledTo(app.buttons["Hard"]).tap()
        app.scrolledTo(app.buttons["Dark"]).tap()
        XCTAssertTrue(app.scrolledTo(app.element("setup.computerNote")).exists)
        XCTAssertFalse(app.scrolledTo(app.element("setup.start")).isEnabled)

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
        XCTAssertFalse(app.element("setup.computerNote").exists)
        XCTAssertTrue(app.scrolledTo(app.element("setup.start")).isEnabled)
    }

    @MainActor
    private func openSetup(in app: XCUIApplication) {
        let newGame = app.element("home.newGame")
        XCTAssertTrue(newGame.waitForExistence(timeout: 10))
        newGame.tap()
        XCTAssertTrue(app.buttons["Computer"].waitForExistence(timeout: 5))
    }
}
