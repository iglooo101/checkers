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
        element("setup.start").tap()
        XCTAssertTrue(
            element("game.turn").waitForExistence(timeout: 5), "The game did not start", file: file,
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

    /// Taps one square and then another.
    @MainActor
    func move(_ from: String, _ to: String) {
        square(from).tap()
        square(to).tap()
    }
}
