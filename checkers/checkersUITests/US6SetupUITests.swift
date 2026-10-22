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
        let start = app.scrolledTo(app.element("setup.start"))
        XCTAssertTrue(start.isEnabled)
        start.tap()
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

    @MainActor
    private func openSetup(in app: XCUIApplication) {
        let newGame = app.element("home.newGame")
        XCTAssertTrue(newGame.waitForExistence(timeout: 10))
        newGame.tap()
        XCTAssertTrue(app.buttons["Computer"].waitForExistence(timeout: 5))
    }
}
