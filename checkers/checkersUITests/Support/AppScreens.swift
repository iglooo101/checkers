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

    /// Taps one square and then another.
    @MainActor
    func move(_ from: String, _ to: String) {
        square(from).tap()
        square(to).tap()
    }
}
