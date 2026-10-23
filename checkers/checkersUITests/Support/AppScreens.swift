import XCTest

/// Finds the app's screens and controls by the accessibility identifiers in
/// `specs/003-game-experience/contracts/screens.md`.
extension XCUIApplication {
    /// The element with this accessibility identifier, whatever its type.
    @MainActor
    func element(_ identifier: String) -> XCUIElement {
        descendants(matching: .any)[identifier]
    }

    /// The board square with this name, such as "c3".
    @MainActor
    func square(_ name: String) -> XCUIElement {
        element("square.\(name)")
    }

    /// Goes from Home to a new two-player game.
    @MainActor
    func startTwoPlayerGame(file: StaticString = #filePath, line: UInt = #line) {
        let newGame = element("home.newGame")
        XCTAssertTrue(
            newGame.waitForExistence(timeout: 10), "Home did not appear", file: file, line: line)
        newGame.tap()
        let twoPlayers = buttons["Two players"]
        XCTAssertTrue(
            twoPlayers.waitForExistence(timeout: 5), "Setup did not appear", file: file, line: line)
        twoPlayers.tap()
        tapStart()
        XCTAssertTrue(
            element("game.turn").waitForExistence(timeout: 5), "The game did not start", file: file,
            line: line)
    }

    /// Goes from Home to a new game against the computer with these choices, such as "Easy" and
    /// "Light".
    @MainActor
    func startComputerGame(
        difficulty: String, side: String, file: StaticString = #filePath, line: UInt = #line
    ) {
        let newGame = element("home.newGame")
        XCTAssertTrue(
            newGame.waitForExistence(timeout: 10), "Home did not appear", file: file, line: line)
        newGame.tap()
        let computer = buttons["Computer"]
        XCTAssertTrue(
            computer.waitForExistence(timeout: 5), "Setup did not appear", file: file, line: line)
        computer.tap()
        scrolledTo(buttons[difficulty]).tap()
        scrolledTo(buttons[side]).tap()
        tapStart()
        XCTAssertTrue(
            element("game.turn").waitForExistence(timeout: 5), "The game did not start", file: file,
            line: line)
    }

    /// Taps Start in Game setup and, if a saved game makes the app ask "Abandon current game?",
    /// answers Abandon: earlier tests leave games saved
    /// (specs/006-saving-and-statistics/research.md R10).
    @MainActor
    func tapStart() {
        scrolledTo(element("setup.start")).tap()
        let abandon = alerts.buttons["Abandon"].firstMatch
        if abandon.waitForExistence(timeout: 1) {
            abandon.tap()
        }
    }

    /// Waits until the turn indicator's text starts with `prefix`.
    @MainActor
    func waitForTurn(
        startingWith prefix: String, timeout: TimeInterval = 5, file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let turn = element("game.turn")
        let predicate = NSPredicate(format: "label BEGINSWITH %@", prefix)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: turn)
        XCTAssertEqual(
            XCTWaiter().wait(for: [expectation], timeout: timeout), .completed,
            "The turn indicator never read \"\(prefix)…\"; it reads \"\(turn.label)\"", file: file,
            line: line)
    }

    /// Opens the game menu and chooses an item by its label, such as "Resign". System menus
    /// expose their items by label.
    @MainActor
    func chooseFromGameMenu(_ item: String, file: StaticString = #filePath, line: UInt = #line) {
        element("game.menu").tap()
        let button = buttons[item]
        XCTAssertTrue(
            button.waitForExistence(timeout: 3), "No \(item) in the game menu", file: file,
            line: line)
        button.tap()
    }

    /// Opens the game menu, reads whether Undo is enabled, and closes the menu again.
    @MainActor
    func isUndoEnabled(file: StaticString = #filePath, line: UInt = #line) -> Bool {
        element("game.menu").tap()
        let undo = buttons["Undo"]
        XCTAssertTrue(
            undo.waitForExistence(timeout: 3), "No Undo in the game menu", file: file, line: line)
        let enabled = undo.isEnabled
        // Close the menu by tapping near the bottom edge, below the board, where no control is;
        // the open menu covers the turn indicator.
        coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.97)).tap()
        XCTAssertTrue(
            element("game.menu").waitForExistence(timeout: 3), "The menu did not close",
            file: file, line: line)
        return enabled
    }

    /// Answers a confirmation alert by the label of one of its buttons.
    @MainActor
    func confirm(_ answer: String, file: StaticString = #filePath, line: UInt = #line) {
        // iOS exposes an alert's Cancel button more than once in the accessibility tree.
        let button = alerts.buttons[answer].firstMatch
        XCTAssertTrue(
            button.waitForExistence(timeout: 3), "No \(answer) button", file: file, line: line)
        button.tap()
    }

    /// Scrolls the current screen until an element exists, for long screens at large text sizes,
    /// where lists create rows only as they scroll into view. Returns the element.
    @MainActor
    @discardableResult
    func scrolledTo(_ element: XCUIElement, attempts: Int = 6) -> XCUIElement {
        var remaining = attempts
        while !element.exists && remaining > 0 {
            swipeUp()
            remaining -= 1
        }
        return element
    }

    /// Launches the app with one stored value replaced for this launch only, through a
    /// `UserDefaults` launch argument (specs/006-saving-and-statistics/research.md R10): `key`
    /// reads as the bytes of `text`. Writes during the launch go to the stored value, which the
    /// next launch without the argument reads.
    @MainActor
    func launch(replacing key: String, with text: String) {
        launch(replacing: [key: text])
    }

    /// Launches the app with several stored values replaced for this launch only, as
    /// `launch(replacing:with:)` does for one.
    @MainActor
    func launch(replacing values: KeyValuePairs<String, String>) {
        launchArguments = values.flatMap { key, text in
            let hex = text.utf8.map { String(format: "%02x", $0) }.joined()
            return ["-\(key)", "<\(hex)>"]
        }
        launch()
    }

    /// Taps one square and then another.
    @MainActor
    func move(_ from: String, _ to: String) {
        square(from).tap()
        square(to).tap()
    }
}

/// Stored values for `launch(replacing:with:)`, in the format of
/// specs/006-saving-and-statistics/contracts/saved-game.md.
enum StoredValues {
    /// A version 1 record with no game at any level: Statistics shows its empty state.
    static let emptyRecord = """
        {"version": 1, "easy": {"wins": 0, "losses": 0, "draws": 0},
         "medium": {"wins": 0, "losses": 0, "draws": 0},
         "hard": {"wins": 0, "losses": 0, "draws": 0}}
        """
}
