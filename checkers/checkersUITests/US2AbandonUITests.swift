import XCTest

/// Starting a new game without losing one by accident (specs/006-saving-and-statistics/spec.md,
/// US2).
final class US2AbandonUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    /// FR-SETUP-04: with a saved game, Start asks "Abandon current game?"; Cancel keeps setup and
    /// the saved game, Abandon starts the new game, which becomes the one Continue leads to.
    @MainActor
    func testUS2_abandonQuestion() {
        let app = XCUIApplication()
        app.launch()
        app.startTwoPlayerGame()
        app.move("c3", "d4")
        app.chooseFromGameMenu("Home")
        XCTAssertTrue(app.element("home.continue").waitForExistence(timeout: 3))

        app.element("home.newGame").tap()
        let twoPlayers = app.buttons["Two players"]
        XCTAssertTrue(twoPlayers.waitForExistence(timeout: 5))
        twoPlayers.tap()
        app.element("setup.start").tap()
        XCTAssertTrue(app.alerts["Abandon current game?"].waitForExistence(timeout: 3))
        app.confirm("Cancel")
        XCTAssertTrue(app.element("setup.start").waitForExistence(timeout: 3))
        XCTAssertFalse(app.element("game.turn").exists)

        app.element("setup.start").tap()
        app.confirm("Abandon")
        XCTAssertTrue(app.element("game.turn").waitForExistence(timeout: 5))
        XCTAssertEqual(app.square("c3").label, "c3, Light man, can move")
        XCTAssertEqual(app.square("d4").label, "d4, empty")

        app.chooseFromGameMenu("Home")
        let resume = app.element("home.continue")
        XCTAssertTrue(resume.waitForExistence(timeout: 3))
        resume.tap()
        XCTAssertEqual(app.square("c3").label, "c3, Light man, can move")
        XCTAssertEqual(app.element("game.turn").label, "Light to move")
    }
}
