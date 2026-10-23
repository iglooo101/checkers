import XCTest

/// Continuing where the player left off (specs/006-saving-and-statistics/spec.md, US1).
final class US1ContinueUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    /// The 32 dark squares, a1 to h8.
    static let squares = (1...8).flatMap { row in
        "abcdefgh".enumerated().compactMap { column, letter in
            (column + row - 1).isMultiple(of: 2) ? "\(letter)\(row)" : nil
        }
    }

    /// A two-player game in which Light, to move, can jump c3–e5 and then e5–g7.
    static let doubleJump = """
        {"version": 1, "setup": {"opponent": "twoPlayers", "difficulty": "easy", "side": "light"},
         "playerSide": null,
         "state": {"position": {"light": 640, "dark": 20979712, "kings": 0}, "sideToMove": "light",
          "chainSquare": null, "outcome": "inProgress", "noProgressCount": 0, "turns": []}}
        """

    /// FR-SAVE-01 to FR-SAVE-03, FR-NAV-02, SC-002: a game left for Home survives closing the
    /// app, and Continue brings it back exactly, within a second.
    @MainActor
    func testUS1_continueAfterRelaunch() {
        let app = XCUIApplication()
        app.launch()
        app.startComputerGame(difficulty: "Easy", side: "Light")
        app.waitForTurn(startingWith: "Light to move")
        app.move("c3", "d4")
        XCTAssertTrue(app.square("d4").label.hasPrefix("d4, Light man"))
        app.waitForTurn(startingWith: "Light to move")
        let labels = Self.squares.map { app.square($0).label }

        app.chooseFromGameMenu("Home")
        XCTAssertTrue(app.element("home.continue").waitForExistence(timeout: 3))
        app.terminate()
        app.launch()
        let resume = app.element("home.continue")
        XCTAssertTrue(resume.waitForExistence(timeout: 10))
        resume.tap()
        XCTAssertTrue(app.element("board").waitForExistence(timeout: 1))
        XCTAssertEqual(Self.squares.map { app.square($0).label }, labels)
        XCTAssertTrue(app.element("game.turn").label.hasPrefix("Light to move"))
    }

    /// FR-SAVE-01: a game is saved when the app goes to the background, here in the middle of a
    /// capture chain, which Continue resumes with the same piece.
    @MainActor
    func testUS1_chainSurvivesBackground() {
        let app = XCUIApplication()
        app.launch(replacing: "savedGame", with: Self.doubleJump)
        let resume = app.element("home.continue")
        XCTAssertTrue(resume.waitForExistence(timeout: 10))
        resume.tap()
        app.move("c3", "e5")
        XCTAssertEqual(app.square("e5").label, "e5, Light man, selected")

        XCUIDevice.shared.press(.home)
        XCTAssertTrue(app.wait(for: .runningBackground, timeout: 5))
        // The app learns it is in the background a moment after the system reports it; the
        // system gives it seconds before it may be ended.
        _ = XCTWaiter.wait(for: [XCTestExpectation(description: "In the background")], timeout: 2)
        app.terminate()
        app.launchArguments = []
        app.launch()
        XCTAssertTrue(resume.waitForExistence(timeout: 10))
        resume.tap()
        XCTAssertEqual(app.square("e5").label, "e5, Light man, selected")
        XCTAssertEqual(app.square("c3").label, "c3, empty")
        XCTAssertEqual(app.square("h2").label, "h2, Light man")
        XCTAssertEqual(app.square("g7").label, "g7, empty, legal target")
        app.square("g7").tap()
        XCTAssertEqual(app.square("g7").label, "g7, Light man")
        XCTAssertTrue(app.element("game.turn").label.hasPrefix("Dark to move"))
    }
}
