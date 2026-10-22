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
        XCTAssertFalse(app.isUndoEnabled(), "Undo should be unavailable at the start")

        app.move("c3", "d4")
        app.move("f6", "e5")
        app.chooseFromGameMenu("Undo")
        XCTAssertEqual(app.square("f6").label, "f6, Dark man, can move")
        XCTAssertEqual(app.element("game.turn").label, "Dark to move")
        app.chooseFromGameMenu("Undo")
        XCTAssertEqual(app.square("c3").label, "c3, Light man, can move")
        XCTAssertEqual(app.element("game.turn").label, "Light to move")
        XCTAssertFalse(app.isUndoEnabled(), "Undo should be unavailable back at the start")
    }
}
