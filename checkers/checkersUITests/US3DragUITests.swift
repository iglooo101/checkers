import XCTest

final class US3DragUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    /// FR-MOVE-02: dragging a man onto a target moves it.
    @MainActor
    func testUS3_dragToMove() {
        let app = XCUIApplication()
        app.launch()
        app.startTwoPlayerGame()
        app.square("c3").press(forDuration: 0.2, thenDragTo: app.square("d4"))
        XCTAssertEqual(app.square("d4").label, "d4, Light man")
        XCTAssertEqual(app.element("game.turn").label, "Dark to move")
    }

    /// FR-MOVE-02: dropping a man on a square that is not a target returns it.
    @MainActor
    func testUS3_invalidDropReturns() {
        let app = XCUIApplication()
        app.launch()
        app.startTwoPlayerGame()
        app.square("c3").press(forDuration: 0.2, thenDragTo: app.square("c5"))
        XCTAssertEqual(app.square("c3").label, "c3, Light man")
        XCTAssertEqual(app.element("game.turn").label, "Light to move")
    }

    /// FR-AID-03: the selected piece is marked, for VoiceOver too.
    @MainActor
    func testUS3_selectionIsMarked() {
        let app = XCUIApplication()
        app.launch()
        app.startTwoPlayerGame()
        app.square("c3").tap()
        XCTAssertTrue(app.square("c3").isSelected)
        app.square("c3").tap()
        XCTAssertFalse(app.square("c3").isSelected)
    }
}
