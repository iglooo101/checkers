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

    /// FR-SETUP-08: at the default text size every choice is on screen without scrolling, with
    /// Difficulty and Side on one line each.
    @MainActor
    func testUS6_choicesFitWithoutScrolling() {
        let app = XCUIApplication()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryL"]
        app.launch()
        openSetup(in: app)
        app.buttons["Computer"].tap()

        let window = app.windows.firstMatch.frame
        let choices = [
            "Computer", "Two players", "Easy", "Medium", "Hard", "Light", "Dark", "Random",
        ]
        for name in choices {
            let choice = app.buttons[name]
            XCTAssertTrue(choice.waitForExistence(timeout: 3), name)
            XCTAssertTrue(choice.isHittable, name)
            XCTAssertTrue(window.contains(choice.frame), name)
        }
        XCTAssertEqual(
            app.buttons["Easy"].frame.midY, app.buttons["Hard"].frame.midY, accuracy: 1)
        XCTAssertEqual(
            app.buttons["Light"].frame.midY, app.buttons["Random"].frame.midY, accuracy: 1)
    }

    /// FR-SETUP-08: at the largest text size the choices stay rows, each with its full text.
    @MainActor
    func testUS6_largestTextKeepsChoicesInRows() {
        let app = XCUIApplication()
        app.launchArguments += [
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
        ]
        app.launch()
        openSetup(in: app)
        app.buttons["Computer"].tap()

        let easy = app.scrolledTo(app.buttons["Easy"])
        let medium = app.scrolledTo(app.buttons["Medium"])
        XCTAssertTrue(easy.exists && medium.exists)
        XCTAssertGreaterThanOrEqual(medium.frame.minY, easy.frame.maxY - 1)
    }

    @MainActor
    private func openSetup(in app: XCUIApplication) {
        let newGame = app.element("home.newGame")
        XCTAssertTrue(newGame.waitForExistence(timeout: 10))
        newGame.tap()
        XCTAssertTrue(app.buttons["Computer"].waitForExistence(timeout: 5))
    }
}
