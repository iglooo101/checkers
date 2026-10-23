import XCTest

final class US7NavigationUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    /// FR-GAME-06: the game menu offers Undo, Resign, Rules, Settings and Home, and the game
    /// screen has no back button that would leave without asking.
    @MainActor
    func testUS7_menuOffersEverything() {
        let app = XCUIApplication()
        app.launch()
        app.startTwoPlayerGame()
        XCTAssertFalse(app.navigationBars.buttons["BackButton"].exists)
        app.element("game.menu").tap()
        for item in ["Undo", "Resign", "Rules", "Settings", "Home"] {
            XCTAssertTrue(app.buttons[item].waitForExistence(timeout: 3), "No \(item) in the menu")
        }
    }

    /// FR-NAV-04: Rules and Settings from the game menu return to the same position.
    @MainActor
    func testUS7_rulesAndSettingsReturnToTheGame() {
        let app = XCUIApplication()
        app.launch()
        app.startTwoPlayerGame()
        app.move("c3", "d4")
        for item in ["Rules", "Settings"] {
            app.chooseFromGameMenu(item)
            XCTAssertTrue(app.element("placeholder.message").waitForExistence(timeout: 3))
            app.navigationBars.buttons.firstMatch.tap()
            XCTAssertTrue(app.element("game.turn").waitForExistence(timeout: 3))
            XCTAssertEqual(app.square("d4").label, "d4, Light man")
            XCTAssertEqual(app.element("game.turn").label, "Dark to move")
        }
    }

    /// FR-NAV-03 (E5 FR-010): Home during a game returns at once, and Continue brings the same
    /// game back.
    @MainActor
    func testUS7_homeKeepsTheGame() {
        let app = XCUIApplication()
        app.launch()
        app.startTwoPlayerGame()
        app.move("c3", "d4")

        app.chooseFromGameMenu("Home")
        let resume = app.element("home.continue")
        XCTAssertTrue(resume.waitForExistence(timeout: 3))
        resume.tap()
        XCTAssertEqual(app.square("d4").label, "d4, Light man")
        XCTAssertEqual(app.element("game.turn").label, "Dark to move")
    }

    /// FR-NAV-02, FR-003: Home's Statistics opens its placeholder screen and returns.
    @MainActor
    func testUS7_placeholdersFromHome() {
        let app = XCUIApplication()
        app.launch()
        let statistics = app.element("home.statistics")
        XCTAssertTrue(statistics.waitForExistence(timeout: 10))
        statistics.tap()
        XCTAssertEqual(
            app.element("placeholder.message").label,
            "Your wins, losses and draws against the computer will appear here.")
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.element("home.newGame").waitForExistence(timeout: 3))
    }

    /// FR-A11Y-04 (in part): at the largest accessibility text size every control can still be
    /// reached and the board fits.
    @MainActor
    func testUS7_largestTextSize() {
        let app = XCUIApplication()
        app.launchArguments += [
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
        ]
        app.launch()
        for identifier in ["home.newGame", "home.statistics", "home.rules", "home.settings"] {
            XCTAssertTrue(app.scrolledTo(app.element(identifier)).isHittable, "\(identifier)")
        }
        app.swipeDown()
        app.element("home.newGame").tap()
        app.buttons["Two players"].tap()
        let start = app.scrolledTo(app.element("setup.start"))
        XCTAssertTrue(start.isHittable)
        start.tap()

        XCTAssertTrue(app.element("game.turn").waitForExistence(timeout: 5))
        XCTAssertTrue(app.element("game.menu").isHittable)
        XCTAssertTrue(app.windows.firstMatch.frame.contains(app.element("board").frame))

        app.chooseFromGameMenu("Resign")
        app.confirm("Resign")
        XCTAssertTrue(app.element("result.playAgain").waitForExistence(timeout: 3))
        XCTAssertTrue(app.element("result.playAgain").isHittable)
        XCTAssertTrue(app.element("result.home").isHittable)
    }
}
