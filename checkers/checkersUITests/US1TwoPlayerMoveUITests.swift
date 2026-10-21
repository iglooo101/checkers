import XCTest

final class US1TwoPlayerMoveUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    /// FR-NAV-01, FR-NAV-02: the app opens on Home, whose four entries each open their screen.
    @MainActor
    func testUS1_homeOffersFourEntries() {
        let app = XCUIApplication()
        app.launch()
        for identifier in ["home.newGame", "home.statistics", "home.rules", "home.settings"] {
            XCTAssertTrue(
                app.element(identifier).waitForExistence(timeout: 10), "Missing \(identifier)")
        }
        for (identifier, title) in [
            ("home.statistics", "Statistics"), ("home.rules", "Rules"),
            ("home.settings", "Settings"),
        ] {
            app.element(identifier).tap()
            XCTAssertTrue(
                app.navigationBars[title].waitForExistence(timeout: 5), "No \(title) screen")
            app.navigationBars.buttons.firstMatch.tap()
            XCTAssertTrue(app.element("home.newGame").waitForExistence(timeout: 5))
        }
    }

    /// FR-MOVE-01, FR-GAME-02, FR-SND-04: a tapped move appears at once and passes the turn.
    @MainActor
    func testUS1_tapToMove() {
        let app = XCUIApplication()
        app.launch()
        app.startTwoPlayerGame()
        XCTAssertEqual(app.element("game.turn").label, "Light to move")
        XCTAssertEqual(app.square("c3").label, "c3, Light man")

        app.move("c3", "d4")

        // Read at once, without waiting: there is no animation to wait for.
        XCTAssertEqual(app.square("d4").label, "d4, Light man")
        XCTAssertEqual(app.square("c3").label, "c3, empty")
        XCTAssertEqual(app.element("game.turn").label, "Dark to move")
    }

    /// FR-PLAT-01, FR-GAME-01: the square board fits in the window and only the turn indicator
    /// shows text.
    @MainActor
    func testUS1_boardFitsAndShowsOnlyTheIndicator() {
        let app = XCUIApplication()
        app.launch()
        app.startTwoPlayerGame()

        let board = app.element("board").frame
        let window = app.windows.firstMatch.frame
        XCTAssertTrue(window.contains(board), "Board \(board) is outside the window \(window)")
        XCTAssertEqual(board.width, board.height, accuracy: 1)
        // The board element includes a 4-point frame on each side around the 8 squares.
        XCTAssertGreaterThanOrEqual((board.width - 8) / 8, 44, "Squares smaller than 44 points")
        XCTAssertEqual(app.staticTexts.allElementsBoundByIndex.map(\.identifier), ["game.turn"])
    }
}
