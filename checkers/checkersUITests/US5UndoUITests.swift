import XCTest

final class US5UndoUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    /// FR-UNDO-01, FR-UNDO-02, FR-UNDO-06: Undo is unavailable at the start, takes back one turn at
    /// a time, and is unavailable again back at the start.
    @MainActor
    func testUS5_undoBackToStart() {
        let app = XCUIApplication()
        app.launch()
        app.startTwoPlayerGame()
        XCTAssertFalse(undoIsEnabled(in: app), "Undo should be unavailable at the start")

        app.move("c3", "d4")
        app.move("f6", "e5")
        app.chooseFromGameMenu("Undo")
        XCTAssertEqual(app.square("f6").label, "f6, Dark man, can move")
        XCTAssertEqual(app.element("game.turn").label, "Dark to move")
        app.chooseFromGameMenu("Undo")
        XCTAssertEqual(app.square("c3").label, "c3, Light man, can move")
        XCTAssertEqual(app.element("game.turn").label, "Light to move")
        XCTAssertFalse(undoIsEnabled(in: app), "Undo should be unavailable back at the start")
    }

    /// Opens the game menu, reads whether Undo is enabled, and closes the menu again.
    @MainActor
    private func undoIsEnabled(in app: XCUIApplication) -> Bool {
        app.element("game.menu").tap()
        let undo = app.buttons["Undo"]
        XCTAssertTrue(undo.waitForExistence(timeout: 3), "No Undo in the game menu")
        let enabled = undo.isEnabled
        // Close the menu by tapping near the bottom edge, below the board, where no control is;
        // the open menu covers the turn indicator.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.97)).tap()
        XCTAssertTrue(
            app.element("game.menu").waitForExistence(timeout: 3), "The menu did not close")
        return enabled
    }
}
