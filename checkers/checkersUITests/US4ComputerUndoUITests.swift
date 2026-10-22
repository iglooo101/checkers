import XCTest

/// Undo against the computer in the running app (specs/005-computer-opponent/spec.md, US4).
final class US4ComputerUndoUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    /// FR-UNDO-03: Undo is unavailable before the player's first move, takes back the player's
    /// move and the computer's reply together, and is unavailable again back at the start.
    @MainActor
    func testUS4_undoTakesBackBothMoves() {
        let app = XCUIApplication()
        app.launch()
        app.startComputerGame(difficulty: "Easy", side: "Light")
        app.waitForTurn(startingWith: "Light to move")
        XCTAssertFalse(app.isUndoEnabled(), "Undo should be unavailable before the first move")

        app.move("c3", "d4")
        app.waitForTurn(startingWith: "Light to move")
        app.chooseFromGameMenu("Undo")
        app.waitForTurn(startingWith: "Light to move")
        XCTAssertEqual(app.square("c3").label, "c3, Light man, can move")
        XCTAssertEqual(app.square("d4").label, "d4, empty")
        for name in ["b6", "d6", "f6", "h6", "a7", "c7", "e7", "g7", "b8", "d8", "f8", "h8"] {
            XCTAssertTrue(
                app.square(name).label.hasPrefix("\(name), Dark man"),
                "\(name) reads \"\(app.square(name).label)\"")
        }
        XCTAssertFalse(app.isUndoEnabled(), "Undo should be unavailable back at the start")
    }
}
