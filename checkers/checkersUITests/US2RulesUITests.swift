import XCTest

/// The Rules screen in the running app (specs/007-settings-themes-sound-and-rules/spec.md, US2).
final class US2RulesUITests: XCTestCase {
    /// FR-HELP-01 FR-HELP-02: Home's Rules shows the sections from the first to the last and
    /// returns Home.
    @MainActor
    func testUS2_rulesFromHome() {
        let app = XCUIApplication()
        app.launch()
        let rules = app.element("home.rules")
        XCTAssertTrue(rules.waitForExistence(timeout: 10))
        rules.tap()
        let title = app.element("rules.board.title")
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertEqual(title.label, "The board")
        XCTAssertTrue(app.element("rules.board.picture").exists)
        XCTAssertTrue(app.scrolledTo(app.element("rules.undoResign.picture"), attempts: 12).exists)
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.element("home.newGame").waitForExistence(timeout: 3))
    }

    /// FR-HELP-02 FR-NAV-04: the game menu's Rules, opened while the computer thinks, returns to
    /// the same game, and the computer's move follows.
    @MainActor
    func testUS2_rulesFromGameMenu() {
        let app = XCUIApplication()
        app.launch()
        app.startComputerGame(difficulty: "Easy", side: "Light")
        app.move("c3", "d4")
        app.chooseFromGameMenu("Rules")
        XCTAssertTrue(app.element("rules.board.title").waitForExistence(timeout: 5))
        app.navigationBars.buttons.firstMatch.tap()
        app.waitForTurn(startingWith: "Light to move", timeout: 10)
        XCTAssertTrue(app.square("d4").label.hasPrefix("d4, Light man"))
    }
}
