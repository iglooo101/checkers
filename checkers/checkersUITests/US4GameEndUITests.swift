import XCTest

final class US4GameEndUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    /// FR-END-02, FR-END-06, FR-END-07: resigning asks first; the result panel shows the outcome
    /// over the final board; Play again starts afresh and Home leaves.
    @MainActor
    func testUS4_resignAndPlayAgain() {
        let app = XCUIApplication()
        app.launch()
        app.startTwoPlayerGame()
        app.move("c3", "d4")

        app.chooseFromGameMenu("Resign")
        app.confirm("Cancel")
        XCTAssertEqual(app.element("game.turn").label, "Dark to move")
        XCTAssertFalse(app.element("result.panel").exists)

        app.chooseFromGameMenu("Resign")
        app.confirm("Resign")
        XCTAssertTrue(app.element("result.text").waitForExistence(timeout: 3))
        XCTAssertEqual(app.element("result.text").label, "Dark resigned")
        XCTAssertEqual(app.square("d4").label, "d4, Light man")

        app.element("result.playAgain").tap()
        XCTAssertEqual(app.element("game.turn").label, "Light to move")
        XCTAssertEqual(app.square("c3").label, "c3, Light man")
        XCTAssertFalse(app.element("result.panel").exists)

        app.chooseFromGameMenu("Resign")
        app.confirm("Resign")
        XCTAssertTrue(app.element("result.home").waitForExistence(timeout: 3))
        app.element("result.home").tap()
        XCTAssertTrue(app.element("home.newGame").waitForExistence(timeout: 3))
    }
}
